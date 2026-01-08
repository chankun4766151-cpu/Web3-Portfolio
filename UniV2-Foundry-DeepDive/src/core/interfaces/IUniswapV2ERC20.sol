// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUniswapV2ERC20 接口
 * @notice Uniswap V2 LP Token 的 ERC20 接口
 * @dev 继承了标准 ERC20 功能，并添加了 permit 签名授权功能（EIP-2612）
 * 
 * LP Token（Liquidity Provider Token）是流动性提供者的凭证：
 * - 当用户向交易对添加流动性时，会收到 LP Token
 * - LP Token 代表用户在池子中的份额
 * - 可以通过销毁 LP Token 来取回相应份额的资产
 */
interface IUniswapV2ERC20 {
    /// @notice 当代币被转移时触发
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /// @notice 当授权额度改变时触发
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice 返回代币名称 "Uniswap V2"
    function name() external pure returns (string memory);
    
    /// @notice 返回代币符号 "UNI-V2"
    function symbol() external pure returns (string memory);
    
    /// @notice 返回代币精度，固定为 18
    function decimals() external pure returns (uint8);
    
    /// @notice 返回代币总供应量
    function totalSupply() external view returns (uint256);
    
    /// @notice 查询指定地址的余额
    function balanceOf(address owner) external view returns (uint256);
    
    /// @notice 查询授权额度
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice 授权函数
    function approve(address spender, uint256 value) external returns (bool);
    
    /// @notice 转账函数
    function transfer(address to, uint256 value) external returns (bool);
    
    /// @notice 授权转账函数
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @notice 返回 EIP-712 域分隔符
    /// @dev 用于 permit 签名验证，防止跨链/跨合约重放攻击
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    
    /// @notice 返回 PERMIT_TYPEHASH
    /// @dev permit 函数的类型哈希，用于 EIP-712 签名
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    
    /// @notice 返回指定地址的 nonce 值
    /// @dev 用于防止签名重放攻击，每次使用 permit 后递增
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice 通过签名授权（EIP-2612）
     * @dev 允许用户通过链下签名来授权，节省 gas
     * 
     * 使用场景：
     * 1. 用户签名授权（链下，不消耗 gas）
     * 2. 第三方将签名提交到链上执行授权和转账（可以是同一笔交易）
     * 
     * @param owner 代币持有者
     * @param spender 被授权者
     * @param value 授权数量
     * @param deadline 签名过期时间
     * @param v 签名的 v 值
     * @param r 签名的 r 值
     * @param s 签名的 s 值
     */
    function permit(
        address owner, 
        address spender, 
        uint256 value, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;
}
