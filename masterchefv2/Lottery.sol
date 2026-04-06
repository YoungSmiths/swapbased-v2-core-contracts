/**
 *Submitted for verification at Etherscan.io on 2020-09-16
*/

pragma solidity 0.8.19;

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
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) {
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

    constructor() {
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

interface ITokenBurnable is IERC20 {
    function burn(uint256 amount) external;
}

/**
 * @title Lottery
 * @notice 基于 `baseToken` 的质押抽奖：用户 `stake` 参与，`resetManager` 等角色驱动开奖与奖金池（日奖池 / 大奖等）；与 MasterChef 无直接铸币耦合。
 * @dev 具体名次分配、手续费与大奖概率见常量与 `Round` 结构；详读业务前请完整走读 `stake`/开奖路径。
 */
contract Lottery is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    struct Round {
        uint256 roundId;
        uint256[] winningPlayers;
        address[] winningPlayersAddresses;
        uint256 dailyPot;
        uint256 jackpotTotal;
        uint256 dailyPotPaidSum;
        bool jackpotEnabled;
        uint256 jackpotPaidSum;
        address jackpotWinner;
        uint256 totalWagered;
        uint256 roundTimestamp;
    }

    struct UserStatsGeneral {
        uint256 roundIdWon;
        uint256 roundIdPrizeId;
        uint256 totalWon;
    }

    struct UserStatsJackpot {
        uint256 roundIdWon;
        uint256 totalJackpotWon;
    }

    Round[] public rounds;
    uint256[] public roundsWithJackpot;
    mapping(address => UserStatsGeneral[]) public userStatsGeneral;
    mapping(address => UserStatsJackpot[]) public userStatsJackpot;
    mapping(address => mapping(uint256 => uint256)) public playerWageredRound; // address,roundId => wageredBalancedOnRound
    mapping(address => uint256) public playerWageredTotal; // address => wageredBalancedTotal

    uint256 public constant PRECISION_DIVIDER = 10000;
    uint256 public constant STEP_PRECISION_DIVIDER = 10000000;
    uint256 public constant WAGER_FEE = 100; // 1% each round
    uint256 public constant JACKPOT_ENABLE_CHANCE = 200; // 2%
    uint256 public constant JACKPOT_ENABLED_MAX_WIN_CHANCE = 10; // 0.1% 
    uint256 public constant JACKPOT_ENABLED_MINIMUM_REWARD = 200; // 2%
    uint256 public constant JACKPOT_ENABLED_MAXIMUM_REWARD = 10000; // 100%

    uint16[] public WIN_PRIZES_POSITIONS = [ // 80% total
        2000, // 1st: 20% of the lottery prize pool
        1500, // 2nd: 15% of the lottery prize pool
        1000, // 3rd: 10% of the lottery prize pool
        800, // 4th: 8% of the lottery prize pool
        700, // 5th: 7% of the lottery prize pool
        600, // 6th: 6% of the lottery prize pool
        500, // 7th: 5% of the lottery prize pool
        400, // 8th: 4% of the lottery prize pool
        300, // 9th: 3% of the lottery prize pool
        200 // 10th: 2% of the lottery prize pool
    ];

    uint256 public constant WIN_PRIZES_EXTRA_STEP_DECREASE = 247;
    uint256 public constant WIN_PRIZES_EXTRA_STEP_MINIMUM = 11100;
    uint256 public constant WIN_PRIZES_EXTRA_STEP_MAXIMUM = 33300;

    // 11th to 100th: 0.333% to 0.111% (in increments of 0.00247%) of the lottery prize pool.
    uint256 public dailyPot;
    uint256 public jackpotPot;
    uint256 public maximumWinners = 100;

    uint256 public nextRound = block.timestamp + 20 hours;
    bool public publicEnabled = true;
    // ----------------------

    IERC20 public baseToken;
    address public resetManager;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    address[] public wagerPlayers;
    mapping(address => uint256) public wagerPlayersByAddress;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _resetManager,
        address _baseToken
    ) {
        resetManager = _resetManager;
        baseToken = IERC20(_baseToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");

        uint256 _newAmount = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _newAmount;

        // Update player ID and arrays
        uint256 playerID = wagerPlayersByAddress[msg.sender];
        if (playerID == 0) {
            // If the player's ID is 0, assign the new player ID
            playerID = wagerPlayers.length + 1;
            wagerPlayersByAddress[msg.sender] = playerID;
            wagerPlayers.push(msg.sender);
        }

        baseToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        // Check if the user's balance becomes 0
        if (_balances[msg.sender] == 0) {
            // Remove the user's entry from the wagerPlayers array
            uint256 playerID = wagerPlayersByAddress[msg.sender];
            if (playerID > 0 && playerID <= wagerPlayers.length) {
                // Update wagerPlayersByAddress for the moved player
                address lastPlayerAddress = wagerPlayers[wagerPlayers.length - 1];
                wagerPlayersByAddress[lastPlayerAddress] = playerID;

                // Move the last element to the position of the removed player
                wagerPlayers[playerID - 1] = lastPlayerAddress;

                // Shorten the array by one element
                wagerPlayers.pop();
            }

            // Remove the user's entry from the wagerPlayersByAddress mapping
            delete wagerPlayersByAddress[msg.sender];
        }

        baseToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
    }

    /* Lottery Functions */

    /// @notice 基于质押权重随机选择用户：用于开奖选出中奖者
    /// @param playerPosition 随机种子位置
    /// @param totalWeight 总权重（全员质押量和）
    /// @return 0 到 totalWeight-1 的随机数
    function random(uint playerPosition, uint totalWeight) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao, // block.difficulty 已废弃，改用 prevrandao
                        block.timestamp,
                        playerPosition
                    )
                )
            ) % totalWeight;
    }

    /// @notice 计算 jackpot 奖励比例：随机选择 2%-100% 之间
    /// @return 奖励比例（万分比）
    function getRandomJackpotAmount() private view returns (uint256) {
        uint256 randomNumber = random(0, STEP_PRECISION_DIVIDER);
        if (randomNumber < JACKPOT_ENABLED_MAX_WIN_CHANCE) {
            return JACKPOT_ENABLED_MAXIMUM_REWARD;
        } else {
            uint256 min = JACKPOT_ENABLED_MINIMUM_REWARD;
            uint256 max = JACKPOT_ENABLED_MAXIMUM_REWARD;
            uint256 range = max - min + 1;
            return min + (randomNumber % range);
        }
    }

    /// @notice 开奖：按质押权重随机选出中奖者，发日奖池 + jackpot；扣手续费并更新奖池。
    function resetRound() external publicCanExecuteOrResetManager nonReentrant {
        require(block.timestamp >= nextRound, "Can only reset round after this one is over.");
        uint256[] memory winningPlayers = getRandomUsers(wagerPlayers.length >= maximumWinners ? maximumWinners : wagerPlayers.length);

        uint256 roundIdNow = rounds.length;
        uint256 dailyPotPaidSum = 0;
        for (uint256 i = 0; i < (winningPlayers.length); i++) {
            uint256 amountWon = 0;
            if (i <= 9) {
                amountWon = dailyPot.mul(WIN_PRIZES_POSITIONS[i]).div(PRECISION_DIVIDER);
            } else {
                amountWon = dailyPot.mul(WIN_PRIZES_EXTRA_STEP_MAXIMUM - ((i - 10) * WIN_PRIZES_EXTRA_STEP_DECREASE)).div(STEP_PRECISION_DIVIDER); // fix
            }     
            UserStatsGeneral[] storage arrayOfUserStats = userStatsGeneral[wagerPlayers[winningPlayers[i]]];
            UserStatsGeneral storage _userStatsGeneral = arrayOfUserStats.push();

            _userStatsGeneral.roundIdWon = roundIdNow;
            _userStatsGeneral.roundIdPrizeId = i;
            _userStatsGeneral.totalWon = amountWon;
                
            baseToken.transfer(wagerPlayers[winningPlayers[i]], amountWon);
            dailyPotPaidSum = dailyPotPaidSum.add(amountWon);   
        }

        // Calculate the total weight of all players' balances
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < wagerPlayers.length; i++) {
            totalWeight = totalWeight.add(_balances[wagerPlayers[i]]);
        }

        // Select a single jackpot winner with weighted probability
        uint256 jackpotWinnerIndex = getRandomUsers(1)[0];

        // Calculate the random amount for the jackpot winner
        uint256 jackpotAmount = 0;
        uint256 jackpotBefore = jackpotPot;
        bool isJackpotEnabled = random(0, PRECISION_DIVIDER) <= JACKPOT_ENABLE_CHANCE;
        if (isJackpotEnabled && totalWeight > 0) {
            uint256 jackpotPercent = getRandomJackpotAmount();
            jackpotAmount = jackpotPot.mul(jackpotPercent).div(PRECISION_DIVIDER);
            jackpotPot = jackpotPot.sub(jackpotAmount);
        }

        // Distribute the jackpotAmount to the selected jackpot winner
        address winnerAddress;
        if (jackpotWinnerIndex < wagerPlayers.length && isJackpotEnabled) {
            winnerAddress = wagerPlayers[jackpotWinnerIndex];
            uint256 reward = jackpotAmount;

            // Limit the reward to the specified range
            reward = Math.min(reward, jackpotBefore.mul(JACKPOT_ENABLED_MAXIMUM_REWARD).div(PRECISION_DIVIDER));
            reward = Math.max(reward, jackpotBefore.mul(JACKPOT_ENABLED_MINIMUM_REWARD).div(PRECISION_DIVIDER));

            jackpotPot = jackpotBefore.sub(reward);

            UserStatsJackpot[] storage arrayOfUserStatsJackpot = userStatsJackpot[winnerAddress];
            UserStatsJackpot storage _userStatsJackpot = arrayOfUserStatsJackpot.push();

            _userStatsJackpot.roundIdWon = roundIdNow;
            _userStatsJackpot.totalJackpotWon = reward;

            baseToken.transfer(winnerAddress, reward);
        }

        address[] memory winningPlayersAddresses = new address[](winningPlayers.length);
        for (uint i = 0; i < winningPlayers.length; i++) {
            winningPlayersAddresses[i] = wagerPlayers[winningPlayers[i]];
        }

        if (isJackpotEnabled) {
            roundsWithJackpot.push(roundIdNow);
        }
        rounds.push(
            Round(
                roundIdNow,
                winningPlayers,
                winningPlayersAddresses,
                dailyPot,
                jackpotBefore,
                dailyPotPaidSum,
                isJackpotEnabled,
                jackpotAmount,
                winnerAddress,
                0, // totalWagered
                block.timestamp // roundTimestamp
            )
        );

        nextRound = block.timestamp + 20 hours;
        dailyPot = dailyPot.sub(dailyPotPaidSum);
        uint256 baseToBurn = 0;
        uint256 totalWagered = 0;

        // Take Wager Fee
        for (uint256 i = 0; i < wagerPlayers.length; i++) {
            uint256 oldBalance = _balances[wagerPlayers[i]];

            uint256 playerWager = playerWageredRound[wagerPlayers[i]][roundIdNow];
            playerWager = playerWager.add(oldBalance); // playerWageredRound
            playerWageredTotal[wagerPlayers[i]] = playerWageredTotal[wagerPlayers[i]].add(oldBalance);
            totalWagered = totalWagered.add(oldBalance);

            uint256 wagerFee = oldBalance.mul(WAGER_FEE).div(PRECISION_DIVIDER);
            uint256 amountWithoutWagerFee = oldBalance.sub(wagerFee);
            _balances[wagerPlayers[i]] = amountWithoutWagerFee;

            // Calculate jackpot and prize pool related values
            baseToBurn = baseToBurn.add(wagerFee.div(2));
            dailyPot = dailyPot.add((wagerFee.mul(30)).div(100));
            jackpotPot = jackpotPot.add((wagerFee.mul(20)).div(100));            
        } 

        rounds[roundIdNow].totalWagered = totalWagered;

        ITokenBurnable(address(baseToken)).burn(baseToBurn);
    }

    function getRandomUsers(uint256 count) public view returns (uint256[] memory) {
        require(count > 0, "Count must be greater than 0");
        require(count <= wagerPlayers.length, "Count exceeds available users");

        uint256[] memory selectedUserIndices = new uint256[](count);
        uint256[] memory userWeights = new uint256[](wagerPlayers.length);

        // Calculate weights based on player balances
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < wagerPlayers.length; i++) {
            userWeights[i] = _balances[wagerPlayers[i]];
            totalWeight += userWeights[i];
        }

        for (uint256 i = 0; i < count; i++) {
            uint256 randomNumber = random(i, totalWeight);
            uint256 cumulativeWeight = 0;

            for (uint256 j = 0; j < wagerPlayers.length; j++) {
                cumulativeWeight += userWeights[j];
                if (randomNumber < cumulativeWeight && userWeights[j] != 0) {
                    selectedUserIndices[i] = j;
                    userWeights[j] = 0; // Mark this player as selected
                    totalWeight -= _balances[wagerPlayers[j]]; // Reduce total weight
                    break;
                }
            }
        }

        return selectedUserIndices;
    }

    function getPreviousRoundStats()
        external
        view
        returns (
            uint256 roundId,
            uint256[] memory winningPlayers,
            address[] memory winningPlayersAddresses,
            uint256 dailyPotTotal,
            uint256 dailyPotPaidSum,
            uint256 jackpotTotal,
            bool jackpotEnabled,
            uint256 jackpotPaidSum,
            address jackpotWinner,
            uint256 totalWagered,
            uint256 roundTimestamp
        )
    {
        if (rounds.length > 0) {
            roundId = rounds[rounds.length - 1].roundId;
            winningPlayers = rounds[rounds.length - 1].winningPlayers;
            dailyPotTotal = rounds[rounds.length - 1].dailyPot;
            dailyPotPaidSum = rounds[rounds.length - 1].dailyPotPaidSum;
            winningPlayersAddresses = rounds[rounds.length - 1].winningPlayersAddresses;
            jackpotTotal = rounds[rounds.length - 1].jackpotTotal;
            jackpotEnabled = rounds[rounds.length - 1].jackpotEnabled;
            jackpotPaidSum = rounds[rounds.length - 1].jackpotPaidSum;
            jackpotWinner = rounds[rounds.length - 1].jackpotWinner;
            totalWagered = rounds[rounds.length - 1].totalWagered;
            roundTimestamp = rounds[rounds.length - 1].roundTimestamp;
        }
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /* ========== FARMS CONTROLS ========== */

    modifier onlyResetManager() {
        require(msg.sender == resetManager, "not reset manager");
        _;
    }

    modifier publicCanExecuteOrResetManager() {
        require(publicEnabled == true || msg.sender == resetManager, "not reset manager || public execution not activated");
        _;
    }

    function addToDailyPot(uint256 _amount) external publicCanExecuteOrResetManager {
        baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        dailyPot = dailyPot.add(_amount);
    }

    function addToJackpot(uint256 _amount) external publicCanExecuteOrResetManager {
        baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        jackpotPot = jackpotPot.add(_amount);
    }

    function setPublicEnabled(bool _enabled) external onlyResetManager {
        publicEnabled = _enabled;
    }

    function retrievePots(uint256 _amount, uint256 _potType) external onlyResetManager {
        if (_potType == 1) {
            baseToken.safeTransfer(msg.sender, _amount);
            jackpotPot = jackpotPot.sub(_amount);
        } else {
            baseToken.safeTransfer(msg.sender, _amount);
            dailyPot = dailyPot.sub(_amount);
        }
    }

    function fixPots(uint256 _amount, uint256 _potType) external onlyResetManager {
        if (_potType == 1) {
            jackpotPot = _amount;
        } else {
            dailyPot = _amount;
        }
    }

    function setMaximumWinners(uint256 _amount) external onlyResetManager {
        maximumWinners = _amount;
    }

    function getRoundsLength() public view returns (uint roundsLength) {
        return rounds.length;
    }

    function getRoundsWithJackpotLength() public view returns (uint roundsWithJackpotLength) {
        return roundsWithJackpot.length;
    }

    function getWagerPlayersLength() public view returns (uint wagerPlayersLength) {
        return wagerPlayers.length;
    }
    
    function getUserStatsGeneralLength(address _player) public view returns (uint wagerPlayersLength) {
        return userStatsGeneral[_player].length;
    }
    
    function getUserStatsJackpotLength(address _player) public view returns (uint wagerPlayersLength) {
        return userStatsJackpot[_player].length;
    }

}