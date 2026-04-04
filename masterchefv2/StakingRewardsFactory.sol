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

/**
 * @title StakingRewardsFactory
 * @notice **简化版**挖矿调度：为每个 `_stakingToken` 部署独立 `StakingRewards`，`mintRewards` 仅向 **单一** `rewardsToken` 铸造（无多币 `ratios`、无 xBASE 投票）。
 * @dev 与 `MasterchefV2` 二选一；`updatePool` 按 `globalSkullPerSecond * allocPoint / totalAllocPoint` 设置各 Farm 的 `rewardRate`。
 */
contract StakingRewardsFactory is Ownable {
    using SafeMath for uint256;
    // immutables
    /// @notice 唯一奖励代币，须实现 IBaseToken.mint
    address public rewardsToken;
    uint public stakingRewardsGenesis;
    uint public totalAllocPoint;

    address public xSkullStaking;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    mapping (address => bool) public isFarm;

    uint public globalSkullPerSecond;
    uint public globalXSkullPerSecond;

        // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SKULLs to distribute per block.
    }
    
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    /**
     * @param _rewardsToken 全池统一的奖励代币地址
     * @param _stakingRewardsGenesis 全局允许开始发奖的时间戳
     */
    constructor(
        address _rewardsToken,
        uint _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'MasterChef: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    /**
     * @notice 为 `_stakingToken` 部署新的 `StakingRewards`（Chef 为本合约 `address(this)`）。
     * @param _stakingToken 用户将质押的代币（如 LP）
     * @param _rewardRate 初始每秒奖励（后续由 `updatePool` 覆盖）
     * @param _farmStartTime 须大于 `stakingRewardsGenesis`
     */
    function deploy(address _stakingToken, uint256 _rewardRate, uint256 _farmStartTime) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[_stakingToken];
        require(info.stakingRewards == address(0), 'MasterChef: already deployed');
        require(_farmStartTime > stakingRewardsGenesis, "Masterchef: cant start farm before global time");

        info.stakingRewards = address(new StakingRewards(address(this), owner(), _stakingToken, _rewardRate, stakingRewardsGenesis));
        isFarm[_stakingToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: IERC20(_stakingToken),
            allocPoint: 0
        }));

        stakingTokens.push(_stakingToken);
    }

    ///// permissionless functions

    /**
     * @notice 由已注册的 Farm 合约调用：向 `_receiver` 铸造 `_amount` 的 `rewardsToken`。
     * @param _receiver 奖励接收方
     * @param _amount 铸造数量（奖励计量）
     */
    function mintRewards(address _receiver, uint256 _amount) public {
        require(isFarm[msg.sender] == true, "MasterChef: only farms can mint rewards");
        require(block.timestamp >= stakingRewardsGenesis, 'Masterchef: rewards too soon');
        require(
            IBaseToken(rewardsToken).mint(_receiver, _amount),
            'MasterChef: mint rewardsToken failed'
        );
    }

    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }


    /// @notice 遍历全部池子并刷新各 Farm 的 `rewardRate`（gas 随池数增长）
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice 按池 `allocPoint` 与 `globalSkullPerSecond` 计算并 `setRewardRate`；若 Farm 已 kill 则置 0。
     * @param _pid `poolInfo` 索引
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[address(pool.lpToken)];

        if(isFarm[address(pool.lpToken)] == false) {
            if (pool.allocPoint != 0) {
                totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
                pool.allocPoint = 0;
                // set reward rates
                IStakingRewards(info.stakingRewards).setRewardRate(0);
            }
        }

        IStakingRewards(info.stakingRewards).setRewardRate(globalSkullPerSecond.mul(pool.allocPoint).div(totalAllocPoint));
    }

    /**
     * @notice 设置某池分配权重（Owner）。
     * @param _pid 池索引
     * @param _allocPoint 新权重，参与 `totalAllocPoint` 分摊
     */
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        if (totalAllocPoint != 0) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
            pool.allocPoint = _allocPoint;
        } else {
            totalAllocPoint = _allocPoint;
            pool.allocPoint = _allocPoint;
        }
    }

    /*********************** FARMS CONTROLS ***********************/

    /// @param _farm 质押代币地址（见本合约 `isFarm` 键语义）
    function killFarm(address _farm) external onlyOwner {
        require(isFarm[_farm] == true, "MasterChef: This is not active");

        isFarm[_farm] = false;

        massUpdatePools();
    }

    /// @param _farm 质押代币地址
    function activateFarm(address _farm) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[_farm];
        require(info.stakingRewards != address(0), 'MasterChef: needs to be a dead farm');
        require(isFarm[_farm] == false, "MasterChef: This is not active");

        isFarm[_farm] = true;

        massUpdatePools();
    }

    /**
     * @notice 设置全局每秒奖励总量（再按各池 `allocPoint` 分摊）。
     * @param _globalSkullPerSecond 新的全局速率
     */
    function setGlobalSkullPerSecond(uint256 _globalSkullPerSecond) public onlyOwner {
        globalSkullPerSecond = _globalSkullPerSecond;
    }
}