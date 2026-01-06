import { createAppKit } from '@reown/appkit/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { WagmiProvider } from 'wagmi'
import { projectId, wagmiAdapter, networks } from './config/wagmi'
import App from './App'

const queryClient = new QueryClient()

// Create the AppKit instance
createAppKit({
    adapters: [wagmiAdapter],
    projectId,
    networks,
    defaultNetwork: networks[0],
    metadata: {
        name: 'NFT Market',
        description: 'NFT Marketplace with AppKit',
        url: 'https://nftmarket.example',
        icons: ['https://avatars.githubusercontent.com/u/37784886']
    },
    features: {
        analytics: true
    }
})

function AppProvider() {
    return (
        <WagmiProvider config={wagmiAdapter.wagmiConfig}>
            <QueryClientProvider client={queryClient}>
                <App />
            </QueryClientProvider>
        </WagmiProvider>
    )
}

export default AppProvider
