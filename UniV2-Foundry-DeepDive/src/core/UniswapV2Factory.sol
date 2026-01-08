// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";

/**
 * @title UniswapV2Factory
 * @notice Uniswap V2 工厂合约
 * @dev 负责创建和管理所有的交易对（Pair）
 * 
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                            工厂模式的优势                                    ║
 * ╠═══════════════════════════════════════════════════════════════════════════╣
 * ║  1. 统一管理：所有交易对由同一个工厂创建                                       ║
 * ║  2. 地址可预测：使用 CREATE2，可以在创建前计算交易对地址                        ║
 * ║  3. 防止重复：同一对代币只能有一个交易对                                       ║
 * ║  4. 注册表功能：维护所有交易对的列表                                          ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 * 
 * CREATE2 地址计算公式：
 * address = keccak256(0xff + factory + salt + init_code_hash)[12:]
 * 
 * 其中：
 * - factory: 工厂合约地址
 * - salt: keccak256(token0, token1)
 * - init_code_hash: UniswapV2Pair 创建代码的哈希
 */
contract UniswapV2Factory is IUniswapV2Factory {
    // ==================== 状态变量 ====================
    
    /**
     * @notice 手续费接收地址
     * @dev 如果设置，每次 swap 的 1/6 手续费（即 0.05%）归协议所有
     *      如果为零地址，这部分手续费归 LP 持有者
     */
    address public feeTo;
    
    /**
     * @notice 有权设置 feeTo 的管理员地址
     */
    address public feeToSetter;

    /**
     * @notice 交易对映射：tokenA => tokenB => pair address
     * @dev 无论参数顺序如何，都返回相同的交易对地址
     *      getPair[tokenA][tokenB] == getPair[tokenB][tokenA]
     */
    mapping(address => mapping(address => address)) public getPair;
    
    /**
     * @notice 所有交易对的数组
     * @dev 用于遍历所有交易对
     */
    address[] public allPairs;

    // ==================== 构造函数 ====================
    
    /**
     * @notice 构造函数
     * @param _feeToSetter 初始管理员地址，有权设置 feeTo
     */
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    // ==================== 视图函数 ====================
    
    /**
     * @notice 获取所有交易对的数量
     * @return 交易对总数
     */
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    // ==================== 核心函数 ====================
    
    /**
     * @notice 创建新的交易对
     * @dev 使用 CREATE2 操作码创建，确保地址可预测
     * 
     * ╔═══════════════════════════════════════════════════════════════════════════╗
     * ║                           CREATE2 工作原理                                  ║
     * ╠═══════════════════════════════════════════════════════════════════════════╣
     * ║  普通 CREATE:  地址由 nonce 和发送者地址决定                                 ║
     * ║  CREATE2:      地址由 salt 和创建代码哈希决定                                ║
     * ║                                                                            ║
     * ║  优势：                                                                     ║
     * ║  - 地址可预测，无需调用合约就能知道交易对地址                                  ║
     * ║  - 用于 Router 中的 pairFor 函数，避免链上查询                               ║
     * ╚═══════════════════════════════════════════════════════════════════════════╝
     * 
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @return pair 新创建的交易对地址
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 两个代币不能相同
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        
        // 对代币地址排序，确保 token0 < token1
        // 这保证了同一对代币只有一个交易对
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        // 两个地址都不能是零地址
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        
        // 确保交易对不存在
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS");
        
        // 获取 UniswapV2Pair 的创建字节码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        
        // 计算 salt = keccak256(token0, token1)
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        
        // 使用 CREATE2 创建合约
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        // 初始化交易对（设置两个代币地址）
        UniswapV2Pair(pair).initialize(token0, token1);
        
        // 更新映射（双向）
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        
        // 添加到数组
        allPairs.push(pair);
        
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // ==================== 管理函数 ====================
    
    /**
     * @notice 设置手续费接收地址
     * @dev 只有 feeToSetter 可以调用
     * @param _feeTo 新的手续费接收地址
     */
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    /**
     * @notice 转移管理权限
     * @dev 只有当前 feeToSetter 可以调用
     * @param _feeToSetter 新的管理员地址
     */
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
