const hre = require("hardhat");

/**
 * Script to deploy MyToken to Ethereum Sepolia (L1)
 * 
 * This is Step 1 of the cross-chain bridging process.
 * 
 * What this does:
 * - Deploys the MyToken ERC20 contract to Sepolia testnet
 * - Mints an initial supply of 1,000,000 tokens to the deployer
 * 
 * Why we need this:
 * - We need an L1 token before we can create its L2 representation
 * - This token will be the source for bridging to Optimism Sepolia
 */
async function main() {
    console.log("🚀 Deploying MyToken to Sepolia L1...\n");

    // Get the deployer's address
    const [deployer] = await hre.ethers.getSigners();
    console.log("📝 Deploying with account:", deployer.address);

    // Check deployer balance
    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("💰 Account balance:", hre.ethers.formatEther(balance), "ETH\n");

    // Deploy MyToken with 1 million tokens (18 decimals)
    const initialSupply = hre.ethers.parseEther("1000000");
    console.log("🪙 Initial supply:", hre.ethers.formatEther(initialSupply), "MTK\n");

    const MyToken = await hre.ethers.getContractFactory("MyToken");
    const myToken = await MyToken.deploy(initialSupply);

    await myToken.waitForDeployment();
    const tokenAddress = await myToken.getAddress();

    console.log("✅ MyToken deployed to:", tokenAddress);
    console.log("🔗 Etherscan:", `https://sepolia.etherscan.io/address/${tokenAddress}\n`);

    // Verify token details
    const name = await myToken.name();
    const symbol = await myToken.symbol();
    const totalSupply = await myToken.totalSupply();
    const deployerBalance = await myToken.balanceOf(deployer.address);

    console.log("📊 Token Details:");
    console.log("   Name:", name);
    console.log("   Symbol:", symbol);
    console.log("   Total Supply:", hre.ethers.formatEther(totalSupply), symbol);
    console.log("   Deployer Balance:", hre.ethers.formatEther(deployerBalance), symbol);

    console.log("\n⏳ Waiting 30 seconds before verification...");
    await new Promise(resolve => setTimeout(resolve, 30000));

    // Verify contract on Etherscan
    console.log("\n🔍 Verifying contract on Etherscan...");
    try {
        await hre.run("verify:verify", {
            address: tokenAddress,
            constructorArguments: [initialSupply],
        });
        console.log("✅ Contract verified successfully!");
    } catch (error) {
        console.log("⚠️  Verification failed:", error.message);
    }

    console.log("\n" + "=".repeat(60));
    console.log("📋 SAVE THIS ADDRESS FOR NEXT STEPS:");
    console.log("L1 Token Address:", tokenAddress);
    console.log("=".repeat(60));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
