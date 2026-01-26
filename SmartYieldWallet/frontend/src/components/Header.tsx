"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Wallet, TrendingUp, ArrowLeftRight, Zap } from "lucide-react";

export function Header() {
    return (
        <header className="fixed top-0 left-0 right-0 z-50 bg-gray-900/80 backdrop-blur-xl border-b border-gray-800">
            <div className="max-w-7xl mx-auto px-6 py-4">
                <div className="flex items-center justify-between">
                    {/* Logo */}
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
                            <Wallet className="w-5 h-5 text-white" />
                        </div>
                        <div>
                            <h1 className="text-xl font-bold bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">
                                SmartYield
                            </h1>
                            <p className="text-xs text-gray-500">Institutional Yield. For Everyone.</p>
                        </div>
                    </div>

                    {/* Navigation */}
                    <nav className="hidden md:flex items-center gap-1">
                        <NavItem icon={<TrendingUp className="w-4 h-4" />} label="Yield Vault" active />
                        <NavItem icon={<ArrowLeftRight className="w-4 h-4" />} label="Bridge" />
                        <NavItem icon={<Zap className="w-4 h-4" />} label="Arbitrage" />
                    </nav>

                    {/* Wallet */}
                    <ConnectButton
                        chainStatus="icon"
                        showBalance={false}
                    />
                </div>
            </div>
        </header>
    );
}

function NavItem({
    icon,
    label,
    active = false
}: {
    icon: React.ReactNode;
    label: string;
    active?: boolean;
}) {
    return (
        <button
            className={`
        flex items-center gap-2 px-4 py-2 rounded-lg transition-all duration-200
        ${active
                    ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                    : "text-gray-400 hover:text-gray-200 hover:bg-gray-800"
                }
      `}
        >
            {icon}
            <span className="text-sm font-medium">{label}</span>
        </button>
    );
}
