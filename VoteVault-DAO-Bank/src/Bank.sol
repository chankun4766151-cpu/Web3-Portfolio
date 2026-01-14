// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Bank
 * @dev 简单的银行合约，用于存储和管理资金
 * 
 * 核心功能：
 * 1. 接收和存储 ETH
 * 2. 只有管理员（Governor 合约）可以提取资金
 * 3. 任何人都可以向合约转账
 * 
 * 访问控制：
 * - admin: Governor 合约地址
 * - 只有 admin 可以调用 withdraw()
 */
contract Bank {
    // 管理员地址（将设置为 Governor 合约）
    address public admin;

    /**
     * @dev 事件：资金存入
     * @param from 存款人地址
     * @param amount 存款金额
     */
    event Deposit(address indexed from, uint256 amount);

    /**
     * @dev 事件：资金提取
     * @param to 接收地址
     * @param amount 提取金额
     */
    event Withdrawal(address indexed to, uint256 amount);

    /**
     * @dev 修饰器：只允许管理员调用
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Bank: only admin can call");
        _;
    }

    /**
     * @dev 构造函数
     * @param _admin 管理员地址（Governor 合约地址）
     */
    constructor(address _admin) {
        require(_admin != address(0), "Bank: admin cannot be zero address");
        admin = _admin;
    }

    /**
     * @dev 接收 ETH 的函数
     * @notice 任何人都可以向合约转账 ETH
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev 提取资金
     * @param to 接收地址
     * @param amount 提取金额
     * @notice 只有管理员（Governor 合约）可以调用
     * 
     * 使用场景：
     * - Governor 合约通过提案投票后，会调用此函数提取资金
     * - 实现了 DAO 对资金使用的民主管理
     */
    function withdraw(address payable to, uint256 amount) external onlyAdmin {
        require(to != address(0), "Bank: cannot withdraw to zero address");
        require(amount > 0, "Bank: amount must be greater than 0");
        require(address(this).balance >= amount, "Bank: insufficient balance");

        // 转账
        (bool success, ) = to.call{value: amount}("");
        require(success, "Bank: transfer failed");

        emit Withdrawal(to, amount);
    }

    /**
     * @dev 查询合约余额
     * @return 合约当前的 ETH 余额
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
