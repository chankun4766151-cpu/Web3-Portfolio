
import 'dotenv/config'
import { PrismaClient } from '@prisma/client'
import path from 'path'

console.log('DATABASE_URL:', process.env.DATABASE_URL)
console.log('CWD:', process.cwd())

const prisma = new PrismaClient({
    log: ['query', 'info', 'warn', 'error'],
})

async function main() {
    try {
        const count = await prisma.transfer.count()
        console.log(`Successfully connected. Transfer count: ${count}`)
    } catch (e) {
        console.error(e)
        process.exit(1)
    } finally {
        await prisma.$disconnect()
    }
}

main()
