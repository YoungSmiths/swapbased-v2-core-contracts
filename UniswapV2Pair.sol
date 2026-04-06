pragma solidity =0.5.16;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

/**
 * @title UniswapV2Pair
 * @notice 单一交易对合约：持有两种 ERC20（token0 < token1），用恒定乘积 x*y=k 做市；LP 份额为继承的 UniswapV2ERC20。
 * @dev 典型用法：用户通过 Router `addLiquidity` → 先把两种代币转入本合约 → 再调 `mint` 铸 LP；`swap` 先转出输出币再校验输入与 K。
 *
 * **实例（BASE/USDC 池）**：token0=USDC，token1=BASE，储备 100 万 USDC 与 50 万 BASE；用户用 USDC 买 BASE 时 `swap(0, amount1Out, user, "")`，池子先转 BASE 给用户，用户侧再转入 USDC，最后校验 (扣 0.3% 费后的) K 不减。
 *
 * **与公式对应**：记 `reserve0` 为 \(x\)、`reserve1` 为 \(y\)，则池子满足 \(x \cdot y = k\)（swap 在扣 0.3% 输入后仍不降低 \(k\)）。`price0/1CumulativeLast` 与 `kLast` 见下方状态变量注释。
 */
contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    /// @notice 首次加池时永久锁进 `address(0)` 的最小 LP 数量，防止首笔流动性被完全撤光导致除零或操纵（Uniswap 固定为 1000 wei LP）。
    uint public constant MINIMUM_LIQUIDITY = 10**3;

    /// @notice `ERC20.transfer` 的函数选择器，供 `_safeTransfer` 用低级 `call` 调用（兼容不返回 bool 的旧代币）。
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    /// @notice 部署本 Pair 的 Factory 合约地址；仅 Factory 可在部署后调用一次 `initialize`。
    address public factory;

    /// @notice 价格较小一侧的代币地址（按地址数值排序：token0 < token1）。实例：USDC(0x...) 与 WETH 成对时，数值小的为 token0。
    address public token0;

    /// @notice 价格较大一侧的代币地址。实例：同上池中 WETH 常为 token1。
    address public token1;

    /// @dev 与 reserve1、blockTimestampLast **打包在同一 storage slot**，节省 Gas；对外通过 `getReserves()` 读取。
    /// @notice token0 在池内记账余额（不一定等于合约内真实 balance，同步靠 `_update`/sync）。
    uint112 private reserve0;

    /// @notice token1 在池内记账余额。
    uint112 private reserve1; 

    /// @notice 最近一次 `_update` 时的区块时间戳（uint32 截断，与 Uniswap 一致用于 TWAP 时间差）。
    uint32  private blockTimestampLast;

    /**
     * @notice **token0 以 token1 计价**的链上积分累计量：每次 `_update` 在 `timeElapsed > 0` 且储备非零时，加上「现货价 × 秒数」。
     * @dev **数值特征**：正常运行下该变量**单调不减、会持续变大**（语义上在累加「价格对时间的积分」）；预言机**不要**把它的绝对值直接当现价用。
     *      **TWAP 用法**：在时刻 T1、T2 各读一次本 getter，则 TWAP ≈ (price0CumulativeLast(T2) − price0CumulativeLast(T1)) / (T2 − T1)（减法在 uint256 模意义下计算，与 Uniswap V2 Oracle 一致）。
     *      **uint256 溢出**：加法允许溢出回绕，集成方只取**两次观测的差**，不依赖绝对大小。
     */
    uint public price0CumulativeLast;

    /**
     * @notice **token1 以 token0 计价**的链上积分累计量；与 `price0CumulativeLast` 对称（现货为 `reserve0/reserve1`）。
     * @dev 同样**单调累加**、链下用**两次观测的差 ÷ 时间差**得到时间加权平均价。
     */
    uint public price1CumulativeLast;

    /// @notice 上一次流动性事件（mint/burn）后的 k=reserve0*reserve1，用于协议费 `_mintFee` 判断 k 是否增长。feeTo 为空时会被置 0。
    uint public kLast;

    /// @notice `lock` 修饰符用的重入锁：1=未锁，0=已锁。实例：swap 中途若可重入会导致储备与 K 校验不一致。
    uint private unlocked = 1;

    /// @notice 互斥锁：`swap` / `mint` / `burn` / `skim` / `sync` 执行中禁止再次进入，防止闪电贷回调重入。
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * @notice 返回池子记账储备与上次更新时间戳。
     * @return _reserve0 token0 储备（记账值）
     * @return _reserve1 token1 储备（记账值）
     * @return _blockTimestampLast 上次 `_update` 写入的区块时间（mod 2^32）
     */
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * @notice 兼容非标准 ERC20 的转账：用 `call` + 检查返回 data。
     * @param token 代币合约地址
     * @param to 收款地址
     * @param value 转账数量（wei）
     */
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    /// @notice 添加流动性：Router 转入 token 后调 `mint`，给 `to` 铸 LP。`amount0/1` 为相对旧储备的增量。
    event Mint(address indexed sender, uint amount0, uint amount1);
    /// @notice 销毁流动性：LP 先转入 Pair 再 `burn`，向 `to` 转出两种底层币。
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    /// @notice 交换：记录实际进出量与接收地址 `to`（可与 `msg.sender` 不同，如路由最后一跳）。
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    /// @notice 储备与 TWAP 累计已更新（`reserve0/1` 为最新记账值）。
    event Sync(uint112 reserve0, uint112 reserve1);

    /// @notice 构造：由 Factory `createPair` 部署时调用，`factory` 记为 Factory 地址。
    constructor() public {
        factory = msg.sender;
    }

    /**
     * @notice 初始化交易对两种代币地址；仅能由 Factory 在创建 Pair 后调用一次。
     * @param _token0 较小地址的代币
     * @param _token1 较大地址的代币
     */
    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice 用当前合约内真实 `balance` 更新 `reserve`、时间戳，并在跨区块时累加「价格×时间」供 TWAP。
     * @param balance0 当前 token0 在合约内的余额（通常刚完成转账后的读数）
     * @param balance1 当前 token1 在合约内的余额
     * @param _reserve0 更新前的旧 reserve0（用于算时间差内应累加的累计价）
     * @param _reserve1 更新前的旧 reserve1
     * @dev **与累计器的关系**：`price0CumulativeLast` / `price1CumulativeLast` 在每次满足条件时加上 **现货 × Δt**（UQ112 下），故长期看是**不断变大的累加器**；**瞬时价格**仍看 `reserve1/reserve0`，TWAP 必须由链下/预言机对累计量做差分。
     *      实例：若上一笔与当前不在同一块且储备非零，则 `price0CumulativeLast += (reserve1/reserve0) * Δt`（在 UQ112x112 定点下）。
     */
    // 更新 reserve 与区块时间戳；每区块首次调用时累加 price*N 用于链上 TWAP
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            // TWAP 累计器：在「上一笔 _update 到此刻」这段秒数 timeElapsed 内，用**当时的现货价**做
            //   累加 += 现货价 × 秒数（UQ112 定点下先 encode 再 uqdiv，避免整数除法丢精度）。
            // - price0CumulativeLast：token0 以 token1 计价，现货 = reserve1/reserve0（例：token0=USDC、token1=BASE
            //   且 reserve0=1000、reserve1=500，则 1 USDC 值 0.5 BASE，累计量在这段时间里按该比每秒增厚）。
            // - price1CumulativeLast：对称，现货 = reserve0/reserve1（1 BASE 值多少 USDC）。
            // 链下预言机对两次观测点做差并除以时间差，即得这段时间的**时间加权平均价**（见 Uniswap V2 白皮书 TWAP）。
            // 补充：两累计量在链上会持续增大；同区块内多次 _update 时 timeElapsed==0 本段不执行，不会重复加。
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        // 行级：把链上实际余额写回「官方储备」，供下次 swap/mint 使用
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /**
     * @notice 若 Factory 开启协议费（feeTo 非零），在 k 增大时向 feeTo 铸造一小部分 LP（Uniswap 经典 1/6 增长份额公式变体）。
     * @param _reserve0 调用时刻的 token0 储备
     * @param _reserve1 调用时刻的 token1 储备
     * @return feeOn 是否开启协议费
     * @dev 实例：交易费积累使 k 上升，协议可抽取相当于 sqrt(k) 边际增长的一部分 LP，避免直接用转账抽手续费。
     */
    // 协议费开启时：按 sqrt(k) 增长的一部分铸造 LP 给 feeTo（Uniswap 经典公式）
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    // 行级：总供给 * (sqrt(K)-sqrt(K_last)) / (5*sqrt(K)+sqrt(K_last)) → 应铸给 feeTo 的 LP 份额（推导见 Uniswap 白皮书）
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /**
     * @notice 铸造 LP：应在 Router 已将「多于旧储备」的 token0/token1 转入本合约后调用。
     * @param to 接收新铸 LP 的地址（常为最终用户或 Router）
     * @return liquidity 本次铸给 `to` 的 LP 数量（不含锁进 0 地址的 MINIMUM_LIQUIDITY）
     * @dev **首笔加池**：流动性 = sqrt(amount0*amount1) - MINIMUM_LIQUIDITY，且 1000 wei LP 永久销毁给 `address(0)`，防止单价操纵。
     *      **后续加池**：按 `min(amount0/reserve0, amount1/reserve1) * totalSupply` 取较小值，避免只单边注资套利。
     *      实例：首池存入 100 USDC + 100 BASE → sqrt(1e4*1e4) 量级减 1000 wei；再有人按比例多存 10 USDC+10 BASE，按份额比例拿 LP。
     */
    // this low-level function should be called from a contract which performs important safety checks
    // 典型调用：UniswapV2Router.addLiquidity / addLiquidityETH —— 先把两种 token transfer 进本合约，再调 mint(to)，
    // 否则 amount0/amount1 为 0 会 INSUFFICIENT_LIQUIDITY_MINTED；Router 里也会用 Pair 余额与期望最小量做校验。
    function mint(address to) external lock returns (uint liquidity) {
        // _reserve*：上一笔 swap/mint/burn 末尾 _update 写入的「会计储备」；balance*：当前 ERC20 在本合约的实有余额。
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        // 行级：balance - reserve = 自上次记账以来净转入量；正常加池场景下即 Router 已转入、尚未被 _update 写回储备的那部分。
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            // 行级：首次流动性，几何平均减最小流动性锁定
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            // 行级：按两侧注资比例取 min，保证不会仅凭单边多转代币套取超额 LP
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        // 把 reserve0/1 同步为当前 balance，下一笔 mint 的「增量」又从新的快照算起（与 swap 末尾同理）。
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @notice 销毁流动性：调用前需先把要销毁的 LP `transfer` 到本合约地址。
     * @param to 接收两种底层代币的地址
     * @return amount0 转出的 token0 数量
     * @return amount1 转出的 token1 数量
     * @dev 按当前合约余额（含手续费、捐赠等）按比例分配，故用 balance 而非仅用 reserve 计算。
     *      实例：用户把 100 LP 转到 Pair 再 `burn(user)`，按 LP/总供给比例取池内 USDC 与 BASE。
     */
    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // 行级：本合约持有的 LP = 用户刚转进来待销毁的份额
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * @notice 交换：按指定输出量先转 token 给 `to`，再要求输入侧补足并使 (扣费后) K 不降低。
     * @param amount0Out 要从池子转出的 token0 数量；单向买 BASE 时常为 0
     * @param amount1Out 要从池子转出的 token1 数量
     * @param to 接收输出代币的地址；若 `data` 非空则还会被回调 `uniswapV2Call`
     * @param data 可选；非空时在转出后调用 `IUniswapV2Callee(to).uniswapV2Call`，用于闪电贷套利
     * @dev 手续费 0.3%：对输入量抽 3/1000，等价于调整后的 balance 乘积 ≥ 旧 reserve 乘积 × 1000²。
     *      实例：池内 100 万 USDC、50 万 BASE，用户买 1 万 BASE → `amount1Out=1e4*10^18`，先转 BASE 给用户，用户再转入约对应 USDC（Router 完成），校验 K。
     */
    // 先按输出量乐观转账，再可选回调 uniswapV2Call，最后根据实际转入量校验 K（含 0.3% 费）
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        // 行级：禁止输出直接打到 token 合约地址，避免破坏余额会计
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        // 行级：乐观发送：先让用户/回调方拿到输出，再在下面检查输入是否到账
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        // 行级：闪电贷/套利合约在此还款或继续调外部 DEX（实例：先借 USDC，再去 Uniswap 卖成 ETH）
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        // 行级：转账与回调结束后读取真实余额，用于推导「实际输入量」
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        // 行级：实际净流入 = 当前余额 − (旧储备 − 已转出)；单边输入时另一边为 0
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        // 手续费 0.3%：输入侧按 amountIn*3/1000 从 balance 中扣除后再比较 K，等价于保留乘积不减
        // 行级：虚拟扣费——把输入乘 997/1000 后再与另一边的 balance 相乘，与旧 k*1000² 比较
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice 将合约内「多于记账储备」的多余代币转给 `to`（误转、捐赠、部分代币有反射等导致 balance > reserve）。
     * @param to 接收多余 token0/token1 的地址
     * @dev 实例：有人直接向 Pair 转 USDC 未调 mint，任何人可 `skim` 把多出的部分领走（通常项目会说明或 Router 避免误转）。
     */
    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    /**
     * @notice 强制用当前 ERC20 余额覆盖记账储备（不设转账），用于代币余额与 reserve 不同步时的修复。
     * @dev 实例：某些边缘代币转账后 Pair 实际余额与 reserve 不一致，可 sync 对齐；**会改变储备与价格**，需慎用。
     */
    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
