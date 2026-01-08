// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/interfaces/IUniswapV2Pair.sol";
import "../core/UniswapV2Pair.sol";

/**
 * @title UniswapV2Library
 * @notice Uniswap V2 辅助计算库
 * @dev 提供交易对地址计算、储备量获取、交换数量计算等功能
 * 
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                        重要：init_code_hash 说明                            ║
 * ╠═══════════════════════════════════════════════════════════════════════════╣
 * ║  pairFor 函数使用 init_code_hash 来计算交易对地址                             ║
 * ║  这个 hash 是 UniswapV2Pair 合约创建字节码的 keccak256 哈希                   ║
 * ║                                                                            ║
 * ║  如果你自己编译了合约，需要重新计算这个 hash！                                  ║
 * ║  使用 ComputeInitCodeHash 脚本可以获得正确的值                                ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
library UniswapV2Library {
    /**
     * @notice 对两个代币地址排序
     * @dev token0 是地址值较小的那个
     *      这确保了同一对代币只有一个交易对
     * @param tokenA 代币A
     * @param tokenB 代币B
     * @return token0 排序后的第一个代币
     * @return token1 排序后的第二个代币
     */
    function sortTokens(address tokenA, address tokenB) 
        internal 
        pure 
        returns (address token0, address token1) 
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /**
     * @notice 计算交易对地址（无需链上查询）
     * @dev 使用 CREATE2 公式计算地址
     * 
     * CREATE2 地址计算：
     * address = keccak256(0xff + factory + salt + init_code_hash)[12:]
     * 
     * 其中：
     * - 0xff: CREATE2 标识符
     * - factory: 工厂合约地址
     * - salt: keccak256(token0, token1)
     * - init_code_hash: UniswapV2Pair 创建字节码的哈希
     * 
     * @param factory 工厂合约地址
     * @param tokenA 代币A
     * @param tokenB 代币B
     * @return pair 计算得到的交易对地址
     */
    function pairFor(address factory, address tokenA, address tokenB) 
        internal 
        pure 
        returns (address pair) 
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        
        // 计算交易对地址
        // 注意：init_code_hash 需要根据本地编译的 UniswapV2Pair 合约重新计算
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            // 这是 UniswapV2Pair 创建字节码的 keccak256 哈希
            // 如果你修改了 UniswapV2Pair 合约或使用不同的编译器版本，需要重新计算
            keccak256(type(UniswapV2Pair).creationCode)
        )))));
    }

    /**
     * @notice 获取交易对的储备量
     * @dev 根据输入顺序返回储备量
     * @param factory 工厂合约地址
     * @param tokenA 代币A
     * @param tokenB 代币B
     * @return reserveA 代币A的储备量
     * @return reserveB 代币B的储备量
     */
    function getReserves(address factory, address tokenA, address tokenB) 
        internal 
        view 
        returns (uint256 reserveA, uint256 reserveB) 
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @notice 等价计算
     * @dev 给定一定数量的代币A和储备量，计算等价的代币B数量
     *      公式：amountB = amountA * reserveB / reserveA
     * @param amountA 代币A数量
     * @param reserveA 代币A储备量
     * @param reserveB 代币B储备量
     * @return amountB 等价的代币B数量
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) 
        internal 
        pure 
        returns (uint256 amountB) 
    {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    /**
     * @notice 计算输出数量
     * @dev 给定输入数量和储备量，计算输出数量
     * 
     * 计算公式（包含 0.3% 手续费）：
     * amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
     * 
     * 推导：
     * 1. 恒定乘积：(reserveIn + amountIn*0.997) * (reserveOut - amountOut) = reserveIn * reserveOut
     * 2. 整理得到上述公式
     * 
     * @param amountIn 输入数量
     * @param reserveIn 输入代币储备量
     * @param reserveOut 输出代币储备量
     * @return amountOut 输出数量
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
        internal 
        pure 
        returns (uint256 amountOut) 
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @notice 计算需要的输入数量
     * @dev 给定期望的输出数量和储备量，计算需要的输入数量
     * 
     * 计算公式：
     * amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1
     * 
     * @param amountOut 期望的输出数量
     * @param reserveIn 输入代币储备量
     * @param reserveOut 输出代币储备量
     * @return amountIn 需要的输入数量
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) 
        internal 
        pure 
        returns (uint256 amountIn) 
    {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    /**
     * @notice 计算多跳交换的输出数量
     * @dev 沿着路径计算每一步的输出
     * 
     * 示例路径：[WETH, USDC, DAI]
     * - 第一步：WETH -> USDC
     * - 第二步：USDC -> DAI
     * 
     * @param factory 工厂合约地址
     * @param amountIn 初始输入数量
     * @param path 交换路径（代币地址数组）
     * @return amounts 每一步的数量数组
     */
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) 
        internal 
        view 
        returns (uint256[] memory amounts) 
    {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @notice 计算多跳交换需要的输入数量
     * @dev 从后往前计算每一步需要的输入
     * 
     * @param factory 工厂合约地址
     * @param amountOut 期望的最终输出数量
     * @param path 交换路径
     * @return amounts 每一步的数量数组
     */
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) 
        internal 
        view 
        returns (uint256[] memory amounts) 
    {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
