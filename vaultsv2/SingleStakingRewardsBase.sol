/**
 *Submitted for verification at Etherscan.io on 2020-09-16
*/

pragma solidity ^0.5.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// Inheritancea
interface IStakingRewards {
    // Views
    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function setRewardRate(uint256 _rewardRate) external;

    function exit() external;
}

interface IMasterChef {
    function mintRewards(address _receiver, uint256 _amount) external;
}

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

/**
 * @title SingleStakingRewardsBase
 * @notice **单币质押 Farm**（类似 Synthetix StakingRewards，但奖励由 MasterChef 铸造发放）。
 *
 * **形象理解**：把本合约想成「存钱罐农场」——用户把 `stakingToken` 存进来占份额；协议按时间往池子里「记」奖励积分（`rewardPerToken`），用户取走时通过 `MasterChef.mintRewards` 真正把代币铸到钱包。
 *
 * **与 masterchefv2/StakingRewards 的关系**：同一套 `rewardPerTokenStored + rewardRate` 累积模型；区别是 **不发 ERC20.transfer(rewardsToken)**，而是 **IMasterChef.mintRewards** 铸奖励币；领取时还会给 `taxWallet` 铸一笔 **ownerFee**（协议抽成）。
 *
 * **数值示例**（帮助心算）：
 * - `depositFee = 500` 表示 500/10000 = **5%** 入金给 `taxWallet`（注释里写的 1% 若与代码不一致，以 `div(10000)` 为准）。
 * - `ownerFee = 200` → 用户领到 100 枚奖励时，再给 taxWallet 铸 100×200/10000 = **2 枚**（若 ownerFee 表示「额外」协议份额，总通胀为 102）。
 * - `rewardRate` 为**每秒**向整池分摊的奖励量（再除以 `_totalSupply` 得到每单位质押的增速）。
 *
 * @dev
 * - `setRewardRate`：**masterChef 或 taxWallet** 可调（`onlyMasterChefOrTaxWallet`），用于与链下/主池排放同步。
 * - `burnFee`：可选；开启后从用户转入的 `amount` 里划一部分调用 `IERC20Burnable.burn`，要求质押币实现 burn 接口。
 */
