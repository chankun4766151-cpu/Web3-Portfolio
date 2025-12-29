const { createPublicClient, http, formatEther, parseEther } = require('viem');
const { sepolia } = require('viem/chains');
const { privateKeyToAccount } = require('viem/accounts');
const { generatePrivateKey } = require('viem/accounts');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// 创建 Sepolia 公共客户端
function createSepoliaClient() {
    return createPublicClient({
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL)
    });
}

// 生成新钱包
function generateWallet() {
    const privateKey = generatePrivateKey();
    const account = privateKeyToAccount(privateKey);

    return {
        privateKey,
        address: account.address
    };
}

// 从私钥加载钱包
function loadWallet() {
    const privateKey = process.env.PRIVATE_KEY;

    if (!privateKey || privateKey === '') {
        return null;
    }

    const account = privateKeyToAccount(privateKey);

    return {
        privateKey,
        address: account.address,
        account
    };
}

// 保存私钥到 .env 文件
function savePrivateKey(privateKey) {
    const envPath = path.join(__dirname, '..', '.env');
    let envContent = fs.readFileSync(envPath, 'utf-8');

    // 更新或添加 PRIVATE_KEY
    if (envContent.includes('PRIVATE_KEY=')) {
        envContent = envContent.replace(/PRIVATE_KEY=.*/, `PRIVATE_KEY=${privateKey}`);
    } else {
        envContent += `\nPRIVATE_KEY=${privateKey}`;
    }

    fs.writeFileSync(envPath, envContent);
}

// 查询 ETH 余额
async function getETHBalance(address) {
    const client = createSepoliaClient();
    const balance = await client.getBalance({ address });
    return formatEther(balance);
}

// 获取账户对象
function getAccount() {
    const wallet = loadWallet();
    if (!wallet) {
        throw new Error('没有找到钱包，请先生成钱包！');
    }
    return wallet.account;
}

module.exports = {
    createSepoliaClient,
    generateWallet,
    loadWallet,
    savePrivateKey,
    getETHBalance,
    getAccount
};
