
import 'dotenv/config'
import { createWalletClient, http, parseEther, parseAbi } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { foundry } from 'viem/chains'

const RPC_URL = process.env.RPC_URL || 'http://127.0.0.1:8545'
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS as `0x${string}`

if (!TOKEN_ADDRESS) {
    console.error('Missing TOKEN_ADDRESS in .env')
    process.exit(1)
}

// Default Anvil Private Key #0
const account = privateKeyToAccount('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80')

const client = createWalletClient({
    account,
    chain: foundry,
    transport: http(RPC_URL),
})

const abi = parseAbi([
    'function transfer(address to, uint256 value) public returns (bool)'
])

async function main() {
    console.log(`Sending transfers from ${account.address} using token at ${TOKEN_ADDRESS}...`)

    // Random addresses
    const recipient1 = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
    const recipient2 = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'

    try {
        const hash1 = await client.writeContract({
            address: TOKEN_ADDRESS,
            abi,
            functionName: 'transfer',
            args: [recipient1, parseEther('1')],
        })
        console.log(`Transaction 1 sent: ${hash1}`)

        const hash2 = await client.writeContract({
            address: TOKEN_ADDRESS,
            abi,
            functionName: 'transfer',
            args: [recipient2, parseEther('5')],
        })
        console.log(`Transaction 2 sent: ${hash2}`)

        console.log('Done! Please wait for the indexer to pick up the events.')
    } catch (error) {
        console.error('Error sending transactions:', error)
    }
}

main()
