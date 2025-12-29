import { http, createConfig } from 'wagmi'
import { mainnet, sepolia, anvil } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'

export const config = createConfig({
  chains: [mainnet, sepolia, anvil],
  connectors: [
    injected(),
  ],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [anvil.id]: http(),
  },
})
