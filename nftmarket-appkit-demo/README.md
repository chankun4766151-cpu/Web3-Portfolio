# NFT Market with AppKit

A decentralized NFT marketplace built with Solidity smart contracts and React frontend, integrated with Reown AppKit (formerly WalletConnect AppKit) for wallet connections.

## Features

- 🎨 Mint NFTs
- 📝 List NFTs for sale
- 💰 Buy NFTs with ERC20 tokens
- 🔐 WalletConnect integration via AppKit
- 📱 Mobile wallet support

## Project Structure

```
nftmarket-appkit-demo/
├── src/                    # Smart contracts
│   ├── MyERC20.sol        # ERC20 payment token
│   ├── MyNFT.sol          # ERC721 NFT contract
│   └── NFTMarket.sol      # Marketplace contract
├── script/                 # Deployment scripts
│   └── Deploy.s.sol
├── test/                   # Contract tests
│   └── NFTMarket.t.sol
└── frontend/              # React frontend
    └── src/
        ├── pages/         # Page components
        ├── config/        # Web3 configuration
        └── App.tsx        # Main app
```

## Smart Contracts

- **MyERC20**: Payment token for purchasing NFTs
- **MyNFT**: ERC721 NFT with minting capability
- **NFTMarket**: Marketplace for listing and buying NFTs

## Setup

### Prerequisites

- Node.js 16+
- Foundry (for smart contracts)
- A WalletConnect Project ID from [Reown Cloud](https://cloud.reown.com)

### Installation

1. Clone the repository
2. Install dependencies:

```bash
# Install Foundry dependencies
forge install

# Install frontend dependencies
cd frontend
npm install
```

3. Set up environment variables:

```bash
# Copy .env.example to .env
cp .env.example .env

# Edit .env and add:
# - Your private key for deployment
# - Sepolia RPC URL
# - WalletConnect Project ID
```

### Running Tests

```bash
forge test -vv
```

### Deployment

Deploy contracts to Sepolia:

```bash
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast
```

Update `frontend/.env` with deployed contract addresses.

### Running Frontend

```bash
cd frontend
npm run dev
```

## Usage

1. **Connect Wallet**: Click "Connect Wallet" and scan QR code with mobile wallet
2. **Mint NFT**: Go to Mint page and create test NFTs
3. **Mint Tokens**: Mint ERC20 tokens for purchasing
4. **List NFT**: Approve and list your NFT for sale
5. **Buy NFT**: Switch accounts and purchase listed NFTs

## Technologies

- **Smart Contracts**: Solidity, Foundry, OpenZeppelin
- **Frontend**: React, TypeScript, Vite
- **Web3**: Reown AppKit, Wagmi, Viem
- **Network**: Ethereum Sepolia Testnet

## License

MIT
