// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniswapV2ERC20.sol";

/**
 * @title UniswapV2ERC20
 * @notice Uniswap V2 LP Token 的 ERC20 实现
 * @dev 这是所有 UniswapV2Pair 的基类，实现了标准 ERC20 功能和 EIP-2612 permit
 * 
 * 关键特性：
 * 1. 标准 ERC20 功能（transfer, approve, transferFrom）
 * 2. EIP-2612 permit 功能（通过签名授权，节省 gas）
 * 3. 固定名称 "Uniswap V2" 和符号 "UNI-V2"
 * 
 * LP Token 的作用：
 * - 代表用户在流动性池中的份额
 * - 可自由转让、交易
 * - 销毁可取回对应份额的底层资产
 */
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    // ==================== 状态变量 ====================
    
    /// @notice 代币名称
    string public constant name = "Uniswap V2";
    
    /// @notice 代币符号
    string public constant symbol = "UNI-V2";
    
    /// @notice 代币精度（18位小数）
    uint8 public constant decimals = 18;
    
    /// @notice 代币总供应量
    uint256 public totalSupply;
    
    /// @notice 地址 => 余额 映射
    mapping(address => uint256) public balanceOf;
    
    /// @notice 授权额度映射：owner => spender => allowance
    mapping(address => mapping(address => uint256)) public allowance;

    // ==================== EIP-2612 相关 ====================
    
    /**
     * @notice EIP-712 域分隔符
     * @dev 在构造函数中计算，包含链ID防止跨链重放
     */
    bytes32 public DOMAIN_SEPARATOR;
    
    /**
     * @notice permit 函数的类型哈希
     * @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
     */
    bytes32 public constant PERMIT_TYPEHASH = 
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    
    /// @notice 每个地址的 nonce 值，用于防止签名重放
    mapping(address => uint256) public nonces;

    // ==================== 构造函数 ====================
    
    /**
     * @notice 构造函数
     * @dev 计算 EIP-712 域分隔符
     */
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // ==================== 内部函数 ====================
    
    /**
     * @notice 内部铸造函数
     * @dev 增加 to 的余额和总供应量
     * @param to 接收地址
     * @param value 铸造数量
     */
    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice 内部销毁函数
     * @dev 减少 from 的余额和总供应量
     * @param from 销毁来源地址
     * @param value 销毁数量
     */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice 内部授权函数
     * @param owner 代币持有者
     * @param spender 被授权者
     * @param value 授权额度
     */
    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice 内部转账函数
     * @param from 发送地址
     * @param to 接收地址
     * @param value 转账数量
     */
    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    // ==================== 公共函数 ====================
    
    /**
     * @notice 授权 spender 使用调用者的代币
     * @param spender 被授权地址
     * @param value 授权额度
     * @return 总是返回 true
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice 转账给指定地址
     * @param to 接收地址
     * @param value 转账数量
     * @return 总是返回 true
     */
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice 从授权账户转账
     * @dev 如果授权额度不是最大值，会扣减授权额度
     * @param from 发送地址
     * @param to 接收地址
     * @param value 转账数量
     * @return 总是返回 true
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        // 如果授权额度不是无限大，则扣减
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice 通过签名授权（EIP-2612）
     * @dev 允许用户通过链下签名来授权，由第三方提交上链
     * 
     * 优势：
     * 1. 用户可以签名授权而不需要持有 ETH
     * 2. 可以在一笔交易中完成授权 + 转账
     * 3. 支持元交易（meta-transaction）模式
     * 
     * @param owner 代币持有者（签名者）
     * @param spender 被授权者
     * @param value 授权数量
     * @param deadline 签名过期时间戳
     * @param v ECDSA 签名的 v 值
     * @param r ECDSA 签名的 r 值
     * @param s ECDSA 签名的 s 值
     */
    function permit(
        address owner, 
        address spender, 
        uint256 value, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external {
        // 检查签名是否过期
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        
        // 构造签名消息哈希
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        
        // 恢复签名者地址
        address recoveredAddress = ecrecover(digest, v, r, s);
        
        // 验证签名有效性
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UniswapV2: INVALID_SIGNATURE");
        
        // 设置授权
        _approve(owner, spender, value);
    }
}
