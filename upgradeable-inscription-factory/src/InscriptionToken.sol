// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title InscriptionToken
 * @dev ERC20 铭文代币 - V1版本
 * 
 * 核心概念：
 * - 铭文机制：模拟比特币 Ordinals 的公平发行机制
 * - totalSupply_: 代币总供应量上限
 * - perMint: 每次铸造的固定数量
 * - 任何人都可以调用 mint()，但每次只能铸造 perMint 数量
 */
contract InscriptionToken is ERC20 {
    // ==================== 状态变量 ====================
    
    /// @dev 代币总供应量上限
    uint256 public immutable totalSupply_;
    
    /// @dev 每次铸造的固定数量
    uint256 public immutable perMint;
    
    /// @dev 已铸造的总量
    uint256 public mintedAmount;
    
    // ==================== 事件 ====================
    
    /// @dev 铸造事件
    event Minted(address indexed to, uint256 amount);
    
    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数
     * @param symbol_ 代币符号（例如："INSC"）
     * @param totalSupply__ 总供应量（例如：21000000）
     * @param perMint_ 每次铸造数量（例如：1000）
     * 
     * 原理：
     * - 使用 immutable 变量节省 gas（编译时存储在字节码中）
     * - 设定代币名称为 "Inscription {symbol}"
     */
    constructor(
        string memory symbol_,
        uint256 totalSupply__,
        uint256 perMint_
    ) ERC20(string(abi.encodePacked("Inscription ", symbol_)), symbol_) {
        require(totalSupply__ > 0, "Total supply must be greater than 0");
        require(perMint_ > 0, "Per mint must be greater than 0");
        require(perMint_ <= totalSupply__, "Per mint exceeds total supply");
        
        totalSupply_ = totalSupply__;
        perMint = perMint_;
    }
    
    // ==================== 公共函数 ====================
    
    /**
     * @dev 铸造代币（公平发行机制）
     * 
     * 原理：
     * - 任何人都可以调用（无权限限制）
     * - 每次只能铸造固定的 perMint 数量
     * - 不能超过 totalSupply_ 上限
     * - 铸造的代币发送给调用者
     * 
     * 这实现了"公平发行"的理念：
     * - 先到先得（first-come, first-served）
     * - 每人每次数量相同（防止巨鲸垄断）
     * - 总量有上限（稀缺性）
     */
    function mint() external {
        // 检查是否还有可铸造的额度
        require(mintedAmount + perMint <= totalSupply_, "Exceeds total supply");
        
        // 更新已铸造数量
        mintedAmount += perMint;
        
        // 铸造代币给调用者
        _mint(msg.sender, perMint);
        
        emit Minted(msg.sender, perMint);
    }
    
    /**
     * @dev 铸造代币到指定地址（用于工厂调用）
     * @param to 接收地址
     * 
     * 原理：
     * - 允许外部合约（如工厂）指定接收者
     * - 保持相同的铸造限制
     */
    function mintTo(address to) external {
        require(to != address(0), "Cannot mint to zero address");
        require(mintedAmount + perMint <= totalSupply_, "Exceeds total supply");
        
        mintedAmount += perMint;
        _mint(to, perMint);
        
        emit Minted(to, perMint);
    }
}
