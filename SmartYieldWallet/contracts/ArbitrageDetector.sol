// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IDEXRouter
 * @dev DEX路由器接口
 */
interface IDEXRouter {
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut);
    
    function name() external view returns (string memory);
}

/**
 * @title ArbitrageDetector
 * @dev 套利机会检测器 - 自动发现DEX/CEX之间的套利机会
 * 
 * 核心功能:
 * 1. 自动扫描多个DEX的价格差异
 * 2. 计算套利利润和Gas成本
 * 3. 推送套利机会供用户选择
 */
contract ArbitrageDetector is Ownable {

    // ============ 结构体 ============
    struct DEXInfo {
        address router;
        string name;
        bool isActive;
    }
    
    struct TokenPair {
        address tokenA;
        address tokenB;
        string symbolA;
        string symbolB;
        bool isActive;
    }
    
    struct ArbitrageOpportunity {
        address tokenA;
        address tokenB;
        string symbolA;
        string symbolB;
        address buyDEX;
        string buyDEXName;
        address sellDEX;
        string sellDEXName;
        uint256 buyPrice;    // tokenB per tokenA
        uint256 sellPrice;   // tokenB per tokenA
        uint256 profitBps;   // 利润率 (basis points)
        uint256 estimatedProfit; // 预估利润 (以tokenB计)
        uint256 timestamp;
    }
    
    struct PriceInfo {
        address dex;
        string dexName;
        uint256 price;
    }

    // ============ 状态变量 ============
    mapping(address => DEXInfo) public dexes;
    address[] public dexList;
    
    TokenPair[] public tokenPairs;
    mapping(bytes32 => bool) public pairExists;
    
    // 最小利润阈值 (basis points, 100 = 1%)
    uint256 public minProfitThreshold = 50; // 0.5%
    
    // 用于计算的标准金额 (1e18 = 1 token)
    uint256 public constant STANDARD_AMOUNT = 1e18;
    
    // 最近检测到的套利机会
    ArbitrageOpportunity[] public recentOpportunities;
    uint256 public constant MAX_OPPORTUNITIES = 10;

    // ============ 事件 ============
    event DEXAdded(address indexed router, string name);
    event DEXRemoved(address indexed router);
    event TokenPairAdded(address tokenA, address tokenB, string symbolA, string symbolB);
    event ArbitrageFound(
        address tokenA,
        address tokenB,
        address buyDEX,
        address sellDEX,
        uint256 profitBps
    );
    event ThresholdUpdated(uint256 newThreshold);

    // ============ 构造函数 ============
    constructor() Ownable(msg.sender) {}

    // ============ DEX管理 ============

    /**
     * @notice 添加DEX
     * @param router DEX路由器地址
     * @param name DEX名称
     */
    function addDEX(address router, string memory name) external onlyOwner {
        require(router != address(0), "Invalid router address");
        require(!dexes[router].isActive, "DEX already exists");

        dexes[router] = DEXInfo({
            router: router,
            name: name,
            isActive: true
        });
        
        dexList.push(router);
        
        emit DEXAdded(router, name);
    }

    /**
     * @notice 移除DEX
     * @param router DEX路由器地址
     */
    function removeDEX(address router) external onlyOwner {
        require(dexes[router].isActive, "DEX not found");
        
        dexes[router].isActive = false;
        
        for (uint256 i = 0; i < dexList.length; i++) {
            if (dexList[i] == router) {
                dexList[i] = dexList[dexList.length - 1];
                dexList.pop();
                break;
            }
        }
        
        emit DEXRemoved(router);
    }

    // ============ 代币对管理 ============

    /**
     * @notice 添加监控的代币对
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param symbolA 代币A符号
     * @param symbolB 代币B符号
     */
    function addTokenPair(
        address tokenA,
        address tokenB,
        string memory symbolA,
        string memory symbolB
    ) external onlyOwner {
        bytes32 pairId = keccak256(abi.encodePacked(tokenA, tokenB));
        require(!pairExists[pairId], "Pair already exists");
        
        tokenPairs.push(TokenPair({
            tokenA: tokenA,
            tokenB: tokenB,
            symbolA: symbolA,
            symbolB: symbolB,
            isActive: true
        }));
        
        pairExists[pairId] = true;
        
        emit TokenPairAdded(tokenA, tokenB, symbolA, symbolB);
    }

    /**
     * @notice 设置最小利润阈值
     * @param threshold 新阈值 (basis points)
     */
    function setMinProfitThreshold(uint256 threshold) external onlyOwner {
        minProfitThreshold = threshold;
        emit ThresholdUpdated(threshold);
    }

    // ============ 套利检测 ============

    /**
     * @notice 扫描所有代币对的套利机会
     * @return opportunities 发现的套利机会数组
     */
    function scanArbitrageOpportunities() 
        external 
        returns (ArbitrageOpportunity[] memory opportunities) 
    {
        // 清空之前的机会
        delete recentOpportunities;
        
        uint256 count = 0;
        ArbitrageOpportunity[] memory tempOpportunities = 
            new ArbitrageOpportunity[](tokenPairs.length * dexList.length * dexList.length);
        
        for (uint256 i = 0; i < tokenPairs.length; i++) {
            if (!tokenPairs[i].isActive) continue;
            
            ArbitrageOpportunity memory opp = _findBestArbitrage(tokenPairs[i]);
            
            if (opp.profitBps >= minProfitThreshold) {
                tempOpportunities[count] = opp;
                count++;
                
                // 存储到最近机会
                if (recentOpportunities.length < MAX_OPPORTUNITIES) {
                    recentOpportunities.push(opp);
                }
                
                emit ArbitrageFound(
                    opp.tokenA,
                    opp.tokenB,
                    opp.buyDEX,
                    opp.sellDEX,
                    opp.profitBps
                );
            }
        }
        
        // 返回实际发现的机会
        opportunities = new ArbitrageOpportunity[](count);
        for (uint256 i = 0; i < count; i++) {
            opportunities[i] = tempOpportunities[i];
        }
        
        return opportunities;
    }

    /**
     * @notice 为特定代币对寻找最佳套利机会
     * @param pair 代币对
     * @return opp 最佳套利机会
     */
    function _findBestArbitrage(TokenPair memory pair) 
        internal 
        view 
        returns (ArbitrageOpportunity memory opp) 
    {
        uint256 bestProfit = 0;
        
        // 获取所有DEX的价格
        PriceInfo[] memory prices = _getAllPrices(pair.tokenA, pair.tokenB);
        
        if (prices.length < 2) return opp;
        
        // 寻找最大价差
        for (uint256 i = 0; i < prices.length; i++) {
            for (uint256 j = 0; j < prices.length; j++) {
                if (i == j || prices[i].price == 0 || prices[j].price == 0) continue;
                
                // 如果在DEX i买入比在DEX j卖出便宜，则有套利机会
                if (prices[j].price > prices[i].price) {
                    uint256 profitBps = ((prices[j].price - prices[i].price) * 10000) / prices[i].price;
                    
                    if (profitBps > bestProfit) {
                        bestProfit = profitBps;
                        
                        opp = ArbitrageOpportunity({
                            tokenA: pair.tokenA,
                            tokenB: pair.tokenB,
                            symbolA: pair.symbolA,
                            symbolB: pair.symbolB,
                            buyDEX: prices[i].dex,
                            buyDEXName: prices[i].dexName,
                            sellDEX: prices[j].dex,
                            sellDEXName: prices[j].dexName,
                            buyPrice: prices[i].price,
                            sellPrice: prices[j].price,
                            profitBps: profitBps,
                            estimatedProfit: (STANDARD_AMOUNT * profitBps) / 10000,
                            timestamp: block.timestamp
                        });
                    }
                }
            }
        }
        
        return opp;
    }

    /**
     * @notice 获取所有DEX的代币价格
     * @param tokenA 代币A
     * @param tokenB 代币B
     * @return prices 各DEX价格数组
     */
    function _getAllPrices(address tokenA, address tokenB) 
        internal 
        view 
        returns (PriceInfo[] memory prices) 
    {
        prices = new PriceInfo[](dexList.length);
        
        for (uint256 i = 0; i < dexList.length; i++) {
            address router = dexList[i];
            if (!dexes[router].isActive) continue;
            
            try IDEXRouter(router).getAmountOut(STANDARD_AMOUNT, tokenA, tokenB) 
                returns (uint256 amountOut) 
            {
                prices[i] = PriceInfo({
                    dex: router,
                    dexName: dexes[router].name,
                    price: amountOut
                });
            } catch {
                prices[i] = PriceInfo({
                    dex: router,
                    dexName: dexes[router].name,
                    price: 0
                });
            }
        }
        
        return prices;
    }

    // ============ 视图函数 ============

    /**
     * @notice 获取最近发现的套利机会
     * @return 套利机会数组
     */
    function getRecentOpportunities() 
        external 
        view 
        returns (ArbitrageOpportunity[] memory) 
    {
        return recentOpportunities;
    }

    /**
     * @notice 获取特定代币对的当前价格差异
     * @param tokenA 代币A
     * @param tokenB 代币B
     * @return dexAddresses DEX地址数组
     * @return dexNames DEX名称数组
     * @return pricesOut 价格数组
     */
    function getPriceDifference(address tokenA, address tokenB)
        external
        view
        returns (
            address[] memory dexAddresses,
            string[] memory dexNames,
            uint256[] memory pricesOut
        )
    {
        dexAddresses = new address[](dexList.length);
        dexNames = new string[](dexList.length);
        pricesOut = new uint256[](dexList.length);
        
        for (uint256 i = 0; i < dexList.length; i++) {
            address router = dexList[i];
            dexAddresses[i] = router;
            dexNames[i] = dexes[router].name;
            
            if (dexes[router].isActive) {
                try IDEXRouter(router).getAmountOut(STANDARD_AMOUNT, tokenA, tokenB) 
                    returns (uint256 amountOut) 
                {
                    pricesOut[i] = amountOut;
                } catch {
                    pricesOut[i] = 0;
                }
            }
        }
        
        return (dexAddresses, dexNames, pricesOut);
    }

    /**
     * @notice 计算特定金额的预期利润
     * @param tokenA 买入代币
     * @param tokenB 卖出代币
     * @param amount 交易金额
     * @param buyDEX 买入DEX
     * @param sellDEX 卖出DEX
     * @return profit 预期利润
     * @return profitBps 利润率 (basis points)
     */
    function calculateProfit(
        address tokenA,
        address tokenB,
        uint256 amount,
        address buyDEX,
        address sellDEX
    ) external view returns (uint256 profit, uint256 profitBps) {
        require(dexes[buyDEX].isActive, "Buy DEX not active");
        require(dexes[sellDEX].isActive, "Sell DEX not active");
        
        // 在buyDEX买入tokenA (用tokenB)
        uint256 buyAmount = IDEXRouter(buyDEX).getAmountOut(amount, tokenB, tokenA);
        
        // 在sellDEX卖出tokenA获得tokenB
        uint256 sellAmount = IDEXRouter(sellDEX).getAmountOut(buyAmount, tokenA, tokenB);
        
        if (sellAmount > amount) {
            profit = sellAmount - amount;
            profitBps = (profit * 10000) / amount;
        } else {
            profit = 0;
            profitBps = 0;
        }
        
        return (profit, profitBps);
    }

    /**
     * @notice 获取DEX数量
     * @return DEX数量
     */
    function getDEXCount() external view returns (uint256) {
        return dexList.length;
    }

    /**
     * @notice 获取代币对数量
     * @return 代币对数量
     */
    function getTokenPairCount() external view returns (uint256) {
        return tokenPairs.length;
    }

    /**
     * @notice 获取所有活跃DEX
     * @return 活跃DEX数组
     */
    function getActiveDEXes() external view returns (address[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < dexList.length; i++) {
            if (dexes[dexList[i]].isActive) {
                activeCount++;
            }
        }
        
        address[] memory activeDEXes = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < dexList.length; i++) {
            if (dexes[dexList[i]].isActive) {
                activeDEXes[index] = dexList[i];
                index++;
            }
        }
        
        return activeDEXes;
    }
}
