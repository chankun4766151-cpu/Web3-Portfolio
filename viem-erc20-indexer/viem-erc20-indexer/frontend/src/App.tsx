import { useMemo, useState } from 'react'

type Transfer = {
  id: number
  token: string
  txHash: string
  logIndex: number
  blockNumber: number
  from: string
  to: string
  value: string
  timestamp: number
}

const API_BASE = 'http://localhost:3001'

function shortHash(s: string) {
  return s.slice(0, 10) + '...' + s.slice(-8)
}

export default function App() {
  const [address, setAddress] = useState('')
  const [loggedIn, setLoggedIn] = useState<string | null>(null)
  const [rows, setRows] = useState<Transfer[]>([])
  const [loading, setLoading] = useState(false)
  const [err, setErr] = useState<string | null>(null)

  const isValid = useMemo(() => /^0x[a-fA-F0-9]{40}$/.test(address.trim()), [address])

  async function loginAndLoad() {
    setErr(null)
    const addr = address.trim()
    if (!/^0x[a-fA-F0-9]{40}$/.test(addr)) {
      setErr('地址格式不对')
      return
    }
    setLoggedIn(addr)
    setLoading(true)
    try {
      const r = await fetch(`${API_BASE}/api/transfers/${addr}`)
      if (!r.ok) throw new Error(await r.text())
      const data = (await r.json()) as Transfer[]
      setRows(data)
    } catch (e: any) {
      setErr(e?.message ?? '请求失败')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ maxWidth: 1000, margin: '40px auto', fontFamily: 'system-ui' }}>
      <h2>ERC20 Transfer Records</h2>

      {!loggedIn ? (
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <input
            placeholder="输入你的地址当作登录（0x...)"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            style={{ width: 520, padding: 10 }}
          />
          <button disabled={!isValid} onClick={loginAndLoad} style={{ padding: '10px 16px' }}>
            登录并查询
          </button>
        </div>
      ) : (
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <div>
            已登录：<b>{loggedIn}</b>
          </div>
          <button
            onClick={() => {
              setLoggedIn(null)
              setRows([])
              setAddress('')
              setErr(null)
            }}
          >
            退出
          </button>
          <button onClick={loginAndLoad} disabled={loading}>
            刷新
          </button>
        </div>
      )}

      {err && <p style={{ color: 'crimson' }}>{err}</p>}
      {loading && <p>Loading...</p>}

      <div style={{ marginTop: 24 }}>
        <table width="100%" cellPadding={10} style={{ borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ textAlign: 'left', borderBottom: '1px solid #ddd' }}>
              <th>Block</th>
              <th>From</th>
              <th>To</th>
              <th>Value (raw)</th>
              <th>Tx</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((x) => (
              <tr key={`${x.txHash}-${x.logIndex}`} style={{ borderBottom: '1px solid #f0f0f0' }}>
                <td>{x.blockNumber}</td>
                <td>{shortHash(x.from)}</td>
                <td>{shortHash(x.to)}</td>
                <td>{x.value}</td>
                <td title={x.txHash}>{shortHash(x.txHash)}</td>
                <td>{new Date(x.timestamp * 1000).toLocaleString()}</td>
              </tr>
            ))}
            {!rows.length && !loading && (
              <tr>
                <td colSpan={6} style={{ padding: 20, color: '#666' }}>
                  没有记录（请确认你已做两笔转账，并且运行过 backend 索引脚本）
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
