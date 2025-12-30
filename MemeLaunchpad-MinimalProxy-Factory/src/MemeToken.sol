// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MemeToken
 * @notice ERC20 代币实现合约，用于通过最小代理模式创建 Meme 代币
 * @dev 使用 initialize 函数而非构造函数，因为代理合约需要在创建后初始化
 */
contract MemeToken is ERC20 {
    /// @notice 工厂合约地址，拥有铸造权限
    address public factory;
    
    /// @notice Meme 发行者地址，接收铸造费用
    address public memeCreator;
    
    /// @notice 最大供应量（总发行量）
    uint256 public maxSupply;
    
    /// @notice 每次铸造的代币数量
    uint256 public perMint;
    
    /// @notice 每次铸造需要支付的费用（wei 计价）
    uint256 public price;
    
    /// @notice 代币符号（存储在代理合约中）
    string private _symbol;
    
    /// @notice 标记合约是否已初始化
    bool private initialized;
    
    /**
     * @notice 构造函数 - 仅在部署实现合约时调用一次
     * @dev 传入空字符串，实际代币信息在 initialize 时设置
     */
    constructor() ERC20("", "") {}
    
    /**
     * @notice 初始化函数 - 每个代理合约创建后调用
     * @dev 只能调用一次，设置代币的所有参数
     * @param symbol_ 代币符号
     * @param _totalSupply 总供应量
     * @param _perMint 每次铸造数量
     * @param _price 每次铸造价格
     * @param _creator Meme 发行者地址
     */
    function initialize(
        string memory symbol_,
        uint256 _totalSupply,
        uint256 _perMint,
        uint256 _price,
        address _creator
    ) external {
        require(!initialized, "Already initialized");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_perMint > 0 && _perMint <= _totalSupply, "Invalid perMint amount");
        require(_creator != address(0), "Invalid creator address");
        
        initialized = true;
        _symbol = symbol_;
        factory = msg.sender; // 调用者是工厂合约
        memeCreator = _creator;
        maxSupply = _totalSupply;
        perMint = _perMint;
        price = _price;
    }
    
    /**
     * @notice 铸造函数 - 只能由工厂合约调用
     * @dev 每次铸造固定数量（perMint），不能超过最大供应量
     * @param to 接收代币的地址
     */
    function mint(address to) external {
        require(msg.sender == factory, "Only factory can mint");
        require(totalSupply() + perMint <= maxSupply, "Exceeds max supply");
        
        _mint(to, perMint);
    }
    
    /**
     * @notice 获取代币符号
     * @dev 重写 ERC20 的 symbol 函数，返回存储的符号
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    /**
     * @notice 获取代币名称
     * @dev 重写 ERC20 的 name 函数，返回固定名称 + 符号
     */
    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked("Meme ", _symbol));
    }
}
