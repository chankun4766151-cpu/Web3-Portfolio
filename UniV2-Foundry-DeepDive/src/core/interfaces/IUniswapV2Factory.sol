// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUniswapV2Factory 接口
 * @notice Uniswap V2 工厂合约接口
 * @dev 工厂合约负责创建和管理所有的交易对（Pair）
 * 
 * 工厂模式的优势：
 * 1. 统一管理所有交易对的创建
 * 2. 使用 CREATE2 确保地址可预测
 * 3. 防止创建重复的交易对
 */
interface IUniswapV2Factory {
    /// @notice 当新的交易对被创建时触发
    /// @param token0 排序后的第一个代币地址（地址值较小的那个）
    /// @param token1 排序后的第二个代币地址（地址值较大的那个）
    /// @param pair 新创建的交易对合约地址
    /// @param allPairsLength 创建后交易对的总数量
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 allPairsLength);

    /**
     * @notice 获取手续费接收地址
     * @dev 如果设置了 feeTo，每次交易的 0.05% 手续费会归协议所有
     *      如果未设置（零地址），这部分手续费会归 LP 持有者
     * @return 手续费接收地址
     */
    function feeTo() external view returns (address);
    
    /**
     * @notice 获取有权设置 feeTo 的地址
     * @return 有权设置手续费接收地址的管理员地址
     */
    function feeToSetter() external view returns (address);

    /**
     * @notice 查询两个代币组成的交易对地址
     * @dev 无论参数顺序如何，都返回相同的交易对地址
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @return pair 交易对合约地址，如果不存在返回零地址
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
    /**
     * @notice 通过索引获取交易对地址
     * @param index 交易对索引（从0开始）
     * @return pair 交易对合约地址
     */
    function allPairs(uint256 index) external view returns (address pair);
    
    /**
     * @notice 获取所有交易对的数量
     * @return 交易对总数
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @notice 创建新的交易对
     * @dev 使用 CREATE2 操作码创建，确保地址可预测
     * 
     * 重要说明：
     * 1. tokenA 和 tokenB 不能相同
     * 2. 两个地址都不能是零地址
     * 3. 该交易对必须不存在
     * 4. 创建后 token0 总是地址值较小的那个
     * 
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @return pair 新创建的交易对合约地址
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice 设置手续费接收地址
     * @dev 只有 feeToSetter 可以调用
     * @param _feeTo 新的手续费接收地址
     */
    function setFeeTo(address _feeTo) external;
    
    /**
     * @notice 设置有权更改 feeTo 的地址
     * @dev 只有当前 feeToSetter 可以调用
     * @param _feeToSetter 新的管理员地址
     */
    function setFeeToSetter(address _feeToSetter) external;
}
