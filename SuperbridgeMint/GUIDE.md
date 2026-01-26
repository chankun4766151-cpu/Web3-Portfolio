# Step-by-Step Execution Guide

This guide will walk you through executing each step of the cross-chain token bridging assignment.

## Prerequisites Checklist

Before starting, ensure you have:
- [ ] Sepolia ETH in your wallet (get from https://sepoliafaucet.com)
- [ ] OP Sepolia ETH in your wallet (get from https://www.alchemy.com/faucets/optimism-sepolia)
- [ ] Created `.env` file with your `PRIVATE_KEY`
- [ ] Installed dependencies with `npm install`

## Step 1: Deploy L1 Token to Sepolia

**Command:**
```bash
npx hardhat run scripts/1-deployL1Token.js --network sepolia
```

**What happens:**
- Deploys MyToken ERC20 contract to Sepolia
- Mints 1,000,000 MTK to your address
- Attempts to verify on Etherscan (optional)

**Expected output:**
```
✅ MyToken deployed to: 0x...
```

**Action required:**
1. Copy the deployed contract address
2. Add to `.env` file:
   ```
   L1_TOKEN_ADDRESS=0xYourTokenAddress
   ```

---

## Step 2: Create L2 Token on Optimism Sepolia

**Command:**
```bash
npx hardhat run scripts/2-createL2Token.js --network optimismSepolia
```

**What happens:**
- Connects to OptimismMintableERC20Factory on L2
- Creates a bridgeable ERC20 token linked to your L1 token
- Returns the L2 token address from the event

**Expected output:**
```
✅ L2 Token Created Successfully!
📍 L2 Token Address: 0x...
```

**Action required:**
1. Copy the L2 token address
2. Add to `.env` file:
   ```
   L2_TOKEN_ADDRESS=0xYourL2TokenAddress
   ```

---

## Step 3 & 4: Bridge Tokens from L1 to L2

**Command:**
```bash
npx hardhat run scripts/3-bridgeTokens.js --network sepolia
```

**What happens:**
1. **Step 3:** Approves L1StandardBridge to spend 100 MTK
2. **Step 4:** Calls `bridgeERC20` to transfer tokens
3. Tokens are locked on L1
4. Message sent to L2 to mint tokens

**Expected output:**
```
✅ BRIDGE TRANSACTION SUCCESSFUL!
📋 L1 Transaction (Sepolia):
   🔗 Explorer: https://sepolia.etherscan.io/tx/0x...

⏳ Waiting for L2 transaction...
   The L2 transaction will appear in 1-3 minutes
```

**Action required:**
1. Save the L1 transaction link for your assignment
2. Wait 1-3 minutes
3. Check your address on OP Sepolia explorer for the L2 transaction
4. Save the L2 transaction link

---

## Finding Your L2 Transaction

After 1-3 minutes, your tokens will arrive on L2:

1. Go to OP Sepolia Explorer:
   ```
   https://sepolia-optimism.etherscan.io/address/YOUR_ADDRESS#tokentxns
   ```

2. Look for a transaction showing:
   - **Type:** Token Transfer (ERC-20)
   - **Token:** MTK
   - **Amount:** 100 MTK
   - **From:** L2StandardBridge
   - **To:** Your address

3. Click on the transaction hash to get the L2 transaction link

---

## Assignment Submission

Submit these two links:

### L1 Transaction Link (Step 4)
```
https://sepolia.etherscan.io/tx/0x[YOUR_TX_HASH]
```
This shows the `bridgeERC20` call on Sepolia

### L2 Transaction Link
```
https://sepolia-optimism.etherscan.io/tx/0x[YOUR_L2_TX_HASH]
```
This shows the token mint on Optimism Sepolia

---

## Troubleshooting

### "Insufficient funds" error
- Check Sepolia ETH balance: Need ~0.01 ETH for gas
- For L2 operations: Need OP Sepolia ETH

### "L1_TOKEN_ADDRESS not set" error
- Make sure you added the address to `.env` file
- No quotes needed, just: `L1_TOKEN_ADDRESS=0x...`

### L2 transaction not appearing
- Be patient! It can take up to 3 minutes
- Check your token transfers, not regular transactions
- Use the token transfers tab in OP Sepolia explorer

### Contract verification failed
- This is optional and doesn't affect functionality
- The contract still works even without verification
- You can manually verify later on Etherscan if needed

---

## Understanding Each Step

### Why deploy our own token?
To practice the bridging mechanism, you need to own a token. Standard tokens like USDC already have bridge support, but for learning, we create our own.

### Why use OptimismMintableERC20Factory?
The L2 token must implement special interfaces that allow the bridge to mint/burn tokens. The factory creates a properly configured token for us.

### Why approve before bridging?
The bridge needs permission to transfer your tokens from your wallet. The `approve` function grants this permission (standard ERC20 pattern).

### How does bridging work?
1. L1: Your tokens are locked in L1StandardBridge
2. L1: A message is sent via CrossDomainMessenger
3. L2: L2StandardBridge receives the message
4. L2: Bridge mints equivalent tokens to your address

The whole process is trustless and secured by Optimism's fraud-proof system.

---

## Next Steps (Optional)

Want to bridge tokens back from L2 to L1?

1. The process is similar but in reverse
2. Call `bridgeERC20` on L2StandardBridge
3. Wait ~7 days for the challenge period
4. Claim your tokens on L1

Note: L2 → L1 takes much longer (7 days) due to the fraud-proof security mechanism.
