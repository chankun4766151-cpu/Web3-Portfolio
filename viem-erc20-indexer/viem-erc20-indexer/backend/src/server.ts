import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import { PrismaClient } from '@prisma/client'

const app = express()
app.use(cors())
app.use(express.json())

// ✅ Prisma 6 正确初始化
const prisma = new PrismaClient()

app.get('/api/transfers/:address', async (req, res) => {
  const address = (req.params.address || '').toLowerCase()
  if (!/^0x[a-f0-9]{40}$/.test(address)) {
    return res.status(400).json({ error: 'Invalid address' })
  }

  const rows = await prisma.transfer.findMany({
    where: {
      OR: [{ from: address }, { to: address }],
    },
    orderBy: [{ blockNumber: 'desc' }, { logIndex: 'desc' }],
    take: 200,
  })

  res.json(rows)
})

app.get('/health', (_, res) => res.json({ ok: true }))

const port = 3001
app.listen(port, () => {
  console.log(`API on http://localhost:${port}`)
})
