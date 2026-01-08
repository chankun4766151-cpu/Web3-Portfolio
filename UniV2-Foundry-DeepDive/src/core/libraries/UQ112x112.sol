// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UQ112x112 库
 * @notice 用于处理 UQ112.112 格式的定点数
 * @dev UQ112.112 是一种定点数格式：
 *      - 112 位整数部分
 *      - 112 位小数部分
 *      - 总共 224 位，可以放入 uint224
 * 
 * 为什么使用定点数？
 * 1. Solidity 不支持浮点数
 * 2. 需要精确表示价格（可能非常大或非常小）
 * 3. 价格累积需要高精度防止溢出
 * 
 * 使用场景：
 * - 累积价格（price0CumulativeLast, price1CumulativeLast）
 * - TWAP 预言机计算
 * 
 * 示例：
 * - 表示 2.5：2.5 * 2^112 = 2.5 * Q112
 * - 表示 0.01：0.01 * 2^112 = 0.01 * Q112
 */
library UQ112x112 {
    /// @notice 2^112，用于定点数转换
    uint224 constant Q112 = 2**112;

    /**
     * @notice 将 uint112 编码为 UQ112x112 格式
     * @dev 将整数左移 112 位，使其成为定点数
     * @param y 要编码的整数
     * @return z UQ112x112 格式的定点数
     * 
     * 示例：
     * encode(5) = 5 * 2^112 = 5.0 (用 UQ112.112 表示)
     */
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    /**
     * @notice UQ112x112 除法
     * @dev 计算 x / y，结果为 UQ112x112 格式
     * @param x 被除数（UQ112x112 格式）
     * @param y 除数（普通 uint112）
     * @return z 商（UQ112x112 格式）
     * 
     * 示例：
     * uqdiv(encode(10), 4) = 10/4 = 2.5 (用 UQ112.112 表示)
     * 
     * 这在计算价格时使用：
     * price0 = reserve1 / reserve0 (以 UQ112.112 格式)
     */
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