contract SingleStakingRewardsBase is IStakingRewards, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ==========
     * 核心公式（全局奖励积分）：
     *   rewardPerToken() = rewardPerTokenStored + (now - lastUpdateTime) * rewardRate * 1e18 / totalSupply
     * 用户应得（预览）：
     *   earned = balance * (rewardPerToken - userRewardPerTokenPaid) / 1e18 + rewards[account]
     * 其中 `1e18` 用于定点精度，避免除法丢太多精度。
     */

    /// @notice MasterChef 合约地址；`getReward` 时对其调用 `mintRewards` 铸奖励代币。
    address public masterChef;

    /// @notice 协议金库/税务地址：收 `depositFee`；可改 `masterChef`、各类费率与 burn 开关；**不是** OpenZeppelin Ownable 的 owner，而是业务上的「管理员」地址。
    address public taxWallet;

    /// @notice 用户质押的 ERC20（LP 或单币均可，只要标准 ERC20 + 本合约逻辑所需接口）。
    IERC20 public stakingToken;

    /// @notice 预留字段；本基类未参与排放周期判断，可与子类或链下统计配合使用。
    uint256 public periodFinish = 0;

    /// @notice **每秒**向整个池子注入的奖励计量（未乘用户份额前先进入 `rewardPerToken` 积分）。数值越大，同样质押量下 `earned` 增长越快。
    uint256 public rewardRate = 0;

    /// @notice 上次更新 `rewardPerTokenStored` 的区块时间；用于计算时间差 `block.timestamp - lastUpdateTime`。
    uint256 public lastUpdateTime;

    /// @notice 已固化进账的「每单位质押累计奖励积分」快照；每次 `updateReward` 会刷新。
    uint256 public rewardPerTokenStored;

    /// @notice 农场开始计奖时间：`block.timestamp < farmStartTime` 时不累积新的 `rewardPerToken`（适合预告上线）。
    uint256 public farmStartTime;

    /// @notice 用户上次结算时的 `rewardPerToken` 快照，用于计算增量奖励。
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice 用户已结算进 `rewards[addr]` 但尚未领取的奖励余额（领取后清零）。
    mapping(address => uint256) public rewards;

    /// @notice 池内总质押量（**扣费后的净额**计入权重，与 `stake` 逻辑一致）。
    uint256 private _totalSupply;

    /// @notice 用户在池中的净质押余额（与 `_totalSupply` 同口径）。
    mapping(address => uint256) private _balances;

    // Fees（基数 10000 = 100%）
    /// @notice 从**已领取奖励**中再给 `taxWallet` 铸的比例（bps）。默认 200 → 2%。
    uint256 public ownerFee = 200; // 2%
    /// @notice 质押时从 `amount` 中划给 `taxWallet` 的比例（bps）。默认 500 → 5%（若产品文档写 1% 请核对部署参数）。
    uint256 public depositFee = 500; // 1%
    /// @notice 开启 `burnFeeEnabled` 后，从质押额中销毁的比例（bps）。
    uint256 public burnFee = 0; // 0%
    /// @notice 是否启用销毁费（需质押 token 支持 `IERC20Burnable.burn`）。
    bool public burnFeeEnabled = false;

    /// @notice 仅允许 MasterChef 或 taxWallet 调用（用于同步 `rewardRate` 等运维操作）。
    modifier onlyMasterChefOrTaxWallet() {
        require(msg.sender == masterChef || msg.sender == taxWallet, "Caller is not MasterChef Contract or Tax Wallet");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice 部署时固定 MasterChef、税务地址、质押币与初始排放；`lastUpdateTime` 未在构造函数中设置，首次有状态更新时由 `updateReward` 写入。
     * @param _masterChef MasterChef 合约；用户 `getReward` 时对其调用 `mintRewards(receiver, amount)`。
     * @param _taxWallet 收取质押手续费、领取时的 owner 分成；**唯一**可调用 `setMasterChef`、`setDepositFee` 等管理函数的地址（代码里用 `taxWallet == msg.sender` 校验）。
     * @param _stakingToken 质押代币合约地址。
     * @param _rewardRate 初始每秒 `rewardRate`（与 `setRewardRate` 同含义）。例：整池每秒分 1e18 wei 的「记账单位」，需与 MasterChef 铸币能力匹配。
     * @param _farmStartTime 链上时间戳；在此之前 `rewardPerToken()` 不随时间增长。**使用场景**：预告 Farm 在周五 12:00 开闸，前端倒计时结束前先部署合约。
     */
    constructor(
        address _masterChef,
        address _taxWallet,
        address _stakingToken,
        uint256 _rewardRate,
        uint256 _farmStartTime
    ) public {
        masterChef = _masterChef;
        taxWallet = _taxWallet;
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        farmStartTime = _farmStartTime;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice 池内质押代币总量（扣费后的净质押权重之和）。
     * @return 全池 `_totalSupply`，与 AMM 的 LP `totalSupply` 同名不同义。
     * **使用场景**：前端展示 TVL、计算自己份额占比 `balanceOf(user) / totalSupply()`。
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice 某地址在当前池中的净质押余额。
     * @param account 用户地址。
     * @return 该用户 `_balances`，与 `withdraw` 可取上限一致。
     * **使用场景**：钱包页面显示「你已质押多少 LP」。
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice 每 1 wei 质押累计的「奖励积分」（放大 1e18 倍），用于全局分摊。
     * @return 当前全局 `rewardPerToken`。
     * **核心逻辑**：池子非空且已过 `farmStartTime` 时，自 `lastUpdateTime` 起每秒增加 `rewardRate * 1e18 / _totalSupply`；总供应为 0 或未到开场时间不累积，避免除零和提前发奖。
     * **小例子**：`_totalSupply = 100e18`，`rewardRate` 每秒使整池增加 R 个奖励单位，则每单位每秒增加 `R * 1e18 / (100e18)` 积分。
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        if (block.timestamp < farmStartTime) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                (block.timestamp).sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    /**
     * @notice 某用户当前可领取奖励预览（未执行 `getReward` 链上结算前）。
     * @param account 用户地址。
     * @return 奖励代币数量（由 MasterChef `mintRewards` 铸造，精度与奖励币一致）。
     * **核心逻辑**：`余额 * (当前 rewardPerToken - 用户已付积分) / 1e18 + 已入账未领 rewards`。
     * **使用场景**：前端「待领取收益」、机器人判断是否值得付 gas 领取。
     */
    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice 使用 EIP-2612/permit（UniswapV2 风格 `permit`）**一笔交易**完成授权 + 质押，省掉事先 `approve`。
     * @param amount 转入的质押代币数量（全额扣费后再计入净质押）。
     * @param deadline permit 签名过期时间戳。
     * @param v, r, s 用户对该 permit 消息的 ECDSA 签名分量。
     * **使用场景**：用户不想先发送 `approve` 再 `stake`（省 gas、体验好）；与 `stake` 逻辑相同，仅多一步 `IUniswapV2ERC20.permit`。
     * **注意**：质押币必须实现与 `IUniswapV2ERC20` 兼容的 `permit`。
     */
    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 _fee = amount.mul(depositFee).div(10000);
        uint256 _burnFee = 0;
        if (burnFeeEnabled) {
            _burnFee = amount.mul(burnFee).div(10000);
        }
        uint256 _amountMinusTotalFees = amount.sub(_fee).sub(_burnFee);

        uint256 _newAmount = _balances[msg.sender].add(_amountMinusTotalFees);
        _totalSupply = _totalSupply.add(_amountMinusTotalFees);
        _balances[msg.sender] = _newAmount;

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        stakingToken.safeTransfer(taxWallet, _fee);
        if (burnFeeEnabled) {
            IERC20Burnable(address(stakingToken)).burn(_burnFee);
        }
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice 质押：用户需事先 `approve` 本合约，或先用 `stakeWithPermit`。
     * @param amount 转入合约的质押代币数量。
     * **核心逻辑**：`depositFee` 转给 `taxWallet`；若开启 `burnFee` 则销毁 `burnFee` 比例；剩余净额增加 `_balances` 与 `_totalSupply`。
     * **使用场景**：常规入金；例如用户有 1000 枚 LP，`depositFee=500`（5%）则约 50 枚给协议，950 枚按权重计奖（另扣 burn 若开启）。
     */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 _fee = amount.mul(depositFee).div(10000);
        uint256 _burnFee = 0;
        if (burnFeeEnabled) {
            _burnFee = amount.mul(burnFee).div(10000);
        }
        uint256 _amountMinusTotalFees = amount.sub(_fee).sub(_burnFee);

        uint256 _newAmount = _balances[msg.sender].add(_amountMinusTotalFees);
        _totalSupply = _totalSupply.add(_amountMinusTotalFees);
        _balances[msg.sender] = _newAmount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        stakingToken.safeTransfer(taxWallet, _fee);
        if (burnFeeEnabled) {
            IERC20Burnable(address(stakingToken)).burn(_burnFee);
        }
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice 提取质押本金（不自动领奖励；若要本息一起取请用 `exit`）。
     * @param amount 减少的净质押数量，从合约转回 `msg.sender`。
     * **使用场景**：只减仓不离场领息；或先 `withdraw` 再单独 `getReward`。
     * **注意**：取出的是**净余额**对应的代币，与入金时扣费后的记账一致。
     */
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice 将已累积的奖励通过 MasterChef **铸造**到用户钱包，并给 `taxWallet` 铸一笔 `ownerFee`。
     * **核心逻辑**：`rewards[msg.sender]` 清零；`mintRewards(msg.sender, reward)`；再 `mintRewards(taxWallet, reward * ownerFee / 10000)`。
     * **使用场景**：定期领息；**无奖励时**也可调用，但不会触发铸币（`reward == 0`）。
     * **注意**：奖励来源是 MasterChef 的铸币权限，不是本合约预存的 ERC20 余额。
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IMasterChef(masterChef).mintRewards(msg.sender, reward);

            // mint ownerFee
            IMasterChef(masterChef).mintRewards(taxWallet, reward.mul(ownerFee).div(10000));
            emit RewardPaid(msg.sender, reward, 0);
        }
    }

    /**
     * @notice 一键「清仓」：取出全部净质押并领取全部待领奖励。
     * **使用场景**：用户想完全退出本池；等价于 `withdraw(全部)` + `getReward()`，且 `withdraw` 用 `public` 可被内部调用。
     * **注意**：受 `nonReentrant` 保护的是 `withdraw` 与 `getReward` 各自内部，此处两次外部调用顺序固定为先本金后奖励。
     */
    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice 在动作执行前把全局与用户奖励「结到当前时刻」。
     * @param account 要结算的用户；传 `address(0)` 时只更新全局快照（若子类或扩展需单独调）。
     * **核心逻辑**：`rewardPerTokenStored = rewardPerToken()`；`lastUpdateTime = block.timestamp`；对用户更新 `rewards` 与 `userRewardPerTokenPaid`。
     * **使用场景**：所有改变份额或领奖励的函数都带此 modifier，保证先结账再改余额，避免奖励被稀释或重入篡改。
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    /// @notice 链下监听排放变更（本基类构造函数未发此事件，子类或外部脚本可选用）。
    event RewardAdded(uint256 reward, uint256 periodFinish);
    /// @notice 用户质押；`amount` 为传入量（含将被扣费部分）。
    event Staked(address indexed user, uint256 amount);
    /// @notice 用户提取本金。
    event Withdrawn(address indexed user, uint256 amount);
    /// @notice 用户领取奖励；第三参数预留类型/池 id，此处为 0。
    event RewardPaid(address indexed user, uint256 reward, uint256 rewardType);

    /* ========== FARMS CONTROLS ========== */

    /**
     * @notice 更新每秒 `rewardRate`，通常与主 MasterChef 池同步排放。
     * @param _rewardRate 新速率。
     * **使用场景**：每周调排放、或迁移到新 MasterChef 后对齐数值。
     * **权限**：`masterChef` 或 `taxWallet`。
     */
    function setRewardRate(uint256 _rewardRate) public onlyMasterChefOrTaxWallet {
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    /**
     * @notice 更换 MasterChef 地址（例如主合约升级）。
     * @param _masterChef 新 MasterChef。
     * **使用场景**：项目方部署新 Chef 后，把 Farm 的铸币入口指到新地址。
     * **权限**：仅 `taxWallet`。
     */
    function setMasterChef(address _masterChef) public {
        require(taxWallet == msg.sender, "Not the owner");
        masterChef = _masterChef;
    }

    /**
     * @notice 设置领取奖励时额外铸给 `taxWallet` 的比例（相对用户领取量）。
     * @param _fee bps，最大 200（合约要求 `<= 200`，即最多 2%）。
     * **使用场景**：协议从「已领取奖励」中再抽一层给金库；与用户 `depositFee` 不同，这是**领奖时**的附加铸币。
     * **权限**：仅 `taxWallet`。
     */
    function setOwnerFeeFromRewardRate(uint256 _fee) public {
        require(taxWallet == msg.sender, "Not the owner");
        require(_fee <= 200, "Fee cant be more than 5%");
        ownerFee = _fee;
    }

    /**
     * @notice 质押时从用户转入额中划给 `taxWallet` 的比例。
     * @param _fee bps，最大 500（5%）。
     * **使用场景**：提高入金手续费抑制快进快出，或活动期临时降费。
     * **权限**：仅 `taxWallet`。
     */
    function setDepositFee(uint256 _fee) public {
        require(taxWallet == msg.sender, "Not the owner");
        require(_fee <= 500, "Fee cant be more than 5%");
        depositFee = _fee;
    }

    /**
     * @notice 设置销毁费比例（需配合 `setBurnFeeEnabled(true)` 且代币实现 `burn`）。
     * @param _fee bps，最大 300（3%）。
     * **使用场景**：通缩型代币经济学，从质押流入中销毁一部分。
     * **权限**：仅 `taxWallet`。
     */
    function setBurnFee(uint256 _fee) public {
        require(taxWallet == msg.sender, "Not the owner");
        require(_fee <= 300, "Fee cant be more than 5%");
        burnFee = _fee;
    }

    /**
     * @notice 开关销毁费逻辑。
     * @param _status true 时 `stake`/`stakeWithPermit` 会执行 `burn`。
     * **使用场景**：先部署为 false，通证升级支持 burn 后再打开。
     * **权限**：仅 `taxWallet`。
     */
    function setBurnFeeEnabled(bool _status) public {
        require(taxWallet == msg.sender, "Not the owner");
        burnFeeEnabled = _status;
    }

}

interface IUniswapV2ERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}