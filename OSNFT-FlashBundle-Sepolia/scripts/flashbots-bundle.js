const hre = require("hardhat");
const { FlashbotsBundleProvider } = require("@flashbots/ethers-provider-bundle");
require("dotenv").config();

async function main() {
    console.log("=".repeat(60));
    console.log("Flashbots Bundle 交易示例 - OpenspaceNFT");
    console.log("=".repeat(60));
    console.log();

    // ============================
    // 1. 初始化 Provider 和 Signer
    // ============================
    console.log("📌 步骤 1: 初始化 Provider 和 Signer");

    // 检查环境变量
    if (!process.env.SEPOLIA_RPC_URL) {
        throw new Error("❌ 缺少 SEPOLIA_RPC_URL 环境变量");
    }
    if (!process.env.OWNER_PRIVATE_KEY) {
        throw new Error("❌ 缺少 OWNER_PRIVATE_KEY 环境变量");
    }
    if (!process.env.USER_PRIVATE_KEY) {
        throw new Error("❌ 缺少 USER_PRIVATE_KEY 环境变量");
    }
    if (!process.env.CONTRACT_ADDRESS) {
        throw new Error("❌ 缺少 CONTRACT_ADDRESS 环境变量，请先部署合约");
    }

    // 创建 Provider
    const provider = new hre.ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);

    // 创建两个钱包
    const ownerWallet = new hre.ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);
    const userWallet = new hre.ethers.Wallet(process.env.USER_PRIVATE_KEY, provider);

    console.log("✅ Owner 地址:", ownerWallet.address);
    console.log("✅ User 地址:", userWallet.address);

    // 检查余额
    const ownerBalance = await provider.getBalance(ownerWallet.address);
    const userBalance = await provider.getBalance(userWallet.address);

    console.log("💰 Owner 余额:", hre.ethers.formatEther(ownerBalance), "ETH");
    console.log("💰 User 余额:", hre.ethers.formatEther(userBalance), "ETH");
    console.log();

    // ============================
    // 2. 初始化 Flashbots Provider
    // ============================
    console.log("📌 步骤 2: 初始化 Flashbots Provider");

    // Flashbots 认证密钥（用于签名，可以是任意私钥）
    const flashbotsAuthKey = process.env.FLASHBOTS_AUTH_KEY || hre.ethers.Wallet.createRandom().privateKey;
    const authSigner = new hre.ethers.Wallet(flashbotsAuthKey, provider);

    console.log("🔑 Flashbots 认证地址:", authSigner.address);

    // 创建 Flashbots Provider
    // 注意: Sepolia 使用 relay-sepolia.flashbots.net
    const flashbotsProvider = await FlashbotsBundleProvider.create(
        provider,
        authSigner,
        'https://relay-sepolia.flashbots.net',
        'sepolia'
    );

    console.log("✅ Flashbots Provider 初始化成功");
    console.log();

    // ============================
    // 3. 准备合约交互
    // ============================
    console.log("📌 步骤 3: 准备合约交互");

    const contractAddress = process.env.CONTRACT_ADDRESS;
    console.log("📝 合约地址:", contractAddress);

    // 获取合约实例
    const OpenspaceNFT = await hre.ethers.getContractFactory("OpenspaceNFT");
    const nftContract = OpenspaceNFT.attach(contractAddress);

    // 检查合约当前状态
    const isPresaleActiveBefore = await nftContract.isPresaleActive();
    console.log("📊 当前预售状态:", isPresaleActiveBefore);
    console.log();

    // ============================
    // 4. 准备 Bundle 交易
    // ============================
    console.log("📌 步骤 4: 准备 Bundle 交易");

    // 获取当前区块号和 gas 价格
    const currentBlock = await provider.getBlockNumber();
    const targetBlockNumber = currentBlock + 2; // 目标区块为当前 + 2

    console.log("🔢 当前区块:", currentBlock);
    console.log("🎯 目标区块:", targetBlockNumber);

    // 获取 base fee
    const block = await provider.getBlock("latest");
    const baseFeePerGas = block.baseFeePerGas;
    const maxPriorityFeePerGas = hre.ethers.parseUnits("2", "gwei"); // 2 Gwei 小费
    const maxFeePerGas = baseFeePerGas * 2n + maxPriorityFeePerGas; // 2x base fee + 优先费

    console.log("⛽ Base Fee:", hre.ethers.formatUnits(baseFeePerGas, "gwei"), "Gwei");
    console.log("⛽ Max Fee:", hre.ethers.formatUnits(maxFeePerGas, "gwei"), "Gwei");
    console.log();

    // 准备交易 1: enablePresale
    console.log("🔨 准备交易 1: enablePresale()");
    const tx1Data = nftContract.interface.encodeFunctionData("enablePresale");

    const transaction1 = {
        to: contractAddress,
        data: tx1Data,
        chainId: 11155111, // Sepolia
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        gasLimit: 100000n, // 估算的 gas
        nonce: await provider.getTransactionCount(ownerWallet.address),
        type: 2, // EIP-1559
        value: 0n
    };

    console.log("  - Signer: Owner");
    console.log("  - Nonce:", transaction1.nonce);

    // 准备交易 2: presale(1) - 购买 1 个 NFT
    console.log("🔨 准备交易 2: presale(1)");
    const tx2Data = nftContract.interface.encodeFunctionData("presale", [1]);

    const transaction2 = {
        to: contractAddress,
        data: tx2Data,
        chainId: 11155111, // Sepolia
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        gasLimit: 200000n, // 估算的 gas
        nonce: await provider.getTransactionCount(userWallet.address),
        type: 2, // EIP-1559
        value: hre.ethers.parseEther("0.01") // 支付 0.01 ETH
    };

    console.log("  - Signer: User");
    console.log("  - Nonce:", transaction2.nonce);
    console.log("  - Value: 0.01 ETH");
    console.log();

    // ============================
    // 5. 签名并创建 Bundle
    // ============================
    console.log("📌 步骤 5: 签名交易并创建 Bundle");

    const signedTransactions = [
        await ownerWallet.signTransaction(transaction1),
        await userWallet.signTransaction(transaction2)
    ];

    console.log("✅ 交易签名完成");
    console.log("📦 Bundle 包含 2 个交易");
    console.log();

    // ============================
    // 6. 提交 Bundle
    // ============================
    console.log("📌 步骤 6: 提交 Bundle 到 Flashbots");

    const bundleSubmitResponse = await flashbotsProvider.sendRawBundle(
        signedTransactions,
        targetBlockNumber
    );

    console.log("✅ Bundle 提交成功");

    // 检查提交响应
    if ('error' in bundleSubmitResponse) {
        console.error("❌ Bundle 提交错误:", bundleSubmitResponse.error.message);
        return;
    }

    const bundleHash = bundleSubmitResponse.bundleHash;
    console.log("🔖 Bundle Hash:", bundleHash);
    console.log();

    // ============================
    // 7. 等待 Bundle 被包含
    // ============================
    console.log("📌 步骤 7: 等待 Bundle 被包含到区块中");
    console.log("⏳ 等待目标区块...");

    const waitResponse = await bundleSubmitResponse.wait();

    if (waitResponse === 0) {
        console.log("✅ Bundle 已被包含到区块中!");
    } else if (waitResponse === 1) {
        console.log("⚠️ Bundle 未被包含 (区块已满或 gas 价格太低)");
    } else {
        console.log("⚠️ 等待 Bundle 超时");
    }
    console.log();

    // ============================
    // 8. 查询 Bundle Stats
    // ============================
    console.log("📌 步骤 8: 查询 Bundle Stats");

    try {
        const stats = await flashbotsProvider.getBundleStats(bundleHash, targetBlockNumber);

        console.log("📊 Bundle Stats:");
        console.log(JSON.stringify(stats, null, 2));
        console.log();
    } catch (error) {
        console.log("⚠️ 无法获取 Bundle Stats:", error.message);
        console.log("(这在 Sepolia 上是正常的，某些 Flashbots 功能可能不完全支持)");
        console.log();
    }

    // ============================
    // 9. 获取交易哈希
    // ============================
    console.log("📌 步骤 9: 获取交易哈希");

    // 解析签名交易以获取哈希
    const parsedTx1 = hre.ethers.Transaction.from(signedTransactions[0]);
    const parsedTx2 = hre.ethers.Transaction.from(signedTransactions[1]);

    const tx1Hash = parsedTx1.hash;
    const tx2Hash = parsedTx2.hash;

    console.log("\n" + "=".repeat(60));
    console.log("📋 最终结果汇总");
    console.log("=".repeat(60));
    console.log();
    console.log("✅ 交易 1 (enablePresale):");
    console.log("   哈希:", tx1Hash);
    console.log("   链接:", `https://sepolia.etherscan.io/tx/${tx1Hash}`);
    console.log();
    console.log("✅ 交易 2 (presale):");
    console.log("   哈希:", tx2Hash);
    console.log("   链接:", `https://sepolia.etherscan.io/tx/${tx2Hash}`);
    console.log();
    console.log("🔖 Bundle Hash:", bundleHash);
    console.log();

    // 额外等待一些时间让交易确认
    console.log("⏳ 等待交易确认...");
    await new Promise(resolve => setTimeout(resolve, 15000)); // 等待 15 秒

    // 验证交易结果
    console.log("📌 步骤 10: 验证交易结果");

    try {
        const receipt1 = await provider.getTransactionReceipt(tx1Hash);
        const receipt2 = await provider.getTransactionReceipt(tx2Hash);

        if (receipt1) {
            console.log("✅ Transaction 1 状态:", receipt1.status === 1 ? "成功" : "失败");
            console.log("   区块号:", receipt1.blockNumber);
        } else {
            console.log("⚠️ Transaction 1 仍在等待确认");
        }

        if (receipt2) {
            console.log("✅ Transaction 2 状态:", receipt2.status === 1 ? "成功" : "失败");
            console.log("   区块号:", receipt2.blockNumber);
        } else {
            console.log("⚠️ Transaction 2 仍在等待确认");
        }

        // 检查用户是否收到 NFT
        if (receipt2 && receipt2.status === 1) {
            const userNFTBalance = await nftContract.balanceOf(userWallet.address);
            console.log("\n🎉 用户 NFT 余额:", userNFTBalance.toString());
        }
    } catch (error) {
        console.log("⚠️ 验证时出错:", error.message);
    }

    console.log("\n" + "=".repeat(60));
    console.log("✅ Flashbots Bundle 流程完成!");
    console.log("=".repeat(60));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ 发生错误:");
        console.error(error);
        process.exit(1);
    });
