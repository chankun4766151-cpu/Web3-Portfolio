// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20 接口
 * @notice 标准 ERC20 代币接口
 * @dev 定义了 ERC20 代币的基本功能
 */
interface IERC20 {
    /// @notice 当代币被转移时触发（包括零值转移）
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /// @notice 当授权额度改变时触发
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice 返回代币名称
    function name() external view returns (string memory);
    
    /// @notice 返回代币符号
    function symbol() external view returns (string memory);
    
    /// @notice 返回代币精度（小数位数）
    function decimals() external view returns (uint8);
    
    /// @notice 返回代币总供应量
    function totalSupply() external view returns (uint256);
    
    /// @notice 查询指定地址的余额
    /// @param owner 要查询的地址
    /// @return 该地址的代币余额
    function balanceOf(address owner) external view returns (uint256);
    
    /// @notice 查询授权额度
    /// @param owner 代币持有者
    /// @param spender 被授权者
    /// @return 剩余的授权额度
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice 授权 spender 最多使用 value 数量的代币
    /// @param spender 被授权的地址
    /// @param value 授权的数量
    /// @return 是否成功
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice 转移代币到指定地址
    /// @param to 接收地址
    /// @param value 转移数量
    /// @return 是否成功
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice 从 from 地址转移代币到 to 地址（需要授权）
    /// @param from 发送地址
    /// @param to 接收地址
    /// @param value 转移数量
    /// @return 是否成功
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
