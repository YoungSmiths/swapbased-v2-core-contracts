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

interface IBaseToken {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

interface ISingleStaking {
    function balanceOf(address account) external view returns (uint256);
}

/* MADE BY KELL */

/**
 * @title MasterChefCoin
 * @notice 与 MasterchefV2 同族的 **流动性挖矿调度中心**：仅已注册的 Farm（`StakingRewards`）可调用 `mintRewards`，按池 `ratios`（万分比）向多种 `IBaseToken` 铸币。
 * @dev 在 V2 基础上增加 **`minters` 与 `mintRewardsByAddress`**：白名单可不经过 Farm 的 `ratios` 拆分，直接对指定代币 `mint`；构造函数将 `minters[部署者]=true`。
 */
contract MasterChefCoin is Ownable {
    using SafeMath for uint256;
    // immutables
    /// @notice 治理代币 xBASE，用于 `getTotalVotePower` 与投票逻辑（与 V2 一致）
    address public xBASE;
    uint public stakingRewardsGenesis;
    uint public totalAllocPoint;
    uint public totalAllocPointCommunity;

    mapping (address => bool) public isFarm;

    uint public lastUpdatedTimeVotes;
    uint public globalSkullPerSecond;
    uint public globalCommunitySkullPerSecond;
    uint256[] public defaultRatios;
    address[] public defaultRewards;

    mapping(address => UserInfo) public userInfo;

    // Info of each user.
    struct UserInfo {
        uint256 vote;
        uint256 votedID;
    }

    // Info of each pool.
    struct PoolInfo {
        address stakingFarm;           // Address of Staking Farm contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SKULLs to distribute per block.
        uint256 allocPointCommunity;       // How many allocation points assigned to this pool. SKULLs to distribute per block.
        bool isVoteable;
        bool masterchefControlled;
        bool countDepositAmountAsVotingPower;

        uint256[] ratios;
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

    /// @notice 可调用 `mintRewardsByAddress` 的白名单地址；部署者为初始 minter
    mapping(address => bool) public minters;

    /// @notice 仅允许 `minters[msg.sender] == true`
    modifier onlyRewardsMinter() {
        require(minters[msg.sender] == true, "Only minters allowed");
        _;
    }

    /**
     * @notice 部署 MasterChefCoin，设置默认多代币奖励与全局挖矿起始时间。
     * @param _xBASE 治理代币 xBASE 合约地址
     * @param _rewards 默认奖励代币列表（须实现 IBaseToken.mint）
     * @param _ratios 与 _rewards 等长的万分比数组，总和通常约定为 10000
     * @param _stakingRewardsGenesis 到达该时间戳后才允许 `mintRewards` / `mintRewardsByAddress`（须 ≥ block.timestamp）
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
        minters[msg.sender] = true;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis

    /**
     * @notice 批量注册已部署的 Farm 合约地址（不内联 new StakingRewards）。
     * @param _addys Farm（StakingRewards）合约地址数组
     * @param _start 各池 Farm 起始时间，须均大于 `stakingRewardsGenesis`
     * @param _masterchefControlled 是否与 Chef 同步 `rewardRate`；为 true 时通常 `isVoteable` 同为 true
     */
    function deployBulk(address[] memory _addys, uint256[] memory _start, bool[] memory _masterchefControlled) public onlyOwner {
        uint256 length = _addys.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _deploy(_addys[pid], _start[pid], _masterchefControlled[pid]);
        }
    }

    /**
     * @notice 注册单个已存在的 Farm 合约。
     * @param _farmAddress StakingRewards 合约地址
     * @param _farmStartTime 该池允许开始计奖的时间（须 > stakingRewardsGenesis）
     * @param _masterchefControlled 是否由 Chef `_updatePool` 驱动 `setRewardRate`
     */
    function deploy(address _farmAddress, uint256 _farmStartTime, bool _masterchefControlled) public onlyOwner {
        _deploy(_farmAddress, _farmStartTime, _masterchefControlled);
    }

    /// @dev 写入 `isFarm`、追加 `poolInfo`、登记 `poolPidByStakingFarmAddress`
    function _deploy(address _farmAddress, uint256 _farmStartTime, bool _masterchefControlled) internal {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farmAddress];
        require(info.stakingRewards == address(0), 'MasterChef: already deployed');
        require(_farmStartTime > stakingRewardsGenesis, "Masterchef: cant start farm before global time");

        info.stakingRewards = _farmAddress;
        isFarm[_farmAddress] = true;
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
     * @notice 内联 `new StakingRewards` 部署新 Farm 并注册；质押标的为 `_stakingToken`（多为 LP）。
     * @param _stakingToken 用户质押的 ERC20（如 Uniswap V2 LP）
     * @param _farmStartTime Farm 起始时间，须 > stakingRewardsGenesis
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
     * @notice Farm 在用户领取奖励时调用：按本池 `rewards`/`ratios` 将 `_amount` 拆成多笔 `mint`（万分比）。
     * @param _receiver 奖励接收地址（通常为领励用户）
     * @param _amount StakingRewards 中累计的「奖励计量」总量（与 `getReward` 中 `reward` 一致）
     */
    function mintRewards(address _receiver, uint256 _amount) public {
        require(isFarm[msg.sender] == true, "MasterChef: only farms can mint rewards");
        require(block.timestamp >= stakingRewardsGenesis, 'Masterchef: rewards too soon');

        updateVotePool(_receiver);
        uint256 poolPid = poolPidByStakingFarmAddress[msg.sender]; // msg.sender is the farm, the receiver is the person who will receive rewards
        PoolInfo storage pool = poolInfo[poolPid];
        for (uint i = 0; i < pool.rewards.length; i++) {
            uint256 amountToMint = _amount.mul(pool.ratios[i]).div(10000);
            require(
                IBaseToken(pool.rewards[i]).mint(_receiver, amountToMint),
                'MasterChef: mint rewardsToken failed'
            );
        }
    }

    /**
     * @notice 白名单入口：不经过 Farm `ratios` 拆分，直接向指定 `IBaseToken` 铸 `_amount` 给 `_receiver`。
     * @param _receiver 接收铸造代币的地址
     * @param _amount 铸造数量
     * @param _token 奖励代币合约地址（须实现 IBaseToken）
     */
    function mintRewardsByAddress(address _receiver, uint256 _amount, address _token) public onlyRewardsMinter {
        require(
            IBaseToken(_token).mint(_receiver, _amount), 'MasterChef: mint rewardsToken failed'
        );
    }

    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }


