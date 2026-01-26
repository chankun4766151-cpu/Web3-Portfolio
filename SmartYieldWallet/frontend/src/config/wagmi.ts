"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, optimismSepolia, mainnet, optimism, arbitrum, base, polygon } from "wagmi/chains";

export const config = getDefaultConfig({
    appName: "SmartYield Wallet",
    projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "demo-project-id",
    chains: [sepolia, optimismSepolia, mainnet, optimism, arbitrum, base, polygon],
    ssr: true,
});
