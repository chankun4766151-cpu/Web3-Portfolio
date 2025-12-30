// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MemeToken.sol";

/**
 * @title MemeFactory
 * @notice 工厂合约，使用最小代理模式创建和管理 Meme 代币
 * @dev 使用 EIP-1167 Clones 库来降低部署成本
 */
contract MemeFactory {
    /// @notice MemeToken 实现合约地址
    address public immutable implementation;
    
    /// @notice 平台方地址（接收 1% 费用）
    address public immutable platformOwner;
    
    /// @notice 代币符号到地址的映射
    mapping(string => address) public memeTokens;
    
    /// @notice Meme 代币创建事件
    event MemeTokenCreated(
        address indexed tokenAddress,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price,
        address indexed creator
    );
    
    /// @notice 代币铸造事件
    event MemeTokenMinted(
        address indexed tokenAddress,
        address indexed minter,
        uint256 amount,
        uint256 platformFee,
        uint256 creatorFee
    );
    
    /**
     * @notice 构造函数
     * @dev 部署 MemeToken 实现合约并保存地址
     */
    constructor() {
        implementation = address(new MemeToken());
        platformOwner = msg.sender;
    }
    
    /**
     * @notice 部署新的 Meme 代币
     * @dev 使用 Clones 库创建最小代理合约，大幅降低 Gas 成本
     * @param symbol 代币符号
     * @param totalSupply 总供应量
     * @param perMint 每次铸造数量
     * @param price 每次铸造价格（wei）
     * @return 新创建的代币合约地址
     */
    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address) {
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(memeTokens[symbol] == address(0), "Symbol already exists");
        
        // 使用 Clones 库创建最小代理合约
        address clone = Clones.clone(implementation);
        
        // 初始化代理合约
        MemeToken(clone).initialize(symbol, totalSupply, perMint, price, msg.sender);
        
        // 保存代币地址
        memeTokens[symbol] = clone;
        
        emit MemeTokenCreated(clone, symbol, totalSupply, perMint, price, msg.sender);
        
        return clone;
    }
    
    /**
     * @notice 铸造 Meme 代币
     * @dev 用户支付费用铸造代币，费用按比例分配：1% 给平台，99% 给发行者
     * @param tokenAddr 要铸造的代币合约地址
     */
    function mintMeme(address tokenAddr) external payable {
        require(tokenAddr != address(0), "Invalid token address");
        
        MemeToken token = MemeToken(tokenAddr);
        
        // 验证支付金额
        uint256 requiredPrice = token.price();
        require(msg.value == requiredPrice, "Incorrect payment amount");
        
        // 计算费用分配
        uint256 platformFee = msg.value * 1 / 100;  // 1% 给平台
        uint256 creatorFee = msg.value - platformFee;  // 99% 给发行者
        
        // 分配费用
        (bool platformSuccess, ) = platformOwner.call{value: platformFee}("");
        require(platformSuccess, "Platform fee transfer failed");
        
        (bool creatorSuccess, ) = token.memeCreator().call{value: creatorFee}("");
        require(creatorSuccess, "Creator fee transfer failed");
        
        // 铸造代币给购买者
        token.mint(msg.sender);
        
        emit MemeTokenMinted(tokenAddr, msg.sender, token.perMint(), platformFee, creatorFee);
    }
    
    /**
     * @notice 获取代币合约地址
     * @param symbol 代币符号
     * @return 代币合约地址
     */
    function getTokenAddress(string memory symbol) external view returns (address) {
        return memeTokens[symbol];
    }
}
