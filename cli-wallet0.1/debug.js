const { createPublicClient, http, formatUnits } = require('viem');
const { sepolia } = require('viem/chains');
require('dotenv').config();

const ERC20_ABI = [
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

async function debug() {
    console.log('🔌 Debugging connection...');
    console.log(`📡 RPC URL: ${process.env.SEPOLIA_RPC_URL}`);
    console.log(`📝 Contract: ${process.env.ERC20_CONTRACT_ADDRESS}`);

    const client = createPublicClient({
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL)
    });

    try {
        console.log('1️⃣  Getting Block Number...');
        const blockNumber = await client.getBlockNumber();
        console.log(`   ✅ Block Number: ${blockNumber}`);

        console.log('2️⃣  Reading Symbol...');
        const symbol = await client.readContract({
            address: process.env.ERC20_CONTRACT_ADDRESS,
            abi: ERC20_ABI,
            functionName: 'symbol'
        });
        console.log(`   ✅ Symbol: ${symbol}`);

        console.log('3️⃣  Reading Decimals...');
        const decimals = await client.readContract({
            address: process.env.ERC20_CONTRACT_ADDRESS,
            abi: ERC20_ABI,
            functionName: 'decimals'
        });
        console.log(`   ✅ Decimals: ${decimals}`);

        console.log('🎉 Connection Success!');
    } catch (error) {
        console.error('❌ Connection Failed:', error);
    }
}

debug();
