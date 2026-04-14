// SPDX-License-Identifier: UNLICENSED
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
    function balanceOf(address account) external view returns (uint256);
}

/* MADE BY KELL */

/**
 * @title MasterchefV2
 * @notice 流动性挖矿「调度中心」：仅允许已注册的 Farm（StakingRewards）调用 mintRewards 铸奖励；
 *         按池分配全局每秒产出（allocPoint）与社区投票份额（allocPointCommunity），并驱动各池 rewardRate。
 * @dev 奖励代币通过 IBaseToken.mint 发放；ratios 为万分比，与 rewards 数组一一对应。
 */
contract MasterchefV2 is Ownable {
    using SafeMath for uint256;
    // immutables
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
    uint256[] public defaultRatios;
    address[] public defaultRewards;

    /// @notice 用户投票状态：记录用户当前投票数量与投给哪个池（votedID）。
    /// @example 小明把 1000 票投给 pid=3，则 userInfo[小明].vote=1000 且 votedID=3；后续余额变化会在 `updateVotePool` 时同步。
    mapping(address => UserInfo) public userInfo;

    // Info of each user.
    struct UserInfo {
        /// @notice 用户当前“投出去”的票数（按 xBASE 计量，可能包含单币质押余额）。
        uint256 vote;
        /// @notice 用户投票的池子 id（poolInfo 索引）。
        uint256 votedID;
    }

    // Info of each pool.
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
    
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingFarmAddress;
    mapping(address => uint) public poolPidByStakingFarmAddress;
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

    // permissioned functions
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

    /// @dev 登记 `isFarm`、追加 `poolInfo`、默认 `ratios/rewards` 来自构造函数（defaultRewards/defaultRatios）。
    ///      这是“只登记不创建”的路径：Farm 合约由外部先部署好，MasterchefV2 只负责调度与铸币。
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

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    /**
     * @notice 内联创建新的 `StakingRewards` 并注册为 Farm。
     * @param _stakingToken 用户质押代币（多为 LP）
     * @param _farmStartTime Farm 起始时间，须大于 `stakingRewardsGenesis`
     */
    /**
     * @notice **使用场景**：Owner 希望“一步到位”创建并登记一个新矿池：这里会 `new StakingRewards(...)` 并把它注册到本 MasterchefV2。
     * @param _stakingToken 用户质押的 ERC20（常见为 LP Token 地址）。
     * @param _farmStartTime 单池开采开始时间戳（必须 > stakingRewardsGenesis）。
     * @dev 与 StakingRewardsFactory 的区别：这里的“key”是 **新 Farm 合约地址**，而不是 LP 地址。
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

    function getRatiosForFarm(uint256 poolIndex) public view returns (uint256[] memory) {
        require(poolIndex < poolInfo.length, "Invalid pool index");
        return poolInfo[poolIndex].ratios;
    }

    function getRewardsForFarm(uint256 poolIndex) public view returns (address[] memory) {
        require(poolIndex < poolInfo.length, "Invalid pool index");
        return poolInfo[poolIndex].rewards;
    }

    ///// permissionless functions

    /**
     * @notice Farm 在用户领取时调用：按本池 rewards/ratios 将 _amount 拆成多笔 mint。
     * @dev 仅 isFarm[msg.sender]；先 updateVotePool 同步投票权变化；_amount 为 StakingRewards 中记账的「奖励计量」。
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

    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }


    // Update reward variables for all pools. Be careful of gas spending!
    // 使用场景：改了全局排放或很多池子的权重后，想让所有池 rewardRate 立刻对齐。
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function massUpdatePools() public onlyOwner {
        _massUpdatePools();
    }

    /// @notice **使用场景**：只更新单个池的 rewardRate（例如运营只调了某一个池的 allocPoint）。
    function updatePool(uint256 _pid) public onlyOwner {
        _updatePool(_pid);
    }

    /**
     * @notice 根据全局参数计算本池 StakingRewards 应有的每秒产出，并 setRewardRate。
     * @dev 可投票池：基础份额 + 社区份额；若 Farm 已被 kill（isFarm 为 false）则清零 alloc 与 rewardRate。
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
                    // set reward rates
                    IStakingRewards(info.stakingRewards).setRewardRate(0);
                }
                if (pool.allocPointCommunity != 0) {
                    totalAllocPointCommunity = totalAllocPointCommunity.sub(pool.allocPointCommunity);
                    pool.allocPointCommunity = 0;
                    // set reward rates
                    IStakingRewards(info.stakingRewards).setRewardRate(0);
                }
            }
        }
    }

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

    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        _set(_pid, _allocPoint);
    }

    function setBulk(uint256[] memory _pids, uint256[] memory _allocs) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _set(_pids[pid], _allocs[pid]);
        }
    }

    /* VOTING */
    // 用户用 xBASE 投票权为某池「拉」社区每秒份额：
    // - globalCommunitySkullPerSecond 是社区加成“总盘子”
    // - allocPointCommunity 是每个池从社区盘子里分走的份额
    // 为了避免投票变化后某些池 rewardRate 长期不刷新，这里以“至少每 7 天一次”触发全量 update。

    function increaseAllocation(uint256 _pid, uint256 _allocPointCommunity) internal {
        if (block.timestamp >= lastUpdatedTimeVotes  + 7 days) {
            _massUpdatePools();
            lastUpdatedTimeVotes = block.timestamp;
        }

        totalAllocPointCommunity = totalAllocPointCommunity.add(_allocPointCommunity);
        poolInfo[_pid].allocPointCommunity = poolInfo[_pid].allocPointCommunity.add(_allocPointCommunity);
    }

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
     */
    function redeemVote(address _user, uint256 _pid) internal {
        UserInfo storage user = userInfo[_user];
        decreaseAllocation(_pid, user.vote);
        user.vote = 0;
        
    }

    // -----------------------------

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
        // get xBASE wallet balance
        uint256 xBaseUserWalletBalance = IERC20(xBASE).balanceOf(_user);
        // get xBASE staked on SingleStake vaults
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

    /*********************** FARMS CONTROLS ***********************/

    function setTokensAndRatiosFarm(uint _pid, address[] calldata _rewards, uint[] calldata _ratios) external onlyOwner {
        // 使用场景：某池从「只发 COIN」升级为「发 COIN + BASE」，或调整分成比例（例如活动期 90/10，常态 80/20）。
        // 注意：_ratios 为万分比数组，必须与 _rewards 一一对应；否则 mintRewards 的 for 循环会按当前 rewards.length 拆分。
        PoolInfo storage pool = poolInfo[_pid];
        pool.ratios = _ratios;
        pool.rewards = _rewards;
    }

    function setDefaultTokensAndRatios(address[] calldata _rewards, uint[] calldata _ratios) external onlyOwner {
        // 使用场景：之后新注册/新创建的池子默认采用新的奖励结构（不会自动回写已存在池）。
        defaultRatios = _ratios;
        defaultRewards = _rewards;
    }

    function killFarm(address _farm) external onlyOwner {
        // 使用场景：紧急下架某矿池（风险/迁移/结束活动）：停止该 farm 调用 mintRewards，并撤掉其投票入口。
        require(isFarm[_farm] == true, "MasterChef: This is not active");

        isFarm[_farm] = false;

        uint256 poolPid = poolPidByStakingFarmAddress[_farm];
        _setIsVoteable(poolPid, false);

        _massUpdatePools();
    }

    function activateFarm(address _farm) external onlyOwner {
        // 使用场景：被 kill 的矿池修复后重新上线（不重新 deploy，不改 stakingFarm 地址）。
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farm];
        require(info.stakingRewards != address(0), 'MasterChef: needs to be a dead farm');
        require(isFarm[_farm] == false, "MasterChef: This is not active");

        isFarm[_farm] = true;

        _massUpdatePools();
    }

    function setIsVoteable(uint256 _pid, bool _isVoteable) external onlyOwner {
        // 使用场景：临时关闭某池的投票入口（例如投票被刷、或该池不希望再吃社区加成）。
        _setIsVoteable(_pid, _isVoteable);
    }

    function _setIsVoteable(uint256 _pid, bool _isVoteable) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isVoteable = _isVoteable;

        if (_isVoteable == false) {
            // 关掉可投票：把该池已积累的社区票全部撤回（allocPointCommunity 归零）。
            decreaseAllocation(_pid, pool.allocPointCommunity);
        }
    }

    function setIsVoteableBulk(uint256[] memory _pids, bool[] memory _voteable) public onlyOwner {
        // 使用场景：一次性批量开关多个池的投票资格（治理提案执行/迁移期）。
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setIsVoteable(_pids[pid], _voteable[pid]);
        }
    }

    function _setIsMasterchefControlled(uint256 _pid, bool _masterchefControlled) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.masterchefControlled = _masterchefControlled;
    }

    function setIsMasterchefControlled(uint256 _pid, bool _masterchefControlled) external onlyOwner {
        // 使用场景：把某池交给“外部脚本/其它合约”控制 rewardRate 时置 false；恢复由 MasterchefV2 按权重自动控速时置 true。
        _setIsMasterchefControlled(_pid, _masterchefControlled);
    }

    function setIsMasterchefControlledBulk(uint256[] memory _pids, bool[] memory _masterchefControlled) public onlyOwner {
        // 使用场景：批量切换多个池是否由 MasterchefV2 控速（例如升级一批池子的控制策略）。
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setIsMasterchefControlled(_pids[pid], _masterchefControlled[pid]);
        }
    }

    function _setCountDepositAmountAsVotingPower(uint256 _pid, bool _countAsVotingPower) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.countDepositAmountAsVotingPower = _countAsVotingPower;
    }

    function setCountDepositAmountAsVotingPower(uint256 _pid, bool _countAsVotingPower) public onlyOwner {
        // 使用场景：允许“把某池里质押的 xBASE 也算投票权”，避免用户必须把 xBASE 放在钱包里才能投票。
        // 风险提示：开启后 getTotalVotePower 会对该池 stakingFarm 调 balanceOf(user)，对实现方有假设。
        _setCountDepositAmountAsVotingPower(_pid, _countAsVotingPower);
    }

    function setCountDepositAmountAsVotingPowerBulk(uint256[] memory _pids, bool[] memory _countAsVotingPower) public onlyOwner {
        // 使用场景：批量开启/关闭多个池的“存款计票”开关。
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setCountDepositAmountAsVotingPower(_pids[pid], _countAsVotingPower[pid]);
        }
    }

    function setGlobalSkullPerSecond(uint256 _globalSkullPerSecond) public onlyOwner {
        // 使用场景：协议整体调整基础 emissions（例如减半日、活动加速期）。改完通常需要调用 massUpdatePools 推送到各池。
        globalSkullPerSecond = _globalSkullPerSecond;
    }

    function setGlobalCommunitySkullPerSecond(uint256 _globalCommunitySkullPerSecond) public onlyOwner {
        // 使用场景：协议整体调整“社区投票加成盘子”的 emissions（例如投票激励期/投票暂停期）。
        globalCommunitySkullPerSecond = _globalCommunitySkullPerSecond;
    }
}