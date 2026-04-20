/**
 *Submitted for verification at FtmScan.com on 2022-10-28
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/libraries/SafeMath.sol

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



/**
 * @title UniswapV2Library（Solidity `library`，内嵌于本文件）
 * @notice 无状态工具库：算 Pair 地址、读储备、**加池比例报价**（`quote`）与 **swap 询价**（`getAmountOut`/`getAmountIn`），以及路径多跳串联。
 * @dev **谁在用**：`UniswapV2Router02` 的加池、swap、页面询价几乎全部委托本库。
 *
 * **两条「定价」线（一看就懂）**
 * - **`quote`**：按池子储备比例做 **线性换算**，**不收** 0.3% 手续费 → 用于 `_addLiquidity` 算「另一侧该打多少」。
 * - **`getAmountOut` / `getAmountIn`**：恒定乘积 \(x\cdot y=k\) 下，输入先乘 **997/1000** 再算输出 → 与 `UniswapV2Pair.swap` 的扣费一致。
 *
 * **参数习惯**：`reserveIn`/`reserveOut` 表示「**即将参与 swap 的那一池**」在 **input→output** 方向上的两侧储备（与 `path[i]`→`path[i+1]` 对齐）。
 */
library UniswapV2Library {
    using SafeMath for uint;

    /**
     * @notice 把任意顺序的 `(tokenA, tokenB)` 排成 **token0 &lt; token1**，与 Factory 存 Pair、Pair 内 `token0/token1` 顺序一致。
     * @param tokenA 代币 A 地址（可与 B 互换传入顺序）
     * @param tokenB 代币 B 地址
     * @return token0 地址较小的一侧
     * @return token1 地址较大的一侧
     * @dev **使用场景**：后面 `pairFor`、`getReserves` 都依赖统一顺序，避免「同一对币两种写法」导致错池。
     *      **实例**：`0xUSDC` 与 `0xWETH` 谁前谁后无所谓，排完后永远 `token0=USDC`（若 USDC 地址更小）。
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    /**
     * @notice **CREATE2 离线推导** Pair 合约地址，**不发交易**即可知道「这对币的池子将在/已在哪个地址」。
     * @param factory 部署 Pair 的 Factory 地址（不同 Factory → 不同 Pair 地址）
     * @param tokenA、tokenB 交易对两种代币（顺序任意）
     * @return pair 该交易对在链上应对应的 Pair 地址（若从未 `createPair`，链上可能尚无代码）
     * @dev **核心逻辑**：`keccak256(0xff, factory, salt, initCodeHash)`，其中 `salt = hash(token0,token1)`，与本文件底部 **init code hash 常量** 绑定；Factory 升级 Pair 实现后该哈希必须同步改 Router。
     *      **使用场景**：Router 在 `addLiquidity` 里 `transferFrom(user, pair, …)` 前要先知道 `pair`；前端与 `factory.getPair` 交叉验证。
     *      **实例**：Base 上同一对币在 A、B 两个 Factory 下会算出 **两个不同** pair 地址。
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'b64118b4e99d4a4163453838112a1695032df46c09f7f09064d4777d2767f8ea' // init code hash
            ))));
    }

    /**
     * @notice 读取 **某一对** `(tokenA, tokenB)` 在链上 Pair 中的 `reserve0/reserve1`，再按 **你传入的 A/B 顺序** 映射回 `reserveA/reserveB`。
     * @param factory Factory 地址（决定用哪个 `pairFor`）
     * @param tokenA 你心里的「A 侧」代币（如路径上的 input）
     * @param tokenB 「B 侧」代币（如 output）
     * @return reserveA 与 `tokenA` 同币种的储备量
     * @return reserveB 与 `tokenB` 同币种的储备量
     * @dev **核心逻辑**：先 `pairFor` → `IUniswapV2Pair.getReserves()` 得 `(reserve0, reserve1)`，若 `tokenA` 实际是 token1，则把两数对调。
     *      **使用场景**：`getAmountOut(amounts[i], …)` 前要拿到「input 币相对 output 币」的两边储备；多跳里每一跳都调用一次。
     *      **实例**：路径 `USDC → BASE`，调用 `getReserves(f, USDC, BASE)` 得 `reserveIn=USDC储备`、`reserveOut=BASE储备`，正好喂给 `getAmountOut`。
     */
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @notice **无手续费** 的比例换算：若价格 = `reserveB/reserveA`，则 `amountA` 个 A「等价」于多少 B。
     * @param amountA 已知的 A 侧数量（如用户打算注入的 tokenA 数量）
     * @param reserveA、reserveB **同一池内** A、B 两侧储备（须与 amountA 同一单位/精度）
     * @return amountB 与 amountA 同比的 B 侧数量：`amountA * reserveB / reserveA`（整除向下取整）
     * @dev **核心逻辑**：纯比例，**不是** swap；不碰 997/1000。
     *      **使用场景**：`Router._addLiquidity` 在 **已有流动性** 时，根据用户想多存的一侧，算另一侧 **最少应存多少** 才能保持池子价格比例。
     *      **实例**：池内 1000 USDC : 500 BASE，你想再存 200 USDC，则 `quote(200, 1000, 500)=100` BASE（若你少于 100 BASE 且低于 min 会 revert）。
     *      **对比**：若用 `getAmountOut` 把 200 USDC 当「卖出」去换 BASE，会 **少于** 100（因扣 0.3%），那是交易，不是加池比例。
     */
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     * @notice **单池 swap 正向询价**：给定 `amountIn`（输入代币数量），在恒定乘积模型下求 **最大可得** `amountOut`。
     * @param amountIn 打入池子的输入量（尚未扣费；函数内按 **0.3%** 处理：`amountIn * 997/1000` 进入乘积公式）
     * @param reserveIn 输入币在池内的储备
     * @param reserveOut 输出币在池内的储备
     * @return amountOut 输出币数量（整除向下取整）
     * @dev **公式推导（与 `UniswapV2Pair.swap` 的 K 校验一致）**：
     *      1. **恒定乘积**：交换前后储备满足 \((x + \Delta x_{\text{eff}})(y - \Delta y) = xy\)，此处 \(x=\texttt{reserveIn}\)，\(y=\texttt{reserveOut}\)，\(\Delta y=\texttt{amountOut}\)。
     *      2. **0.3% 费在输入侧**：用户打入 `amountIn`，只有 \(\frac{997}{1000}\) 计入「有效增量」参与乘积，即 \(\Delta x_{\text{eff}} = \texttt{amountIn} \cdot \frac{997}{1000}\)（另 \(\frac{3}{1000}\texttt{amountIn}\) 视为手续费留在池内，不进入该乘积等式右侧的 \(xy\) 比较方式与 Pair 实现一致）。
     *      3. **代入**：\((\texttt{reserveIn} + \texttt{amountIn}\cdot\frac{997}{1000})(\texttt{reserveOut} - \texttt{amountOut}) = \texttt{reserveIn}\cdot\texttt{reserveOut}\)。
     *      4. **解 \(\texttt{amountOut}\)**：由 \(\texttt{reserveOut} - \texttt{amountOut} = \dfrac{\texttt{reserveIn}\cdot\texttt{reserveOut}}{\texttt{reserveIn} + \texttt{amountIn}\cdot\frac{997}{1000}}\)，得
     *         \(\texttt{amountOut} = \texttt{reserveOut} - \dfrac{\texttt{reserveIn}\cdot\texttt{reserveOut}}{\texttt{reserveIn} + \texttt{amountIn}\cdot\frac{997}{1000}}
     *         = \dfrac{\texttt{reserveOut}\cdot\texttt{amountIn}\cdot\frac{997}{1000}}{\texttt{reserveIn} + \texttt{amountIn}\cdot\frac{997}{1000}}\)。
     *      5. **整数实现**：分子分母同乘 \(1000\) 消去分式，即
     *         \(\texttt{amountOut} = \dfrac{997\cdot\texttt{amountIn}\cdot\texttt{reserveOut}}{1000\cdot\texttt{reserveIn} + 997\cdot\texttt{amountIn}}\)，
     *         对应代码 `numerator = amountIn*997*reserveOut`，`denominator = reserveIn*1000 + amountIn*997`，最后 **向下取整**。
     *      **使用场景**：`swapExact*`、`getAmountsOut` 每一跳；前端展示「我卖 X 能买多少 Y」。
     *      **实例**：深池里卖 10,000 USDC，`amountOut` 略小于用现货价 `quote` 算出的值（因 997/1000）。
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator; // 本质上是：Δy = y *( Δx / (Δx + x))
    }

    /**
     * @notice **单池 swap 反向询价**：希望 **恰好拿到** `amountOut` 个输出币，求 **至少需要** 多少输入币。
     * @param amountOut 目标输出量（必须 &lt; reserveOut，否则池子流动性不足）
     * @param reserveIn、reserveOut 与 `getAmountOut` 同含义
     * @return amountIn 所需输入量；公式末尾 **+1** 保证在整数除法下仍满足 Pair 的 K 约束
     * @dev **核心逻辑**：由 `getAmountOut` 反解；`+1` 避免链上整除导致实际输入略小而换不到宣称的 `amountOut`。
     *      **使用场景**：`swapTokensForExactTokens`、`swapETHForExactTokens`、`getAmountsIn` 每一跳。
     *      **实例**：「我要精确 1,000 BASE」→ 算出至少付多少 USDC；用户再设 `amountInMax` 防滑点。
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    /**
     * @notice **多跳正向询价**：给定路径首端输入 `amountIn`，沿 `path` 逐池用 `getAmountOut` 串联，得到 **每一跳之后** 的资产数量。
     * @param factory 用于 `getReserves` / `pairFor` 的 Factory
     * @param amountIn 路径起点 `path[0]` 上的输入数量
     * @param path 代币地址序列，长度 ≥2，相邻两项对应一个 Pair，例如 `[USDC, WETH, BASE]`
     * @return amounts 长度与 `path` 相同；`amounts[i]` 表示走到第 `i` 个节点时的代币余额（币种为 `path[i]`）
     * @dev **核心逻辑**：对 `i = 0 … len-2`，取池 `(path[i], path[i+1])` 的储备，把 `amounts[i]` 当输入，`amounts[i+1]=getAmountOut(...)`。
     *      **使用场景**：Router `swapExactTokensForTokens` 先算整条路径再 `_swap`；前端展示「卖 100 USDC 最终得多少 BASE」。
     *      **实例**：`path = [USDC,WETH,BASE]`，`amounts = [100e6, w1, b1]`，滑点主要看 `b1` 是否 ≥ `amountOutMin`。
     */
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @notice **多跳反向询价**：固定路径 **末端** 想得到 `amountOut`（`path[path.length-1]` 的数量），反推 **首端** 至少需要多少 `path[0]`。
     * @param factory Factory 地址
     * @param amountOut 最后一跳产出的目标数量（用户「想买多少」）
     * @param path 与 `getAmountsOut` 相同；算法从 **最后一格向前** 填
     * @return amounts `amounts[len-1]=amountOut`，`amounts[0]` 为所需首端输入 **下限**
     * @dev **核心逻辑**：`i` 从 `len-1` 递减到 `1`，对池 `(path[i-1], path[i])` 调用 `getAmountIn(amounts[i], …)` 得到 `amounts[i-1]`。
     *      **使用场景**：`swapTokensForExactTokens`、`swapETHForExactTokens`；前端显示「买到 X 个 BASE 最多要花多少 USDC」。
     *      **实例**：路径 `[USDC,WETH,BASE]`，想要 `1 BASE`，可能算出 `amounts[0]=50 USDC`，用户再设 `amountInMax=52` 防涨价。
     */
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/UniswapV2Router02.sol

