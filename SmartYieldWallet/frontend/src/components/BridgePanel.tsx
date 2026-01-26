"use client";

import { useState } from "react";
import {
    ArrowLeftRight,
    ChevronDown,
    Clock,
    DollarSign,
    Loader2,
    Zap,
    Check,
    AlertCircle
} from "lucide-react";

// 模拟的链数据
const chains = [
    { id: 1, name: "Ethereum", logo: "⟠", color: "from-blue-500 to-indigo-500" },
    { id: 10, name: "Optimism", logo: "🔴", color: "from-red-500 to-red-600" },
    { id: 137, name: "Polygon", logo: "🟣", color: "from-purple-500 to-purple-600" },
    { id: 42161, name: "Arbitrum", logo: "🔵", color: "from-blue-400 to-blue-600" },
    { id: 8453, name: "Base", logo: "🔷", color: "from-blue-500 to-blue-700" },
];

// 模拟的跨链桥数据
const mockBridges = [
    {
        name: "Stargate",
        logo: "⭐",
        fee: 2.5,
        time: "2-5 min",
        success: 99.5,
        isOptimal: true
    },
    {
        name: "Across",
        logo: "🌉",
        fee: 3.2,
        time: "1-2 min",
        success: 99.8,
        isOptimal: false
    },
    {
        name: "Hop Protocol",
        logo: "🐰",
        fee: 4.1,
        time: "5-10 min",
        success: 99.2,
        isOptimal: false
    },
    {
        name: "Celer",
        logo: "🔗",
        fee: 3.8,
        time: "10-20 min",
        success: 98.9,
        isOptimal: false
    },
];

