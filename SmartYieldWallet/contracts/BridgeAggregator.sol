// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IBridge
 * @dev 跨链桥接口
 */
interface IBridge {
    function getFee(
        uint256 srcChainId,
        uint256 dstChainId,
        address token,
        uint256 amount
    ) external view returns (uint256 fee, uint256 estimatedTime);
    
    function bridge(
        uint256 dstChainId,
        address token,
        uint256 amount,
        address recipient
    ) external payable;
    
    function name() external view returns (string memory);
}

/**
 * @title BridgeAggregator
 * @dev 跨链桥聚合器 - 自动选择最优（最便宜）的跨链桥
 * 
 * 核心功能:
 * 1. 集成多个跨链桥 (Stargate, Across, Hop, Celer等)
 * 2. 智能路由选择成本最低的跨链方案
 * 3. 显示预估费用和到账时间
 */
contract BridgeAggregator is Ownable {
    using SafeERC20 for IERC20;

    // ============ 结构体 ============
    struct BridgeInfo {
        address bridgeAddress;
        string name;
        bool isActive;
        uint256 successRate; // 成功率 (basis points, 10000 = 100%)
    }
    
    struct BridgeQuote {
        address bridge;
        string bridgeName;
        uint256 fee;
        uint256 estimatedTime; // 预估时间(秒)
        bool isAvailable;
    }

    struct BridgeRoute {
        address bridge;
        uint256 fee;
        uint256 estimatedTime;
    }

    // ============ 状态变量 ============
    mapping(address => BridgeInfo) public bridges;
    address[] public bridgeList;
    
    // 支持的链
    mapping(uint256 => bool) public supportedChains;
    uint256[] public chainList;

    // ============ 事件 ============
    event BridgeAdded(address indexed bridge, string name);
    event BridgeRemoved(address indexed bridge);
    event BridgeExecuted(
        address indexed user,
        address indexed bridge,
        uint256 srcChainId,
        uint256 dstChainId,
        address token,
        uint256 amount,
        uint256 fee
    );
    event ChainAdded(uint256 chainId);
    event ChainRemoved(uint256 chainId);

    // ============ 构造函数 ============
    constructor() Ownable(msg.sender) {
        // 添加一些默认支持的链 (可以在部署后修改)
        _addChain(1);       // Ethereum Mainnet
        _addChain(10);      // Optimism
        _addChain(137);     // Polygon
        _addChain(42161);   // Arbitrum
        _addChain(8453);    // Base
        _addChain(11155111); // Sepolia
        _addChain(11155420); // Optimism Sepolia
    }

    // ============ 桥管理函数 ============

    /**
     * @notice 添加新的跨链桥
     * @param bridge 桥合约地址
     * @param name 桥名称
     */
    function addBridge(address bridge, string memory name) external onlyOwner {
        require(bridge != address(0), "Invalid bridge address");
        require(!bridges[bridge].isActive, "Bridge already exists");

        bridges[bridge] = BridgeInfo({
            bridgeAddress: bridge,
            name: name,
            isActive: true,
            successRate: 9500 // 默认95%成功率
        });
        
        bridgeList.push(bridge);
        
        emit BridgeAdded(bridge, name);
    }

    /**
     * @notice 移除跨链桥
     * @param bridge 桥合约地址
     */
    function removeBridge(address bridge) external onlyOwner {
        require(bridges[bridge].isActive, "Bridge not found");
        
        bridges[bridge].isActive = false;
        
        // 从数组中移除
        for (uint256 i = 0; i < bridgeList.length; i++) {
            if (bridgeList[i] == bridge) {
                bridgeList[i] = bridgeList[bridgeList.length - 1];
                bridgeList.pop();
                break;
            }
        }
        
        emit BridgeRemoved(bridge);
    }

    /**
     * @notice 添加支持的链
     * @param chainId 链ID
     */
    function addChain(uint256 chainId) external onlyOwner {
        _addChain(chainId);
    }

    function _addChain(uint256 chainId) internal {
        if (!supportedChains[chainId]) {
            supportedChains[chainId] = true;
            chainList.push(chainId);
            emit ChainAdded(chainId);
        }
    }

    // ============ 核心功能 ============

    /**
     * @notice 获取所有桥的报价
     * @param dstChainId 目标链ID
     * @param token 代币地址
     * @param amount 金额
     * @return quotes 所有桥的报价数组
     */
    function getAllBridgeQuotes(
        uint256 dstChainId,
        address token,
        uint256 amount
    ) external view returns (BridgeQuote[] memory quotes) {
        uint256 srcChainId = block.chainid;
        quotes = new BridgeQuote[](bridgeList.length);
        
        for (uint256 i = 0; i < bridgeList.length; i++) {
            address bridgeAddr = bridgeList[i];
            BridgeInfo memory info = bridges[bridgeAddr];
            
            if (info.isActive) {
                try IBridge(bridgeAddr).getFee(srcChainId, dstChainId, token, amount) 
                    returns (uint256 fee, uint256 estimatedTime) 
                {
                    quotes[i] = BridgeQuote({
                        bridge: bridgeAddr,
                        bridgeName: info.name,
                        fee: fee,
                        estimatedTime: estimatedTime,
                        isAvailable: true
                    });
                } catch {
                    quotes[i] = BridgeQuote({
                        bridge: bridgeAddr,
                        bridgeName: info.name,
                        fee: 0,
                        estimatedTime: 0,
                        isAvailable: false
                    });
                }
            }
        }
        
        return quotes;
    }

    /**
     * @notice 获取最优跨链路由
     * @param dstChainId 目标链ID
     * @param token 代币地址
     * @param amount 金额
     * @return optimalBridge 最优桥地址
     * @return fee 费用
     * @return estimatedTime 预估时间
     */
    function getOptimalBridge(
        uint256 dstChainId,
        address token,
        uint256 amount
    ) public view returns (
        address optimalBridge,
        uint256 fee,
        uint256 estimatedTime
    ) {
        uint256 srcChainId = block.chainid;
        uint256 lowestFee = type(uint256).max;
        
        for (uint256 i = 0; i < bridgeList.length; i++) {
            address bridgeAddr = bridgeList[i];
            
            if (bridges[bridgeAddr].isActive) {
                try IBridge(bridgeAddr).getFee(srcChainId, dstChainId, token, amount) 
                    returns (uint256 bridgeFee, uint256 time) 
                {
                    if (bridgeFee < lowestFee) {
                        lowestFee = bridgeFee;
                        optimalBridge = bridgeAddr;
                        fee = bridgeFee;
                        estimatedTime = time;
                    }
                } catch {
                    continue;
                }
            }
        }
        
        return (optimalBridge, fee, estimatedTime);
    }

    /**
     * @notice 执行跨链转账
     * @param dstChainId 目标链ID
     * @param token 代币地址
     * @param amount 金额
     * @param recipient 接收地址
     * @param useOptimal 是否使用最优桥
     * @param specificBridge 指定桥地址(如果不使用最优)
     */
    function bridge(
        uint256 dstChainId,
        address token,
        uint256 amount,
        address recipient,
        bool useOptimal,
        address specificBridge
    ) external payable {
        require(supportedChains[dstChainId], "Destination chain not supported");
        require(amount > 0, "Amount must be greater than 0");
        
        address bridgeToUse;
        uint256 fee;
        
        if (useOptimal) {
            (bridgeToUse, fee, ) = getOptimalBridge(dstChainId, token, amount);
            require(bridgeToUse != address(0), "No available bridge");
        } else {
            require(bridges[specificBridge].isActive, "Bridge not active");
            bridgeToUse = specificBridge;
            (fee, ) = IBridge(bridgeToUse).getFee(block.chainid, dstChainId, token, amount);
        }
        
        require(msg.value >= fee, "Insufficient fee");
        
        // 转入代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(bridgeToUse, amount);
        
        // 执行跨链
        IBridge(bridgeToUse).bridge{value: fee}(dstChainId, token, amount, recipient);
        
        // 退还多余的费用
        if (msg.value > fee) {
            (bool success, ) = msg.sender.call{value: msg.value - fee}("");
            require(success, "Refund failed");
        }
        
        emit BridgeExecuted(
            msg.sender,
            bridgeToUse,
            block.chainid,
            dstChainId,
            token,
            amount,
            fee
        );
    }

    // ============ 视图函数 ============

    /**
     * @notice 获取所有活跃的桥
     * @return 桥地址数组
     */
    function getActiveBridges() external view returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < bridgeList.length; i++) {
            if (bridges[bridgeList[i]].isActive) {
                activeCount++;
            }
        }
        
        address[] memory activeBridges = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < bridgeList.length; i++) {
            if (bridges[bridgeList[i]].isActive) {
                activeBridges[index] = bridgeList[i];
                index++;
            }
        }
        
        return activeBridges;
    }

    /**
     * @notice 获取支持的链列表
     * @return 链ID数组
     */
    function getSupportedChains() external view returns (uint256[] memory) {
        return chainList;
    }

    /**
     * @notice 获取桥信息
     * @param bridge 桥地址
     * @return 桥信息
     */
    function getBridgeInfo(address bridge) external view returns (BridgeInfo memory) {
        return bridges[bridge];
    }

    /**
     * @notice 获取桥数量
     * @return 桥数量
     */
    function getBridgeCount() external view returns (uint256) {
        return bridgeList.length;
    }
}
