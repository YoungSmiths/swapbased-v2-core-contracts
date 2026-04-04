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

import "./SingleStakingRewardsXBase.sol";

interface IBaseToken {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

/**
 * @title SingleStakingRewardsFactoryXBase
 * @notice **vaultsv2 专用**简化 Chef：注册 `SingleStakingRewardsXBase` Farm 地址，`mintRewards` 仅向单一 `rewardsToken` 铸造（逻辑对齐 `masterchefv2/StakingRewardsFactory`）。
 * @dev `deploy` 传入已部署的 Farm 合约地址；`updatePool` 按 `globalSkullPerSecond` 与 `allocPoint` 调用各 Farm 的 `setRewardRate`。
 */
contract SingleStakingRewardsFactoryXBase is Ownable {
    using SafeMath for uint256;
    // immutables
    address public rewardsToken;
    uint public stakingRewardsGenesis;
    uint public totalAllocPoint;

    mapping (address => bool) public isFarm;

    uint public globalSkullPerSecond;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
    }

    // Info of each pool.
    struct PoolInfo {
        address stakingFarm;           // Address of Staking Farm contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SKULLs to distribute per block.
    }
    
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingFarmAddress;

    /**
     * @param _rewardsToken `mintRewards` 时铸造的 IBaseToken
     * @param _stakingRewardsGenesis 全局允许发奖的起始时间
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
     * @notice 注册已部署的 Farm（`SingleStakingRewardsXBase`）合约地址。
     * @param _farmAddress Farm 合约地址
     * @param _farmStartTime 预留参数（本实现未强校验，以 Farm 构造为准）
     */
    function deploy(address _farmAddress, uint256 _farmStartTime) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farmAddress];
        require(info.stakingRewards == address(0), 'MasterChef: already deployed');

        info.stakingRewards = _farmAddress;
        isFarm[_farmAddress] = true;
        poolInfo.push(PoolInfo({
            stakingFarm: _farmAddress,
            allocPoint: 0
        }));
    }

    ///// permissionless functions

    /**
     * @notice 由已注册 Farm 调用，向 `_receiver` 铸造 `_amount` 的 `rewardsToken`。
     * @param _receiver 奖励接收方
     * @param _amount 铸造数量
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


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @param _pid `poolInfo` 索引
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[pool.stakingFarm];

        if(isFarm[pool.stakingFarm] == false) {
            if (pool.allocPoint != 0) {
                totalAllocPoint = totalAllocPoint.sub(pool.allocPoint);
                pool.allocPoint = 0;
                // set reward rates
                IStakingRewards(info.stakingRewards).setRewardRate(0);
            }
        }

        IStakingRewards(info.stakingRewards).setRewardRate(globalSkullPerSecond.mul(pool.allocPoint).div(totalAllocPoint));
    }

    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        if (totalAllocPoint != 0) {
            totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
            poolInfo[_pid].allocPoint = _allocPoint;
        } else {
            totalAllocPoint = _allocPoint;
            poolInfo[_pid].allocPoint = _allocPoint;
        }
    }

    /*********************** FARMS CONTROLS ***********************/

    function killFarm(address _farm) external onlyOwner {
        require(isFarm[_farm] == true, "MasterChef: This is not active");

        isFarm[_farm] = false;

        massUpdatePools();
    }

    function activateFarm(address _farm) external onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingFarmAddress[_farm];
        require(info.stakingRewards != address(0), 'MasterChef: needs to be a dead farm');
        require(isFarm[_farm] == false, "MasterChef: This is not active");

        isFarm[_farm] = true;

        massUpdatePools();
    }

    function setGlobalSkullPerSecond(uint256 _globalSkullPerSecond) public onlyOwner {
        globalSkullPerSecond = _globalSkullPerSecond;
    }
}