export function BridgePanel() {
    const [amount, setAmount] = useState("");
    const [sourceChain, setSourceChain] = useState(chains[0]);
    const [destChain, setDestChain] = useState(chains[1]);
    const [showSourceDropdown, setShowSourceDropdown] = useState(false);
    const [showDestDropdown, setShowDestDropdown] = useState(false);
    const [isBridging, setIsBridging] = useState(false);
    const [useOptimal, setUseOptimal] = useState(true);

    const handleBridge = async () => {
        setIsBridging(true);
        await new Promise(resolve => setTimeout(resolve, 2000));
        setIsBridging(false);
        setAmount("");
    };

    const swapChains = () => {
        const temp = sourceChain;
        setSourceChain(destChain);
        setDestChain(temp);
    };

    const optimalBridge = mockBridges.find(b => b.isOptimal);

    return (
        <div className="space-y-6">
            {/* Bridge Info Banner */}
            <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 rounded-2xl border border-blue-500/20 p-6">
                <div className="flex items-center gap-3 mb-2">
                    <Zap className="w-6 h-6 text-blue-400" />
                    <h2 className="text-lg font-bold">Smart Bridge Aggregator</h2>
                </div>
                <p className="text-gray-400 text-sm">
                    Automatically finds the cheapest and fastest route across 5+ bridges
                </p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Bridge Form */}
                <div className="bg-gray-800/50 rounded-2xl border border-gray-700/50 p-6">
                    {/* Source Chain */}
                    <div className="mb-4">
                        <label className="text-sm text-gray-400 mb-2 block">From</label>
                        <div className="relative">
                            <button
                                onClick={() => setShowSourceDropdown(!showSourceDropdown)}
                                className="w-full flex items-center justify-between bg-gray-900/50 rounded-xl p-4 hover:bg-gray-900/70 transition-all"
                            >
                                <div className="flex items-center gap-3">
                                    <div className={`w-10 h-10 rounded-full bg-gradient-to-r ${sourceChain.color} flex items-center justify-center text-xl`}>
                                        {sourceChain.logo}
                                    </div>
                                    <span className="font-medium">{sourceChain.name}</span>
                                </div>
                                <ChevronDown className="w-5 h-5 text-gray-400" />
                            </button>

                            {showSourceDropdown && (
                                <ChainDropdown
                                    chains={chains}
                                    onSelect={(chain) => {
                                        setSourceChain(chain);
                                        setShowSourceDropdown(false);
                                    }}
                                    excludeId={destChain.id}
                                />
                            )}
                        </div>
                    </div>

                    {/* Swap Button */}
                    <div className="flex justify-center my-4">
                        <button
                            onClick={swapChains}
                            className="w-10 h-10 rounded-full bg-gray-700 hover:bg-gray-600 flex items-center justify-center transition-all"
                        >
                            <ArrowLeftRight className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Destination Chain */}
                    <div className="mb-4">
                        <label className="text-sm text-gray-400 mb-2 block">To</label>
                        <div className="relative">
                            <button
                                onClick={() => setShowDestDropdown(!showDestDropdown)}
                                className="w-full flex items-center justify-between bg-gray-900/50 rounded-xl p-4 hover:bg-gray-900/70 transition-all"
                            >
                                <div className="flex items-center gap-3">
                                    <div className={`w-10 h-10 rounded-full bg-gradient-to-r ${destChain.color} flex items-center justify-center text-xl`}>
                                        {destChain.logo}
                                    </div>
                                    <span className="font-medium">{destChain.name}</span>
                                </div>
                                <ChevronDown className="w-5 h-5 text-gray-400" />
                            </button>

                            {showDestDropdown && (
                                <ChainDropdown
                                    chains={chains}
                                    onSelect={(chain) => {
                                        setDestChain(chain);
                                        setShowDestDropdown(false);
                                    }}
                                    excludeId={sourceChain.id}
                                />
                            )}
                        </div>
                    </div>

                    {/* Amount Input */}
                    <div className="bg-gray-900/50 rounded-xl p-4 mb-4">
                        <div className="flex items-center justify-between mb-2">
                            <span className="text-sm text-gray-400">Amount (USDC)</span>
                            <button className="text-sm text-blue-400 hover:text-blue-300">MAX</button>
                        </div>
                        <input
                            type="number"
                            value={amount}
                            onChange={(e) => setAmount(e.target.value)}
                            placeholder="0.00"
                            className="w-full bg-transparent text-2xl font-bold outline-none"
                        />
                    </div>

                    {/* Use Optimal Toggle */}
                    <label className="flex items-center gap-3 p-4 bg-blue-500/10 rounded-xl border border-blue-500/20 mb-4 cursor-pointer">
                        <input
                            type="checkbox"
                            checked={useOptimal}
                            onChange={(e) => setUseOptimal(e.target.checked)}
                            className="w-5 h-5 rounded accent-blue-500"
                        />
                        <div>
                            <div className="font-medium flex items-center gap-2">
                                <Zap className="w-4 h-4 text-blue-400" />
                                Use Optimal Route
                            </div>
                            <div className="text-sm text-gray-400">
                                Automatically select the cheapest bridge
                            </div>
                        </div>
                    </label>

                    {/* Bridge Button */}
                    <button
                        onClick={handleBridge}
                        disabled={!amount || isBridging}
                        className="w-full py-4 bg-gradient-to-r from-blue-500 to-purple-500 rounded-xl font-bold text-white
              disabled:opacity-50 disabled:cursor-not-allowed hover:from-blue-600 hover:to-purple-600 transition-all
              flex items-center justify-center gap-2"
                    >
                        {isBridging ? (
                            <>
                                <Loader2 className="w-5 h-5 animate-spin" />
                                Bridging...
                            </>
                        ) : (
                            <>
                                <ArrowLeftRight className="w-5 h-5" />
                                Bridge Assets
                            </>
                        )}
                    </button>
                </div>

                {/* Bridge Comparison */}
                <div className="bg-gray-800/50 rounded-2xl border border-gray-700/50 p-6">
                    <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                        <ArrowLeftRight className="w-5 h-5 text-blue-400" />
                        Bridge Comparison
                    </h3>

                    <div className="space-y-3">
                        {mockBridges.map((bridge) => (
                            <div
                                key={bridge.name}
                                className={`p-4 rounded-xl transition-all cursor-pointer
                  ${bridge.isOptimal
                                        ? "bg-blue-500/10 border border-blue-500/30"
                                        : "bg-gray-900/30 hover:bg-gray-900/50 border border-transparent"
                                    }`}
                            >
                                <div className="flex items-center justify-between mb-3">
                                    <div className="flex items-center gap-3">
                                        <span className="text-2xl">{bridge.logo}</span>
                                        <div>
                                            <div className="font-medium flex items-center gap-2">
                                                {bridge.name}
                                                {bridge.isOptimal && (
                                                    <span className="text-xs bg-blue-500 text-white px-2 py-0.5 rounded-full flex items-center gap-1">
                                                        <Check className="w-3 h-3" />
                                                        CHEAPEST
                                                    </span>
                                                )}
                                            </div>
                                            <div className="text-sm text-gray-500">
                                                Success Rate: {bridge.success}%
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="bg-gray-800/50 rounded-lg p-2">
                                        <div className="text-xs text-gray-500 flex items-center gap-1">
                                            <DollarSign className="w-3 h-3" />
                                            Fee
                                        </div>
                                        <div className={`font-bold ${bridge.isOptimal ? "text-blue-400" : ""}`}>
                                            ${bridge.fee.toFixed(2)}
                                        </div>
                                    </div>
                                    <div className="bg-gray-800/50 rounded-lg p-2">
                                        <div className="text-xs text-gray-500 flex items-center gap-1">
                                            <Clock className="w-3 h-3" />
                                            Time
                                        </div>
                                        <div className="font-bold">{bridge.time}</div>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>

                    {/* Savings Banner */}
                    {optimalBridge && (
                        <div className="mt-4 p-4 bg-gradient-to-r from-emerald-500/10 to-blue-500/10 rounded-xl border border-emerald-500/20">
                            <div className="flex items-center gap-2 text-emerald-400 mb-1">
                                <Check className="w-4 h-4" />
                                <span className="text-sm font-medium">Potential Savings</span>
                            </div>
                            <div className="text-lg font-bold">
                                Save up to ${(4.1 - 2.5).toFixed(2)} using {optimalBridge.name}
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

function ChainDropdown({
    chains,
    onSelect,
    excludeId
}: {
    chains: typeof chains; // Using typeof to maintain type
    onSelect: (chain: typeof chains[0]) => void;
    excludeId: number;
}) {
    return (
        <div className="absolute top-full left-0 right-0 mt-2 bg-gray-800 rounded-xl border border-gray-700 overflow-hidden z-50">
            {chains.filter(c => c.id !== excludeId).map((chain) => (
                <button
                    key={chain.id}
                    onClick={() => onSelect(chain)}
                    className="w-full flex items-center gap-3 p-3 hover:bg-gray-700/50 transition-all"
                >
                    <div className={`w-8 h-8 rounded-full bg-gradient-to-r ${chain.color} flex items-center justify-center text-lg`}>
                        {chain.logo}
                    </div>
                    <span className="font-medium">{chain.name}</span>
                </button>
            ))}
        </div>
    );
}
