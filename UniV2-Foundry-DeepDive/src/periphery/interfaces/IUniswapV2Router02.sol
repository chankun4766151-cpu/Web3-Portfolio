// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IUniswapV2Router01.sol";

/**
 * @title IUniswapV2Router02 接口
 * @notice Uniswap V2 Router 第二版接口
 * @dev 继承 Router01，添加了对"转账收费"代币的支持
 * 
 * 什么是"转账收费"代币？
 * 某些代币在转账时会自动扣除一定比例作为税费（如 SafeMoon）
 * 这类代币接收方收到的数量小于发送的数量
 * 
 * Router02 的 *SupportingFeeOnTransferTokens 函数专门处理这种情况
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
    /**
     * @notice 移除流动性（ETH），支持转账收费代币
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountETH);

    /**
     * @notice 精确输入交换，支持转账收费代币
     * @dev 不返回 amounts，因为实际接收数量可能与计算值不同
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