    // Update reward variables for all pools. Be careful of gas spending!
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function massUpdatePools() public onlyOwner {
        _massUpdatePools();
    }

    function updatePool(uint256 _pid) public onlyOwner {
        _updatePool(_pid);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[pool.stakingFarm];
        if (pool.masterchefControlled == true) {
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

    function redeemVote(address _user, uint256 _pid) internal {
        UserInfo storage user = userInfo[_user];
        decreaseAllocation(_pid, user.vote);
        user.vote = 0;
        
    }

    // -----------------------------

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

    function votePool(uint256 _pid) external {
        require(poolInfo[_pid].isVoteable, "vote not permitted");
        address _user = msg.sender;
        require(voted[_user] == false);
        require(getTotalVotePower(_user) > 0, " no voting power");
        UserInfo storage user = userInfo[_user];
        vote(_user, getTotalVotePower(_user), _pid);
        user.votedID = _pid;
        voted[_user] = true;
    }
    

    function unVotePool() external {
        address _user = msg.sender;
        require(voted[_user], "not voted");
        UserInfo storage user = userInfo[_user];
        redeemVote(_user, user.votedID);
        voted[_user] = false;
    }

    function updateVotePool(address _user) internal {
        if (voted[_user]){
            UserInfo storage user = userInfo[_user];
            vote(_user, getTotalVotePower(_user), user.votedID);
        }
        if (getTotalVotePower(_user) == 0){
            voted[_user] = false;
        }
    }

    /*********************** FARMS CONTROLS ***********************/

    function setTokensAndRatiosFarm(uint _pid, address[] calldata _rewards, uint[] calldata _ratios) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.ratios = _ratios;
        pool.rewards = _rewards;
    }

    function setDefaultTokensAndRatios(address[] calldata _rewards, uint[] calldata _ratios) external onlyOwner {
        defaultRatios = _ratios;
        defaultRewards = _rewards;
    }

    function killFarm(address _farm) external onlyOwner {
        require(isFarm[_farm] == true, "MasterChef: This is not active");

        isFarm[_farm] = false;

        uint256 poolPid = poolPidByStakingFarmAddress[_farm];
        _setIsVoteable(poolPid, false);

        _massUpdatePools();
    }

    function activateFarm(address _farm) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farm];
        require(info.stakingRewards != address(0), 'MasterChef: needs to be a dead farm');
        require(isFarm[_farm] == false, "MasterChef: This is not active");

        isFarm[_farm] = true;

        _massUpdatePools();
    }

    function setIsVoteable(uint256 _pid, bool _isVoteable) external onlyOwner {
        _setIsVoteable(_pid, _isVoteable);
    }

    function _setIsVoteable(uint256 _pid, bool _isVoteable) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isVoteable = _isVoteable;

        if (_isVoteable == false) {
            decreaseAllocation(_pid, pool.allocPointCommunity);
        }
    }

    function setIsVoteableBulk(uint256[] memory _pids, bool[] memory _voteable) public onlyOwner {
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
        _setIsMasterchefControlled(_pid, _masterchefControlled);
    }

    function setIsMasterchefControlledBulk(uint256[] memory _pids, bool[] memory _masterchefControlled) public onlyOwner {
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
        _setCountDepositAmountAsVotingPower(_pid, _countAsVotingPower);
    }

    function setCountDepositAmountAsVotingPowerBulk(uint256[] memory _pids, bool[] memory _countAsVotingPower) public onlyOwner {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _setCountDepositAmountAsVotingPower(_pids[pid], _countAsVotingPower[pid]);
        }
    }

    function setGlobalSkullPerSecond(uint256 _globalSkullPerSecond) public onlyOwner {
        globalSkullPerSecond = _globalSkullPerSecond;
    }

    function setGlobalCommunitySkullPerSecond(uint256 _globalCommunitySkullPerSecond) public onlyOwner {
        globalCommunitySkullPerSecond = _globalCommunitySkullPerSecond;
    }

    function setMinters(address _minter, bool _canMint) public onlyOwner {
        minters[_minter] = _canMint;
    }
}