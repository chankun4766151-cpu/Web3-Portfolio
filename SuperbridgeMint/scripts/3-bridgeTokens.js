const hre = require("hardhat");

/**
 * Script to approve and bridge tokens from L1 (Sepolia) to L2 (Optimism Sepolia)
 * 
 * This combines Steps 3 & 4 of the cross-chain bridging process:
 * - Step 3: Approve L1StandardBridge to spend your tokens
 * - Step 4: Call bridgeERC20 to initiate the cross-chain transfer
 * 
 * What this does:
 * - Approves the L1StandardBridge contract to spend your L1 tokens
 * - Calls bridgeERC20 to lock tokens on L1 and mint them on L2
 * - The bridge will automatically mint equivalent tokens on L2 after ~1-3 minutes
 * 
 * How it works:
 * 1. Your tokens are locked in the L1StandardBridge on Sepolia
 * 2. A message is sent to L2 via the CrossDomainMessenger
 * 3. The L2StandardBridge receives the message and mints tokens to your address
 * 
 * @param {string} L1_TOKEN_ADDRESS - Your L1 token address from Step 1
 * @param {string} L2_TOKEN_ADDRESS - Your L2 token address from Step 2
 * @param {string} BRIDGE_AMOUNT - Amount of tokens to bridge (in ether units, e.g., "100")
 */
