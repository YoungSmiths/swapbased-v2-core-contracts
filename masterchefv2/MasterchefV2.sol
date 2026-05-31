// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.16;

/**
 * @dev 基础访问控制：存在一个 owner，可对特定函数享有独占权限。
 *      通过继承使用，提供 `onlyOwner` 修饰符，将函数限制为仅 owner 可调用。
 */
contract Ownable {
    /// @notice 当前合约 owner 地址
    address private _owner;

    /// @notice owner 变更事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev 初始化：将部署者设为初始 owner。
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @notice 返回当前 owner 地址。
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev 若非 owner 调用则 revert。
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice 若调用者为当前 owner 则返回 true。
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @notice 放弃 ownership；之后无法再调用 `onlyOwner` 函数。
     * @dev 仅当前 owner 可调用。放弃后合约无 owner，仅 owner 可用的功能将永久不可用。
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @notice 将合约所有权转移给新账户。
     * @dev 仅当前 owner 可调用。
     * @param newOwner 新 owner 地址，不可为零地址。
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev 内部转移 ownership 并发出事件。
     * @param newOwner 新 owner 地址。
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

import "./StakingRewards.sol";

/**
 * @notice MasterchefV2 发奖所需的最小接口：奖励币必须能按计量「铸给某个地址」。
 * @dev 这里假设奖励币是你们体系里的可增发币（例如 COIN / BASE）。
 * @example 小明在矿池领到 100 的奖励计量，MasterchefV2 会对每个奖励币调用：
 *          `mint(小明地址, 100 * ratio / 10000)`，把币直接铸进小明钱包。
 */
interface IBaseToken {
    /**
     * @param recipient_ 接收奖励的地址（一般为领取人）。
     * @param amount_ 铸造数量（最小单位）。
     * @return 是否铸造成功；本合约要求返回 true，否则整笔领取回滚。
     */
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

/**
 * @notice 可选的「单币质押计票」接口：用于把某些池子的质押余额计入投票权。
 * @dev 这里用 balanceOf 来读取用户在某个合约里的“存款余额”（实现方可以是 StakingRewards 也可以是其它 Vault）。
 * @example 协议允许“把 xBASE 存到某个单币池也算投票权”，则该池的 stakingFarm 合约需要实现 balanceOf(user)。
 */
interface ISingleStaking {
    /// @notice 查询用户在单币质押合约中的余额（用于计票）。
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title MasterchefV2
 * @notice 流动性挖矿「调度中心」：仅允许已注册的 Farm（StakingRewards）调用 mintRewards 铸奖励；
 *         按池分配全局每秒产出（allocPoint）与社区投票份额（allocPointCommunity），并驱动各池 rewardRate。
 * @dev 奖励代币通过 IBaseToken.mint 发放；ratios 为万分比，与 rewards 数组一一对应。
 */
contract MasterchefV2 is Ownable {
    using SafeMath for uint256;

    /// @notice 治理/锁仓凭证代币地址：用于计算投票权（钱包余额 + 可选的单币质押余额）。
    /// @example 用户把 BASE 锁成 xBASE 后，xBASE 余额越高，能为喜欢的矿池投的“社区加成票”越多。
    address public xBASE;
    /// @notice 全局开闸时间：到达该时间戳后才允许 `mintRewards`（避免“偷跑挖矿”）。
    /// @example 项目公告周五 20:00 开矿：stakingRewardsGenesis=周五20:00；周五19:59 任何池都领不到奖励（会 revert）。
    uint public stakingRewardsGenesis;
    /// @notice 所有池子的「基础分配」权重之和；与 `globalSkullPerSecond` 一起决定每池每秒基础产出。
    /// @example 两池 alloc=30 与 70，总和=100：全局每秒 1000，则池 A 每秒 300、池 B 每秒 700（比例示意，实际为最小单位）。
    uint public totalAllocPoint;
    /// @notice 所有池子的「社区投票」权重之和；与 `globalCommunitySkullPerSecond` 一起决定每池每秒社区加成。
    /// @example 社区加成全局每秒 200；某池拿到社区票 50/100，则该池额外加成 100/秒。
    uint public totalAllocPointCommunity;

    /// @notice 是否为已注册 Farm（StakingRewards 合约地址）；仅 `true` 的地址可调用 `mintRewards`。
    /// @example 只有被登记的矿池合约才能“让 MasterchefV2 铸币给用户”，防止任意合约冒充矿池无限铸币。
    mapping (address => bool) public isFarm;

    /// @notice 上次因投票触发全量更新池子的时间；配合 “至少 7 天” 的窗口触发 `_massUpdatePools`，避免投票长期偏差。
    uint public lastUpdatedTimeVotes;
    /// @notice 全局每秒向所有「基础 alloc」池子分配的总计量（再按 `allocPoint` 分摊到各池）。
    uint public globalSkullPerSecond;
    /// @notice 全局每秒向所有「社区投票」池子分配的总计量（再按 `allocPointCommunity` 分摊）。
    uint public globalCommunitySkullPerSecond;
    /// @notice 新注册池默认奖励拆分万分比（与 defaultRewards 等长）；`deploy` / `deployWithCreation` 时拷贝进 poolInfo。
    uint256[] public defaultRatios;
    /// @notice 新注册池默认奖励代币地址列表；须实现 `IBaseToken.mint`。
    address[] public defaultRewards;

    /// @notice 用户投票状态：记录用户当前投票数量与投给哪个池（votedID）。
    /// @example 小明把 1000 票投给 pid=3，则 userInfo[小明].vote=1000 且 votedID=3；后续余额变化会在 `updateVotePool` 时同步。
    mapping(address => UserInfo) public userInfo;

    /// @notice 每个用户的投票状态。
    struct UserInfo {
        /// @notice 用户当前“投出去”的票数（按 xBASE 计量，可能包含单币质押余额）。
        uint256 vote;
        /// @notice 用户投票的池子 id（poolInfo 索引）。
        uint256 votedID;
    }

    /// @notice 每个矿池（Farm）的调度与奖励配置。
    struct PoolInfo {
        /// @notice 该池对应的 StakingRewards（Farm）合约地址（用户 stake/withdraw/getReward 的入口）。
        address stakingFarm;
        /// @notice 基础分配权重：参与 `globalSkullPerSecond` 分摊。
        uint256 allocPoint;
        /// @notice 社区投票权重：参与 `globalCommunitySkullPerSecond` 分摊（仅可投票池使用）。
        uint256 allocPointCommunity;
        /// @notice 是否允许用户把票投给本池（投票会累加 `allocPointCommunity`）。
        bool isVoteable;
        /// @notice 是否由本合约根据全局参数自动调用 `setRewardRate` 控制该池产出。
        /// @example 若为 false，表示该池的 rewardRate 由外部手工或其它逻辑控制，MasterchefV2 不会动它。
        bool masterchefControlled;
        /// @notice 若为 true，则把该池（或该池对应合约）里的存款余额也计入投票权。
        /// @example “把 xBASE 存进单币池也算投票权” 就需要开启此开关，并要求 stakingFarm 实现 balanceOf(user)。
        bool countDepositAmountAsVotingPower;

        /// @notice 与 rewards 一一对应的万分比；mintRewards 时按 `_amount * ratio / 10000` 拆分多币铸造。
        /// @example rewards=[COIN, BASE], ratios=[8000, 2000] 表示每次发奖 80% 铸 COIN，20% 铸 BASE。
        uint256[] ratios;
        /// @notice 奖励代币地址列表（每个都必须实现 `IBaseToken.mint`）。
        address[] rewards;
    }
    
    /// @notice 已注册矿池列表；下标即为 `pid`。
    PoolInfo[] public poolInfo;

    /// @notice 按 Farm 地址登记的矿池元数据（与 poolInfo 通过 pid 关联）。
    struct StakingRewardsInfo {
        /// @notice StakingRewards 合约地址（与 mapping 的 key 通常相同）。
        address stakingRewards;
    }

    /// @notice Farm 合约地址 → 登记信息；`mintRewards` 时由 `msg.sender` 反查配置。
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingFarmAddress;
    /// @notice Farm 合约地址 → `poolInfo` 数组下标（pid）。
    mapping(address => uint) public poolPidByStakingFarmAddress;
    /// @notice 用户是否已调用过 `votePool` 且尚未 `unVotePool`。
    mapping(address => bool) public voted;

    /**
     * @notice 部署 MasterchefV2：绑定 xBASE、默认多代币奖励与全局挖矿起始时间。
     * @param _xBASE 治理代币 xBASE 地址（投票权）
     * @param _rewards 默认奖励代币地址数组
     * @param _ratios 与 _rewards 对齐的万分比
     * @param _stakingRewardsGenesis 全局允许 `mintRewards` 的起始时间戳
     */
    constructor(
        address _xBASE,
        address[] memory _rewards,
        uint256[] memory _ratios,
        uint _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'MasterChef: genesis too soon');

        xBASE = _xBASE;
        defaultRewards = _rewards;
        defaultRatios = _ratios;
        stakingRewardsGenesis = _stakingRewardsGenesis;
        lastUpdatedTimeVotes = block.timestamp;
    }

    // ========== 需 owner 权限：部署与注册 Farm ==========

    /**
     * @notice **使用场景**：一次性把多个已部署的 `StakingRewards` 矿池注册进 MasterchefV2（常用于迁移或批量上线）。
     * @dev **谁来调用**：仅 `owner`（通常是项目多签、Timelock 执行器或运维发布脚本）可调用。
     *      典型流程：先由部署脚本/Factory 在链上创建一批 Farm，收集它们地址后，再由多签一次调用本函数批量注册，
     *      避免逐个 `deploy(...)` 多次发交易、提高上线效率。
     * @example 例子：新季度要同时上线 6 个 LP 池（ETH/BASE、USDC/BASE、DAI/BASE...），
     *          运维脚本先拿到 6 个 Farm 地址数组 `_addys`，对应起始时间 `_start` 与是否 Chef 控速 `_masterchefControlled`，
     *          由多签一次提交 `deployBulk` 完成批量登记。
     * @param _addys StakingRewards 合约地址数组（每个地址就是一个矿池）。
     * @param _start 每个矿池的开采开始时间（必须都 > stakingRewardsGenesis）。
     * @param _masterchefControlled 每个矿池是否由本合约自动控制 rewardRate。
     * @dev 该函数只是“登记+建表”，真正的 rewardRate 会在后续 `massUpdatePools/updatePool` 时按权重写入。
     */
    function deployBulk(address[] memory _addys, uint256[] memory _start, bool[] memory _masterchefControlled) public onlyOwner {
        uint256 length = _addys.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _deploy(_addys[pid], _start[pid], _masterchefControlled[pid]);
        }
    }

    /**
     * @notice **使用场景**：注册单个已存在的 Farm（StakingRewards）合约（例如新上线一个 LP 矿池）。
     * @param _farmAddress StakingRewards 合约地址（不是 LP 地址）。
     * @param _farmStartTime 该池开始计奖的时间戳。
     * @param _masterchefControlled 是否由本合约根据全局参数驱动该池 rewardRate。
     */
    function deploy(address _farmAddress, uint256 _farmStartTime, bool _masterchefControlled) public onlyOwner {
        _deploy(_farmAddress, _farmStartTime, _masterchefControlled);
    }

    /**
     * @dev 登记 `isFarm`、追加 `poolInfo`；Farm 须外部先部署，本合约只调度与铸币。
     *      默认 `ratios/rewards` 来自构造函数；新池 alloc 初值为 0，需 Owner 再 `set` 并 `massUpdatePools`。
     * @param _farmAddress 已部署的 StakingRewards 地址。
     * @param _farmStartTime 须大于 `stakingRewardsGenesis`（本函数内仅校验，不写入 StakingRewards）。
     * @param _masterchefControlled 是否由 Chef 自动控速；为 true 时默认可投票。
     */
    function _deploy(address _farmAddress, uint256 _farmStartTime, bool _masterchefControlled) internal {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farmAddress];
        require(info.stakingRewards == address(0), 'MasterChef: already deployed');
        require(_farmStartTime > stakingRewardsGenesis, "Masterchef: cant start farm before global time");

        info.stakingRewards = _farmAddress;
        isFarm[_farmAddress] = true;
        // 逐行说明：新池先以 alloc=0/allocCommunity=0 登记，避免一上线就分走 emissions；运营应随后调用 set/setBulk 分配权重。
        poolInfo.push(PoolInfo({
            stakingFarm: _farmAddress,
            allocPoint: 0,
            allocPointCommunity: 0,
            ratios: defaultRatios,
            rewards: defaultRewards,
            masterchefControlled: _masterchefControlled,
            isVoteable: _masterchefControlled == true ? true : false,
            countDepositAmountAsVotingPower: false
        }));
        poolPidByStakingFarmAddress[_farmAddress] = poolInfo.length - 1;
    }

    /**
     * @notice **使用场景**：Owner 一步创建并登记新矿池：内联 `new StakingRewards(...)` 并写入 `poolInfo`。
     * @param _stakingToken 用户质押的 ERC20（常见为 LP Token 地址）。
     * @param _farmStartTime 单池开采开始时间戳（必须 > stakingRewardsGenesis）。
     * @dev 与 StakingRewardsFactory 的区别：索引 key 是 **Farm 合约地址**，不是 LP 地址。
     *      奖励不早于 genesis 发放；新池初始 alloc 为 0，需 Owner 再 `set` 权重并 `massUpdatePools`。
     */
    function deployWithCreation(address _stakingToken, uint256 _farmStartTime) public onlyOwner {
        address newFarm = address(new StakingRewards(address(this), owner(), _stakingToken, 0, _farmStartTime));
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[newFarm];
        require(_farmStartTime > stakingRewardsGenesis, "Masterchef: cant start farm before global time");

        info.stakingRewards = newFarm;
        isFarm[newFarm] = true;
        poolInfo.push(PoolInfo({
            stakingFarm: newFarm,
            allocPoint: 0,
            allocPointCommunity: 0,
            ratios: defaultRatios,
            rewards: defaultRewards,
            masterchefControlled: true,
            isVoteable: true,
            countDepositAmountAsVotingPower: false
        }));
        poolPidByStakingFarmAddress[newFarm] = poolInfo.length - 1;
    }

    /**
     * @notice 查询某 pid 的奖励拆分万分比。
     * @param poolIndex `poolInfo` 下标（pid）。
     */
    function getRatiosForFarm(uint256 poolIndex) public view returns (uint256[] memory) {
        require(poolIndex < poolInfo.length, "Invalid pool index");
        return poolInfo[poolIndex].ratios;
    }

    /**
     * @notice 查询某 pid 的奖励代币地址列表。
     * @param poolIndex `poolInfo` 下标（pid）。
     */
    function getRewardsForFarm(uint256 poolIndex) public view returns (address[] memory) {
        require(poolIndex < poolInfo.length, "Invalid pool index");
        return poolInfo[poolIndex].rewards;
    }

    // ========== 无权限限制：Farm 回调铸币 ==========

    /**
     * @notice Farm 在用户领取时调用：按本池 rewards/ratios 将 _amount 拆成多笔 mint。
     * @dev 仅 isFarm[msg.sender]；先 updateVotePool 同步投票权变化；_amount 为 StakingRewards 中记账的「奖励计量」。
     * @param _receiver 最终收奖励的用户地址。
     * @param _amount StakingRewards 侧结算的奖励计量（再按 ratios 拆成多币种 mint）。
     */
    function mintRewards(address _receiver, uint256 _amount) public {
        // 核心安全线：只有登记过的 StakingRewards 才能触发铸币，避免任意合约无限 mint。
        require(isFarm[msg.sender] == true, "MasterChef: only farms can mint rewards");
        // 全局开闸前禁止发奖：即便某个池“内部算出了 rewards”，也会卡在这里回滚。
        require(block.timestamp >= stakingRewardsGenesis, 'Masterchef: rewards too soon');
 
        // 在铸币前先把投票状态同步一遍：如果用户的 xBASE 余额变化了，这里会调整其投票票数，从而影响 allocPointCommunity。
        updateVotePool(_receiver);
        // msg.sender 是矿池合约，receiver 是最终领币的用户；用矿池地址找到对应 pid。
        uint256 poolPid = poolPidByStakingFarmAddress[msg.sender];
        PoolInfo storage pool = poolInfo[poolPid];
        // 逐币种拆分：例如 ratios=[8000,2000] 时，一次领取会铸两笔：80% 给 COIN，20% 给 BASE。
        for (uint i = 0; i < pool.rewards.length; i++) {
            uint256 amountToMint = _amount.mul(pool.ratios[i]).div(10000);
            require(
                IBaseToken(pool.rewards[i]).mint(_receiver, amountToMint),
                'MasterChef: mint rewardsToken failed'
            );
        }
    }

    /**
     * @notice 提取误转入本合约的 ERC20（仅 owner）。
     * @param token 代币合约地址。
     * @param amount 转出数量。
     */
    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @dev 遍历所有池并调用 `_updatePool`；池多时注意 Gas。
     * @notice 使用场景：调整全局排放或权重后，一次性同步各池 `rewardRate`。
     */
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /**
     * @notice 对外暴露的全量刷新各池 `rewardRate`（仅 owner）。
     */
    function massUpdatePools() public onlyOwner {
        _massUpdatePools();
    }

    /**
     * @notice 只更新单个池的 `rewardRate`（例如仅调整了某一池的 allocPoint）。
     * @param _pid `poolInfo` 下标。
     */
    function updatePool(uint256 _pid) public onlyOwner {
        _updatePool(_pid);
    }

    /**
     * @notice 根据全局参数计算本池 StakingRewards 应有的每秒产出，并 setRewardRate。
     * @dev 可投票池：基础份额 + 社区份额；若 Farm 已被 kill（isFarm 为 false）则清零 alloc 与 rewardRate。
     * @param _pid `poolInfo` 下标。
     */
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[pool.stakingFarm];
        if (pool.masterchefControlled == true) {
            // 基础线：全局每秒产出 * 本池 allocPoint / 总 allocPoint（总为 0 时退化为全局全给，避免除零）
            uint normalRewardRate = totalAllocPoint == 0 ? globalSkullPerSecond : globalSkullPerSecond.mul(pool.allocPoint).div(totalAllocPoint);
            if (pool.isVoteable == true) {
                uint256 actualRate = IStakingRewards(info.stakingRewards).rewardRate();
                uint communityRewardRate = totalAllocPointCommunity == 0 ? globalCommunitySkullPerSecond : globalCommunitySkullPerSecond.mul(pool.allocPointCommunity).div(totalAllocPointCommunity);
                uint256 newRate = normalRewardRate.add(communityRewardRate);
                if (actualRate != newRate) {
                    IStakingRewards(info.stakingRewards).setRewardRate(newRate);
                }
            } else {
                uint256 actualRate = IStakingRewards(info.stakingRewards).rewardRate();
                if (actualRate != normalRewardRate) {
                    IStakingRewards(info.stakingRewards).setRewardRate(normalRewardRate);
                }
            }

            if(isFarm[pool.stakingFarm] == false) {
                if (pool.allocPoint != 0) {
                    totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
                    pool.allocPoint = 0;
                    // 下架池：将链上 rewardRate 置 0
                    IStakingRewards(info.stakingRewards).setRewardRate(0);
                }
                if (pool.allocPointCommunity != 0) {
                    totalAllocPointCommunity = totalAllocPointCommunity.sub(pool.allocPointCommunity);
                    pool.allocPointCommunity = 0;
                    // 下架池：将链上 rewardRate 置 0
                    IStakingRewards(info.stakingRewards).setRewardRate(0);
                }
            }
        }
    }

    /**
     * @dev 更新单池基础权重并维护 `totalAllocPoint`；改后需 `updatePool` / `massUpdatePools` 才会写入 Farm。
     * @param _pid 池索引。
     * @param _allocPoint 新的基础 alloc 权重。
     */
    function _set(uint256 _pid, uint256 _allocPoint) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (totalAllocPoint != 0) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
            pool.allocPoint = _allocPoint;
        } else {
            totalAllocPoint = _allocPoint;
            pool.allocPoint = _allocPoint;
        }
    }

    /**
     * @notice 设置某池基础分配权重（仅 owner）。
     * @param _pid 池索引。
     * @param _allocPoint 基础 alloc 权重。
     */
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        _set(_pid, _allocPoint);
    }

    /**
     * @notice 批量设置多池基础 alloc（仅 owner）。
     * @param _pids 池索引数组。
     * @param _allocs 与 _pids 等长的权重数组。
     */
    function setBulk(uint256[] memory _pids, uint256[] memory _allocs) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _set(_pids[pid], _allocs[pid]);
        }
    }

    // ========== 投票：xBASE 决定社区排放 allocPointCommunity ==========
    // 用户用 xBASE 为某池「拉」社区每秒份额：
    // - globalCommunitySkullPerSecond 是社区加成总盘子
    // - allocPointCommunity 是各池从社区盘子分走的份额
    // 至少每 7 天投票变动会触发一次 _massUpdatePools，避免 rewardRate 长期不刷新。

    /**
     * @dev 增加某池社区权重及全局 `totalAllocPointCommunity`。
     * @param _pid 池索引。
     * @param _allocPointCommunity 本次增加的社区票数/权重。
     */
    function increaseAllocation(uint256 _pid, uint256 _allocPointCommunity) internal {
        if (block.timestamp >= lastUpdatedTimeVotes  + 7 days) {
            _massUpdatePools();
            lastUpdatedTimeVotes = block.timestamp;
        }

        totalAllocPointCommunity = totalAllocPointCommunity.add(_allocPointCommunity);
        poolInfo[_pid].allocPointCommunity = poolInfo[_pid].allocPointCommunity.add(_allocPointCommunity);
    }

    /**
     * @dev 减少某池社区权重及全局 `totalAllocPointCommunity`。
     * @param _pid 池索引。
     * @param _allocPointCommunity 本次减少的社区票数/权重。
     */
    function decreaseAllocation(uint256 _pid, uint256 _allocPointCommunity) internal {
        if (block.timestamp >= lastUpdatedTimeVotes  + 7 days) {
            _massUpdatePools();
            lastUpdatedTimeVotes = block.timestamp;
        }

        totalAllocPointCommunity = totalAllocPointCommunity.sub(_allocPointCommunity);
        poolInfo[_pid].allocPointCommunity = poolInfo[_pid].allocPointCommunity.sub(_allocPointCommunity);
    }

    /**
     * @notice 内部投票结算：把用户在目标池的“已投票数”调整到 `_amount`，并把差额同步到该池 `allocPointCommunity`。
     * @dev 业务背景：这里维护的是「社区加成盘子」的分配权，不是直接给用户发币。
     *      池子最终社区加成速率公式见 `_updatePool`：
     *      `globalCommunitySkullPerSecond * pool.allocPointCommunity / totalAllocPointCommunity`。
     *      换句话说：用户投票越多，池子的 `allocPointCommunity` 越高，池子每秒能分到的“社区奖励份额”越多。
     * @example 场景1（加票）：
     *          小明原先投给 ETH/BASE 池 1000 票，现在 xBASE 变成 1500，
     *          本函数会把 increaseAmount=500 加到该池 community 权重。
     * @example 场景2（减票）：
     *          小明原先 1000 票，后来只剩 700，
     *          本函数会把 decreaseAmount=300 从该池 community 权重里扣掉。
     * @param _user 投票用户。
     * @param _amount 目标票数（与当前 user.vote 的差额会增减 allocPointCommunity）。
     * @param _pid 被投票的池索引。
     */
    function vote(address _user, uint256 _amount, uint256 _pid) internal {
        UserInfo storage user = userInfo[_user];
    
        if (_amount > user.vote){
            uint256 increaseAmount = _amount.sub(user.vote);
            user.vote = _amount;
            increaseAllocation(_pid, increaseAmount);
        } 
        else {
            uint256 decreaseAmount = user.vote.sub(_amount);
            user.vote = _amount;
            decreaseAllocation(_pid, decreaseAmount);
        }
    }

    /**
     * @notice 撤销用户在某池的全部投票（把该用户贡献给池子的 community 权重一次性减回去）。
     * @dev 业务场景：用户点击 `unVotePool`，或治理希望用户重新投其它池时，会先做这一步。
     * @example 小明在 3 号池投了 1500 票，调用后 3 号池 `allocPointCommunity` 会减少 1500，小明的 `user.vote` 归零。
     * @param _user 撤票用户。
     * @param _pid 当前投票所在的池索引。
     */
    function redeemVote(address _user, uint256 _pid) internal {
        UserInfo storage user = userInfo[_user];
        decreaseAllocation(_pid, user.vote);
        user.vote = 0;
        
    }

    /**
     * @notice 计算用户当前总投票权：`xBASE 钱包余额 + 被标记为计票池中的存款余额`。
     * @dev 业务背景：协议允许把“持有 xBASE”与“把 xBASE 存进指定单币池”都算作治理投票权，
     *      这样用户不用在“拿收益”和“保留投票权”之间二选一。
     * @param _user 用户地址
     * @return 可用于 `votePool` 的权重（此函数只算权重，不判断是否已经投过票）
     * @example 小明钱包有 800 xBASE，另在被标记为计票的单币池里存了 200 xBASE，
     *          则 `getTotalVotePower(小明)=1000`。
     */
    function getTotalVotePower(address _user) public view returns(uint256){
        // 钱包持有的 xBASE
        uint256 xBaseUserWalletBalance = IERC20(xBASE).balanceOf(_user);
        // 在开启计票开关的单币池中质押的 xBASE
        uint256 length = poolInfo.length;
        uint256 totalUserDeposits;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].countDepositAmountAsVotingPower == true) {
                totalUserDeposits += ISingleStaking(poolInfo[pid].stakingFarm).balanceOf(_user);
            }
        }
        uint256 amount1 = xBaseUserWalletBalance.add(totalUserDeposits);
        return amount1;
    }

    /**
     * @notice 把用户“当前全部投票权”一次性投给某个池（本设计一人同一时刻只能投一个池）。
     * @dev 使用场景：社区希望把更多社区加成排放给某个池（例如 ETH/BASE 池），
     *      用户进入前端点“Vote”后会走这个入口。
     * @param _pid `poolInfo` 中的池索引（必须 `isVoteable=true`）
     * @example 小明当前投票权 1000，给 2 号池投票后：
     *          - userInfo[小明].vote = 1000
     *          - userInfo[小明].votedID = 2
     *          - voted[小明] = true
     *          - 2 号池 allocPointCommunity 增加 1000
     */
    function votePool(uint256 _pid) external {
        require(poolInfo[_pid].isVoteable, "vote not permitted");
        address _user = msg.sender;
        require(voted[_user] == false);
        require(getTotalVotePower(_user) > 0, " no voting power");
        UserInfo storage user = userInfo[_user];
        // 把用户“当前全部投票权”一次性投给该池（本合约设计为一人只能投一个池）。
        vote(_user, getTotalVotePower(_user), _pid);
        user.votedID = _pid;
        voted[_user] = true;
    }
    

    /// @notice 撤销当前投票并回收对应 `allocPointCommunity`。
    /// @dev 使用场景：用户准备把票从 A 池改投 B 池，或暂时不参与投票时先执行本函数。
    function unVotePool() external {
        address _user = msg.sender;
        require(voted[_user], "not voted");
        UserInfo storage user = userInfo[_user];
        redeemVote(_user, user.votedID);
        voted[_user] = false;
    }

    /**
     * @notice 在关键时机同步用户投票状态：若用户已投票，按最新投票权重重算其票；若权重归零则清理投票标记。
     * @dev 业务背景：用户的投票权会随 xBASE 余额和计票存款变化而变化，
     *      若不重算，池子的社区权重会“滞后”于真实持仓。
     *      本合约在 `mintRewards` 前调用它，确保领币流程顺带把投票状态校准到最新。
     * @example 小明曾投票 1000，后来把 xBASE 全卖掉：
     *          下次触发 `mintRewards` 时这里会发现投票权为 0，并把 `voted[小明]` 置 false。
     */
    /**
     * @param _user 待同步投票状态的用户（常为领奖人 `_receiver`）。
     */
    function updateVotePool(address _user) internal {
        if (voted[_user]){
            UserInfo storage user = userInfo[_user];
            // 在领币/触发时同步：用户 xBASE 余额可能变化，更新其票数并调整池子的 allocPointCommunity。
            vote(_user, getTotalVotePower(_user), user.votedID);
        }
        if (getTotalVotePower(_user) == 0){
            // 若用户投票权归零（例如把 xBASE 全卖掉/解锁掉），则自动清除投票标记，避免占着“已投票”状态。
            voted[_user] = false;
        }
    }

    // ========== 农场运维：奖励结构、上下架、投票与全局排放 ==========

    /**
     * @notice 设置某池的奖励代币列表与万分比拆分（仅 owner）。
     * @dev 使用场景：某池从只发 COIN 升级为 COIN+BASE，或调整活动期比例。
     *      `_ratios` 须与 `_rewards` 等长，总和通常约定为 10000。
     * @param _pid 池索引。
     * @param _rewards 奖励代币地址数组。
     * @param _ratios 万分比数组。
     */
    function setTokensAndRatiosFarm(uint _pid, address[] calldata _rewards, uint[] calldata _ratios) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.ratios = _ratios;
        pool.rewards = _rewards;
    }

    /**
     * @notice 设置此后新 `deploy` / `deployWithCreation` 池子的默认奖励结构（仅 owner）。
     * @dev 不会自动回写已存在池；已存在池请用 `setTokensAndRatiosFarm`。
     */
    function setDefaultTokensAndRatios(address[] calldata _rewards, uint[] calldata _ratios) external onlyOwner {
        defaultRatios = _ratios;
        defaultRewards = _rewards;
    }

    /**
     * @notice 紧急下架矿池：禁止 `mintRewards`，关闭投票并刷新各池速率。
     * @param _farm StakingRewards 合约地址。
     */
    function killFarm(address _farm) external onlyOwner {
        require(isFarm[_farm] == true, "MasterChef: This is not active");

        isFarm[_farm] = false;

        uint256 poolPid = poolPidByStakingFarmAddress[_farm];
        _setIsVoteable(poolPid, false);

        _massUpdatePools();
    }

    /**
     * @notice 重新启用曾被 `killFarm` 的矿池（不重新 deploy，Farm 地址不变）。
     * @param _farm StakingRewards 合约地址。
     */
    function activateFarm(address _farm) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farm];
        require(info.stakingRewards != address(0), 'MasterChef: needs to be a dead farm');
        require(isFarm[_farm] == false, "MasterChef: This is not active");

        isFarm[_farm] = true;

        _massUpdatePools();
    }

    /**
     * @notice 开关某池是否允许用户 `votePool`（仅 owner）。
     * @param _pid 池索引。
     * @param _isVoteable true 表示可投票。
     */
    function setIsVoteable(uint256 _pid, bool _isVoteable) external onlyOwner {
        _setIsVoteable(_pid, _isVoteable);
    }

    /**
     * @dev 关闭投票时会将该池已积累的 `allocPointCommunity` 一次性扣回。
     */
    function _setIsVoteable(uint256 _pid, bool _isVoteable) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isVoteable = _isVoteable;

        if (_isVoteable == false) {
            // 关掉可投票：把该池已积累的社区票全部撤回（allocPointCommunity 归零）。
            decreaseAllocation(_pid, pool.allocPointCommunity);
        }
    }

    /**
     * @notice 批量开关多池投票资格（仅 owner）。
     */
    function setIsVoteableBulk(uint256[] memory _pids, bool[] memory _voteable) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setIsVoteable(_pids[pid], _voteable[pid]);
        }
    }

    /**
     * @dev 设置某池是否由本合约通过 `_updatePool` 自动写 `rewardRate`。
     */
    function _setIsMasterchefControlled(uint256 _pid, bool _masterchefControlled) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.masterchefControlled = _masterchefControlled;
    }

    /**
     * @notice 开关某池是否由 MasterchefV2 自动控速（仅 owner）。
     * @dev false 时外部自行调 StakingRewards.setRewardRate；true 时由 alloc 与投票驱动。
     */
    function setIsMasterchefControlled(uint256 _pid, bool _masterchefControlled) external onlyOwner {
        _setIsMasterchefControlled(_pid, _masterchefControlled);
    }

    /**
     * @notice 批量开关多池是否由 MasterchefV2 控速（仅 owner）。
     */
    function setIsMasterchefControlledBulk(uint256[] memory _pids, bool[] memory _masterchefControlled) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setIsMasterchefControlled(_pids[pid], _masterchefControlled[pid]);
        }
    }

    /**
     * @dev 设置某池质押余额是否计入投票权（须 stakingFarm 实现 balanceOf）。
     */
    function _setCountDepositAmountAsVotingPower(uint256 _pid, bool _countAsVotingPower) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.countDepositAmountAsVotingPower = _countAsVotingPower;
    }

    /**
     * @notice 开关「某池内质押的 xBASE 是否计票」（仅 owner）。
     * @dev 开启后 `getTotalVotePower` 会对该池 `stakingFarm.balanceOf` 外部调用。
     */
    function setCountDepositAmountAsVotingPower(uint256 _pid, bool _countAsVotingPower) public onlyOwner {
        _setCountDepositAmountAsVotingPower(_pid, _countAsVotingPower);
    }

    /**
     * @notice 批量开关多池的存款计票（仅 owner）。
     */
    function setCountDepositAmountAsVotingPowerBulk(uint256[] memory _pids, bool[] memory _countAsVotingPower) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setCountDepositAmountAsVotingPower(_pids[pid], _countAsVotingPower[pid]);
        }
    }

    /**
     * @notice 设置全局基础每秒排放计量（仅 owner）；改后建议 `massUpdatePools`。
     * @param _globalSkullPerSecond 新的 `globalSkullPerSecond`。
     */
    function setGlobalSkullPerSecond(uint256 _globalSkullPerSecond) public onlyOwner {
        globalSkullPerSecond = _globalSkullPerSecond;
    }

    /**
     * @notice 设置全局社区投票每秒排放计量（仅 owner）；改后建议 `massUpdatePools`。
     * @param _globalCommunitySkullPerSecond 新的 `globalCommunitySkullPerSecond`。
     */
    function setGlobalCommunitySkullPerSecond(uint256 _globalCommunitySkullPerSecond) public onlyOwner {
        globalCommunitySkullPerSecond = _globalCommunitySkullPerSecond;
    }
}