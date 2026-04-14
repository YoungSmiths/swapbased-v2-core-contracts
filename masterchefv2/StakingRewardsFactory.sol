pragma solidity ^0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

import "./StakingRewards.sol";

/**
 * @notice 奖励代币必须满足的铸造接口（例如协议里的 BASE / COIN 等带 `mint` 的代币）。
 * @dev Factory 的 `mintRewards` 会调用 `rewardsToken.mint(用户, 数量)`，该地址必须能按 MasterChef 计量去铸币。
 * @example 用户小明在 ETH/BASE 矿池点「领取奖励」：`StakingRewards` 算出应得 100 枚 COIN，回调本 Factory，再由 Factory 调用 `COIN.mint(小明地址, 100)`。
 */
interface IBaseToken {
    /**
     * @notice 按 MasterChef 计量向用户铸奖励币。
     * @param recipient_ 接收新铸代币的地址（例：领奖用户）。
     * @param amount_ 铸造数量，最小单位。
     * @return 是否铸造成功；Factory 要求为 true，否则 `mintRewards` revert。
     */
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

/**
 * @title StakingRewardsFactory —— 多矿池「总厨」
 * @notice **简化版**挖矿调度：每个质押币种（多为 LP）对应 **一份** 已部署的 `StakingRewards`；全协议共用一个 `rewardsToken`，通过 `mint` 发奖。
 * @dev 与 `MasterchefV2` 通常二选一。权重公式：某池每秒奖励 = `globalSkullPerSecond * allocPoint / totalAllocPoint`。
 * @example 运营同时开 ETH/BASE LP 池和 USDC/BASE LP 池：对两个 LP 地址各 `deploy` 一次，再分别 `set` 不同 `allocPoint`，最后 `setGlobalSkullPerSecond` 定全站每秒总产出，由池子按权重分摊。
 */
contract StakingRewardsFactory is Ownable {
    using SafeMath for uint256;

    // ========== 状态变量（结合 Farm：多池分摊 emissions） ==========

    /// @notice 全协议唯一奖励代币地址（须实现 `IBaseToken.mint`）。
    /// @example 页面统一发 COIN 时填 `CoinToken`；不会出现一池铸 A、另一池铸 B（本合约为单币奖励模型）。
    address public rewardsToken;

    /// @notice 全局「允许开始发奖」的 Unix 时间戳；早于此刻 `mintRewards` 会 revert。
    /// @example 预告周五 20:00 开矿，部署时设为该时刻；周五 19:59 用户无法领出奖励，避免提前透支。
    uint public stakingRewardsGenesis;

    /// @notice 所有池子 `allocPoint` 之和；为 0 时 `updatePool` 中 `div(totalAllocPoint)` 会 **除以零** 导致失败。
    /// @example 两池权重 30 与 70，则 `totalAllocPoint = 100`，第一池拿走全站每秒 emissions 的 30%。
    uint public totalAllocPoint;

    /// @notice 预留字段：可对接 xToken 类质押（本合约体内 **未读写**，仅占位）。
    address public xSkullStaking;

    /// @notice 已部署 Farm 的质押代币地址列表（顺序与 `poolInfo` 一致，便于前端枚举）。
    /// @example `stakingTokens[0]` 为 ETH-BASE LP，`stakingTokens[1]` 为 USDC-BASE LP。
    address[] public stakingTokens;

    /// @notice 某 LP 是否处于「可铸币」活跃状态：`killFarm` 置 false 后其 `StakingRewards` 无法再调 `mintRewards`。
    /// @example 下架上古池 `killFarm(lpOld)` 后，旧池用户若仍触发领取，会在 `isFarm[msg.sender]` 处失败。
    mapping (address => bool) public isFarm;

    /// @notice 全站每秒奖励计量（wei/秒）；按各池 `allocPoint` 拆成每个 `StakingRewards.rewardRate`。
    /// @example `globalSkullPerSecond = 1e18` 表示全协议每秒共发 1e18 最小单位奖励（具体含意取决于代币 decimals）。
    uint public globalSkullPerSecond;

    /// @notice 预留；与 x 轨 emissions 相关（本合约 **未使用**）。
    uint public globalXSkullPerSecond;

    /// @notice 经典 MasterChef 用户信息结构；**本 Factory 内未使用**，保留多为兼容习惯或链下索引。
    struct UserInfo {
        uint256 amount;
    }

    /// @notice 池元数据：用户质押的 ERC20（多为 LP）与在总权重中的份额。
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
    }

    PoolInfo[] public poolInfo;

