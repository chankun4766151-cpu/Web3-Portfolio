"use client";

import { useState } from "react";
import {
    TrendingUp,
    ArrowUpRight,
    ArrowDownRight,
    Shield,
    Percent,
    ChevronDown,
    Loader2
} from "lucide-react";

// 模拟的收益协议数据
const mockProtocols = [
    { name: "Aave V3", apy: 5.23, tvl: "$2.1B", risk: "Low", logo: "🏦" },
    { name: "Compound", apy: 4.87, tvl: "$1.8B", risk: "Low", logo: "📊" },
    { name: "Lido", apy: 4.12, tvl: "$15.2B", risk: "Low", logo: "🌊" },
    { name: "Yearn", apy: 8.45, tvl: "$450M", risk: "Medium", logo: "💎" },
    { name: "Convex", apy: 12.34, tvl: "$3.2B", risk: "Medium", logo: "🔺" },
];

export function YieldVault() {
    const [amount, setAmount] = useState("");
    const [isDepositing, setIsDepositing] = useState(false);
    const [activeTab, setActiveTab] = useState<"deposit" | "withdraw">("deposit");

    // 模拟数据
    const userBalance = 10250.45;
    const totalEarnings = 1250.45;
    const currentAPY = 8.45;
    const optimalProtocol = mockProtocols[3]; // Yearn

    const handleDeposit = async () => {
        setIsDepositing(true);
        // 模拟交易
        await new Promise(resolve => setTimeout(resolve, 2000));
        setIsDepositing(false);
        setAmount("");
    };

    return (
        <div className="space-y-6">
            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <StatCard
                    title="Total Balance"
                    value={`$${userBalance.toLocaleString()}`}
                    change="+12.5%"
                    positive
                    icon={<TrendingUp className="w-5 h-5" />}
                />
                <StatCard
                    title="Total Earnings"
                    value={`$${totalEarnings.toLocaleString()}`}
                    change="+$45.23 today"
                    positive
                    icon={<ArrowUpRight className="w-5 h-5" />}
                />
                <StatCard
                    title="Current APY"
                    value={`${currentAPY}%`}
                    subtitle={`via ${optimalProtocol.name}`}
                    icon={<Percent className="w-5 h-5" />}
                />
            </div>

            {/* Main Content */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Deposit/Withdraw Panel */}
                <div className="bg-gray-800/50 rounded-2xl border border-gray-700/50 p-6">
                    <div className="flex gap-2 mb-6">
                        <button
                            onClick={() => setActiveTab("deposit")}
                            className={`flex-1 py-2 rounded-lg font-medium transition-all ${activeTab === "deposit"
                                    ? "bg-emerald-500 text-white"
                                    : "bg-gray-700/50 text-gray-400 hover:text-white"
                                }`}
                        >
                            Deposit
                        </button>
                        <button
                            onClick={() => setActiveTab("withdraw")}
                            className={`flex-1 py-2 rounded-lg font-medium transition-all ${activeTab === "withdraw"
                                    ? "bg-emerald-500 text-white"
                                    : "bg-gray-700/50 text-gray-400 hover:text-white"
                                }`}
                        >
                            Withdraw
                        </button>
                    </div>

                    {/* Token Selector */}
                    <div className="flex items-center justify-between bg-gray-900/50 rounded-xl p-4 mb-4">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-blue-500/20 flex items-center justify-center text-xl">
                                💎
                            </div>
                            <div>
                                <div className="font-medium">USDC</div>
                                <div className="text-sm text-gray-500">Balance: 5,000.00</div>
                            </div>
                        </div>
                        <ChevronDown className="w-5 h-5 text-gray-400" />
                    </div>

                    {/* Amount Input */}
                    <div className="bg-gray-900/50 rounded-xl p-4 mb-4">
                        <div className="flex items-center justify-between mb-2">
                            <span className="text-sm text-gray-400">Amount</span>
                            <button className="text-sm text-emerald-400 hover:text-emerald-300">
                                MAX
                            </button>
                        </div>
                        <input
                            type="number"
                            value={amount}
                            onChange={(e) => setAmount(e.target.value)}
                            placeholder="0.00"
                            className="w-full bg-transparent text-2xl font-bold outline-none"
                        />
                    </div>

                    {/* Optimal Protocol Info */}
                    <div className="bg-emerald-500/10 rounded-xl p-4 mb-4 border border-emerald-500/20">
                        <div className="flex items-center gap-2 text-emerald-400 mb-2">
                            <Shield className="w-4 h-4" />
                            <span className="text-sm font-medium">Optimal Strategy Selected</span>
                        </div>
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <span className="text-xl">{optimalProtocol.logo}</span>
                                <span className="font-medium">{optimalProtocol.name}</span>
                            </div>
                            <div className="text-right">
                                <div className="text-emerald-400 font-bold">{optimalProtocol.apy}% APY</div>
                                <div className="text-xs text-gray-500">TVL: {optimalProtocol.tvl}</div>
                            </div>
                        </div>
                    </div>

                    {/* Submit Button */}
                    <button
                        onClick={handleDeposit}
                        disabled={!amount || isDepositing}
                        className="w-full py-4 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-xl font-bold text-white
              disabled:opacity-50 disabled:cursor-not-allowed hover:from-emerald-600 hover:to-teal-600 transition-all
              flex items-center justify-center gap-2"
                    >
                        {isDepositing ? (
                            <>
                                <Loader2 className="w-5 h-5 animate-spin" />
                                Processing...
                            </>
                        ) : (
                            activeTab === "deposit" ? "Deposit & Earn" : "Withdraw"
                        )}
                    </button>
                </div>

                {/* Protocol Comparison */}
                <div className="bg-gray-800/50 rounded-2xl border border-gray-700/50 p-6">
                    <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                        <TrendingUp className="w-5 h-5 text-emerald-400" />
                        Yield Protocols
                    </h3>

                    <div className="space-y-3">
                        {mockProtocols.map((protocol, index) => (
                            <div
                                key={protocol.name}
                                className={`flex items-center justify-between p-4 rounded-xl transition-all cursor-pointer
                  ${index === 3
                                        ? "bg-emerald-500/10 border border-emerald-500/30"
                                        : "bg-gray-900/30 hover:bg-gray-900/50 border border-transparent"
                                    }`}
                            >
                                <div className="flex items-center gap-3">
                                    <span className="text-2xl">{protocol.logo}</span>
                                    <div>
                                        <div className="font-medium flex items-center gap-2">
                                            {protocol.name}
                                            {index === 3 && (
                                                <span className="text-xs bg-emerald-500 text-white px-2 py-0.5 rounded-full">
                                                    OPTIMAL
                                                </span>
                                            )}
                                        </div>
                                        <div className="text-sm text-gray-500">TVL: {protocol.tvl}</div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className={`font-bold ${index === 3 ? "text-emerald-400" : "text-white"}`}>
                                        {protocol.apy}%
                                    </div>
                                    <div className={`text-xs ${protocol.risk === "Low" ? "text-green-400" : "text-yellow-400"
                                        }`}>
                                        {protocol.risk} Risk
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}

function StatCard({
    title,
    value,
    change,
    subtitle,
    positive = true,
    icon,
}: {
    title: string;
    value: string;
    change?: string;
    subtitle?: string;
    positive?: boolean;
    icon: React.ReactNode;
}) {
    return (
        <div className="bg-gray-800/50 rounded-2xl border border-gray-700/50 p-6">
            <div className="flex items-center justify-between mb-4">
                <span className="text-gray-400 text-sm">{title}</span>
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center
          ${positive ? "bg-emerald-500/10 text-emerald-400" : "bg-red-500/10 text-red-400"}`}
                >
                    {icon}
                </div>
            </div>
            <div className="text-2xl font-bold mb-1">{value}</div>
            {change && (
                <div className={`text-sm flex items-center gap-1 ${positive ? "text-emerald-400" : "text-red-400"
                    }`}>
                    {positive ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
                    {change}
                </div>
            )}
            {subtitle && <div className="text-sm text-gray-500">{subtitle}</div>}
        </div>
    );
}
