"use client";

import { useState, useEffect } from "react";
import {
    Zap,
    TrendingUp,
    TrendingDown,
    AlertTriangle,
    DollarSign,
    ArrowRight,
    RefreshCw,
    Play,
    Clock,
    Percent
} from "lucide-react";

// 模拟套利机会数据
const mockOpportunities = [
    {
        id: 1,
        tokenPair: "ETH/USDC",
        buyDex: "Uniswap",
        sellDex: "SushiSwap",
        buyPrice: 2145.50,
        sellPrice: 2158.30,
        profitPercent: 0.59,
        estimatedProfit: 12.80,
        gasEstimate: 3.50,
        netProfit: 9.30,
        confidence: "High",
        timestamp: Date.now() - 10000,
    },
    {
        id: 2,
        tokenPair: "WBTC/ETH",
        buyDex: "Curve",
        sellDex: "Balancer",
        buyPrice: 15.234,
        sellPrice: 15.312,
        profitPercent: 0.51,
        estimatedProfit: 78.00,
        gasEstimate: 8.00,
        netProfit: 70.00,
        confidence: "High",
        timestamp: Date.now() - 25000,
    },
    {
        id: 3,
        tokenPair: "LINK/ETH",
        buyDex: "Uniswap",
        sellDex: "1inch",
        buyPrice: 0.00642,
        sellPrice: 0.00651,
        profitPercent: 1.40,
        estimatedProfit: 9.00,
        gasEstimate: 4.00,
        netProfit: 5.00,
        confidence: "Medium",
        timestamp: Date.now() - 45000,
    },
    {
        id: 4,
        tokenPair: "ARB/USDC",
        buyDex: "SushiSwap",
        sellDex: "Uniswap",
        buyPrice: 1.235,
        sellPrice: 1.248,
        profitPercent: 1.05,
        estimatedProfit: 13.00,
        gasEstimate: 5.00,
        netProfit: 8.00,
        confidence: "Medium",
        timestamp: Date.now() - 60000,
    },
];

