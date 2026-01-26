# Cross-Chain Token Bridge Assignment

This project demonstrates how to deploy an ERC20 token on Ethereum Sepolia (L1) and bridge it to Optimism Sepolia (L2) using the standard Optimism bridge.

## 📋 Assignment Overview

Complete the following steps:
1. ✅ Deploy your own L1 Token on Sepolia
2. ✅ Use OptimismMintableERC20Factory to create L2 Token
3. ✅ Authorize L1StandardBridge to spend your tokens
4. ✅ Call bridgeERC20 on L1StandardBridge

## 🛠️ Prerequisites

- Node.js v16 or higher
- Sepolia ETH (from [Sepolia Faucet](https://sepoliafaucet.com))
- OP Sepolia ETH (from [Alchemy Faucet](https://www.alchemy.com/faucets/optimism-sepolia))
- Etherscan API key (optional, for contract verification)

## 📦 Installation

```bash
npm install
```

## ⚙️ Configuration

1. Copy the environment template:
```bash
cp .env.example .env
```

2. Edit `.env` and add your private key:
```
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://rpc.sepolia.org
OP_SEPOLIA_RPC_URL=https://sepolia.optimism.io
ETHERSCAN_API_KEY=your_etherscan_api_key_optional
OPTIMISM_ETHERSCAN_API_KEY=your_optimism_etherscan_api_key_optional
```

**⚠️ Security Warning**: Never commit your `.env` file or share your private key!

## 🚀 Usage

### Step 1: Deploy L1 Token

Deploy MyToken contract to Ethereum Sepolia:

```bash
npx hardhat run scripts/1-deployL1Token.js --network sepolia
```

**What this does:**
- Deploys an ERC20 token with 1,000,000 MTK initial supply
- Verifies the contract on Etherscan
- Outputs the L1 token address

**Save the L1 token address** - you'll need it for the next step!

### Step 2: Create L2 Token

Before running this script, add your L1 token address to `.env`:
```
L1_TOKEN_ADDRESS=0x...  # Your address from Step 1
```

Then create the L2 token on Optimism Sepolia:

```bash
npx hardhat run scripts/2-createL2Token.js --network optimismSepolia
```

**What this does:**
- Calls OptimismMintableERC20Factory on L2
- Creates a bridgeable ERC20 token that mirrors your L1 token
- Outputs the L2 token address

**Save the L2 token address** - you'll need it for bridging!

### Step 3 & 4: Bridge Tokens

Add both token addresses to `.env`:
```
L1_TOKEN_ADDRESS=0x...  # From Step 1
L2_TOKEN_ADDRESS=0x...  # From Step 2
BRIDGE_AMOUNT=100       # Amount to bridge (in tokens, not wei)
```

Then run the bridge script:

```bash
npx hardhat run scripts/3-bridgeTokens.js --network sepolia
```

**What this does:**
- Approves L1StandardBridge to spend your tokens (Step 3)
- Calls bridgeERC20 to transfer tokens to L2 (Step 4)
- Outputs both L1 and L2 transaction links

**Wait 1-3 minutes** for the L2 transaction to appear!

## 🔍 Monitoring Your Bridge Transaction

After running the bridge script:

1. **L1 Transaction (Immediate):** Check the Sepolia Etherscan link provided
2. **L2 Transaction (1-3 minutes):** 
   - Go to https://sepolia-optimism.etherscan.io
   - Search for your wallet address
   - Look for a token transfer transaction

## 📝 Key Contract Addresses

### Ethereum Sepolia (L1)
- **L1StandardBridge:** `0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1`

### Optimism Sepolia (L2)
- **OptimismMintableERC20Factory:** `0x4200000000000000000000000000000000000012`
- **L2StandardBridge:** `0x4200000000000000000000000000000000000010`

## 📚 Educational Explanations

### What is the L1StandardBridge?

The L1StandardBridge is the main contract for moving tokens from Ethereum (L1) to Optimism (L2). When you call `bridgeERC20`:
1. Your tokens are **locked** on L1 in the bridge contract
2. A message is sent to L2 via the CrossDomainMessenger
3. The L2StandardBridge **mints** equivalent tokens on L2

### Why use OptimismMintableERC20Factory?

Before you can bridge custom tokens, there needs to be a corresponding token on L2. The factory:
- Creates a standardized L2 token that implements `IOptimismMintableERC20`
- Gives the L2 bridge permission to mint/burn tokens
- Ensures compatibility with the bridge infrastructure

### How long does bridging take?

- **L1 → L2:** Approximately 1-3 minutes after L1 confirmation
- **L2 → L1:** ~7 days due to the fraud-proof challenge period

### What are the gas costs?

On testnet, approximate costs:
- Deploy L1 token: ~0.01-0.02 ETH
- Create L2 token: ~0.0001 ETH
- Approve + Bridge: ~0.005-0.01 ETH

## 🗂️ Project Structure

```
SuperbridgeMint/
├── contracts/
│   └── MyToken.sol              # ERC20 token contract
├── scripts/
│   ├── 1-deployL1Token.js       # Deploy token to L1
│   ├── 2-createL2Token.js       # Create L2 token via factory
│   └── 3-bridgeTokens.js        # Approve & bridge tokens
├── hardhat.config.js            # Network configuration
├── .env.example                 # Environment template
├── package.json
└── README.md
```

## 🆘 Troubleshooting

### "Insufficient funds" error
- Ensure you have enough Sepolia ETH for gas fees
- For L2 operations, ensure you have OP Sepolia ETH

### "Invalid name" npm error
- The directory name contains special characters
- We've created the project in `SuperbridgeMint` without special chars

### L2 transaction not appearing
- Bridge transactions take 1-3 minutes to finalize on L2
- Check your address on OP Sepolia explorer for token transfers
- The transaction WILL appear - just be patient!

### Contract verification failed
- This is optional and doesn't affect functionality
- Ensure you have a valid Etherscan API key in `.env`
- You can manually verify later on Etherscan

## 📖 Additional Resources

- [Optimism Bridge Documentation](https://docs.optimism.io/builders/app-developers/bridging/standard-bridge)
- [Optimism Contract Addresses](https://docs.optimism.io/chain/addresses)
- [Optimism Sepolia Explorer](https://sepolia-optimism.etherscan.io)
- [Sepolia Testnet Explorer](https://sepolia.etherscan.io)

## 📄 License

MIT
