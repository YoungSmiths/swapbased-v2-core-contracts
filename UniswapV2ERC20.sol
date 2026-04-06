pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

/**
 * @title UniswapV2ERC20
 * @notice **LP Token 基类**：标准 ERC20 + **EIP-2612 permit**（离线签名授权）。由 `UniswapV2Pair` 继承，每个交易对一份 LP 份额代币。
 * @dev **谁在用**：用户加池后持有的是「本合约实现的」LP；Router `removeLiquidity` 会 `transferFrom` 用户的 LP 到 Pair 再 `burn`。
 *      **实例**：Alice 在 WETH/BASE 池加流动性，钱包里出现 `UNI-V2` 余额，即本合约逻辑下的 `balanceOf[Alice]`；撤池时把 LP 转给 Pair 销毁。
 *
 * **与 Pair 的关系**：`_mint`/`_burn` 仅由子合约 `UniswapV2Pair` 在 `mint`/`burn`/`_mintFee` 路径调用，普通用户不能凭空调用内部铸销。
 */
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    /// @notice LP 代币名称（部署后固定；具体池可在子类或工厂层覆盖元数据，标准 V2 模板为 `Uniswap V2`）。
    string public constant name = 'Uniswap V2';
    /// @notice LP 代币符号，区块浏览器与钱包展示为 `UNI-V2`。
    string public constant symbol = 'UNI-V2';
    /// @notice 小数位 18，与常见 ETH 单位一致，便于和 wei 级储备心算对照。
    uint8 public constant decimals = 18;

    /// @notice 已发行的 LP 总供应量；加池 `_mint` 增加，撤池 `_burn` 减少。
    uint  public totalSupply;

    /// @notice 每个地址持有的 LP 数量。实例：`balanceOf[Alice] = 1e21` 表示 Alice 持有 1000 个最小单位精度为 18 的 LP（视 UI 如何展示）。
    mapping(address => uint) public balanceOf;

    /// @notice `allowance[owner][spender]`：owner 允许 spender 通过 `transferFrom` 代扣的剩余额度。
    /// @dev **使用场景**：用户 `approve(Router, 额度)` 后，Router 可在撤池时把 LP 从用户转给 Pair。`uint(-1)` 表示**无限授权**，`transferFrom` 时不会递减。
    mapping(address => mapping(address => uint)) public allowance;

    /// @notice EIP-712 域分隔符，用于 `permit` 验签；构造时写入 `chainId` 与本合约地址，防跨链/跨合约重放。
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice `permit` 所签消息类型的哈希，对应类型串
    /// `Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)`。
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice 每个 owner 已用过的 `permit` 序号，防同一签名被重复使用。
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @notice 初始化 **EIP-712 DOMAIN_SEPARATOR**（名称、版本 `1`、链 ID、本合约地址）。
     * @dev **使用场景**：部署 Pair 时由继承链调用；钱包/前端签 `permit` 时必须与链上 `DOMAIN_SEPARATOR` 一致，否则验签失败。
     */
    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @notice 铸造 LP：增加 `totalSupply` 与 `to` 的余额，从 `address(0)` 记账转入。
     * @param to 接收新 LP 的地址（加池时常为流动性提供者）
     * @param value 铸造数量（wei，18 位）
     * @dev **仅内部**：由 `UniswapV2Pair.mint` / 协议费 `_mintFee` 等调用。**实例**：首池加流动性除 `MINIMUM_LIQUIDITY` 外铸给 Alice。
     */
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice 销毁 LP：扣减 `from` 余额与总供给。
     * @param from 被扣 LP 的地址
     * @param value 销毁数量
     * @dev **仅内部**：由 `UniswapV2Pair.burn` 等在把 LP 转到本合约后调用。**实例**：撤池时 Pair `burn` 销毁用户转入的 LP。
     */
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice 设置授权额度并触发 `Approval` 事件。
     * @param owner 资产持有人（LP 所有者）
     * @param spender 被授权者（如 Router）
     * @param value 允许代扣的上限
     * @dev **核心逻辑**：标准 ERC20 `allowance` 存储；`approve`/`permit` 最终都落到此函数。
     */
    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice 内部转账：仅改余额，**不**检查 allowance（由外层 `transfer`/`transferFrom` 负责）。
     * @param from 付款方
     * @param to 收款方
     * @param value 金额
     */
    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @notice **授权**：`msg.sender` 允许 `spender` 至多转移 `value` 枚 LP（供 `transferFrom` 使用）。
     * @param spender 被授权合约地址，常见为 `UniswapV2Router02`
     * @param value 额度；设为 `2^256-1`（`uint(-1)`）时常被 UI 称为「无限授权」
     * @return 恒为 `true`（与主流 ERC20 一致）
     * @dev **使用场景**：撤池前授权 Router 把 LP 从用户钱包转到 Pair；或授权聚合器合约。
     */
    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice **转账**：`msg.sender` 转 `value` 枚 LP 给 `to`。
     * @param to 收款地址
     * @param value 数量
     * @return 恒为 `true`
     * @dev **使用场景**：用户把 LP 转给冷钱包；或 **撤池时 Router 要求用户先把 LP 转到 Pair 地址**，再由 Pair `burn`（常见模式是 `transferFrom` 到 Pair，见 Router 实现）。
     */
    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice **代转**：在 `allowance[from][msg.sender]` 足够时，从 `from` 扣款并转给 `to`。
     * @param from LP 转出方（用户地址）
     * @param to 收款方
     * @param value 数量
     * @return 恒为 `true`
     * @dev **核心逻辑**：若授权为 `uint(-1)`（最大值），**不**递减 allowance，省 gas 且符合「无限授权」习惯；否则每次扣减已用额度。
     *      **使用场景**：Router `removeLiquidity` 执行 `IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity)`，把用户 LP 送到 Pair 以调用 `burn`。
     */
    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice **EIP-2612 离线授权**：用户用私钥对结构化消息签名，第三方代提交本交易，等效于 `approve(spender, value)`，**无需先发起链上 approve**。
     * @param owner 签名者（LP 持有人）
     * @param spender 被授权者
     * @param value 授权额度
     * @param deadline 签名过期时间（unix 秒），早于 `block.timestamp` 则 revert
     * @param v, r, s ECDSA 签名分量
     * @dev **核心逻辑**：按 EIP-712 拼 `digest`，`ecrecover` 必须等于 `owner`；`nonces[owner]` 自增防重放。
     *      **使用场景**：移动端钱包一次签名完成「授权 Router + 撤流动性」；Gasless 或元交易中继。
     *      **实例**：用户在前端签 `Permit(Router, liquidity, deadline, nonce)`，Router 合约先调 `pair.permit` 再 `removeLiquidity`。
     */
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