async function main() {
    // ⚠️ IMPORTANT: Set these values from previous steps
    const L1_TOKEN_ADDRESS = process.env.L1_TOKEN_ADDRESS || "YOUR_L1_TOKEN_ADDRESS_HERE";
    const L2_TOKEN_ADDRESS = process.env.L2_TOKEN_ADDRESS || "YOUR_L2_TOKEN_ADDRESS_HERE";
    const BRIDGE_AMOUNT = process.env.BRIDGE_AMOUNT || "100"; // Amount in tokens (not wei)

    if (L1_TOKEN_ADDRESS === "YOUR_L1_TOKEN_ADDRESS_HERE" ||
        L2_TOKEN_ADDRESS === "YOUR_L2_TOKEN_ADDRESS_HERE") {
        console.error("❌ Error: Please set L1_TOKEN_ADDRESS and L2_TOKEN_ADDRESS in your .env file");
        process.exit(1);
    }

    console.log("🌉 Starting Bridge Process from L1 to L2...\n");

    const [deployer] = await hre.ethers.getSigners();
    console.log("📝 Using account:", deployer.address);

    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("💰 ETH balance:", hre.ethers.formatEther(balance), "ETH\n");

    // L1StandardBridge address on Sepolia
    const L1_STANDARD_BRIDGE = "0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1";

    console.log("📋 Bridge Configuration:");
    console.log("   L1 Token:", L1_TOKEN_ADDRESS);
    console.log("   L2 Token:", L2_TOKEN_ADDRESS);
    console.log("   Bridge Contract:", L1_STANDARD_BRIDGE);
    console.log("   Amount to Bridge:", BRIDGE_AMOUNT, "MTK\n");

    // Get token contract
    const tokenABI = [
        "function approve(address spender, uint256 amount) returns (bool)",
        "function balanceOf(address account) view returns (uint256)",
        "function allowance(address owner, address spender) view returns (uint256)",
        "function symbol() view returns (string)",
        "function decimals() view returns (uint8)"
    ];

    const token = await hre.ethers.getContractAt(tokenABI, L1_TOKEN_ADDRESS);

    // Check token balance
    const tokenBalance = await token.balanceOf(deployer.address);
    const symbol = await token.symbol();
    console.log("🪙 Your L1 token balance:", hre.ethers.formatEther(tokenBalance), symbol);

    const bridgeAmountWei = hre.ethers.parseEther(BRIDGE_AMOUNT);

    if (tokenBalance < bridgeAmountWei) {
        console.error(`❌ Error: Insufficient balance. You have ${hre.ethers.formatEther(tokenBalance)} ${symbol} but trying to bridge ${BRIDGE_AMOUNT} ${symbol}`);
        process.exit(1);
    }

    // ============================================================
    // STEP 3: Approve L1StandardBridge
    // ============================================================
    console.log("\n" + "=".repeat(60));
    console.log("STEP 3: Approving L1StandardBridge");
    console.log("=".repeat(60) + "\n");

    const currentAllowance = await token.allowance(deployer.address, L1_STANDARD_BRIDGE);
    console.log("📊 Current allowance:", hre.ethers.formatEther(currentAllowance), symbol);

    if (currentAllowance < bridgeAmountWei) {
        console.log("📝 Approving", BRIDGE_AMOUNT, symbol, "for L1StandardBridge...");
        const approveTx = await token.approve(L1_STANDARD_BRIDGE, bridgeAmountWei);
        console.log("⏳ Approval transaction:", approveTx.hash);
        console.log("   Waiting for confirmation...");

        await approveTx.wait();
        console.log("✅ Approval confirmed!");
        console.log("🔗", `https://sepolia.etherscan.io/tx/${approveTx.hash}`);
    } else {
        console.log("✅ Already approved!");
    }

    // ============================================================
    // STEP 4: Bridge Tokens
    // ============================================================
    console.log("\n" + "=".repeat(60));
    console.log("STEP 4: Bridging Tokens to L2");
    console.log("=".repeat(60) + "\n");

    // L1StandardBridge ABI
    const bridgeABI = [
        "function bridgeERC20(address _localToken, address _remoteToken, uint256 _amount, uint32 _minGasLimit, bytes calldata _extraData)",
        "event ERC20DepositInitiated(address indexed _l1Token, address indexed _l2Token, address indexed _from, address _to, uint256 _amount, bytes _data)"
    ];

    const bridge = await hre.ethers.getContractAt(bridgeABI, L1_STANDARD_BRIDGE);

    console.log("🌉 Calling bridgeERC20...");
    console.log("   Parameters:");
    console.log("   - Local Token (L1):", L1_TOKEN_ADDRESS);
    console.log("   - Remote Token (L2):", L2_TOKEN_ADDRESS);
    console.log("   - Amount:", BRIDGE_AMOUNT, symbol);
    console.log("   - Min Gas Limit: 200,000");
    console.log("   - Extra Data: 0x (empty)\n");

    const bridgeTx = await bridge.bridgeERC20(
        L1_TOKEN_ADDRESS,  // L1 token
        L2_TOKEN_ADDRESS,  // L2 token  
        bridgeAmountWei,   // Amount
        200000,            // Min gas limit for L2 execution
        "0x"               // Extra data (empty)
    );

    console.log("⏳ Bridge transaction sent:", bridgeTx.hash);
    console.log("   Waiting for confirmation...");

    const receipt = await bridgeTx.wait();
    console.log("✅ Transaction confirmed in block:", receipt.blockNumber);

    // Display transaction links
    console.log("\n" + "=".repeat(60));
    console.log("✅ BRIDGE TRANSACTION SUCCESSFUL!");
    console.log("=".repeat(60));
    console.log("\n📋 L1 Transaction (Sepolia):");
    console.log("   Hash:", bridgeTx.hash);
    console.log("   🔗 Explorer:", `https://sepolia.etherscan.io/tx/${bridgeTx.hash}`);

    console.log("\n⏳ Waiting for L2 transaction...");
    console.log("   The L2 transaction will appear in 1-3 minutes");
    console.log("   You can monitor your address on L2:");
    console.log("   🔗", `https://sepolia-optimism.etherscan.io/address/${deployer.address}`);

    console.log("\n" + "=".repeat(60));
    console.log("📝 HOW TO FIND YOUR L2 TRANSACTION:");
    console.log("=".repeat(60));
    console.log("1. Go to the Optimism Sepolia explorer");
    console.log("2. Search for your address:", deployer.address);
    console.log("3. Look for a 'Token Transfer' transaction");
    console.log("4. It should show", BRIDGE_AMOUNT, symbol, "received");
    console.log("\n🔗 Direct link:", `https://sepolia-optimism.etherscan.io/address/${deployer.address}#tokentxns`);

    console.log("\n" + "=".repeat(60));
    console.log("📋 ASSIGNMENT SUBMISSION:");
    console.log("=".repeat(60));
    console.log("L1 Transaction Link:");
    console.log(`https://sepolia.etherscan.io/tx/${bridgeTx.hash}`);
    console.log("\nL2 Transaction Link:");
    console.log("(Check the link above in 1-3 minutes)");
    console.log("=".repeat(60));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
