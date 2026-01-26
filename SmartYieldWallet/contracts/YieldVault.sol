// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IYieldProtocol
 * @dev 通用收益协议接口，支持不同的借贷平台
 */
interface IYieldProtocol {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getAPY() external view returns (uint256);
    function getBalance(address user) external view returns (uint256);
    function name() external view returns (string memory);
}

/**
 * @title YieldVault
 * @dev 智能收益聚合器 - 自动将用户资产路由到最优收益协议
 * 
 * 核心功能:
 * 1. 用户存入资产自动赚取利息
 * 2. 内置优化路由，自动选择最佳借贷平台
 * 3. 支持多种收益策略 (Aave, Compound, Lido 等)
 */
contract YieldVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============
    IERC20 public immutable depositToken;
    
    // 协议列表
    address[] public protocols;
    mapping(address => bool) public isProtocol;
    
    // 用户余额
    mapping(address => uint256) public userDeposits;
    uint256 public totalDeposits;
    
    // 当前最优协议
    address public currentOptimalProtocol;
    
    // 协议分配比例 (basis points, 10000 = 100%)
    mapping(address => uint256) public protocolAllocations;
    
    // ============ 事件 ============
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ProtocolAdded(address indexed protocol, string name);
    event ProtocolRemoved(address indexed protocol);
    event Rebalanced(address indexed newOptimalProtocol, uint256 apy);
    event AllocationUpdated(address indexed protocol, uint256 allocation);

    // ============ 构造函数 ============
    constructor(address _depositToken) Ownable(msg.sender) {
        depositToken = IERC20(_depositToken);
    }

    // ============ 用户函数 ============

    /**
     * @notice 存入资产
     * @param amount 存入金额
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // 转入代币
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // 更新用户余额
        userDeposits[msg.sender] += amount;
        totalDeposits += amount;
        
        // 如果有最优协议，自动存入
        if (currentOptimalProtocol != address(0)) {
            depositToken.approve(currentOptimalProtocol, amount);
            IYieldProtocol(currentOptimalProtocol).deposit(amount);
        }
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice 提取资产
     * @param amount 提取金额
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(userDeposits[msg.sender] >= amount, "Insufficient balance");
        
        // 更新用户余额
        userDeposits[msg.sender] -= amount;
        totalDeposits -= amount;
        
        // 如果有协议，从协议提取
        if (currentOptimalProtocol != address(0)) {
            IYieldProtocol(currentOptimalProtocol).withdraw(amount);
        }
        
        // 转回给用户
        depositToken.safeTransfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice 获取用户余额（含利息）
     * @param user 用户地址
     * @return 用户总余额
     */
    function getUserBalance(address user) external view returns (uint256) {
        if (totalDeposits == 0) return userDeposits[user];
        
        uint256 totalVaultBalance = getTotalVaultBalance();
        return (userDeposits[user] * totalVaultBalance) / totalDeposits;
    }

    // ============ 协议管理函数 ============

    /**
     * @notice 添加新的收益协议
     * @param protocol 协议地址
     */
    function addProtocol(address protocol) external onlyOwner {
        require(protocol != address(0), "Invalid protocol address");
        require(!isProtocol[protocol], "Protocol already added");
        
        protocols.push(protocol);
        isProtocol[protocol] = true;
        
        emit ProtocolAdded(protocol, IYieldProtocol(protocol).name());
    }

    /**
     * @notice 移除收益协议
     * @param protocol 协议地址
     */
    function removeProtocol(address protocol) external onlyOwner {
        require(isProtocol[protocol], "Protocol not found");
        
        // 从数组中移除
        for (uint256 i = 0; i < protocols.length; i++) {
            if (protocols[i] == protocol) {
                protocols[i] = protocols[protocols.length - 1];
                protocols.pop();
                break;
            }
        }
        
        isProtocol[protocol] = false;
        protocolAllocations[protocol] = 0;
        
        if (currentOptimalProtocol == protocol) {
            currentOptimalProtocol = address(0);
        }
        
        emit ProtocolRemoved(protocol);
    }

    /**
     * @notice 重新平衡资产到最优协议
     */
    function rebalance() external onlyOwner {
        address optimalProtocol = getOptimalProtocol();
        
        if (optimalProtocol != currentOptimalProtocol && optimalProtocol != address(0)) {
            // 从旧协议提取
            if (currentOptimalProtocol != address(0)) {
                uint256 balance = IYieldProtocol(currentOptimalProtocol).getBalance(address(this));
                if (balance > 0) {
                    IYieldProtocol(currentOptimalProtocol).withdraw(balance);
                }
            }
            
            // 存入新协议
            uint256 vaultBalance = depositToken.balanceOf(address(this));
            if (vaultBalance > 0) {
                depositToken.approve(optimalProtocol, vaultBalance);
                IYieldProtocol(optimalProtocol).deposit(vaultBalance);
            }
            
            currentOptimalProtocol = optimalProtocol;
            
            emit Rebalanced(optimalProtocol, IYieldProtocol(optimalProtocol).getAPY());
        }
    }

    // ============ 视图函数 ============

    /**
     * @notice 获取最优收益协议
     * @return 最优协议地址
     */
    function getOptimalProtocol() public view returns (address) {
        if (protocols.length == 0) return address(0);
        
        address optimal = protocols[0];
        uint256 highestAPY = IYieldProtocol(protocols[0]).getAPY();
        
        for (uint256 i = 1; i < protocols.length; i++) {
            uint256 apy = IYieldProtocol(protocols[i]).getAPY();
            if (apy > highestAPY) {
                highestAPY = apy;
                optimal = protocols[i];
            }
        }
        
        return optimal;
    }

    /**
     * @notice 获取所有协议的APY
     * @return 协议地址数组和对应APY数组
     */
    function getAllProtocolAPYs() external view returns (address[] memory, uint256[] memory) {
        uint256[] memory apys = new uint256[](protocols.length);
        
        for (uint256 i = 0; i < protocols.length; i++) {
            apys[i] = IYieldProtocol(protocols[i]).getAPY();
        }
        
        return (protocols, apys);
    }

    /**
     * @notice 获取Vault总余额
     * @return 总余额
     */
    function getTotalVaultBalance() public view returns (uint256) {
        uint256 balance = depositToken.balanceOf(address(this));
        
        if (currentOptimalProtocol != address(0)) {
            balance += IYieldProtocol(currentOptimalProtocol).getBalance(address(this));
        }
        
        return balance;
    }

    /**
     * @notice 获取当前APY
     * @return 当前收益率
     */
    function getCurrentAPY() external view returns (uint256) {
        if (currentOptimalProtocol == address(0)) return 0;
        return IYieldProtocol(currentOptimalProtocol).getAPY();
    }

    /**
     * @notice 获取协议数量
     * @return 协议数量
     */
    function getProtocolCount() external view returns (uint256) {
        return protocols.length;
    }
}