    /// @notice 某个质押代币（LP 地址）对应的单池矿池合约。
    /// @dev `stakingRewards` 即 `new StakingRewards` 的部署地址；用户与该 LP 相关的 stake/withdraw 都在此合约。
    /// @example `stakingRewardsInfoByStakingToken[ETH_BASE_LP].stakingRewards` 指向「ETH/BASE 矿池」实例。
    struct StakingRewardsInfo {
        address stakingRewards;
    }

    /// @notice LP 合约地址 → 其矿池元数据（与 `deploy` 时传入的 `_stakingToken` 为同一 key）。
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    /**
     * @notice **使用场景**：协议首次部署，固定「奖池铸哪种币」和「最早何时允许铸币」。
     * @param _rewardsToken 奖励代币合约，须实现 `mint` 且能对 MasterChef 计量成功铸出（如 COIN）。
     * @param _stakingRewardsGenesis 全局开闸 Unix 时间，必须 **>= block.timestamp**，避免写在「过去」导致调度混乱。
     * @dev 继承 `Ownable()`，部署者即为首个 `owner()`，后续可 `transferOwnership` 交给多签。
     */
    constructor(
        address _rewardsToken,
        uint _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'MasterChef: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    // ========== Owner：部署新矿池 ==========

    /**
     * @notice **使用场景**：上新 Farm，用户在新 `StakingRewards` 里质押 LP、领取统一奖励币（如 SwapBased 文档中的 Farm 补贴）。
     * @param _stakingToken 用户质押的 ERC20；Farm 场景多为 **LP Token**（例：ETH/BASE 交易对流动性凭证）。
     * @param _rewardRate 子合约 **初始** 每秒 `rewardRate`；上线后多由 `updatePool` 用全局公式覆盖。
     * @param _farmStartTime 必须 **严格大于** `stakingRewardsGenesis`（例：全局周五 20:00 开闸，此处至少 20:01），否则 revert。
     * @dev **实现细节**：`new StakingRewards(..., stakingRewardsGenesis)` 把 **全局创世时间** 传入子合约的 `farmStartTime`，
     *      **未**传入 `_farmStartTime`；`_farmStartTime` 仅用于本函数校验。若需每池不同开矿时刻需改子合约构造函数。
     */
    function deploy(address _stakingToken, uint256 _rewardRate, uint256 _farmStartTime) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[_stakingToken];
        // 同一 LP 只能部署一次，避免误操作生成两个矿池、用户不知道押哪个合约。
        require(info.stakingRewards == address(0), 'MasterChef: already deployed');
        require(_farmStartTime > stakingRewardsGenesis, "Masterchef: cant start farm before global time");
 
        // masterChef = 本 Factory；taxWallet = owner()，收取 StakingRewards 内 depositFee/ownerFee。最后一参 = 全局开闸时间（见 @dev）。
        info.stakingRewards = address(new StakingRewards(address(this), owner(), _stakingToken, _rewardRate, stakingRewardsGenesis));
        // 新池可铸币、可挖矿，直至日后 `killFarm`。
        isFarm[_stakingToken] = true;
        // 占 `poolInfo` 一格；allocPoint 先 0，由 Owner 后续 `set(pid, 权重)` 决定该池分走多少 emissions。
        poolInfo.push(PoolInfo({
            lpToken: IERC20(_stakingToken),
            allocPoint: 0
        }));

        stakingTokens.push(_stakingToken);
    }

    // ========== 矿池回调：统一铸币出口 ==========

    /**
     * @notice **使用场景**：用户在某池 `getReward()` 时，该池 `StakingRewards` 回调此处，把应得奖励 `mint` 到用户地址。
     * @param _receiver 收款地址，一般为领取用户本人（例：小明领奖 → COIN 打到小明钱包）。
     * @param _amount 铸造数量，代币最小单位。
     * @dev 仅 `isFarm[msg.sender] == true` 的合约可调，防止 EOA 伪装领币。
     */
    function mintRewards(address _receiver, uint256 _amount) public {
        // 例：只有「ETH/BASE StakingRewards」合约地址调用此函数会过；小明用钱包直接调 Factory 会被拒。
        require(isFarm[msg.sender] == true, "MasterChef: only farms can mint rewards");
        // 未到全局开闸时间禁止 mint，与「预告开矿时间」一致。
        require(block.timestamp >= stakingRewardsGenesis, 'Masterchef: rewards too soon');
        // 奖励币必须返回 true；`mint` 失败则领取整笔回滚。
        require(
            IBaseToken(rewardsToken).mint(_receiver, _amount),
            'MasterChef: mint rewardsToken failed'
        );
    }

