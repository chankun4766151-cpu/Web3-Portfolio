const hre = require("hardhat");

/**
 * Script to create L2 token on Optimism Sepolia using OptimismMintableERC20Factory
 * 
 * This is Step 2 of the cross-chain bridging process.
 * 
 * What this does:
 * - Calls OptimismMintableERC20Factory on L2 to create a bridgeable token
 * - The L2 token is automatically configured to work with the standard bridge
 * 
 * Why we need this:
 * - The standard bridge requires an OptimismMintableERC20 token on L2
 * - This L2 token can be minted by the L2 bridge when tokens are deposited from L1
 * - The factory ensures the token follows the correct interface
 * 
 * @param {string} L1_TOKEN_ADDRESS - Your deployed L1 token address from Step 1
 */
async function main() {
    // ⚠️ IMPORTANT: Replace this with your L1 token address from Step 1
    const L1_TOKEN_ADDRESS = process.env.L1_TOKEN_ADDRESS || "YOUR_L1_TOKEN_ADDRESS_HERE";

    if (L1_TOKEN_ADDRESS === "YOUR_L1_TOKEN_ADDRESS_HERE") {
        console.error("❌ Error: Please set L1_TOKEN_ADDRESS in your .env file or replace it in this script");
        process.exit(1);
    }

    console.log("🚀 Creating L2 token on Optimism Sepolia...\n");

    const [deployer] = await hre.ethers.getSigners();
    console.log("📝 Using account:", deployer.address);

    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("💰 Account balance:", hre.ethers.formatEther(balance), "ETH\n");

    // OptimismMintableERC20Factory address on OP Sepolia (predeploy)
    const FACTORY_ADDRESS = "0x4200000000000000000000000000000000000012";

    console.log("📋 Configuration:");
    console.log("   L1 Token:", L1_TOKEN_ADDRESS);
    console.log("   Factory:", FACTORY_ADDRESS);
    console.log("   Token Name: MyToken");
    console.log("   Token Symbol: MTK\n");

    // Factory ABI - only the function we need
    const factoryABI = [
        "function createOptimismMintableERC20(address _remoteToken, string memory _name, string memory _symbol) returns (address)",
        "event OptimismMintableERC20Created(address indexed localToken, address indexed remoteToken, address deployer)"
    ];

    const factory = await hre.ethers.getContractAt(factoryABI, FACTORY_ADDRESS);

    console.log("🏭 Calling createOptimismMintableERC20...");
    const tx = await factory.createOptimismMintableERC20(
        L1_TOKEN_ADDRESS,
        "MyToken",
        "MTK"
    );

    console.log("⏳ Transaction sent:", tx.hash);
    console.log("   Waiting for confirmation...");

    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed in block:", receipt.blockNumber);

    // Parse the event to get the L2 token address
    const event = receipt.logs.find(log => {
        try {
            const parsed = factory.interface.parseLog(log);
            return parsed.name === "OptimismMintableERC20Created";
        } catch {
            return false;
        }
    });

    if (event) {
        const parsedEvent = factory.interface.parseLog(event);
        const l2TokenAddress = parsedEvent.args.localToken;

        console.log("\n🎉 L2 Token Created Successfully!");
        console.log("🔗 Transaction:", `https://sepolia-optimism.etherscan.io/tx/${tx.hash}`);
        console.log("📍 L2 Token Address:", l2TokenAddress);
        console.log("🔗 Token Explorer:", `https://sepolia-optimism.etherscan.io/address/${l2TokenAddress}`);

        console.log("\n" + "=".repeat(60));
        console.log("📋 SAVE THIS ADDRESS FOR NEXT STEPS:");
        console.log("L2 Token Address:", l2TokenAddress);
        console.log("=".repeat(60));
    } else {
        console.log("\n⚠️  Could not parse event. Please check the transaction manually:");
        console.log("🔗", `https://sepolia-optimism.etherscan.io/tx/${tx.hash}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
