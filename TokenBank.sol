// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定义最简版 ERC20 接口，用于与外部 Token 合约交互
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenBank {
    IERC20 public token; // 要存入的 ERC20 代币合约
    mapping(address => uint256) public balances; // 记录每个用户的存款数量

    constructor(address _token) {
        token = IERC20(_token); // 绑定指定 token
    }

    // 存入 token
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");

        // 从用户地址把 token 转入银行合约
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // 更新用户余额
        balances[msg.sender] += amount;
    }

    // 提取 token
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 更新余额
        balances[msg.sender] -= amount;

        // 从银行合约转回给用户
        bool success = token.transfer(msg.sender, amount);
        require(success, "Withdraw transfer failed");
    }
}
