import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import { createPublicClient, http, parseAbiItem } from 'viem'
import { foundry } from 'viem/chains'

const prisma = new PrismaClient()

const RPC_URL = process.env.RPC_URL!
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS! as `0x${string}`

const client = createPublicClient({
  chain: foundry,
  transport: http(RPC_URL),
})

const transferEvent = parseAbiItem(
  'event Transfer(address indexed from, address indexed to, uint256 value)'
)

async function main() {
  const latestBlock = await client.getBlockNumber()

  const logs = await client.getLogs({
    address: TOKEN_ADDRESS,
    event: transferEvent,
    fromBlock: 0n,
    toBlock: latestBlock,
  }) // getLogs 用法参考 :contentReference[oaicite:2]{index=2}

  for (const log of logs) {
    const bn = Number(log.blockNumber)
    const block = await client.getBlock({ blockNumber: log.blockNumber })
    const ts = Number(block.timestamp)

    const from = (log.args as any).from as string
    const to = (log.args as any).to as string
    const value = ((log.args as any).value as bigint).toString()

    await prisma.transfer.upsert({
      where: {
        txHash_logIndex: { txHash: log.transactionHash!, logIndex: log.logIndex! },
      },
      update: {},
      create: {
        token: TOKEN_ADDRESS.toLowerCase(),
        txHash: log.transactionHash!,
        logIndex: log.logIndex!,
        blockNumber: bn,
        from: from.toLowerCase(),
        to: to.toLowerCase(),
        value,
        timestamp: ts,
      },
    })
  }

  console.log(`Indexed ${logs.length} transfer logs into SQLite.`)
  await prisma.$disconnect()
}

main().catch(async (e) => {
  console.error(e)
  await prisma.$disconnect()
  process.exit(1)
})