pragma solidity =0.6.6;








/**
 * @title UniswapV2Router02
 * @notice DEX 前端/用户调用的路由合约：把「授权 + 转账 + Pair.mint/swap/burn」封装成一步，并处理 ETH↔WETH。
 * @dev 部署时注入 `factory`（创建/查找 Pair）与 `WETH`（本链包装 ETH）。所有对外 swap/加池需先对 Router 或先 permit。
 *
 * **典型流程（一看就懂）**
 * - **双币加池**：用户授权两种 ERC20 → `addLiquidity`：Router 按池子比例算出实际注入量，转入 Pair → `mint(to)` 得 LP。
 * - **ETH 加池**：用户随交易附带 `msg.value` → `addLiquidityETH`：多余 ETH 会退回；内部把 ETH 换成 WETH 再与 TOKEN 成对。
 * - **精确输入换币**：`swapExactTokensForTokens`：指定「我出 100 USDC，最少收多少 BASE」，path 可多跳。
 * - **精确输出换币**：`swapTokensForExactTokens`：指定「我要正好 50 BASE，最多付多少 USDC」。
 *
 * `deadline`：用户签名或 UI 填「此交易最晚有效时间」，过期整笔回滚，避免 mempool 里挂太久被不利成交。
 */
contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;

    /// @notice 本 Router 绑定的 UniswapV2Factory，用于 `getPair`/`createPair` 及 Library 里算 Pair 地址。
    address public immutable override factory;
    /**
     * @notice 本链 **已部署的** WETH（Wrapped 原生 gas 币）合约地址，类型上按 `IWETH` 调用（`deposit`/`withdraw`/`transfer`）。
     * @dev **WETH 是什么**：把链上原生币（如 ETH）1:1 包装成 **ERC20**，才能和别的代币一样进 Pair 的 `token0/token1`；池子里流动性是 **WETH+TOKEN**，不是裸原生币余额。
     *      **谁部署**：一般为该链 **公开、共识使用的** WETH 实现（如主网常见 WETH9）；**不是**本仓库单独实现的业务合约，部署 Router 时把该链文档里的 WETH 地址传入构造函数即可。
     *      **代码里怎么用**：`addLiquidityETH` / `swapExactETHForTokens` 等先把 `msg.value` `deposit` 成 WETH 再转进 Pair；取款类再把 WETH `withdraw` 成原生币打给用户。
     */
    address public immutable override WETH;

    /// @notice 要求 `deadline >= block.timestamp`，过期则 `EXPIRED` 整笔回滚。
    /// @dev **实例**：用户在 12:00 签名允许交易，设 `deadline = 12:30`；若矿工 12:31 才打包，交易失败，避免用旧价格成交。
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    /// @param _factory UniswapV2Factory 部署地址
    /// @param _WETH 当前链上 WETH 地址（如 Base 上官方 WETH）
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    /// @notice 仅允许从 **WETH 合约** 向本合约发送原生 ETH（`withdraw` 时触发），其它地址直接转 ETH 会因 `assert` 失败，避免 Router 锁死用户误转的 ETH。
    /// @dev **实例**：`IWETH.withdraw` 会把 ETH 打到 `address(this)`，仅此路径合法；朋友误操作 `transfer` ETH 到 Router 地址会失败。
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****

    /**
     * @notice 计算「在已有池子比例下」本次应注入的 tokenA/tokenB 数量；无池则首注用 desired 全额。
     * @param tokenA、tokenB 两种资产（顺序任意，内部会 sort）
     * @param amountADesired/amountBDesired 用户愿意出的上限（类似滑点上限一侧）
     * @param amountAMin/amountBMin 另一侧最低接受量（防被夹：比例变化过大则 revert）
     * @return amountA、amountB 实际将转入 Pair 的数量
     * @dev **有池时**：用 `quote` 保持与 reserve 同比；若一侧 desired 过剩则收缩另一侧到最优，并检查 min。
     *      **实例**：池里 USDC:BASE=2:1，你想加 2000 USDC+800 BASE → 会收敛为 1600 USDC+800 BASE（按池比例），若少于你的 min 则失败。
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // 若链上尚无该交易对：先 createPair。例：某新币首次与 USDC 组池，Factory 会部署新 Pair 合约。
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        // 读当前池内两侧储备（按你传入的 tokenA/tokenB 顺序映射）。例：已有 100 万 USDC 与 500 ETH 流动性。
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        // 首注（空池）：用户给多少就按多少注入，**比例由用户自定**，此后池子价格由这笔首注决定。例：首注 1 USDC + 1 某 meme，初始价即 1:1。
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 已有流动性：按池子现价用 quote 算「若打满 amountADesired 的 A，另一侧应配多少 B」。例：池 2:1，想加 2000 A 则最优 B=1000。
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                // 用户愿意给的 B 够用：打满 A 侧，B 只取最优量（可能小于 desired）。例：只消耗 800 B 即可与 2000 A 成比例。
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                // 用户给的 A 相对过多：改为打满 B 侧，用 quote 反算需要多少 A。例：只想加 500 B，则算出只需 1000 A。
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice **双 ERC20 加流动性**：从 **`msg.sender`** 拉取两种代币进 Pair，再 `mint(to)` 把新 LP 发给 **`to`**。
     * @param to **LP 接收方**，由调用者填写；**不必**等于 `msg.sender`。
     * @return amountA、amountB 实际注入量；liquidity 本次铸造的 LP 数量
     * @dev **扣款 vs 收 LP**：`safeTransferFrom(..., msg.sender, pair, ...)` 只从 **调用者** 扣 `tokenA`/`tokenB`，故 **`approve(Router)` 须由 `msg.sender` 完成**；`Pair.mint(to)` 把 LP 记入 **`to`** 的 `balanceOf`。
     *      **常见相同**：个人在 UI 加池，填 `to = 本人地址`，此时 `to == msg.sender`。
     *      **常见不同**：① **金库/多签** 发起交易但希望 LP 记在 `to = 协议金库`；② **聚合/代理合约** 代用户调用且合约自己持有代币时 `msg.sender` 为合约，仍可将 `to` 设为用户 EOA（视业务是否先把币转入合约）；③ **一键发 LP 给合作方** 由付款方调 Router，`to = 合作方地址`。
     *      **核心顺序**：`_addLiquidity` → `transferFrom`×2（from 均为 `msg.sender`）→ `Pair.mint(to)`。
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        // 算出本次实际注入量（可能小于 desired，以贴合池子比例）。例：想加 2000A+2000B，池 2:1 时实际 2000A+1000B。
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 从调用者钱包扣 tokenA 进 Pair。例：用户已 approve Router 花 USDC。
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        // 同理扣 tokenB。两笔都成功后 Pair 余额增加，mint 才有依据。
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // Pair 按新增余额/总供应铸 LP，发给 to。例：收到 0.01 LP 代表占有池子份额。
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /**
     * @notice **ETH + 单币加池**：`msg.value` 作为 ETH 侧上限；ERC20 从 `msg.sender` 扣；LP 发给 **`to`**（含义同 `addLiquidity`）。
     * @param to 接收 LP 的地址，可与 `msg.sender` 不同（见 `addLiquidity` 注释）。
     * @return amountToken、amountETH 实际注入的代币与 ETH（WETH 计量）；liquidity 铸造的 LP
     * @dev **ETH 与退款**：实际用于 `deposit` 的 ETH 为 `amountETH`，若 `msg.value > amountETH`，**多余原生币退回 `msg.sender`**（与 `to` 无关）。
     *      **代币侧**：`token` 仍 `transferFrom(msg.sender, pair, amountToken)`，须 **`msg.sender` 已 approve**。
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        // ETH 侧用 msg.value 作为「desired」参与比例计算；token 侧用 amountTokenDesired。例：附 1 ETH + 最多 3000 项目币。
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // 从用户拉 ERC20 进 Pair（ETH 不能 approve，故 token 仍走 transferFrom）。
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        // deposit：从本合约携带 amountETH 原生币存入 WETH 合约，给本 Router 地址 1:1 增加 WETH 余额（池子只认 ERC20，不认裸 ETH）。
        IWETH(WETH).deposit{value: amountETH}();
        // transfer(pair)：把等额 WETH 打进 Pair，与上一行已转入的 token 一起形成「两侧增量」，供 mint 使用。
        assert(IWETH(WETH).transfer(pair, amountETH));
        // mint(to)：Pair 用余额减旧 reserve 算流动性，向 to 铸造 LP（扣款方仍是 msg.sender，收 LP 方为 to）。
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund：若用户附带的 msg.value 大于实际注入的 amountETH，多余 wei 退回 msg.sender（ETH 找零与 to 无关）。
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****

    /**
     * @notice **移除双币流动性**：把 LP 从用户转到 Pair，再 `burn` 按比例取回 tokenA/tokenB。
     * @param liquidity 要销毁的 LP 数量（用户须已 `approve` Router 或先 `permit`）
     * @param amountAMin/amountBMin 两侧最低可取回量（滑点保护）
     * @param to 接收两种代币的地址
     * @return amountA、amountB 实际取回的两种代币数量
     * @dev **核心顺序**：`pair.transferFrom(user→pair)` → `burn(to)`。**使用场景**：做市商撤出资金到钱包。
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 把 LP 从用户划到 Pair 合约地址，burn 才能销毁 LP 并按份额释放底层币。例：撤 100 LP。
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        // burn(to)：销毁 LP，把 token0/token1 打给 to（此处 to 在 ETH 撤池变体里会是 address(this)）。例：拿回 USDC+BASE。
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        // 把 (amount0,amount1) 映射回用户传入的 tokenA/tokenB 顺序，便于与 amountAMin/BMin 比较。
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        // 滑点：任一侧少于用户底线则 revert。例：暴跌时池比例变差，取回量可能低于预期。
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    /**
     * @notice **移除 TOKEN/ETH 池**：内部仍是 TOKEN–WETH Pair，`burn` 后把 WETH `withdraw` 成原生 ETH 打给 `to`。
     * @dev **使用场景**：用户只想拿回 ETH + 项目币；Router 先 `removeLiquidity` 到 `address(this)` 再 unwrap。
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        // 底层仍撤 TOKEN/WETH 池，LP 从用户进 Pair；底层币先打到 Router（address(this)）以便先 unwrap WETH。
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // ERC20 直接转给用户。例：项目币回钱包。
        TransferHelper.safeTransfer(token, to, amountToken);
        // WETH 销毁换出等量原生币到本合约。
        IWETH(WETH).withdraw(amountETH);
        // ETH 打给用户。例：ETH 回 MetaMask。
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @notice 与 `removeLiquidity` 相同，但先用 **EIP-2612 permit** 授权 LP，省去单独 `approve` 交易。
     * @dev **使用场景**：移动端/聚合器用签名一键撤池；`approveMax` 为 true 时常量授权 Router。
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     * @notice `removeLiquidityETH` + permit，一步签名撤 ETH 池流动性。
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    // 「转账扣税」代币说明：链上**没有**由 Router 维护的白名单；是否扣税完全由**该 token 合约**在 transfer 里实现。
    // 常见含费类型：项目自定义买卖/转账税（营销、回流 LP、销毁）、部分反射/重基类代币；**标准 USDC、WETH、未改动的 OZ ERC20** 等通常转账全额到账。
    // 识别方式：读代币源码或文档、区块浏览器小额试转对比 balance；本合约无法自动判断某地址是否为税币。

    /**
     * @notice **撤 ETH 池（支持转账抽税代币）**：`burn` 后不把 `amountToken` 当确定值，而是把 Router 持有的该 token **余额全转** `to`。
     * @return amountETH 仍按 WETH 计量返回（非税币侧）
     * @dev **哪些代币会 transfer 扣税**：无固定列表；由**各代币合约**自行实现（常见为项目税、反射币等，见本节上方行注释）。主流稳定币与规范 ERC20 通常不扣。
     *      **为何存在（「卡死」= 整笔交易 revert，用户撤不出池）**：
     *      标准 `removeLiquidityETH` 在 `burn` 后会 `safeTransfer(token, to, amountToken)`，`amountToken` 来自 Pair 公式。
     *      若该 token **转出即扣税**（fee-on-transfer），Pair → Router 实际到账可能 **少于** `amountToken`（例如名义 1000、扣 10% 后 Router 仅 900），
     *      再按 **1000** 转给用户会因余额不足而 **revert**，撤池一直失败。
     *      本函数改为 `safeTransfer(token, to, balanceOf(this))`，只转**实有余额**，避免上述情况。
     *      **代价**：返回值中 token 侧不保证等于内部 `amountToken` 变量，仅保证 ETH 侧 min 已通过 `removeLiquidity` 检查。
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // 税币：Pair 已把 token 打进本合约，但到账可能少于 burn 返回值；按「实有余额」一次转给 to，避免按名义 amount 转出导致余额不足 revert。
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @notice 上者 + permit，适合「税币 + ETH」池一键撤流动性。
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****

    /**
     * @notice 多跳兑换内核：**首池已收到输入资产**（余额已增加）后，按 `amounts[]` 逐池 `swap`，中间跳把输出直接打进下一池。
     * @param amounts 每跳结束后的数量（与 path 等长），由 `getAmountsOut` 或 `getAmountsIn` 事先算好
     * @param path 代币地址路径，如 [USDC, WETH, BASE]
     * @param _to **最后一跳**接收最终输出代币的地址；非最后一跳时 `to` 为下一池 Pair，以省 gas、避免二次转账
     * @dev **为何首笔须先到账**：`Pair.swap` 会校验 K，输入须已进池；外层函数负责 `transferFrom` 或 WETH 转入第一池。
     */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            // 当前这一跳的输入币、输出币。例：i=0 时 input=USDC，output=WETH。
            (address input, address output) = (path[i], path[i + 1]);
            // Pair 合约里 reserve0/1 固定按 token0<token1，这里确定谁是 token0 以便填 amount0Out/amount1Out。
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            // 本跳应输出的数量（已在链下/库中按 0.3% 费算好）。例：第二跳应出 0.4 WETH。
            uint amountOut = amounts[i + 1];
            // 只有一侧有输出：swap 要么出 token0 要么出 token1，另一侧为 0。例：若 input 是 token1，则 amount0Out=amountOut。
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            // 非最后一跳：把输出直接打到「下一跳的 Pair」，省一次中转 gas；最后一跳打到用户指定的 _to。例：USDC→WETH→BASE，第一跳到 WETH-BASE 池地址。
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            // 调用 Pair.swap：池子已在上一笔 transfer 中收到 input，此处只校验 K 并转出 output。
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @notice **精确输入**：付出恰好 `amountIn` 的首资产，沿 path 换出，**最少**收到 `amountOutMin`（末资产）。
     * @param amountIn 输入数量（wei/最小单位）
     * @param amountOutMin 最后一跳输出下限，低于则 `INSUFFICIENT_OUTPUT_AMOUNT`（滑点保护）
     * @param path 兑换路径，首元素为用户付出的代币
     * @param to 最终收款地址
     * @return amounts 每一跳后的数量，便于前端展示
     * @dev **使用场景**：「我出 100 USDC 买 BASE，最少收 95 BASE」；先 `getAmountsOut` 再 `_swap`。
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 整条路径正向询价：amounts[0]=amountIn，末项为预计到手的目标币数量。例：100 USDC 经两跳得 95 BASE。
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 末币实际数量（询价）不得低于用户底线，否则宁可不做（防夹子/暴涨暴跌）。例：最少要 90 BASE。
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 把首币从用户直接打进第一池 Pair，使 Pair 余额增加，随后的 swap 才能通过 K 检查。
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // 按预计算好的每跳输出量依次 swap，最终目标币到 to。
        _swap(amounts, path, to);
    }

    /**
     * @notice **精确输出**：希望最后一跳**正好**得到 `amountOut`，愿意付出的首资产**不超过** `amountInMax`。
     * @return amounts[0] 为实际从用户拉取的首资产数量（≤ amountInMax）
     * @dev **使用场景**：「我要正好 1000 BASE，最多付 500 USDC」；用 `getAmountsIn` 反推首端输入。
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 反向询价：固定最后一跳输出 amountOut，反推首端至少要付多少 path[0]。例：正好要买 1000 BASE，算出需 50 USDC。
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 若涨价导致需要超过用户愿意支付的上限，则 revert。例：最多只出 52 USDC，算出要 55 则失败。
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 只从用户扣算出的首端输入（≤ amountInMax），打进第一池。
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice **用原生 ETH 做「精确输入」换 ERC20**：随交易发送的 `msg.value` 即为本笔要卖出的 ETH 数量（wei），合约先 wrap 成 WETH 再按 path 多跳 swap。
     * @dev **使用场景**：用户只有 ETH、想一键买任意 ERC20（如 BASE、某 meme），无需事先手动 WETH.deposit 再 approve。前端常见：Uniswap/聚合器「用 ETH 支付」按钮。
     * **实例**：用 0.5 ETH 买 BASE，`path = [WETH, BASE]`；`amountOutMin` 设为「最少收到 1200 BASE」；`to` 填自己钱包；过期时间设 `block.timestamp + 20 分钟`。
     * @param amountOutMin 路径**最后一跳**（目标代币）最少收到数量；低于则整笔 revert。例：预估能买 1000 币，设 970 防 3% 滑点。
     * @param path 代币地址序列，**首元素必须是本链 WETH 地址**（与状态变量 `WETH` 一致）。例：`[WETH, USDC, 某山寨]` 表示 ETH→USDC→山寨；不能写成 `[USDC, …]` 开头。
     * @param to 收到**最终 ERC20** 的地址（EOA 或合约）。例：个人地址；或 DCA/策略合约代收。
     * @param deadline 交易截止时间（Unix 秒），与 `ensure` 修饰符配合；例：当前时间 + 600，防交易在 mempool 挂太久。
     * @return amounts 长度与 `path` 相同；`amounts[i]` 为走到第 `i` 个节点时的数量；**最后一项**为实际换得的目标代币数量（与末币 `balanceOf` 一致，标准币无税时）。
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 首段必须是 WETH：否则无法把本笔 ETH 与池子的定价对齐（池子里存的是 WETH 不是裸 ETH）。例：误传 [USDC, BASE] 会直接 revert。
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 用整笔附带的 ETH 作为首端输入做链上询价；amounts[0] 恒为 msg.value。例：发 1e18 wei，则 amounts[0]=1e18。
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        // 末币数量若低于你设的「最少到手」，说明滑点或价格变动超出容忍，整笔回滚。例：只换到 800 而你要求 ≥900。
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 把询价用到的 ETH 从 Router 充入 WETH 合约，Router 获得等额 WETH 余额。标准情况下 amounts[0]==msg.value。
        IWETH(WETH).deposit{value: amounts[0]}();
        // 将等额 WETH 转入第一跳 Pair，使池子 input 侧储备增加，后续 swap 才能满足恒定乘积校验。
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        // 沿 path 执行多跳 swap；最后一跳把目标 ERC20 发给 to。例：WETH→USDC→目标币，to 收到目标币。
        _swap(amounts, path, to);
    }

    /**
     * @notice **用 ERC20 换出「精确数量」的原生 ETH**：末跳必须是 WETH；多跳结束后 Router 持有 WETH，再 `withdraw` 解包成 ETH 打给 `to`。
     * @dev **使用场景**：想从钱包**精确提现**若干 ETH（如正好 0.1 ETH 交房租），愿意多付一点项目币作为输入上限。与 `swapExactTokensForETH`（固定卖多少币）不同，本函数固定**输出 ETH 数量**。
     * **实例**：path 末为 WETH，`amountOut = 0.1 ether`，`amountInMax` 为最多愿意花的 BASE；若池子涨价导致需要 BASE 超过上限则 revert。
     * @param amountOut 希望换得的 **ETH 数量**（wei），内部以 WETH 计量 1:1。
     * @param amountInMax 愿意支付的 **首币** 上限（防涨价）。例：最多付 5000 BASE。
     * @param path 首为卖出的 ERC20，末为 WETH。例：`[BASE, WETH]` 或 `[BASE, USDC, WETH]`。
     * @param to 接收 **原生 ETH** 的地址（Router 会 withdraw 后 `safeTransferETH`）。
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 末跳必须是 WETH，否则无法在本合约内 unwrap 成 ETH。例：误写成 [BASE, USDC] 会 revert。
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 反推：要得到恰好 amountOut 的 WETH/ETH，首端需付多少 path[0]。例：精确 0.1 ETH 需卖 3000 BASE。
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 若需要的首币超过用户愿意出的上限，拒绝交易（防价格向不利方向移动）。
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 从用户只扣算出的首币数量到第一池。
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // 最后一跳输出到 Router 自己，便于集中持有 WETH 再一次性 withdraw。
        _swap(amounts, path, address(this));
        // WETH → ETH：destroy WETH 余额，等额原生币发送到本合约，随后转给 to。
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // 把 ETH 打到用户指定地址。例：冷钱包收款。
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @notice **精确输入 ERC20 换 ETH**：固定卖出 `amountIn` 个首币，换得的 WETH 至少 `amountOutMin`（再 unwrap 成 ETH 给 `to`）。
     * @dev **使用场景**：「我清仓 10000 项目币，换 ETH 落袋」，接受输出随行情变化，只保护**最少换到多少 ETH**。
     * **实例**：`amountIn = 10000e18`，`amountOutMin = 0.45 ether`，path 以 WETH 结尾；若池子太浅导致 10000 币换不到 0.45 ETH 则 revert。
     * @param amountIn 卖出的首币数量（该币最小单位）。
     * @param amountOutMin 换得的 WETH/ETH **下限**（wei）。
     * @param path 首为要卖的 ERC20，末为 WETH。
     * @param to 接收原生 ETH 的地址。
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 正向询价：固定输入 amountIn，得到每跳数量及最终 WETH 数量。
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 末币（WETH）数量低于用户容忍的最低 ETH 则失败。
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 用户首币打入第一池。
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // WETH 打到 Router 再 unwrap。
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @notice **用 ETH 换「精确数量」的 ERC20**：目标输出固定为 `amountOut`，实际消耗的 ETH 由 `getAmountsIn` 反推；**多付的 ETH 退回** `msg.sender`。
     * @dev **使用场景**：订单簿/支付场景需要「正好收到 100 USDC」，愿意多押一点 ETH 在交易里，执行后只扣需要的部分。**与** `swapExactETHForTokens`（固定花多少 ETH）正相反。
     * **实例**：要买恰好 `100e6` USDC，前端附 `0.06 ETH` 防价格波动；若链上只需 `0.052 ETH`，剩余 `0.008 ETH` 自动退回钱包。
     * @param amountOut 最后一跳代币的**精确**数量（如 USDC 的 6 位小数单位）。
     * @param path 必须以 WETH 开头。例：`[WETH, USDC]`。
     * @param to 收到目标 ERC20 的地址。
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 反推需要多少 WETH（ETH）作为输入才能买到 amountOut 的末币。
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        // 用户附带的 ETH 必须 ≥ 所需输入，否则 revert（提示附带的 ETH 不够付）。
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        // 只 wrap 需要的 ETH 量，避免多锁 WETH。
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // 若用户多付了 msg.value（常见于 UI 预留缓冲），把差额退回 msg.sender。例：附 1 ETH 仅用 0.3 ETH，退 0.7 ETH。
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // 税币范围同「撤池」一节：仅指在 transfer 中**非 1:1 到账**的代币；须用户/前端按合约地址自行判断，Router 不枚举。

    /**
     * @notice 税币 / 反射币专用多跳：不预先信任 `getAmountsOut` 的数值，每一跳用 **Pair 实际余额 − reserve** 作为输入再算输出。
     * @dev **与 `_swap` 区别**：标准 swap 假设转入额=计划值；抽税代币到账变少会导致 K 校验失败或金额不准，故用链上实测输入。
     *      **涉及哪些代币**：见本节上行注释；与「项目方自定义税/反射」类同源，**非** USDC/WETH 等标准币的默认行为。
     */
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            // 读链上储备，用于与 Pair 当前余额对比。
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            // **核心**：税币转入后 Pair 实际余额增加量可能小于名义转账额（被扣税），用「余额 − reserve」作为真实输入再算输出。例：转 1000 入账 900。
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            // 用真实输入按 AMM 公式算本跳应输出多少 output。
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @notice 税币版 **精确输入**：转入 `amountIn` 后，用 **`to` 最终代币余额增量 ≥ amountOutMin** 判定成功（无固定 amounts 数组）。
     * @dev **使用场景**：路径中含转账扣费代币；**无返回值**，前端需自行读余额或链下估算。
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        // 先把名义输入转进首池（税币可能扣费，故后面不能靠预计算的 amounts[]）。
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        // 记录 swap 前 to 在目标代币上的余额。例：swap 前 BASE 余额 0。
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // 逐跳用「实际余额增量」驱动 swap，适用于中间币有转账税的情形。
        _swapSupportingFeeOnTransferTokens(path, to);
        // 用余额差验收：最终到手增量 ≥ amountOutMin。例：swap 后 BASE 多了 950，要求 ≥900 则通过。
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice 税币版 **ETH 精确输入换代币**：全程用 `msg.value` deposit 后进首池，末资产以 `to` 的余额增量验收。
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 整笔 ETH 作为输入；若首跳后 WETH 仍有税/特殊逻辑，走支持税的分支。
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice 税币版 **代币换 ETH**：多跳到 Router 收 WETH，再按合约实际持有的 WETH 余额 `withdraw`（不用标准 `amounts` 末项）。
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // 税币从用户转进首池。
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        // 末跳到 Router，收集 WETH；不依赖预计算 amounts 最后一项，而以实际 WETH 余额为准。
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 全部 unwrap 成 ETH 打给 to（税币路径下用实际余额更稳）。
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS（对外暴露，便于前端/其它合约与 Router 同一套公式询价）****

    /// @notice 同库函数 `quote`：按比例换算，不含手续费；供前端与加池比例展示。
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /// @notice 同库函数 `getAmountOut`：单池、含 0.3% 费。
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @notice 同库函数 `getAmountIn`：单池反推所需输入。
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /**
     * @notice 绑定本 Router 的 `factory`，多跳正向询价。
     * @dev **使用场景**：UI 展示「卖出 100 A 大约得多少 B」；path 须 ≥2 且代币顺序与将用于 swap 的路径一致。
     */
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @notice 绑定本 Router 的 `factory`，多跳反向询价（给定最终输出，求首端输入）。
     */
    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}