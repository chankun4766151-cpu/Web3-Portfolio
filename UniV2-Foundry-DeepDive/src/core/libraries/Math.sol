// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Math 库
 * @notice 提供基础数学运算
 * @dev 主要用于计算平方根，这在计算首次添加流动性时的 LP Token 数量时非常重要
 */
library Math {
    /**
     * @notice 返回两个数中的较小值
     * @param x 第一个数
     * @param y 第二个数
     * @return z 较小的那个数
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /**
     * @notice 计算平方根（向下取整）
     * @dev 使用巴比伦方法（牛顿迭代法的一种）
     * 
     * 算法原理：
     * 1. 从一个初始猜测值开始
     * 2. 不断迭代：z = (z + y/z) / 2
     * 3. 直到结果收敛
     * 
     * 为什么需要平方根？
     * - 首次添加流动性时：liquidity = sqrt(amount0 * amount1)
     * - 这确保了 LP Token 与两种代币的几何平均值成正比
     * 
     * @param y 要计算平方根的数
     * @return z 平方根结果
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // 如果 y == 0, z 保持为 0
    }
}
