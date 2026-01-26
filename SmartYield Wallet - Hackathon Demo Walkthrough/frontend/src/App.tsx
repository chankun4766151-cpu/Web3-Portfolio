import { useState } from 'react';
import Navbar from './components/Navbar/Navbar';
import Dashboard from './components/Dashboard/Dashboard';
import YieldPage from './components/YieldPage/YieldPage';
import BridgePage from './components/BridgePage/BridgePage';
import ArbitragePage from './components/ArbitragePage/ArbitragePage';
import './index.css';

function App() {
  const [walletAddress, setWalletAddress] = useState<string>();

  const handleConnect = () => {
    // Mock wallet connection for demo
    const mockAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb';
    setWalletAddress(mockAddress);
  };

  return (
    <div className="app">
      <Navbar walletAddress={walletAddress} onConnect={handleConnect} />
      <main>
        <Dashboard />
        <YieldPage />
        <BridgePage />
        <ArbitragePage />
      </main>
      <footer style={{
        textAlign: 'center',
        padding: 'var(--spacing-2xl)',
        color: 'var(--text-tertiary)',
        borderTop: '1px solid var(--glass-border)'
      }}>
        <p>SmartYield Wallet - Hackathon Demo 2026</p>
        <p style={{ fontSize: '0.875rem', marginTop: 'var(--spacing-sm)' }}>
          Powered by AI • Secured by Smart Contracts
        </p>
      </footer>
    </div>
  );
}

export default App;
