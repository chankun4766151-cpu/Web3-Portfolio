// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./InscriptionTokenV2.sol";

/**
 * @title InscriptionFactoryV2
 * @dev 可升级的铭文工厂合约 - V2版本
 * 
 * V2 核心变化：
 * 1. 使用最小代理（Clones/EIP-1167）部署代币
 *    - 使用 Clones.clone() 创建代理
 *    - 每个代币只需约 40K gas（vs V1 的 1M+ gas）
 * 
 * 2. 添加价格机制
 *    - deployInscription 新增 price 参数
 *    - mintInscription 变为 payable，需要支付费用
 *    - 收集的费用可由 owner 提取
 * 
 * 3. 存储布局兼容性
 *    - 保持 V1 的 deployedTokens 映射（slot 不变）
 *    - 新增 tokenPrices, collectedFees, tokenImplementation
 * 
 * 原理：
 * - 代理合约升级后，存储数据保持不变
 * - 新增的状态变量追加到存储末尾
 * - 不能删除或重新排列 V1 的状态变量
 */
contract InscriptionFactoryV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ==================== V1 状态变量（不能修改）====================
    
    /// @dev 记录每个 symbol 对应的 token 地址（V1 继承）
    mapping(string => address) public deployedTokens;
    
    // ==================== V2 新增状态变量 ====================
    
    /// @dev 记录每个代币的价格（每个 token 的价格）
    mapping(address => uint256) public tokenPrices;
    
    /// @dev 累计收取的费用
    uint256 public collectedFees;
    
    /// @dev Token 实现合约地址（用于克隆）
    address public tokenImplementation;
    
    // ==================== 事件 ====================
    
    /// @dev 部署代币事件（V2 版本，包含 price）
    event TokenDeployed(
        string indexed symbol,
        address indexed tokenAddress,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    );
    
    /// @dev 铸造代币事件
    event TokenMinted(
        address indexed tokenAddress,
        address indexed minter,
        uint256 amount,
        uint256 feePaid
    );
    
    /// @dev 提取费用事件
    event FeesWithdrawn(address indexed owner, uint256 amount);
    
    // ==================== 初始化 V2 ====================
    
    /**
     * @dev V2 初始化函数
     * 
     * 原理：
     * - 升级时会调用这个函数
     * - reinitializer(2) 表示这是第二次初始化
     * - 不能使用 initializer（已经在 V1 使用过）
     */
    function initializeV2(address tokenImplementation_) public reinitializer(2) {
        require(tokenImplementation_ != address(0), "Invalid implementation address");
        tokenImplementation = tokenImplementation_;
        collectedFees = 0;
    }
    
    // ==================== 核心函数 ====================
    
    /**
     * @dev 部署铭文代币（V2版本，使用最小代理）
     * @param symbol 代币符号
     * @param totalSupply 总供应量
     * @param perMint 每次铸造数量
     * @param price 每个 token 的价格（wei）
     * @return tokenAddress 部署的代币地址
     * 
     * 原理：
     * - 使用 Clones.clone() 创建最小代理
     * - 代理合约大小约 55 字节
     * - 调用代理的 initialize() 进行初始化
     * - gas 成本约 40K（vs V1 的 1M+）
     * 
     * 最小代理工作原理：
     * - 代理合约字节码包含实现合约地址
     * - 所有调用通过 delegatecall 转发到实现合约
     * - 状态存储在代理合约中，逻辑在实现合约中
     */
    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address tokenAddress) {
        require(deployedTokens[symbol] == address(0), "Symbol already exists");
        require(tokenImplementation != address(0), "Implementation not set");
        
        // 使用 Clones 创建最小代理
        tokenAddress = Clones.clone(tokenImplementation);
        
        // 初始化代理
        InscriptionTokenV2(tokenAddress).initialize(symbol, totalSupply, perMint);
        
        // 记录部署信息
        deployedTokens[symbol] = tokenAddress;
        tokenPrices[tokenAddress] = price;
        
        emit TokenDeployed(symbol, tokenAddress, totalSupply, perMint, price);
    }
    
    /**
     * @dev 铸造代币（V2版本，需要支付费用）
     * @param tokenAddr 代币地址
     * 
     * 原理：
     * - payable 函数可以接收 ETH
     * - 检查 msg.value >= perMint * price
     * - 收取的 ETH 存储在合约中
     * - 多付的 ETH 会退还给用户
     */
    function mintInscription(address tokenAddr) external payable {
        require(tokenAddr != address(0), "Invalid token address");
        
        InscriptionTokenV2 token = InscriptionTokenV2(tokenAddr);
        uint256 perMint = token.perMint();
        uint256 price = tokenPrices[tokenAddr];
        
        // 计算需要支付的费用
        uint256 requiredFee = perMint * price;
        require(msg.value >= requiredFee, "Insufficient payment");
        
        // 铸造代币给调用者
        token.mintTo(msg.sender);
        
        // 记录收取的费用
        collectedFees += requiredFee;
        
        // 退还多余的 ETH
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }
        
        emit TokenMinted(tokenAddr, msg.sender, perMint, requiredFee);
    }
    
    /**
     * @dev 提取收取的费用（仅 owner）
     * 
     * 安全措施：
     * - 使用 Checks-Effects-Interactions 模式
     * - 先更新状态再转账（防止重入攻击）
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = collectedFees;
        require(amount > 0, "No fees to withdraw");
        
        // 先更新状态
        collectedFees = 0;
        
        // 再转账
        payable(owner()).transfer(amount);
        
        emit FeesWithdrawn(owner(), amount);
    }
    
    // ==================== 升级函数 ====================
    
    /**
     * @dev 授权升级（UUPS 必需）
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // ==================== 视图函数 ====================
    
    /**
     * @dev 获取代币地址
     */
    function getTokenAddress(string memory symbol) external view returns (address) {
        return deployedTokens[symbol];
    }
    
    /**
     * @dev 获取代币价格
     */
    function getTokenPrice(address tokenAddr) external view returns (uint256) {
        return tokenPrices[tokenAddr];
    }
}
