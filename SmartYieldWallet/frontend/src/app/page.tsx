"use client";

import { useState } from "react";
import { Header } from "@/components/Header";
import { YieldVault } from "@/components/YieldVault";
import { BridgePanel } from "@/components/BridgePanel";
import { ArbitragePanel } from "@/components/ArbitragePanel";
import { TrendingUp, ArrowLeftRight, Zap, Sparkles } from "lucide-react";

type TabType = "yield" | "bridge" | "arbitrage";

export default function Home() {
  const [activeTab, setActiveTab] = useState<TabType>("yield");

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-gray-950">
      <Header />

      {/* Main Content */}
      <main className="pt-24 pb-12 px-6">
        <div className="max-w-7xl mx-auto">
          {/* Hero Section */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-500/10 rounded-full border border-emerald-500/20 text-emerald-400 text-sm mb-4">
              <Sparkles className="w-4 h-4" />
              Smart Banking. Institutional Yield. For Everyone.
            </div>
            <h1 className="text-4xl md:text-5xl font-bold mb-4 bg-gradient-to-r from-white via-emerald-200 to-teal-200 bg-clip-text text-transparent">
              SmartYield Wallet
            </h1>
            <p className="text-gray-400 text-lg max-w-2xl mx-auto">
              Maximize your returns with automated yield optimization, cross-chain bridging,
              and real-time arbitrage opportunities.
            </p>
          </div>

          {/* Tab Navigation */}
          <div className="flex justify-center mb-8">
            <div className="inline-flex p-1 bg-gray-800/50 rounded-2xl border border-gray-700/50">
              <TabButton
                active={activeTab === "yield"}
                onClick={() => setActiveTab("yield")}
                icon={<TrendingUp className="w-5 h-5" />}
                label="Yield Vault"
                color="emerald"
              />
              <TabButton
                active={activeTab === "bridge"}
                onClick={() => setActiveTab("bridge")}
                icon={<ArrowLeftRight className="w-5 h-5" />}
                label="Bridge"
                color="blue"
              />
              <TabButton
                active={activeTab === "arbitrage"}
                onClick={() => setActiveTab("arbitrage")}
                icon={<Zap className="w-5 h-5" />}
                label="Arbitrage"
                color="yellow"
              />
            </div>
          </div>

          {/* Tab Content */}
          <div className="animate-fadeIn">
            {activeTab === "yield" && <YieldVault />}
            {activeTab === "bridge" && <BridgePanel />}
            {activeTab === "arbitrage" && <ArbitragePanel />}
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-800 py-8 px-6">
        <div className="max-w-7xl mx-auto text-center text-gray-500 text-sm">
          <p>SmartYield Wallet © 2025 | Built for ETH Hackathon</p>
          <p className="mt-2">
            Powered by Aave, Compound, Stargate, Uniswap, and more.
          </p>
        </div>
      </footer>
    </div>
  );
}

function TabButton({
  active,
  onClick,
  icon,
  label,
  color,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  label: string;
  color: "emerald" | "blue" | "yellow";
}) {
  const colorClasses = {
    emerald: "from-emerald-500 to-teal-500 text-white",
    blue: "from-blue-500 to-indigo-500 text-white",
    yellow: "from-yellow-500 to-orange-500 text-black",
  };

  return (
    <button
      onClick={onClick}
      className={`
        flex items-center gap-2 px-6 py-3 rounded-xl font-medium transition-all duration-300
        ${active
          ? `bg-gradient-to-r ${colorClasses[color]} shadow-lg`
          : "text-gray-400 hover:text-white hover:bg-gray-700/50"
        }
      `}
    >
      {icon}
      <span className="hidden sm:inline">{label}</span>
    </button>
  );
}
