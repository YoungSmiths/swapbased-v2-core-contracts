// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './helpers/ReentrancyGuard.sol';

interface token is IERC20 {
    function burn(uint256 amount) external;
}

interface IMasterChef {
    function mintRewards(address _receiver, uint256 _amount) external;
}

/**
 * @title xBASE
 * @notice BASE 的包装/衍生 ERC20：支持 **Operator 增发**、`lock` 用 BASE 换 xBASE（底层 BASE 销毁）、**归属 vest** 后通过 **MasterChef.mintRewards** 领取奖励计量。
 * @dev `claim` 将 `totalVested` 作为 `_amount` 传给 Chef，由部署配置的 `ratios` 拆成多币铸造；`setRewardRate` 供 Chef 回调写入 `rewardRate` 字段。
 */
contract xBASE is ERC20("xBASE", "xBASE"), Ownable, ReentrancyGuard { 
    using SafeERC20 for IERC20;
    using SafeERC20 for token;
    using SafeMath for uint256;

    /// @notice 底层 BASE 代币（须实现 `burn`）
    token public BASE;
    /// @notice 由 MasterChef 写入的每秒计量，可与外围脚本联动
    uint256 public rewardRate;
    /// @notice 负责 `mintRewards` 的 MasterChef 合约地址
    address public masterChef;
    /// @notice 可调用 `mint` 增发的运维地址
    address public _operator;

    /// @param _token BASE 代币合约地址
    constructor(token _token) {
        _operator = msg.sender;
        BASE = _token;
    }

    modifier onlyMasterChef() {
        require(msg.sender == masterChef, "Caller is not MasterChef contract");
        _;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    struct vestPosition {
        uint256 totalVested;
        uint256 lastInteractionTime;
        uint256 VestPeriod;
    }

    /// @notice 用户归属仓位列表；`claim` 后对应项 `totalVested` 置 0
    mapping (address => vestPosition[]) public userInfo;
    /// @notice 用户已创建的 vest 仓位数量（便于前端遍历 id）
    mapping (address => uint256) public userPositions;

    /// @notice `vest` 使用的默认归属时长
    uint256 public vestingPeriod = 30 days;
    /// @notice `vestHalf` 使用的较短归属时长
    uint256 public shortVestingPeriod = 7 days;

    /**
     * @notice Operator 向 `recipient_` 增发 xBASE。
     * @param recipient_ 接收地址
     * @param amount_ 铸造数量
     */
    function mint(address recipient_, uint256 amount_) external onlyOperator returns (bool) {
        _mint(recipient_, amount_);
        return true;
    }

    /// @notice 销毁调用者本人 xBASE
    /// @param _amount 销毁数量
    function burn(uint256 _amount) external  {
        _burn(msg.sender, _amount);
    }

    /**
     * @notice 查询某仓位剩余归属时间（秒）；实现中沿用 `msg.sender` 维度读取 `userInfo`。
     * @param _address 预留参数（当前视图逻辑与 `msg.sender` 混用，调用时请以实际链上行为为准）
     * @param id `userInfo[msg.sender]` 中的仓位索引
     * @return 剩余秒数，已到期则为 0
     */
    function remainTime(address _address, uint256 id) public view returns(uint256) {
        uint256 timePass = block.timestamp.sub(userInfo[_address][id].lastInteractionTime);
        uint256 remain;
        if (timePass >= userInfo[msg.sender][id].VestPeriod){
            remain = 0;
        }
        else {
            remain = userInfo[msg.sender][id].VestPeriod- timePass;
        }
        return remain;
    }


    /**
     * @notice 将 xBASE 销毁并开启一笔 **30 天** 归属；到期后 `claim` 按 `totalVested` 向 Chef 请领。
     * @param _amount 参与归属并销毁的 xBASE 数量
     */
    function vest(uint256 _amount) external nonReentrant {

        require(this.balanceOf(msg.sender) >= _amount, "xBASE balance too low");

        userInfo[msg.sender].push(vestPosition({
            totalVested: _amount,
            lastInteractionTime: block.timestamp,
            VestPeriod: vestingPeriod
        }));

        userPositions[msg.sender] += 1; 
        _burn(msg.sender, _amount);
    }

   /**
    * @notice 将 xBASE 销毁并开启一笔 **7 天** 归属；记入 `totalVested` 为 `_amount * 100 / 200`（即一半计量）。
    * @param _amount 参与归属并销毁的 xBASE 数量
    */
   function vestHalf(uint256 _amount) external nonReentrant {

        require(this.balanceOf(msg.sender) >= _amount, "xBASE balance too low");

        userInfo[msg.sender].push(vestPosition({
            totalVested: _amount.mul(100).div(200),
            lastInteractionTime: block.timestamp,
            VestPeriod: shortVestingPeriod
        }));
        
        userPositions[msg.sender] += 1; 
        _burn(msg.sender, _amount);
    }

    /**
     * @notice 用户转入 BASE，合约销毁等量 BASE 并向用户 **1:1 铸造 xBASE**（进入流通）。
     * @param _amount 锁入的 BASE 数量
     */
    function lock(uint256 _amount) external nonReentrant {
        require(BASE.balanceOf(msg.sender) >= _amount, "BASE balance too low");
        uint256 amountOut = _amount;
        BASE.safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, amountOut);
        BASE.burn(_amount);
    }

    /**
     * @notice 归属结束后领取：对 `totalVested` 调用 `masterChef.mintRewards`。
     * @param id `userInfo[msg.sender]` 中的仓位索引
     */
    function claim(uint256 id) external nonReentrant {
        require(remainTime(msg.sender, id) == 0, "vesting not end");
        vestPosition storage position = userInfo[msg.sender][id];
        uint256 claimAmount = position.totalVested;
        position.totalVested = 0;
        IMasterChef(masterChef).mintRewards(msg.sender, claimAmount);
    }

    /// @param _rewardRate Chef 同步的每秒奖励参数
    function setRewardRate(uint256 _rewardRate) public onlyMasterChef {
        rewardRate = _rewardRate;
    }

    /// @param _masterChef 新的 MasterChef 地址
    function setMasterChef(address _masterChef) public onlyOwner {
        masterChef = _masterChef;
    }

    /// @param newOperator_ 新 Operator 地址
    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        _operator = newOperator_;
    }

}
