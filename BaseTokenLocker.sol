/**
 *Submitted for verification at basescan.org on 2023-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title BaseTokenLocker
 * @author 基于 Basescan 验证版本扩展注释
 * @notice 面向项目方/用户的「ERC20 锁仓合约」：将任意 IERC20（常见为 LP Token）存入本合约，约定未来某一时刻由指定地址 `withdrawer` 取回；
 *         收取两笔费用：① 以 `BaseToken`（如 BASE）支付的固定 `lockFee`；② 从锁仓代币中按 `lpLockFee`（万分比）抽成给 `marketingAddress`。
 * @dev
 * - 锁仓记录以自增 `depositsCount` 为 `_id`，`lockedToken[_id]` 存明细；`walletTokenBalance[token][user]` 为记账（与 withdraw 时扣减对应）。
 * - 部署时硬编码默认 `BaseToken` 地址，Owner 可 `setBaseToken` 更换。
 * - `lockTokensByBase` 中先 `transferFrom` 全额入合约再拆分手续费：若第二笔对 `_token` 仍使用 `transferFrom(msg.sender, ...)`，调用方需已 approve 足够额度且余额仍覆盖该笔（与具体代币转账模型有关）。
 */
contract BaseTokenLocker is Ownable{
    using SafeMath for uint256;

    /// @notice 单笔锁仓记录
    struct Items {
        IERC20 token;              // 被锁的 ERC20（多为 LP）
        address withdrawer;        // 到期后唯一可取回地址（可与存入者不同）
        uint256 amount;            // 扣完 lp 比例手续费后、留在本合约待领取的数量
        uint256 unlockTimestamp;   // 解锁时间（秒级 Unix 时间戳）
        bool withdrawn;            // 是否已领取，防双花
    }

    /// @notice 已生成的锁仓笔数，同时作为新记录的 id
    uint256 public depositsCount;
    /// @notice 某代币合约地址 -> 该代币下所有锁仓 id 列表（索引用）
    mapping (address => uint256[]) private depositsByTokenAddress;
    /// @notice 某 `withdrawer` 地址 -> 其作为领取人的所有锁仓 id 列表
    mapping (address => uint256[]) public depositsByWithdrawer;
    /// @notice 锁仓 id -> 明细
    mapping (uint256 => Items) public lockedToken;
    /// @notice token 地址 -> 用户地址 -> 该用户在本合约中的「记账余额」（与单笔 lock 的 amount 累计一致，withdraw 时扣减）
    mapping (address => mapping(address => uint256)) public walletTokenBalance;

    /// @notice 用于支付固定锁仓费的代币（如 BASE），默认地址可经 Owner 修改
    IERC20 public BaseToken = IERC20(0xd07379a755A8f11B57610154861D694b2A0f615a);
    /// @notice 每次锁仓需向 marketing 支付的 BaseToken 数量（默认 100_000 * 10^18 量级，取决于代币 decimals）
    uint256 public lockFee = 100000 ether; // 100,000 BASE（命名 ether 仅作 18 位习惯）
    /// @notice 从锁仓代币中抽取的比例，万分比（50 = 0.5%）
    uint256 public lpLockFee = 50; // 0.5%
    /// @notice 接收 BASE 固定费与 LP 比例费的营销/协议地址
    address public marketingAddress;

    event Withdraw(address withdrawer, uint256 amount);
    event Lock(address token, uint256 amount, uint256 id);

    /// @notice 部署时将 `marketingAddress` 设为部署者，后续可由 Owner 修改
    constructor() {
        marketingAddress = msg.sender;
    }

    /**
     * @notice 锁仓：调用者支付 BaseToken 固定费 + 授权并转入待锁 `_token`，扣减 LP 比例费后剩余记入 `_id` 记录，到期由 `_withdrawer` 领取。
     * @param _token 要锁定的 ERC20 合约（须先 approve 本合约至少 `_amount`）
     * @param _withdrawer 解锁后有权 `withdrawTokens` 的地址（团队多签、金库或本人均可）
     * @param _amount 希望锁入的代币数量（若代币有转账税，实际入账以合约余额差为准）
     * @param _unlockTimestamp 解锁时间戳（秒），须大于当前区块时间且为秒（< 1e10 的启发式校验）
     * @return _id 本笔锁仓的唯一编号，供前端展示与后续 `withdrawTokens` 使用
     */
    function lockTokensByBase(IERC20 _token, address _withdrawer, uint256 _amount, uint256 _unlockTimestamp) external returns (uint256 _id) {
        require(_amount > 0, 'Token amount too low!');
        require(_unlockTimestamp < 10000000000, 'Unlock timestamp is not in seconds!');
        require(_unlockTimestamp > block.timestamp, 'Unlock timestamp is not in the future!');
        require(_token.allowance(msg.sender, address(this)) >= _amount, 'Approve tokens first!');
        require(BaseToken.balanceOf(msg.sender) >= lockFee, "Need to pay lock fee!");

        // 实际入账数量（兼容通缩/费代币：以合约余额差为准）
        uint256 beforeDeposit = _token.balanceOf(address(this));
        _token.transferFrom(msg.sender, address(this), _amount);
        uint256 afterDeposit = _token.balanceOf(address(this));

        _amount = afterDeposit.sub(beforeDeposit);
        // LP 手续费：从本笔入账中切出万分比给营销地址
        uint256 _lpLockFeeAmount = _amount.mul(lpLockFee).div(10000);
        uint256 _amountSubFee = _amount.sub(_lpLockFeeAmount);

        // 固定费：BASE（或当前 BaseToken）从用户转至 marketing
        BaseToken.transferFrom(msg.sender, marketingAddress, lockFee);
        // 将 LP 手续费部分从用户转至 marketing（若代币已全额进入本合约，需保证 approve/余额模型与代币一致）
        _token.transferFrom(msg.sender, marketingAddress, _lpLockFeeAmount);

        // 记账：剩余部分记在给「存入者」名下（withdraw 时由 withdrawer 扣减同一 token 下余额）
        walletTokenBalance[address(_token)][msg.sender] = walletTokenBalance[address(_token)][msg.sender].add(_amountSubFee);

        _id = ++depositsCount;
        lockedToken[_id].token = _token;
        lockedToken[_id].withdrawer = _withdrawer;
        lockedToken[_id].amount = _amountSubFee;
        lockedToken[_id].unlockTimestamp = _unlockTimestamp;
        lockedToken[_id].withdrawn = false;

        depositsByTokenAddress[address(_token)].push(_id);
        depositsByWithdrawer[_withdrawer].push(_id);

        emit Lock(address(_token), _amountSubFee, _id);

        return _id;
    }

    /**
     * @notice 到期后由记录的 `withdrawer` 取回该笔剩余代币。
     * @param _id `lockTokensByBase` 返回的锁仓编号
     */
    function withdrawTokens(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTimestamp, 'Tokens are still locked!');
        require(msg.sender == lockedToken[_id].withdrawer, 'You are not the withdrawer!');
        require(!lockedToken[_id].withdrawn, 'Tokens are already withdrawn!');

        lockedToken[_id].withdrawn = true;

        // 从「当前调用者（withdrawer）」名下扣减记账；lock 时记在「存入者」名下，若二者不同可能导致 SafeMath 下溢——业务上应保证 withdrawer 与存入者一致或另行约定
        walletTokenBalance[address(lockedToken[_id].token)][msg.sender] = walletTokenBalance[address(lockedToken[_id].token)][msg.sender].sub(lockedToken[_id].amount);

        emit Withdraw(msg.sender, lockedToken[_id].amount);
        lockedToken[_id].token.transfer(msg.sender, lockedToken[_id].amount);
    }

    /// @notice 修改营销收款地址
    /// @param _marketingAddress 新地址
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    /// @notice 修改固定锁仓费（BaseToken 数量）
    /// @param _lockFee 新费用数值（含 decimals）
    function setLockFee(uint256 _lockFee) external onlyOwner {
        lockFee = _lockFee;
    }

    /// @notice 修改 LP 锁仓抽成比例（万分比）
    /// @param _lpLockFee 新比例，如 50 表示 0.5%
    function setLpLockFee(uint256 _lpLockFee) external onlyOwner {
        lpLockFee = _lpLockFee;
    }

    /// @param _token 代币合约地址
    /// @return 该代币在「按 token 索引的 id 列表」
    function getDepositsByTokenAddress(address _token) view external returns (uint256[] memory) {
        return depositsByTokenAddress[_token];
    }

    /// @param _withdrawer 领取人地址
    /// @return 该地址作为 withdrawer 的所有锁仓 id
    function getDepositsByWithdrawer(address _withdrawer) view external returns (uint256[] memory) {
        return depositsByWithdrawer[_withdrawer];
    }

    /// @notice 本合约持有的某 ERC20 余额（近似于该 token 锁仓总量，若仅有本合约用途）
    /// @param _token 代币合约地址
    /// @return 合约 `balanceOf` 读数
    function getTokenTotalLockedBalance(address _token) view external returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice 更换用于支付固定锁仓费的 BaseToken 地址
    /// @param _token 新 IERC20
    function setBaseToken(IERC20 _token) external onlyOwner {
        BaseToken = _token;
    }
}