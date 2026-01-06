import { useState } from 'react'
import { useAppKit } from '@reown/appkit/react'
import { useAccount, useDisconnect } from 'wagmi'
import ListNFT from './pages/ListNFT'
import BuyNFT from './pages/BuyNFT'
import MintNFT from './pages/MintNFT'
import './App.css'

type Page = 'mint' | 'list' | 'buy'

function App() {
  const [currentPage, setCurrentPage] = useState<Page>('mint')
  const { open } = useAppKit()
  const { address, isConnected } = useAccount()
  const { disconnect } = useDisconnect()

  return (
    <div className="app">
      <header>
        <h1>🎨 NFT Market</h1>
        <nav>
          <button onClick={() => setCurrentPage('mint')}>Mint</button>
          <button onClick={() => setCurrentPage('list')}>List NFT</button>
          <button onClick={() => setCurrentPage('buy')}>Buy NFT</button>
        </nav>
        <div className="wallet-section">
          {isConnected && address ? (
            <div className="connected">
              <span className="address">{address.slice(0, 6)}...{address.slice(-4)}</span>
              <button onClick={() => disconnect()}>Disconnect</button>
            </div>
          ) : (
            <button className="connect-btn" onClick={() => open()}>
              Connect Wallet
            </button>
          )}
        </div>
      </header>

      <main>
        {currentPage === 'mint' && <MintNFT />}
        {currentPage === 'list' && <ListNFT />}
        {currentPage === 'buy' && <BuyNFT />}
      </main>

      <footer>
        <p>Built with AppKit & WalletConnect</p>
      </footer>
    </div>
  )
}

export default App
