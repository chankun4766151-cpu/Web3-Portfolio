// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUniswapV2Router01 接口
 * @notice Uniswap V2 Router 第一版接口
 * @dev 定义了添加/移除流动性和交换的基本功能
 */
interface IUniswapV2Router01 {
    /// @notice 返回工厂合约地址
    function factory() external view returns (address);
    
    /// @notice 返回 WETH 合约地址
    function WETH() external view returns (address);

    // ==================== 添加流动性 ====================
    
    /**
     * @notice 添加流动性（两个 ERC20 代币）
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param amountADesired 期望添加的代币A数量
     * @param amountBDesired 期望添加的代币B数量
     * @param amountAMin 最小接受的代币A数量（滑点保护）
     * @param amountBMin 最小接受的代币B数量（滑点保护）
     * @param to LP Token 接收地址
     * @param deadline 交易截止时间戳
     * @return amountA 实际添加的代币A数量
     * @return amountB 实际添加的代币B数量
     * @return liquidity 获得的 LP Token 数量
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice 添加流动性（一个 ERC20 + ETH）
     * @dev ETH 会自动转换为 WETH
     * @param token 代币地址
     * @param amountTokenDesired 期望添加的代币数量
     * @param amountTokenMin 最小接受的代币数量
     * @param amountETHMin 最小接受的 ETH 数量
     * @param to LP Token 接收地址
     * @param deadline 交易截止时间戳
     * @return amountToken 实际添加的代币数量
     * @return amountETH 实际添加的 ETH 数量
     * @return liquidity 获得的 LP Token 数量
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    // ==================== 移除流动性 ====================
    
    /**
     * @notice 移除流动性（两个 ERC20 代币）
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param liquidity 要销毁的 LP Token 数量
     * @param amountAMin 最小接受的代币A数量
     * @param amountBMin 最小接受的代币B数量
     * @param to 代币接收地址
     * @param deadline 交易截止时间戳
     * @return amountA 取出的代币A数量
     * @return amountB 取出的代币B数量
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice 移除流动性（一个 ERC20 + ETH）
     * @dev WETH 会自动转换为 ETH
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice 使用 permit 签名移除流动性
     * @dev 可以在一笔交易中完成授权 + 移除流动性
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    // ==================== 交换函数 ====================
    
    /**
     * @notice 使用精确数量的输入代币交换
     * @dev 指定输入数量，获得尽可能多的输出
     * @param amountIn 输入代币数量
     * @param amountOutMin 最小输出数量（滑点保护）
     * @param path 交换路径（代币地址数组）
     * @param to 输出代币接收地址
     * @param deadline 交易截止时间戳
     * @return amounts 每一步的交换数量
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice 交换获得精确数量的输出代币
     * @dev 指定输出数量，尽可能少地支付输入
     * @param amountOut 期望的输出数量
     * @param amountInMax 最大输入数量（滑点保护）
     * @param path 交换路径
     * @param to 输出代币接收地址
     * @param deadline 交易截止时间戳
     * @return amounts 每一步的交换数量
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
    function swapTokensForExactETH(
        uint256 amountOut, 
        uint256 amountInMax, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function swapExactTokensForETH(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function swapETHForExactTokens(
        uint256 amountOut, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    // ==================== 辅助函数 ====================
    
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}
