// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUniswapV2Callee 接口
 * @notice 闪电贷回调接口
 * @dev 如果要使用 Uniswap V2 的闪电贷功能，接收合约需要实现此接口
 * 
 * 闪电贷（Flash Loan / Flash Swap）工作原理：
 * 1. 用户调用 pair.swap()，指定要借出的代币数量和回调数据
 * 2. Pair 合约先将代币转给用户
 * 3. Pair 合约调用用户合约的 uniswapV2Call 函数
 * 4. 用户在回调中使用借来的代币（如套利）
 * 5. 用户在回调结束前归还本金 + 0.3% 手续费
 * 6. Pair 合约检查还款是否足够
 * 
 * 使用场景：
 * - 套利交易
 * - 清算
 * - 自我清算（避免被清算）
 * - 一键杠杆
 */
interface IUniswapV2Callee {
    /**
     * @notice 闪电贷回调函数
     * @param sender 发起 swap 调用的地址
     * @param amount0 借出的 token0 数量
     * @param amount1 借出的 token1 数量
     * @param data 调用者传入的额外数据
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
