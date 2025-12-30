'use client';

import { WagmiProvider, createConfig, http } from 'wagmi';
import { sepolia } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit';
import { useState } from 'react';
import '@rainbow-me/rainbowkit/styles.css';

/**
 * wagmi 配置
 * 
 * 说明：
 * - 使用 Sepolia 测试网
 * - RainbowKit 提供钱包连接 UI
 * - 你需要从 WalletConnect Cloud 获取免费的 projectId
 *   https://cloud.walletconnect.com
 */

const config = getDefaultConfig({
    appName: 'TokenBank Permit2',
    projectId: '2582d3be264a721da8a61be149d70eaa', // 👈 替换为你的 WalletConnect Project ID
    chains: [sepolia],
    transports: {
        [sepolia.id]: http(),
    },
    ssr: true,
});

export function Providers({ children }: { children: React.ReactNode }) {
    const [queryClient] = useState(() => new QueryClient());

    return (
        <WagmiProvider config={config}>
            <QueryClientProvider client={queryClient}>
                <RainbowKitProvider>
                    {children}
                </RainbowKitProvider>
            </QueryClientProvider>
        </WagmiProvider>
    );
}
