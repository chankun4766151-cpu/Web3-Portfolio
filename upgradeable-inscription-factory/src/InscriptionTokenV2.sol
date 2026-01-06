// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title InscriptionTokenV2
 * @dev 可初始化的 ERC20 铭文代币 - 用于最小代理（Minimal Proxy）
 * 
 * 核心概念：
 * 1. 最小代理（EIP-1167）：
 *    - 部署一个约55字节的极小代理合约
 *    - 代理合约将所有调用转发到这个实现合约
 *    - 节省 90%+ 的部署 gas
 * 
 * 2. 为什么不能使用构造函数？
 *    - 代理合约通过 delegatecall 调用实现合约
 *    - 构造函数只在部署实现合约时执行一次
 *    - 每个代理需要独立的初始化，使用 initialize()
 * 
 * 3. 与 V1 的区别：
 *    - V1: 每次 new 一个完整的合约（约 1M gas）
 *    - V2: 克隆一个最小代理（约 40K gas）
 */
contract InscriptionTokenV2 is Initializable, ERC20Upgradeable {
    // ==================== 状态变量 ====================
    
    /// @dev 代币总供应量上限
    uint256 public totalSupply_;
    
    /// @dev 每次铸造的固定数量
    uint256 public perMint;
    
    /// @dev 已铸造的总量
    uint256 public mintedAmount;
    
    // ==================== 事件 ====================
    
    /// @dev 铸造事件
    event Minted(address indexed to, uint256 amount);
    
    // ==================== 初始化 ====================
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 禁用实现合约的初始化
        // 这防止有人直接使用实现合约
        _disableInitializers();
    }
    
    /**
     * @dev 初始化函数（替代构造函数）
     * @param symbol_ 代币符号
     * @param totalSupply__ 总供应量
     * @param perMint_ 每次铸造数量
     * 
     * 原理：
     * - 每个代理克隆后都会调用这个函数进行初始化
     * - initializer 修饰符确保只能调用一次
     * - 参数与 V1 构造函数相同，但使用状态变量存储（非 immutable）
     * 
     * 注意：
     * - V2 不能使用 immutable（代理无法共享 immutable）
     * - 使用普通状态变量会增加 gas，但代理部署节省的 gas 远大于此
     */
    function initialize(
        string memory symbol_,
        uint256 totalSupply__,
        uint256 perMint_
    ) public initializer {
        require(totalSupply__ > 0, "Total supply must be greater than 0");
        require(perMint_ > 0, "Per mint must be greater than 0");
        require(perMint_ <= totalSupply__, "Per mint exceeds total supply");
        
        // 初始化 ERC20
        __ERC20_init(string(abi.encodePacked("Inscription ", symbol_)), symbol_);
        
        // 设置铭文参数
        totalSupply_ = totalSupply__;
        perMint = perMint_;
        mintedAmount = 0;
    }
    
    // ==================== 公共函数 ====================
    
    /**
     * @dev 铸造代币给调用者
     */
    function mint() external {
        require(mintedAmount + perMint <= totalSupply_, "Exceeds total supply");
        
        mintedAmount += perMint;
        _mint(msg.sender, perMint);
        
        emit Minted(msg.sender, perMint);
    }
    
    /**
     * @dev 铸造代币到指定地址
     * @param to 接收地址
     */
    function mintTo(address to) external {
        require(to != address(0), "Cannot mint to zero address");
        require(mintedAmount + perMint <= totalSupply_, "Exceeds total supply");
        
        mintedAmount += perMint;
        _mint(to, perMint);
        
        emit Minted(to, perMint);
    }
}
