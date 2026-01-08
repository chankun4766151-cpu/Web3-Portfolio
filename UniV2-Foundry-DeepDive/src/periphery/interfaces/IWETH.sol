// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IWETH 接口
 * @notice Wrapped ETH 接口
 * @dev WETH 是 ERC20 包装的 ETH，用于 ETH 与 ERC20 代币的统一处理
 * 
 * 为什么需要 WETH？
 * 1. ETH 不是 ERC20 代币，不兼容 ERC20 接口
 * 2. Uniswap 的交易对只支持 ERC20
 * 3. WETH 将 ETH 1:1 包装为 ERC20，实现统一处理
 */
interface IWETH {
    /// @notice 存入 ETH，获得等量 WETH
    function deposit() external payable;
    
    /// @notice 取出 WETH，换回等量 ETH
    /// @param amount 取出数量
    function withdraw(uint256 amount) external;
    
    /// @notice 转账 WETH
    function transfer(address to, uint256 value) external returns (bool);
}
