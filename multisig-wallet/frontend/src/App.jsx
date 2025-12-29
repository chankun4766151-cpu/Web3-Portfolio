import React, { useState } from 'react'
import { useAccount, useConnect, useDisconnect, useBalance, useWriteContract, useSignTypedData, usePublicClient, useSignMessage } from 'wagmi'
import { parseEther, keccak256, abiParameters, encodeAbiParameters, hexToBytes, concat } from 'viem'
import { injected } from 'wagmi/connectors'
import { Wallet, Landmark, ShoppingBag, CheckCircle, ArrowRight, ShieldCheck } from 'lucide-react'

// ABIs
import MyTokenABI from './abis/MyToken.json'
import TokenBankABI from './abis/TokenBank.json'
import NFTMarketABI from './abis/NFTMarket.json'

// Contract Addresses (Placeholders - need to be updated after deployment)
const MY_TOKEN_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'
const TOKEN_BANK_ADDRESS = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'
const NFT_MARKET_ADDRESS = '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9'

function App() {
  const { address, isConnected } = useAccount()
  const { connect } = useConnect()
  const { disconnect } = useDisconnect()
  const publicClient = usePublicClient()
  const { signTypedDataAsync } = useSignTypedData()
  const { signMessageAsync } = useSignMessage()
  const { writeContractAsync } = useWriteContract()

  const [depositAmount, setDepositAmount] = useState('10')
  const [whitelistSignature, setWhitelistSignature] = useState('')
  const [status, setStatus] = useState('')

  const { data: tokenBalance } = useBalance({
    address: address,
    token: MY_TOKEN_ADDRESS,
  })

  const handleConnect = () => connect({ connector: injected() })

  const handlePermitDeposit = async () => {
    try {
      if (!address) return
      setStatus('Signing permit...')

      const amount = parseEther(depositAmount)
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600)

      // 1. Get nonce from contract
      const nonce = await publicClient.readContract({
        address: MY_TOKEN_ADDRESS,
        abi: MyTokenABI,
        functionName: 'nonces',
        args: [address],
      })

      // 2. Sign typed data for Permit
      const domain = {
        name: 'MyToken',
        version: '1',
        chainId: publicClient.chain.id,
        verifyingContract: MY_TOKEN_ADDRESS,
      }

      const types = {
        Permit: [
          { name: 'owner', type: 'address' },
          { name: 'spender', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      }

      const signature = await signTypedDataAsync({
        domain,
        types,
        primaryType: 'Permit',
        message: {
          owner: address,
          spender: TOKEN_BANK_ADDRESS,
          value: amount,
          nonce: nonce,
          deadline: deadline,
        },
      })

      const { v, r, s } = splitSignature(signature)

      // 3. Call permitDeposit
      setStatus('Depositing...')
      const tx = await writeContractAsync({
        address: TOKEN_BANK_ADDRESS,
        abi: TokenBankABI,
        functionName: 'permitDeposit',
        args: [amount, deadline, v, r, s],
      })

      setStatus(`Deposit successful! TX: ${tx}`)
    } catch (error) {
      console.error(error)
      setStatus(`Error: ${error.message}`)
    }
  }

  // Demo helper: In a real app, this happens on the server/admin side
  const handleAdminSign = async () => {
    try {
      setStatus('Admin signing (demo)...')
      // For this demo, we assume the connected user is the project party
      // and they are signing for themselves to whitelist themselves.
      const messageHash = keccak256(encodeAbiParameters(
        [{ type: 'address' }],
        [address]
      ))

      // Note: useSignMessage adds the prefix \x19Ethereum Signed Message:\n32
      // This matches MessageHashUtils.toEthSignedMessageHash in Solidity
      const sig = await signMessageAsync({
        message: { raw: hexToBytes(messageHash) },
      })

      setWhitelistSignature(sig)
      setStatus('Whitelist signature obtained!')
    } catch (error) {
      console.error(error)
      setStatus(`Admin Sign Error: ${error.message}`)
    }
  }

  const handlePermitBuy = async () => {
    try {
      if (!whitelistSignature) {
        setStatus('Get whitelist signature first!')
        return
      }

      setStatus('Buying NFT...')

      // Need to approve tokens first if not using permit for purchase
      // (Requirement asked for permitDeposit in Bank, but permitBuy in Market just for whitelist)
      // For simplicity in UI, we check if approval is needed... but here let's just approve
      const txApprove = await writeContractAsync({
        address: MY_TOKEN_ADDRESS,
        abi: MyTokenABI,
        functionName: 'approve',
        args: [NFT_MARKET_ADDRESS, parseEther('100')],
      })

      setStatus('Buying NFT...')
      const tx = await writeContractAsync({
        address: NFT_MARKET_ADDRESS,
        abi: NFTMarketABI,
        functionName: 'permitBuy',
        args: [whitelistSignature],
      })

      setStatus(`NFT Purchased! TX: ${tx}`)
    } catch (error) {
      console.error(error)
      setStatus(`Error: ${error.message}`)
    }
  }

  const splitSignature = (hex) => {
    const r = hex.slice(0, 66)
    const s = '0x' + hex.slice(66, 130)
    const v = parseInt(hex.slice(130, 132), 16)
    return { v, r, s }
  }

  return (
    <div className="min-h-screen bg-slate-900 text-white font-sans p-8">
      <div className="max-w-4xl mx-auto space-y-8">
        <header className="flex justify-between items-center py-6 border-b border-slate-700">
          <div>
            <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-emerald-400 bg-clip-text text-transparent">
              Token & NFT Portal
            </h1>
            <p className="text-slate-400">EIP-2612 Permit & Signature Whitelist</p>
          </div>
          {isConnected ? (
            <div className="flex items-center gap-4 bg-slate-800 p-2 px-4 rounded-full border border-slate-700">
              <span className="text-sm font-mono">{address.slice(0, 6)}...{address.slice(-4)}</span>
              <button
                onClick={() => disconnect()}
                className="text-xs bg-red-500/10 text-red-400 hover:bg-red-500/20 px-3 py-1 rounded-full transition-colors"
              >
                Disconnect
              </button>
            </div>
          ) : (
            <button
              onClick={handleConnect}
              className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 px-6 py-2 rounded-full font-semibold transition-all hover:scale-105 active:scale-95"
            >
              <Wallet size={18} /> Connect Wallet
            </button>
          )}
        </header>

        {isConnected && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* Token Bank Card */}
            <div className="bg-slate-800 rounded-3xl p-8 border border-slate-700 shadow-xl space-y-6">
              <div className="flex items-center gap-3">
                <Landmark className="text-blue-400" />
                <h2 className="text-xl font-bold">Token Bank</h2>
              </div>

              <div className="space-y-2">
                <label className="text-sm text-slate-400">Balance: {tokenBalance?.formatted} MTK</label>
                <div className="flex gap-2">
                  <input
                    type="number"
                    value={depositAmount}
                    onChange={(e) => setDepositAmount(e.target.value)}
                    className="flex-1 bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button
                    onClick={handlePermitDeposit}
                    className="bg-blue-600 hover:bg-blue-500 px-4 py-2 rounded-xl transition-colors font-semibold"
                  >
                    Permit Deposit
                  </button>
                </div>
              </div>
              <p className="text-xs text-slate-500 italic">Uses EIP-2612 offline signature for gas-efficient authorization in one step.</p>
            </div>

            {/* NFT Market Card */}
            <div className="bg-slate-800 rounded-3xl p-8 border border-slate-700 shadow-xl space-y-6">
              <div className="flex items-center gap-3">
                <ShoppingBag className="text-emerald-400" />
                <h2 className="text-xl font-bold">NFT Market</h2>
              </div>

              <div className="space-y-4">
                <div className="p-4 bg-slate-900 rounded-2xl border border-slate-700 space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-semibold">Whitelist Status</span>
                    {whitelistSignature ? (
                      <span className="flex items-center gap-1 text-xs text-emerald-400">
                        <CheckCircle size={14} /> Signed
                      </span>
                    ) : (
                      <span className="text-xs text-slate-500">Not Whitelisted</span>
                    )}
                  </div>
                  <button
                    onClick={handleAdminSign}
                    className="w-full bg-slate-700 hover:bg-slate-600 py-2 rounded-xl text-sm transition-colors"
                  >
                    Obtain Admin Whitelist Signature
                  </button>
                </div>

                <button
                  onClick={handlePermitBuy}
                  disabled={!whitelistSignature}
                  className={`w-full py-3 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all ${whitelistSignature
                    ? 'bg-emerald-600 hover:bg-emerald-500 shadow-lg shadow-emerald-900/20'
                    : 'bg-slate-700 opacity-50 cursor-not-allowed'
                    }`}
                >
                  <ShieldCheck size={20} /> Buy Exclusive NFT
                </button>
              </div>
              <p className="text-xs text-slate-500 italic">Market check signature provided by project party before allowing purchase.</p>
            </div>
          </div>
        )}

        {status && (
          <div className="bg-slate-800/50 border border-slate-700 p-4 rounded-2xl flex items-center gap-3">
            <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse" />
            <span className="text-sm text-slate-300 break-all">{status}</span>
          </div>
        )}

        <footer className="text-center py-12 text-slate-500 text-sm">
          Built with EIP-2612 & EIP-712 Concepts
        </footer>
      </div>
    </div>
  )
}

export default App
