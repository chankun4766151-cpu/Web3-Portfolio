// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "./interfaces/IERC20.sol";
import "./UniswapV2ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

/**
 * @title UniswapV2Pair
 * @notice Uniswap V2 交易对合约 - AMM 的核心实现
 * @dev 这是 Uniswap V2 最重要的合约！实现了恒定乘积做市商（CPMM）的所有逻辑
 * 
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                    恒定乘积公式 (Constant Product Formula)                   ║
 * ║                              x * y = k                                     ║
 * ║                                                                            ║
 * ║  x = token0 储备量                                                          ║
 * ║  y = token1 储备量                                                          ║
 * ║  k = 恒定乘积（交易后只能增加或不变）                                           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 * 
 * 核心功能：
 * 1. mint() - 添加流动性，获得 LP Token
 * 2. burn() - 移除流动性，销毁 LP Token
 * 3. swap() - 代币交换
 * 4. 价格预言机 - 累积价格用于 TWAP
 * 
 * 手续费机制：
 * - 每次 swap 收取 0.3% 手续费
 * - 0.25% 归 LP 持有者
 * - 0.05% 归协议（如果 feeTo 已设置）
 */
contract UniswapV2Pair is UniswapV2ERC20 {
    using UQ112x112 for uint224;

    // ==================== Events ====================
    
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // ==================== 常量 ====================
    
    /**
     * @notice 最小流动性
     * @dev 首次添加流动性时，永久锁定 1000 个最小单位的 LP Token
     * 
     * 为什么要锁定？
     * 防止"首个流动性提供者"攻击：
     * 1. 攻击者以极小的流动性创建池子
     * 2. 然后通过捐赠代币来操纵价格
     * 3. 导致后续 LP 损失
     * 
     * 锁定最小流动性确保池子始终有一定的基础流动性
     */
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    
    /// @dev transfer 函数选择器，用于安全转账
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    // ==================== 状态变量 ====================
    
    /// @notice 工厂合约地址
    address public factory;
    
    /// @notice token0 地址（地址值较小的代币）
    address public token0;
    
    /// @notice token1 地址（地址值较大的代币）
    address public token1;

    /**
     * @notice 储备量和时间戳的打包存储
     * @dev 使用 uint112 存储储备量，uint32 存储时间戳
     *      三个值打包在一个 256 位的 storage slot 中，节省 gas
     *      112 + 112 + 32 = 256 bits
     */
    uint112 private reserve0;           // token0 储备量
    uint112 private reserve1;           // token1 储备量
    uint32  private blockTimestampLast; // 最后更新的区块时间戳

    /**
     * @notice token0 的累积价格
     * @dev 价格以 UQ112.112 格式存储
     *      price0CumulativeLast += reserve1/reserve0 * timeElapsed
     *      用于计算 TWAP（时间加权平均价格）
     */
    uint256 public price0CumulativeLast;
    
    /// @notice token1 的累积价格
    uint256 public price1CumulativeLast;
    
    /**
     * @notice 最后的 k 值
     * @dev kLast = reserve0 * reserve1
     *      用于计算协议手续费
     *      只在 feeTo 不为零时更新
     */
    uint256 public kLast;

    // ==================== 重入锁 ====================
    
    /// @dev 用于防止重入攻击
    uint256 private unlocked = 1;
    
    /**
     * @notice 防重入修饰器
     * @dev 使用状态变量锁而不是 OpenZeppelin 的 ReentrancyGuard
     *      在函数执行期间锁定，执行完成后解锁
     */
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // ==================== 构造函数 ====================
    
    /**
     * @notice 构造函数
     * @dev 设置 factory 为 msg.sender（由 Factory 合约创建）
     */
    constructor() {
        factory = msg.sender;
    }

    // ==================== 初始化 ====================
    
    /**
     * @notice 初始化交易对
     * @dev 只能由 factory 调用一次
     *      设置两个代币的地址
     * @param _token0 第一个代币地址
     * @param _token1 第二个代币地址
     */
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    // ==================== 视图函数 ====================
    
    /**
     * @notice 获取当前储备量
     * @return _reserve0 token0 储备量
     * @return _reserve1 token1 储备量
     * @return _blockTimestampLast 最后更新时间戳
     */
    function getReserves() public view returns (
        uint112 _reserve0, 
        uint112 _reserve1, 
        uint32 _blockTimestampLast
    ) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // ==================== 内部函数 ====================
    
    /**
     * @notice 安全转账
     * @dev 使用低级 call 执行转账，检查返回值
     *      兼容不符合标准的 ERC20 代币（如 USDT）
     * @param token 代币地址
     * @param to 接收地址
     * @param value 转账数量
     */
    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "UniswapV2: TRANSFER_FAILED");
    }

    /**
     * @notice 更新储备量并累积价格
     * @dev 这是价格预言机的核心！
     * 
     * 价格累积原理：
     * 1. 计算自上次更新以来的时间差
     * 2. 将当前价格乘以时间差，累加到累积价格
     * 3. TWAP = (priceCumulativeNow - priceCumulativeBefore) / timeElapsed
     * 
     * @param balance0 新的 token0 余额
     * @param balance1 新的 token1 余额
     * @param _reserve0 旧的 token0 储备量
     * @param _reserve1 旧的 token1 储备量
     */
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        // 检查余额不超过 uint112 最大值
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "UniswapV2: OVERFLOW");
        
        // 获取当前时间戳（截断为 uint32）
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        
        // 计算时间差（处理溢出情况）
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast;
        }
        
        // 如果时间过了且储备量不为零，累积价格
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // 使用 unchecked 因为累积价格设计为可溢出
            unchecked {
                // price0 = reserve1 / reserve0 (用 UQ112.112 格式)
                price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                // price1 = reserve0 / reserve1 (用 UQ112.112 格式)
                price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }
        
        // 更新储备量
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        
        emit Sync(reserve0, reserve1);
    }

    /**
     * @notice 铸造协议手续费的 LP Token
     * @dev 只有在 feeTo 不为零时才会铸造
     * 
     * 手续费计算原理：
     * 1. 交易手续费会使 k 值增长
     * 2. k 的增长 = 新 k - 旧 kLast
     * 3. 协议应得的份额 = k增长量 / 5（即 1/5，对应 0.05% / 0.25%）
     * 4. 通过铸造 LP Token 实现收费
     * 
     * @param _reserve0 当前 token0 储备量
     * @param _reserve1 当前 token1 储备量
     * @return feeOn 是否开启了协议费用
     */
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        
        if (feeOn) {
            if (_kLast != 0) {
                // 计算 k 的平方根
                uint256 rootK = Math.sqrt(uint256(_reserve0) * _reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                
                if (rootK > rootKLast) {
                    // 计算应铸造的 LP Token 数量
                    // liquidity = totalSupply * (rootK - rootKLast) / (5 * rootK + rootKLast)
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    
                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // ==================== 核心函数 ====================
    
    /**
     * @notice 添加流动性，铸造 LP Token
     * @dev 调用前需要先将两种代币转入合约！
     * 
     * ╔═══════════════════════════════════════════════════════════════════════════╗
     * ║                           添加流动性流程                                    ║
     * ╠═══════════════════════════════════════════════════════════════════════════╣
     * ║  1. 用户将 token0 和 token1 转入 Pair 合约                                  ║
     * ║  2. 调用 mint(to)                                                         ║
     * ║  3. 合约计算应铸造的 LP Token 数量                                          ║
     * ║  4. 铸造 LP Token 给用户                                                   ║
     * ╚═══════════════════════════════════════════════════════════════════════════╝
     * 
     * LP Token 计算：
     * - 首次添加：liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
     * - 后续添加：liquidity = min(amount0/reserve0, amount1/reserve1) * totalSupply
     * 
     * @param to LP Token 接收地址
     * @return liquidity 铸造的 LP Token 数量
     */
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        
        // 获取当前余额
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        
        // 计算新增的代币数量
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        // 铸造协议费用
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        
        if (_totalSupply == 0) {
            // 首次添加流动性
            // 使用几何平均数计算 LP Token 数量
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // 永久锁定最小流动性到零地址
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 后续添加流动性
            // 取两个比例中较小的那个，防止单边添加
            liquidity = Math.min(
                amount0 * _totalSupply / _reserve0, 
                amount1 * _totalSupply / _reserve1
            );
        }
        
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        
        // 如果开启手续费，更新 kLast
        if (feeOn) kLast = uint256(reserve0) * reserve1;
        
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @notice 移除流动性，销毁 LP Token
     * @dev 调用前需要先将 LP Token 转入合约！
     * 
     * ╔═══════════════════════════════════════════════════════════════════════════╗
     * ║                           移除流动性流程                                    ║
     * ╠═══════════════════════════════════════════════════════════════════════════╣
     * ║  1. 用户将 LP Token 转入 Pair 合约                                         ║
     * ║  2. 调用 burn(to)                                                         ║
     * ║  3. 合约计算应返还的两种代币数量                                             ║
     * ║  4. 销毁 LP Token，转出代币给用户                                           ║
     * ╚═══════════════════════════════════════════════════════════════════════════╝
     * 
     * 返还数量计算：
     * - amount0 = liquidity * balance0 / totalSupply
     * - amount1 = liquidity * balance1 / totalSupply
     * 
     * @param to 代币接收地址
     * @return amount0 返还的 token0 数量
     * @return amount1 返还的 token1 数量
     */
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        
        // 获取当前余额
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        
        // 获取用户转入的 LP Token 数量
        uint256 liquidity = balanceOf[address(this)];

        // 铸造协议费用
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        
        // 按比例计算应返还的代币数量
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        
        require(amount0 > 0 && amount1 > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");
        
        // 销毁 LP Token
        _burn(address(this), liquidity);
        
        // 转出代币
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        
        // 更新储备量
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        
        // 如果开启手续费，更新 kLast
        if (feeOn) kLast = uint256(reserve0) * reserve1;
        
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * @notice 代币交换
     * @dev 这是 Uniswap V2 最核心的函数！
     * 
     * ╔═══════════════════════════════════════════════════════════════════════════╗
     * ║                              交换流程                                       ║
     * ╠═══════════════════════════════════════════════════════════════════════════╣
     * ║  1. 用户将输入代币转入 Pair 合约（在调用 swap 之前）                          ║
     * ║  2. 调用 swap(amount0Out, amount1Out, to, data)                           ║
     * ║  3. 合约验证恒定乘积不变式                                                  ║
     * ║  4. 转出请求的代币数量                                                     ║
     * ╚═══════════════════════════════════════════════════════════════════════════╝
     * 
     * 恒定乘积验证：
     * (balance0 * 1000 - amount0In * 3) * (balance1 * 1000 - amount1In * 3) >= k * 1000^2
     * 
     * 注意：乘以 1000 是为了处理 0.3% 手续费 (1000 - 3 = 997)
     * 
     * 闪电贷支持：
     * - 如果 data 非空，会调用 to.uniswapV2Call()
     * - 可以先借出代币，在回调中还款
     * 
     * @param amount0Out 要取出的 token0 数量
     * @param amount1Out 要取出的 token1 数量
     * @param to 代币接收地址
     * @param data 回调数据（如果非空则执行闪电贷）
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "UniswapV2: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // 使用局部变量避免 stack too deep 错误
            address _token0 = token0;
            address _token1 = token1;
            
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            
            // 乐观转账（先转出代币）
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            
            // 闪电贷回调
            if (data.length > 0) {
                IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            }
            
            // 获取转账后的余额
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        
        // 计算实际输入的代币数量
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");
        
        // 验证恒定乘积不变式（考虑 0.3% 手续费）
        {
            // balance0Adjusted = balance0 * 1000 - amount0In * 3
            // balance1Adjusted = balance1 * 1000 - amount1In * 3
            // require: balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 1000^2
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            require(
                balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * _reserve1 * (1000**2),
                "UniswapV2: K"
            );
        }

        // 更新储备量
        _update(balance0, balance1, _reserve0, _reserve1);
        
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice 提取多余的代币
     * @dev 将实际余额与储备量的差额发送到指定地址
     *      用于处理意外转入或捐赠的代币
     * @param to 接收地址
     */
    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    /**
     * @notice 强制同步储备量
     * @dev 将储备量更新为当前实际余额
     *      用于恢复因代币转入导致的不一致状态
     */
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)), 
            IERC20(token1).balanceOf(address(this)), 
            reserve0, 
            reserve1
        );
    }
}
