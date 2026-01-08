// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUniswapV2Pair 接口
 * @notice Uniswap V2 交易对合约接口
 * @dev 这是 Uniswap V2 的核心合约，实现了自动做市商（AMM）的所有功能
 * 
 * 核心概念：
 * 1. 恒定乘积公式：x * y = k
 *    - x, y 是两种代币的储备量
 *    - k 是恒定乘积，交易后 k 不能减少
 * 
 * 2. 流动性挖矿：
 *    - 提供流动性获得 LP Token
 *    - LP Token 代表池子份额
 *    - 每次交易收取 0.3% 手续费给 LP
 * 
 * 3. 价格预言机：
 *    - 累积价格用于 TWAP（时间加权平均价格）
 *    - 防止价格操纵
 */
interface IUniswapV2Pair {
    // ==================== Events ====================
    // 注意：Transfer 和 Approval 事件通过 UniswapV2ERC20 继承
    
    /**
     * @notice 铸造 LP Token 事件
     * @param sender 操作发起者（通常是 Router）
     * @param amount0 存入的 token0 数量
     * @param amount1 存入的 token1 数量
     */
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    
    /**
     * @notice 销毁 LP Token 事件
     * @param sender 操作发起者
     * @param amount0 取出的 token0 数量
     * @param amount1 取出的 token1 数量
     * @param to 资产接收地址
     */
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    
    /**
     * @notice 交换事件
     * @param sender 操作发起者
     * @param amount0In 输入的 token0 数量
     * @param amount1In 输入的 token1 数量
     * @param amount0Out 输出的 token0 数量
     * @param amount1Out 输出的 token1 数量
     * @param to 输出代币接收地址
     */
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    
    /**
     * @notice 同步事件 - 当储备量与实际余额同步时触发
     * @param reserve0 同步后的 token0 储备量
     * @param reserve1 同步后的 token1 储备量
     */
    event Sync(uint112 reserve0, uint112 reserve1);

    // ==================== ERC20 Functions ====================
    
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    // ==================== EIP-2612 Permit ====================
    
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    // ==================== Pair Constants ====================
    
    /**
     * @notice 最小流动性常量
     * @dev 首次添加流动性时，会永久锁定 MINIMUM_LIQUIDITY 数量的 LP Token
     *      这是为了防止首个流动性提供者通过操纵价格来获利
     *      被锁定的 LP Token 发送到零地址
     * @return 最小流动性值（1000）
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    
    /// @notice 返回工厂合约地址
    function factory() external view returns (address);
    
    /// @notice 返回 token0 地址（地址值较小的代币）
    function token0() external view returns (address);
    
    /// @notice 返回 token1 地址（地址值较大的代币）
    function token1() external view returns (address);

    // ==================== Reserves & Price Oracle ====================
    
    /**
     * @notice 获取当前储备量和最后更新时间
     * @dev 使用 uint112 存储储备量是为了节省 gas（打包在一个 slot 中）
     * 
     * @return reserve0 token0 的储备量
     * @return reserve1 token1 的储备量
     * @return blockTimestampLast 最后一次更新的区块时间戳
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    
    /**
     * @notice token0 的累积价格
     * @dev 用于计算 TWAP（时间加权平均价格）
     *      价格以 UQ112x112 格式存储（定点数）
     *      价格 = token1数量 / token0数量
     */
    function price0CumulativeLast() external view returns (uint256);
    
    /**
     * @notice token1 的累积价格
     * @dev 价格 = token0数量 / token1数量
     */
    function price1CumulativeLast() external view returns (uint256);
    
    /**
     * @notice 最后一次流动性事件后的 k 值
     * @dev k = reserve0 * reserve1
     *      用于协议手续费的计算
     */
    function kLast() external view returns (uint256);

    // ==================== Core Functions ====================
    
    /**
     * @notice 铸造 LP Token（添加流动性）
     * @dev 调用前需要先将两种代币转入合约
     * 
     * 计算逻辑：
     * - 首次添加：liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
     * - 之后添加：liquidity = min(amount0/reserve0, amount1/reserve1) * totalSupply
     * 
     * @param to LP Token 接收地址
     * @return liquidity 铸造的 LP Token 数量
     */
    function mint(address to) external returns (uint256 liquidity);
    
    /**
     * @notice 销毁 LP Token（移除流动性）
     * @dev 调用前需要先将 LP Token 转入合约
     * 
     * 计算逻辑：
     * - amount0 = liquidity * balance0 / totalSupply
     * - amount1 = liquidity * balance1 / totalSupply
     * 
     * @param to 资产接收地址
     * @return amount0 返还的 token0 数量
     * @return amount1 返还的 token1 数量
     */
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice 执行代币交换
     * @dev 这是 Uniswap V2 的核心函数！
     * 
     * 工作流程：
     * 1. 调用者先将输入代币转入合约
     * 2. 调用 swap 指定要取出的数量
     * 3. 合约验证交换后 k 值不减少
     * 4. 转出请求的代币数量
     * 
     * 闪电贷支持：
     * - 可以先借出代币，在回调中还款
     * - 需要在同一笔交易中归还本金 + 手续费
     * 
     * @param amount0Out 要取出的 token0 数量
     * @param amount1Out 要取出的 token1 数量
     * @param to 代币接收地址
     * @param data 回调数据，如果非空则调用接收者的 uniswapV2Call
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    
    /**
     * @notice 将多余的代币发送到指定地址
     * @dev 用于处理意外转入的代币
     *      将实际余额与储备量的差额发送出去
     * @param to 接收地址
     */
    function skim(address to) external;
    
    /**
     * @notice 强制同步储备量与实际余额
     * @dev 将储备量更新为当前实际余额
     *      用于恢复异常状态
     */
    function sync() external;

    /**
     * @notice 初始化交易对
     * @dev 只能由工厂合约调用一次
     *      设置 token0 和 token1 地址
     * @param token0 第一个代币地址
     * @param token1 第二个代币地址
     */
    function initialize(address token0, address token1) external;
}
