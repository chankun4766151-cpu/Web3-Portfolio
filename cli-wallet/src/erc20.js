const { encodeFunctionData, parseUnits, formatUnits } = require('viem');
const { createWalletClient, http } = require('viem');
const { sepolia } = require('viem/chains');
const { createSepoliaClient, getAccount } = require('./wallet');
require('dotenv').config();

// ERC20 ABI - 只需要我们要用的函数
const ERC20_ABI = [
    {
        name: 'balanceOf',
        type: 'function',
        stateMutability: 'view',
        inputs: [{ name: 'account', type: 'address' }],
        outputs: [{ name: 'balance', type: 'uint256' }]
    },
    {
        name: 'transfer',
        type: 'function',
        stateMutability: 'nonpayable',
        inputs: [
            { name: 'to', type: 'address' },
            { name: 'amount', type: 'uint256' }
        ],
        outputs: [{ name: 'success', type: 'bool' }]
    },
    {
        name: 'decimals',
        type: 'function',
        stateMutability: 'view',
        inputs: [],
        outputs: [{ name: '', type: 'uint8' }]
    },
    {
        name: 'symbol',
        type: 'function',
        stateMutability: 'view',
        inputs: [],
        outputs: [{ name: '', type: 'string' }]
    }
];

// 获取 ERC20 合约地址
function getERC20Address() {
    return process.env.ERC20_CONTRACT_ADDRESS;
}

// 查询 ERC20 代币余额
async function getERC20Balance(address) {
    const client = createSepoliaClient();
    const tokenAddress = getERC20Address();

    try {
        // 获取代币精度
        const decimals = await client.readContract({
            address: tokenAddress,
            abi: ERC20_ABI,
            functionName: 'decimals'
        });

        // 获取余额
        const balance = await client.readContract({
            address: tokenAddress,
            abi: ERC20_ABI,
            functionName: 'balanceOf',
            args: [address]
        });

        // 格式化余额
        return formatUnits(balance, decimals);
    } catch (error) {
        throw new Error(`查询 ERC20 余额失败: ${error.message}`);
    }
}

// 获取代币符号
async function getTokenSymbol() {
    const client = createSepoliaClient();
    const tokenAddress = getERC20Address();

    try {
        const symbol = await client.readContract({
            address: tokenAddress,
            abi: ERC20_ABI,
            functionName: 'symbol'
        });
        return symbol;
    } catch (error) {
        return 'TOKEN';
    }
}

// 构建并发送 ERC20 转账交易（EIP-1559）
async function sendERC20Transfer(toAddress, amount) {
    const account = getAccount();
    const tokenAddress = getERC20Address();
    const client = createSepoliaClient();

    console.log('\n📝 正在构建交易...');

    // 获取代币精度
    const decimals = await client.readContract({
        address: tokenAddress,
        abi: ERC20_ABI,
        functionName: 'decimals'
    });

    // 转换金额
    const amountInWei = parseUnits(amount, decimals);

    // 编码 transfer 函数调用
    const data = encodeFunctionData({
        abi: ERC20_ABI,
        functionName: 'transfer',
        args: [toAddress, amountInWei]
    });

    console.log('✅ 交易数据已编码');

    // 创建钱包客户端
    const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL)
    });

    console.log('⛽ 正在估算 Gas...');

    // 获取当前的 Gas 价格信息（EIP-1559）
    const block = await client.getBlock({ blockTag: 'latest' });
    const baseFeePerGas = block.baseFeePerGas;
    const maxPriorityFeePerGas = parseUnits('2', 'gwei'); // 2 Gwei 小费
    const maxFeePerGas = baseFeePerGas * BigInt(2) + maxPriorityFeePerGas;

    console.log(`📊 Gas 价格信息（EIP-1559）:`);
    console.log(`   - Base Fee: ${formatUnits(baseFeePerGas, 'gwei')} Gwei`);
    console.log(`   - Max Priority Fee: ${formatUnits(maxPriorityFeePerGas, 'gwei')} Gwei`);
    console.log(`   - Max Fee: ${formatUnits(maxFeePerGas, 'gwei')} Gwei`);

    console.log('\n✍️  正在签名交易...');

    // 发送交易（Viem 会自动处理签名）
    const hash = await walletClient.sendTransaction({
        to: tokenAddress,
        data,
        maxFeePerGas,
        maxPriorityFeePerGas,
    });

    console.log(`\n✅ 交易已签名并发送！`);
    console.log(`📤 交易哈希: ${hash}`);
    console.log(`🔗 查看交易: https://sepolia.etherscan.io/tx/${hash}`);

    console.log('\n⏳ 等待交易确认...');

    // 等待交易确认
    const receipt = await client.waitForTransactionReceipt({ hash });

    if (receipt.status === 'success') {
        console.log('✅ 交易成功确认！');
        console.log(`📦 区块号: ${receipt.blockNumber}`);
        console.log(`⛽ Gas 使用: ${receipt.gasUsed.toString()}`);
    } else {
        console.log('❌ 交易失败！');
    }

    return {
        hash,
        receipt,
        explorerUrl: `https://sepolia.etherscan.io/tx/${hash}`
    };
}

module.exports = {
    getERC20Balance,
    getTokenSymbol,
    sendERC20Transfer,
    ERC20_ABI
};
