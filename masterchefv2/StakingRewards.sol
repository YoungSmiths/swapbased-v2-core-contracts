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

    function rewardRate() external view returns (uint256);
    
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

/**
 * @title StakingRewards
 * @notice 单池质押：Synthetix 式 rewardPerToken 积分；用户领取时由 MasterChef 按池配置铸造多种奖励代币。
 * @dev 质押扣 depositFee（万分比）至 taxWallet；getReward 另铸 ownerFee 比例给 taxWallet。rewardRate 仅应由 MasterChef 通过 setRewardRate 同步。
 */
contract StakingRewards is IStakingRewards, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    /**
     * @notice MasterChef 合约地址。
     * @dev 核心控制器。本合约通过调用 MasterChef 的 `mintRewards` 来实际铸造和发放奖励。
     * @example 场景：当用户调用 `getReward()` 时，本合约会请求 `masterChef` 向用户增发奖励代币。
     */
    address public masterChef;

    /**
     * @notice 税收/协议收入接收钱包地址。
     * @dev 用于接收质押手续费 (depositFee) 和额外的协议管理费 (ownerFee)。
     * @example 场景：用户质押 100 LP 时，1 LP (1%) 会被直接发送到 `taxWallet`。
     */
    address public taxWallet;

    /**
     * @notice 奖励代币合约实例。
     * @dev 虽然定义了此变量以保持与经典 Synthetix 模式兼容，但实际奖励发放逻辑通常由 MasterChef 统一处理。
     */
    IERC20 public rewardsToken;

    /**
     * @notice 用户质押的代币合约实例（通常是 Uniswap V2 LP Token）。
     * @dev 决定了本池子“挖矿”所需的本金类型。
     * @example 场景：在 BASE/ETH 池中，`stakingToken` 就是 BASE-ETH LP 代币。
     */
    IERC20 public stakingToken;

    /**
     * @notice 当前奖励周期的结束时间戳。
     * @dev 预留字段，用于标识本轮奖励排放何时停止。
     */
    uint256 public periodFinish = 0;

    /**
     * @notice 每秒发放的奖励计量速率（单位：wei/秒）。
     * @dev 决定了矿池的“产出速度”。
     * @example 举例：若 `rewardRate` 为 1e18，则全池用户每秒共同瓜分 1 个单位的奖励计量。
     */
    uint256 public rewardRate = 0;

    /**
     * @notice 最近一次更新全局奖励积分的时间戳。
     * @dev 用于计算从上次更新到现在这段时间内产生的奖励总量。
     */
    uint256 public lastUpdateTime;

    /**
     * @notice 每单位质押代币累积的全局奖励积分（已存储值）。
     * @dev 核心算法：该值会随时间增加，增量 = (经过的时间 * rewardRate) / 总质押量。
     */
    uint256 public rewardPerTokenStored;

    /**
     * @notice 挖矿正式开始的时间戳。
     * @dev 在此时间之前，即使有质押，也不会产生任何奖励积分。
     * @example 场景：项目宣布明天 10:00 开始挖矿，则 `farmStartTime` 设置为该时间，防止“偷跑”。
     */
    uint256 public farmStartTime;

    /**
     * @notice 记录每个用户已结算（已支付）的奖励积分。
     * @dev 用于计算用户从上次操作到现在新产生的奖励：`balance * (全局积分 - 用户已付积分)`。
     */
    mapping(address => uint256) public userRewardPerTokenPaid;

    /**
     * @notice 记录每个用户当前已存入但未领取的奖励数量。
     * @dev 当用户质押或取款时，未领取的奖励会从积分形式结算并累加到这个变量中。
     */
    mapping(address => uint256) public rewards;

    /**
     * @notice 全池总质押量。
     * @dev 用于计算奖励分配的权重。
     */
    uint256 private _totalSupply;

    /**
     * @notice 每个用户的质押余额映射。
     * @dev 决定了每个用户在奖励分配中所占的份额。
     */
    mapping(address => uint256) private _balances;

    /**
     * @notice 协议额外收取的管理费比例（万分比）。
     * @dev 当用户领取奖励时，MasterChef 会额外铸造 `reward * 2%` 给 `taxWallet`。
     * @example 举例：用户领取 1000 奖励，协议会额外产生 20 给团队。
     */
    uint256 public constant ownerFee = 200; // 2%

    /**
     * @notice 质押手续费比例（万分比）。
     * @dev 用户存入时扣除。
     * @example 举例：用户存 10000，实际入账 9900，100 作为手续费。
     */
    uint256 public constant depositFee = 100; // 1%

    modifier onlyMasterChef() {
        require(msg.sender == masterChef, "Caller is not MasterChef contract");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice 创建单池 Farm：质押 `_stakingToken`，奖励通过 `masterChef.mintRewards` 铸造（非本合约预存）。
     * @param _masterChef MasterChef 合约地址（须实现 `mintRewards`）
     * @param _taxWallet 接收 depositFee（1%）与 ownerFee（2% 额外铸币）的地址
     * @param _stakingToken 用户质押的 ERC20（多为 LP）
     * @param _rewardRate 初始每秒奖励计量；由 Chef `setRewardRate` 覆盖时为常见路径
     * @param _farmStartTime 早于该时间 `rewardPerToken` 不累积（挖矿未开始）
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

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice 每单位质押代币累计的「奖励计量」积分（放大 1e18）；每秒增加 rewardRate/_totalSupply
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

    /// @notice 用户待领取 = 余额 * (全局积分 - 用户已结算积分) / 1e18 + 已缓存的 rewards
    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice 使用 Uniswap V2 风格 `permit` 一步授权并质押，扣 1% depositFee 至 `taxWallet`。
     * @param amount 转入的质押代币数量（含将支付给 taxWallet 的 fee）
     * @param deadline permit 截止时间
     * @param v r s EIP-712 签名分量
     */
    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 _fee = amount.mul(depositFee).div(10000);
        uint256 _amountMinusFee = amount.sub(_fee);

        uint256 _newAmount = _balances[msg.sender].add(_amountMinusFee);
        _totalSupply = _totalSupply.add(_amountMinusFee);
        _balances[msg.sender] = _newAmount;

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        stakingToken.safeTransfer(taxWallet, _fee);
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice 质押：从用户转入 `amount`，扣万分比 `depositFee` 至 `taxWallet`，净额计入用户质押权重。
     * @param amount 质押数量（最小单位）
     */
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        uint256 _fee = amount.mul(depositFee).div(10000);
        uint256 _amountMinusFee = amount.sub(_fee);

        uint256 _newAmount = _balances[msg.sender].add(_amountMinusFee);
        _totalSupply = _totalSupply.add(_amountMinusFee);
        _balances[msg.sender] = _newAmount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        stakingToken.safeTransfer(taxWallet, _fee);
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice 取出质押本金（无额外退出费；奖励需另调 `getReward`）。
     * @param amount 取出数量，不得超过用户在本池余额
     */
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice 领取已累积奖励：对用户 `mintRewards` 主奖励，再对 `taxWallet` 铸 `reward * ownerFee / 10000`。
     * @dev 奖励代币由 MasterChef 按池配置多币种拆分；本处仅传递「计量」`reward`。
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IMasterChef(masterChef).mintRewards(msg.sender, reward);

            // 协议费：按用户 reward 的 ownerFee 万分比再铸给 taxWallet
            IMasterChef(masterChef).mintRewards(taxWallet, reward.mul(ownerFee).div(10000));
            emit RewardPaid(msg.sender, reward, 0);
        }
    }

    /// @notice 先取回全部质押再领取奖励（两笔逻辑在同一交易内顺序执行）。
    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== MODIFIERS ========== */

    /// @notice 先刷新全局积分再结算 account 的待领取快照（须在 stake/withdraw/getReward 等入口执行）
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

    event RewardAdded(uint256 reward, uint256 periodFinish);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 rewardType);

    /* ========== FARMS CONTROLS ========== */

    /**
     * @notice 仅 MasterChef 可调：更新每秒奖励速率并刷新 `lastUpdateTime`。
     * @param _rewardRate 新的每秒奖励计量（与 `rewardPerToken` 积分一致）
     */
    function setRewardRate(uint256 _rewardRate) public onlyMasterChef {
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    /**
     * @notice 迁移 MasterChef 地址（仅限当前 `taxWallet` 调用，用于升级 Chef）。
     * @param _masterChef 新 MasterChef 合约地址
     */
    function setMasterChef(address _masterChef) public {
        require(taxWallet == msg.sender, "Not the owner");
        masterChef = _masterChef;
    }

}

interface IUniswapV2ERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}