export function ArbitragePanel() {
    const [opportunities, setOpportunities] = useState(mockOpportunities);
    const [isScanning, setIsScanning] = useState(false);
    const [lastScan, setLastScan] = useState(new Date());
    const [autoScan, setAutoScan] = useState(true);

    // 模拟自动扫描
    useEffect(() => {
        if (!autoScan) return;

        const interval = setInterval(() => {
            // 随机更新一些数据以模拟实时变化
            setOpportunities(prev => prev.map(opp => ({
                ...opp,
                profitPercent: opp.profitPercent + (Math.random() - 0.5) * 0.1,
                timestamp: Date.now() - Math.floor(Math.random() * 60000),
            })));
        }, 5000);

        return () => clearInterval(interval);
    }, [autoScan]);

    const handleScan = async () => {
        setIsScanning(true);
        await new Promise(resolve => setTimeout(resolve, 2000));
        setLastScan(new Date());
        setIsScanning(false);
    };

    const totalOpportunities = opportunities.length;
    const totalProfit = opportunities.reduce((sum, opp) => sum + opp.netProfit, 0);
    const avgProfit = totalProfit / totalOpportunities;

    return (
        <div className="space-y-6">
            {/* Header Stats */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-gradient-to-br from-yellow-500/10 to-orange-500/10 rounded-2xl border border-yellow-500/20 p-5">
                    <div className="flex items-center gap-2 text-yellow-400 mb-2">
                        <Zap className="w-5 h-5" />
                        <span className="text-sm">Active Opportunities</span>
                    </div>
                    <div className="text-3xl font-bold">{totalOpportunities}</div>
                </div>

                <div className="bg-gradient-to-br from-emerald-500/10 to-teal-500/10 rounded-2xl border border-emerald-500/20 p-5">
                    <div className="flex items-center gap-2 text-emerald-400 mb-2">
                        <DollarSign className="w-5 h-5" />
                        <span className="text-sm">Total Potential Profit</span>
                    </div>
                    <div className="text-3xl font-bold">${totalProfit.toFixed(2)}</div>
                </div>

                <div className="bg-gradient-to-br from-blue-500/10 to-indigo-500/10 rounded-2xl border border-blue-500/20 p-5">
                    <div className="flex items-center gap-2 text-blue-400 mb-2">
                        <Percent className="w-5 h-5" />
                        <span className="text-sm">Avg. Profit per Trade</span>
                    </div>
                    <div className="text-3xl font-bold">${avgProfit.toFixed(2)}</div>
                </div>

                <div className="bg-gradient-to-br from-purple-500/10 to-pink-500/10 rounded-2xl border border-purple-500/20 p-5">
                    <div className="flex items-center gap-2 text-purple-400 mb-2">
                        <Clock className="w-5 h-5" />
                        <span className="text-sm">Last Scan</span>
                    </div>
                    <div className="text-xl font-bold">{lastScan.toLocaleTimeString()}</div>
                </div>
            </div>

            {/* Controls */}
            <div className="flex flex-wrap items-center justify-between gap-4 bg-gray-800/50 rounded-2xl border border-gray-700/50 p-4">
                <div className="flex items-center gap-4">
                    <button
                        onClick={handleScan}
                        disabled={isScanning}
                        className="flex items-center gap-2 px-4 py-2 bg-yellow-500 hover:bg-yellow-600 rounded-lg font-medium text-black transition-all disabled:opacity-50"
                    >
                        {isScanning ? (
                            <>
                                <RefreshCw className="w-4 h-4 animate-spin" />
                                Scanning...
                            </>
                        ) : (
                            <>
                                <RefreshCw className="w-4 h-4" />
                                Scan Now
                            </>
                        )}
                    </button>

                    <label className="flex items-center gap-2 cursor-pointer">
                        <input
                            type="checkbox"
                            checked={autoScan}
                            onChange={(e) => setAutoScan(e.target.checked)}
                            className="w-4 h-4 rounded accent-yellow-500"
                        />
                        <span className="text-sm text-gray-400">Auto-scan every 5s</span>
                    </label>
                </div>

                <div className="text-sm text-gray-500">
                    Monitoring 50+ DEX pairs across 5 chains
                </div>
            </div>

            {/* Opportunities List */}
            <div className="bg-gray-800/50 rounded-2xl border border-gray-700/50 overflow-hidden">
                <div className="p-4 border-b border-gray-700/50">
                    <h3 className="text-lg font-bold flex items-center gap-2">
                        <Zap className="w-5 h-5 text-yellow-400" />
                        Arbitrage Opportunities
                    </h3>
                </div>

                <div className="divide-y divide-gray-700/50">
                    {opportunities
                        .sort((a, b) => b.netProfit - a.netProfit)
                        .map((opp) => (
                            <ArbitrageRow key={opp.id} opportunity={opp} />
                        ))}
                </div>
            </div>

            {/* Risk Warning */}
            <div className="flex items-start gap-3 p-4 bg-yellow-500/10 rounded-xl border border-yellow-500/20">
                <AlertTriangle className="w-5 h-5 text-yellow-400 flex-shrink-0 mt-0.5" />
                <div>
                    <div className="font-medium text-yellow-400 mb-1">Risk Warning</div>
                    <div className="text-sm text-gray-400">
                        Arbitrage opportunities can disappear within seconds. Gas prices and network congestion may affect profitability.
                        Always verify current prices before executing trades.
                    </div>
                </div>
            </div>
        </div>
    );
}

function ArbitrageRow({ opportunity }: { opportunity: typeof mockOpportunities[0] }) {
    const [isExecuting, setIsExecuting] = useState(false);
    const timeAgo = Math.floor((Date.now() - opportunity.timestamp) / 1000);

    const handleExecute = async () => {
        setIsExecuting(true);
        await new Promise(resolve => setTimeout(resolve, 2000));
        setIsExecuting(false);
    };

    return (
        <div className="p-4 hover:bg-gray-700/30 transition-all">
            <div className="flex items-center justify-between gap-4 flex-wrap">
                {/* Token Pair & Route */}
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-yellow-500/20 to-orange-500/20 flex items-center justify-center">
                        <TrendingUp className="w-6 h-6 text-yellow-400" />
                    </div>

                    <div>
                        <div className="font-bold text-lg">{opportunity.tokenPair}</div>
                        <div className="flex items-center gap-2 text-sm text-gray-400">
                            <span className="text-blue-400">{opportunity.buyDex}</span>
                            <ArrowRight className="w-4 h-4" />
                            <span className="text-emerald-400">{opportunity.sellDex}</span>
                        </div>
                    </div>
                </div>

                {/* Prices */}
                <div className="flex gap-6">
                    <div className="text-center">
                        <div className="text-xs text-gray-500 mb-1">Buy Price</div>
                        <div className="font-medium text-blue-400">${opportunity.buyPrice.toFixed(2)}</div>
                    </div>
                    <div className="text-center">
                        <div className="text-xs text-gray-500 mb-1">Sell Price</div>
                        <div className="font-medium text-emerald-400">${opportunity.sellPrice.toFixed(2)}</div>
                    </div>
                </div>

                {/* Profit Info */}
                <div className="flex gap-6">
                    <div className="text-center">
                        <div className="text-xs text-gray-500 mb-1">Spread</div>
                        <div className={`font-bold ${opportunity.profitPercent > 0.5 ? "text-emerald-400" : "text-yellow-400"
                            }`}>
                            +{opportunity.profitPercent.toFixed(2)}%
                        </div>
                    </div>
                    <div className="text-center">
                        <div className="text-xs text-gray-500 mb-1">Est. Profit</div>
                        <div className="font-bold text-emerald-400">${opportunity.estimatedProfit.toFixed(2)}</div>
                    </div>
                    <div className="text-center">
                        <div className="text-xs text-gray-500 mb-1">Gas</div>
                        <div className="font-medium text-red-400">-${opportunity.gasEstimate.toFixed(2)}</div>
                    </div>
                    <div className="text-center">
                        <div className="text-xs text-gray-500 mb-1">Net Profit</div>
                        <div className="font-bold text-lg text-emerald-400">${opportunity.netProfit.toFixed(2)}</div>
                    </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-3">
                    <div className={`text-xs px-2 py-1 rounded-full ${opportunity.confidence === "High"
                            ? "bg-emerald-500/20 text-emerald-400"
                            : "bg-yellow-500/20 text-yellow-400"
                        }`}>
                        {opportunity.confidence}
                    </div>

                    <div className="text-xs text-gray-500">{timeAgo}s ago</div>

                    <button
                        onClick={handleExecute}
                        disabled={isExecuting}
                        className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 rounded-lg font-medium text-black transition-all disabled:opacity-50"
                    >
                        {isExecuting ? (
                            <RefreshCw className="w-4 h-4 animate-spin" />
                        ) : (
                            <>
                                <Play className="w-4 h-4" />
                                Execute
                            </>
                        )}
                    </button>
                </div>
            </div>
        </div>
    );
}
