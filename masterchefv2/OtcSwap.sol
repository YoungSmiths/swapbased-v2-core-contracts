/**
 *Submitted for verification at Arbiscan on 2023-05-15
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: buybackengine.sol


pragma solidity ^0.8.0;

/**
 * @title OtcSwap
 * @notice 链上 OTC：用户用 **xBASE** 按固定比例换取本合约储备的 **BASE**；用户支付的 xBASE 全部转给 **Owner**（典型用途为回购进国库或多签）。
 * @dev
 * - 用户调用 `otcSwap` 前须对本合约 `approve` 足够 **xBASE**；合约内须有足额 **BASE**（由 Owner `supplyBASE` 注入）。
 * - `swapRate` 为**百分数**（如 35 表示 35%）：用户支付 `amount` 枚 xBASE 时，获得 `amount * swapRate / 100` 枚 BASE（源码中 `baseAmount`）。
 * - `otcSwap` 使用 `nonReentrant`，避免与 ERC20 钩子组合时的重入风险。
 * - `totalXBASE` 仅累计经 `otcSwap` 进入 Owner 路径的 xBASE 数量，便于链下统计与对账。
 */
contract OtcSwap is Ownable, ReentrancyGuard {
    /// @notice 用户支付的 ERC20，通常为包装/质押衍生代币 **xBASE**。
    IERC20 public xBASE;
    /// @notice 本合约储备并兑付给用户的 ERC20，通常为 **BASE**。
    IERC20 public BASE;
    /// @notice 兑换比例（百分数）：BASE 输出量 = `amount * swapRate / 100`；默认 35；可由 Owner 在 [25, 50] 内调整。
    uint256 public swapRate = 35; // 35%
    /// @notice 累计已通过 `otcSwap` 从用户侧收取并转给 Owner 的 xBASE 数量（统计字段）。
    uint256 public totalXBASE = 0;

    /**
     * @notice 部署时固定两种代币地址，不可在链上更改（需重新部署方可换币对）。
     * @param _xBASE 用户支付的代币合约地址（xBASE）。
     * @param _BASE 本合约持有并支付给用户的代币合约地址（BASE）。
     */
    constructor(IERC20 _xBASE, IERC20 _BASE) {
        xBASE = _xBASE;
        BASE = _BASE;
    }

    /**
     * @notice 用户使用 xBASE 按当前 `swapRate` 兑换 BASE。
     * @param amount 用户支付的 xBASE 数量（代币最小单位，通常为 wei 精度）。
     * @dev 核心逻辑：① `transferFrom` 将 `amount` 从用户转至 **owner()**；② `baseAmount = amount * swapRate / 100`；③ 检查本合约 BASE 余额 ≥ `baseAmount`；④ 向用户 `transfer` BASE；⑤ `totalXBASE += amount`。
     */
    function otcSwap(uint256 amount) public nonReentrant {
        require(xBASE.transferFrom(msg.sender, owner(), amount), "Transfer of xBASE failed");

        // 按百分比例计算应付 BASE；整数除法向下取整
        uint256 baseAmount = amount * swapRate / 100;
        require(BASE.balanceOf(address(this)) >= baseAmount, "Insufficient BASE in contract");

        require(BASE.transfer(msg.sender, baseAmount), "Transfer of BASE failed");

        totalXBASE += amount;
    }

    /**
     * @notice Owner 从自有余额向本合约注入 BASE，维持兑付流动性。
     * @param amount 从 `msg.sender`（Owner）转入本合约的 BASE 数量。
     */
    function supplyBASE(uint256 amount) public onlyOwner {
        require(BASE.transferFrom(msg.sender, address(this), amount), "Supply of BASE failed");
    }

    /**
     * @notice Owner 从本合约取回 BASE（例如调整库存或紧急撤出）。
     * @param amount 取回数量；不得超过本合约当前 BASE 余额。
     */
    function retrieveBASE(uint256 amount) public onlyOwner {
        require(BASE.balanceOf(address(this)) >= amount, "Insufficient BASE in contract");
        require(BASE.transfer(msg.sender, amount), "Retrieval of BASE failed");
    }

    /**
     * @notice 调整兑换比例（百分数），影响后续每笔 `otcSwap` 的 BASE 输出。
     * @param newRate 新比例，必须在 **25～50**（含边界），否则 revert。
     * @dev 例如设为 40 表示用户每 100 单位 xBASE 换得 40 单位 BASE（在余额充足前提下）。
     */
    function changeSwapRate(uint256 newRate) public onlyOwner {
        require(newRate >= 25 && newRate <= 50, "Swap rate out of range");
        swapRate = newRate;
    }
}