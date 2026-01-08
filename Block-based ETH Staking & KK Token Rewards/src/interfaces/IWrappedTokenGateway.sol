// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IWrappedTokenGateway - Aave V3 ETH 网关接口
 * @notice 用于将原生 ETH 存入/取出 Aave 协议
 * @dev Aave 只接受 ERC20 代币，所以需要通过 Gateway 处理 ETH
 * 
 * 工作原理：
 * 1. 用户发送 ETH 到 Gateway
 * 2. Gateway 将 ETH 包装成 WETH
 * 3. Gateway 将 WETH 存入 Aave Pool
 * 4. 用户收到 aWETH（生息代币）
 * 
 * Sepolia 地址: 0x387d311e47e80b498169e6fb51d3193167d89F7D
 * Mainnet 地址: 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C
 */
interface IWrappedTokenGateway {
    /**
     * @dev 将 ETH 存入 Aave 协议
     * @param pool Aave Pool 地址
     * @param onBehalfOf 接收 aWETH 的地址
     * @param referralCode 推荐码（目前无效，可设为 0）
     * 
     * 使用方式：
     * gateway.depositETH{value: amount}(poolAddress, address(this), 0);
     */
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /**
     * @dev 从 Aave 协议取出 ETH
     * @param pool Aave Pool 地址
     * @param amount 取出的 ETH 数量
     * @param to 接收 ETH 的地址
     * 
     * 注意：调用前需要先 approve aWETH 给 Gateway
     */
    function withdrawETH(
        address pool,
        uint256 amount,
        address to
    ) external;
}

/**
 * @title IERC20 - 简化的 ERC20 接口
 * @dev 用于与 aWETH 代币交互
 */
interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
