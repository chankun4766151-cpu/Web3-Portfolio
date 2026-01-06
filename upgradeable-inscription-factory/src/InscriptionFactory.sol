// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./InscriptionToken.sol";

/**
 * @title InscriptionFactory
 * @dev 可升级的铭文工厂合约 - V1版本
 * 
 * 核心概念：
 * 1. UUPS 代理模式 (Universal Upgradeable Proxy Standard)
 *    - 代理合约：存储状态，保持地址不变
 *    - 实现合约：包含业务逻辑，可以升级
 *    - 升级逻辑在实现合约中，比 Transparent Proxy 更节省 gas
 * 
 * 2. 为什么使用 Initializable 而不是 constructor？
 *    - 代理合约通过 delegatecall 调用实现合约
 *    - constructor 只在部署实现合约时执行一次
 *    - 代理合约的状态需要通过 initialize() 函数初始化
 * 
 * 3. V1 版本特点：
 *    - 使用 `new` 关键字部署 ERC20 代币
 *    - 不收取任何费用
 */
contract InscriptionFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ==================== 状态变量 ====================
    
    /// @dev 记录每个 symbol 对应的 token 地址
    /// @notice 映射: symbol => token address
    mapping(string => address) public deployedTokens;
    
    // ==================== 事件 ====================
    
    /// @dev 部署代币事件
    event TokenDeployed(
        string indexed symbol,
        address indexed tokenAddress,
        uint256 totalSupply,
        uint256 perMint
    );
    
    /// @dev 铸造代币事件
    event TokenMinted(
        address indexed tokenAddress,
        address indexed minter,
        uint256 amount
    );
    
    // ==================== 初始化 ====================
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 禁用实现合约的初始化
        // 这是安全最佳实践：防止有人直接初始化实现合约
        _disableInitializers();
    }
    
    /**
     * @dev 初始化函数（替代构造函数）
     * 
     * 原理：
     * - 代理合约部署后会调用这个函数进行初始化
     * - initializer 修饰符确保只能调用一次
     * - 链式调用父合约的初始化函数
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender);  // 初始化 Ownable，设置 owner
    }
    
    // ==================== 核心函数 ====================
    
    /**
     * @dev 部署铭文代币（V1版本）
     * @param symbol 代币符号
     * @param totalSupply 总供应量
     * @param perMint 每次铸造数量
     * @return tokenAddress 部署的代币地址
     * 
     * 原理：
     * - 使用 `new` 关键字创建新的合约实例
     * - 每个代币都是独立的合约
     * - gas 成本较高（约 1M+ gas）
     */
    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint
    ) external returns (address tokenAddress) {
        // 检查该 symbol 是否已经被使用
        require(deployedTokens[symbol] == address(0), "Symbol already exists");
        
        // 使用 new 创建代币合约
        InscriptionToken token = new InscriptionToken(symbol, totalSupply, perMint);
        tokenAddress = address(token);
        
        // 记录部署的代币
        deployedTokens[symbol] = tokenAddress;
        
        emit TokenDeployed(symbol, tokenAddress, totalSupply, perMint);
    }
    
    /**
     * @dev 铸造代币
     * @param tokenAddr 代币地址
     * 
     * 原理：
     * - 调用代币的 mintTo() 函数
     * - 将代币铸造给调用者（msg.sender）
     * - V1 版本不收取任何费用
     */
    function mintInscription(address tokenAddr) external {
        require(tokenAddr != address(0), "Invalid token address");
        
        InscriptionToken token = InscriptionToken(tokenAddr);
        
        // 铸造代币给调用者
        token.mintTo(msg.sender);
        
        emit TokenMinted(tokenAddr, msg.sender, token.perMint());
    }
    
    // ==================== 升级函数 ====================
    
    /**
     * @dev 授权升级（UUPS 必需）
     * 
     * 原理：
     * - UUPS 模式要求在实现合约中定义升级权限
     * - 只有 owner 可以升级合约
     * - 这个函数在执行升级时会被调用
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // ==================== 视图函数 ====================
    
    /**
     * @dev 获取代币地址
     * @param symbol 代币符号
     * @return 代币地址
     */
    function getTokenAddress(string memory symbol) external view returns (address) {
        return deployedTokens[symbol];
    }
}
