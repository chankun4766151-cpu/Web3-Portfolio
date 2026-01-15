const hre = require("hardhat");

async function main() {
    console.log("开始部署 OpenspaceNFT 合约到 Sepolia 网络...\n");

    // 获取部署者账户
    const [deployer] = await hre.ethers.getSigners();
    console.log("部署账户地址:", deployer.address);

    // 获取账户余额
    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("账户余额:", hre.ethers.formatEther(balance), "ETH\n");

    // 部署合约
    console.log("正在部署合约...");
    const OpenspaceNFT = await hre.ethers.getContractFactory("OpenspaceNFT");
    const nft = await OpenspaceNFT.deploy();

    await nft.waitForDeployment();
    const contractAddress = await nft.getAddress();

    console.log("\n✅ OpenspaceNFT 合约部署成功!");
    console.log("📝 合约地址:", contractAddress);
    console.log("🔗 Etherscan:", `https://sepolia.etherscan.io/address/${contractAddress}`);

    // 验证合约初始状态
    const isPresaleActive = await nft.isPresaleActive();
    const nextTokenId = await nft.nextTokenId();
    const owner = await nft.owner();

    console.log("\n📊 合约初始状态:");
    console.log("- 预售状态 (isPresaleActive):", isPresaleActive);
    console.log("- 下一个 Token ID (nextTokenId):", nextTokenId.toString());
    console.log("- Owner 地址:", owner);

    console.log("\n💡 提示: 请将合约地址保存到 .env 文件中:");
    console.log(`CONTRACT_ADDRESS=${contractAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