    /**
     * @notice **使用场景**：误把某 ERC20 转入 Factory 时，Owner 提出到多签/运维地址（合约本身不设存款逻辑）。
     * @param token ERC20 合约地址。
     * @param amount 转出数量（须 ≤ Factory 在该 token 上的余额）。
     * @dev 未禁止 `token == rewardsToken`，操作前需确认不误提重要余额。
     */
    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @notice **使用场景**：调整 `globalSkullPerSecond` 或各池 `set` 权重后，一次性把所有子池 `rewardRate` 同步到最新公式。
     * @dev Gas 随 `poolInfo.length` 增长；池子极多时可链下分批只调 `updatePool(pid)`。
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        // 逐个池刷新：pid=0 即最早 deploy 的池，避免只改全局速率却忘了某一池仍是旧 rewardRate。
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice **使用场景**：按当前全局速率与本池权重，重写该池 `StakingRewards` 的每秒产出；运维调 `massUpdatePools` 时会逐池调用。
     * @param _pid `poolInfo` 下标；第一个 `deploy` 的池为 0，第二个为 1，以此类推。
     * @dev 若 `totalAllocPoint == 0`，下行 `.div(totalAllocPoint)` **除以零** revert；须避免关池后总权重误为 0 仍调用（或先保证至少一池有权）。
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[address(pool.lpToken)];

        // 该 LP 已被 kill：`isFarm` 为 false，应从总权重里剔除并令该池不再产生新奖励。
        if(isFarm[address(pool.lpToken)] == false) {
            if (pool.allocPoint != 0) {
                // 例：原 total=100、本池 30 → 扣掉后 total=70，其它存活池分母变小、占比上升。
                totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
                pool.allocPoint = 0;
                IStakingRewards(info.stakingRewards).setRewardRate(0);
            }
        }

        // 核心公式：本池每秒奖励 = globalSkullPerSecond * allocPoint / totalAllocPoint（与文档中「按权重分摊补贴」一致）。
        IStakingRewards(info.stakingRewards).setRewardRate(globalSkullPerSecond.mul(pool.allocPoint).div(totalAllocPoint));
    }

    /**
     * @notice **使用场景**：运营加减某池热度——新池多加 `allocPoint`，老池减产；不改变 `globalSkullPerSecond` 时动的是 **相对份额**。
     * @param _pid 目标池索引。
     * @param _allocPoint 新权重。
     * @dev **不会**自动 `massUpdatePools`；常见做法：同一笔交易里先 `set` 再 `massUpdatePools`，否则各池 rate 仍为旧值。
     */
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        if (totalAllocPoint != 0) {
            // 总权重 = 原总和 - 本池旧值 + 本池新值，避免重复加旧权重。
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
            pool.allocPoint = _allocPoint;
        } else {
            // 首次给系统分配权重：总和与单池同时建立。
            totalAllocPoint = _allocPoint;
            pool.allocPoint = _allocPoint;
        }
    }

    /*********************** FARMS CONTROLS ***********************/

    /**
     * @notice **使用场景**：紧急下架某矿池（LP 废弃、风险等）：取消该池 `mintRewards` 资格，并经由 `massUpdatePools` 把 rate 清零。
     * @param _farm 与 `deploy` 时相同的 `_stakingToken`（LP）地址。
     */
    function killFarm(address _farm) external onlyOwner {
        require(isFarm[_farm] == true, "MasterChef: This is not active");

        isFarm[_farm] = false;

        massUpdatePools();
    }

    /**
     * @notice **使用场景**：曾对某池 `killFarm`，修复后恢复挖矿；**不**重新 `deploy`，沿用原 `StakingRewards` 地址。
     * @param _farm 质押代币（LP）地址。
     * @dev 第二个 require 的 revert 文案为历史字面 "This is not active"，语义实为「池子必须当前处于关闭状态」；已在运行中的池会 revert。
     */
    function activateFarm(address _farm) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[_farm];
        require(info.stakingRewards != address(0), 'MasterChef: needs to be a dead farm');
        require(isFarm[_farm] == false, "MasterChef: This is not active");

        isFarm[_farm] = true;

        massUpdatePools();
    }

    /**
     * @notice **使用场景**：协议级调整 emissions——如减半日把全站每秒铸币总量减半；各池 `allocPoint` **比例**不变。
     * @param _globalSkullPerSecond 新全局每秒计量；设 0 可停所有池新产出（已累积未领部分由 `StakingRewards` 内逻辑处理）。
     * @dev 仅写状态变量；须再调 `massUpdatePools` 才会写入每个子合约 `rewardRate`。
     */
    function setGlobalSkullPerSecond(uint256 _globalSkullPerSecond) public onlyOwner {
        globalSkullPerSecond = _globalSkullPerSecond;
    }
}