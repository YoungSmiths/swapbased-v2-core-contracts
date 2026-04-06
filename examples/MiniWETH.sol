// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MiniWETH — 教学用极简 WETH 实现（对照 UniswapV2Router02 里的 IWETH 用法）
 *
 * **和 Router 的对应关系**
 * 1. `addLiquidityETH` 里：`IWETH(WETH).deposit{value: amountETH}()` → 本合约 `deposit()`，
 *    给 **Router 合约地址** 增加 WETH 余额（Router 是 msg.sender）。
 * 2. 接着：`IWETH(WETH).transfer(pair, amountETH)` → 本合约 `transfer`，把 WETH 转给 Pair。
 * 3. `swap` 换出 ETH 时：`WETH.withdraw(amount)` → 把 WETH 销毁并给 `msg.sender` 转原生币。
 *
 * **主网 WETH9** 逻辑与此同类，但多了 `fallback` 收 ETH、事件等；本文件只保留理解 Router 所需的最小集合。
 * **生产环境请使用链上官方 WETH 地址**，不要直接部署本文件当真币。
 */
contract MiniWETH {
    string public constant name = "Wrapped Ether (Demo)";
    string public constant symbol = "WETH";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    /// 原生 ETH 打进 WETH 合约，1:1 铸出 WETH 余额给调用者
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /// 销毁调用者的 WETH，并退回等量原生 ETH
    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "MiniWETH: balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Withdrawal(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "MiniWETH: ETH send");
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "MiniWETH: allowance");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(balanceOf[from] >= amount, "MiniWETH: balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /// 直接向合约转 ETH 时等价于 deposit()（与 WETH9 行为一致，便于理解）
    receive() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }
}
