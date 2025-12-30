// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPermit2
 * @notice Permit2 接口，用于基于签名的代币授权和转账
 * @dev 这是 Uniswap Permit2 合约的简化接口
 * 完整合约: https://github.com/Uniswap/permit2
 * 
 * 作用说明：
 * Permit2 是一个通用授权合约，用户只需一次性授权 Permit2，
 * 之后就可以通过签名的方式让任何 DApp 使用自己的代币，
 * 无需为每个 DApp 单独进行 approve 操作
 */
interface IPermit2 {
    /// @notice 代币和金额详情（用于签名授权）
    /// @dev 用户签名时需要指定允许使用哪个代币和多少数量
    struct TokenPermissions {
        // ERC20 代币地址
        address token;
        // 可以使用的最大金额
        uint256 amount;
    }

    /// @notice 单个代币转账的完整签名授权数据
    /// @dev 这是用户签名的完整数据结构
    struct PermitTransferFrom {
        TokenPermissions permitted;  // 允许的代币和金额
        // 防重放攻击的唯一值（每个用户的每次签名都不同）
        uint256 nonce;
        // 签名的截止时间（过期后签名无效）
        uint256 deadline;
    }

    /// @notice 指定接收方地址和金额的详情
    /// @dev 实际执行转账时使用，由调用者（如 TokenBank）指定
    struct SignatureTransferDetails {
        // 接收方地址（代币转到哪里）
        address to;
        // 请求的转账金额（不能超过签名授权的金额）
        uint256 requestedAmount;
    }

    /// @notice 批量代币转账的签名授权数据
    /// @dev 可以在一次签名中授权多个代币的转账
    struct PermitBatchTransferFrom {
        // 允许的代币列表及对应金额
        TokenPermissions[] permitted;
        // 防重放攻击的唯一值
        uint256 nonce;
        // 签名的截止时间
        uint256 deadline;
    }

    /// @notice 用于防止签名重放攻击的位图
    /// @dev 从代币所有者地址和索引映射到位图
    /// @param owner 代币所有者地址
    /// @param wordPosition 位图中的位置索引
    /// @return 返回 uint256 位图
    function nonceBitmap(address owner, uint256 wordPosition) external view returns (uint256);

    /// @notice 使用签名授权转账代币（单个代币）
    /// @dev 这是核心函数，验证签名并执行转账
    /// @param permit 用户签名的授权数据
    /// @param transferDetails 转账详情（接收方和金额）
    /// @param owner 代币所有者（签名者）
    /// @param signature EIP-712 签名
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice 使用签名授权转账多个代币
    /// @param permit 批量授权数据
    /// @param transferDetails 批量转账详情
    /// @param owner 代币所有者
    /// @param signature 签名
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice 返回当前链的域分隔符（用于 EIP-712 签名）
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
