import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { NFT_ADDRESS, TOKEN_ADDRESS, NFT_ABI, TOKEN_ABI } from '../config/contracts'
import { parseEther } from 'viem'

export default function MintNFT() {
    const { address } = useAccount()
    const [tokenUri, setTokenUri] = useState('')
    const [mintAmount, setMintAmount] = useState('1000')

    const { writeContract: mintNFT, data: nftHash } = useWriteContract()
    const { writeContract: mintToken, data: tokenHash } = useWriteContract()

    const { isLoading: isMintingNFT, isSuccess: nftSuccess } = useWaitForTransactionReceipt({
        hash: nftHash,
    })

    const { isLoading: isMintingToken, isSuccess: tokenSuccess } = useWaitForTransactionReceipt({
        hash: tokenHash,
    })

    const handleMintNFT = () => {
        if (!address || !tokenUri) return

        mintNFT({
            address: NFT_ADDRESS as `0x${string}`,
            abi: NFT_ABI,
            functionName: 'mint',
            args: [address, tokenUri],
        })
    }

    const handleMintToken = () => {
        if (!address || !mintAmount) return

        mintToken({
            address: TOKEN_ADDRESS as `0x${string}`,
            abi: TOKEN_ABI,
            functionName: 'mint',
            args: [address, parseEther(mintAmount)],
        })
    }

    if (!address) {
        return (
            <div className="container">
                <h2>Mint Assets</h2>
                <p>Please connect your wallet to mint assets</p>
            </div>
        )
    }

    return (
        <div className="container">
            <h2>Mint Assets</h2>

            <div className="mint-section">
                <h3>Mint NFT</h3>
                <div className="form-group">
                    <label>Token URI:</label>
                    <input
                        type="text"
                        value={tokenUri}
                        onChange={(e) => setTokenUri(e.target.value)}
                        placeholder="ipfs://... or https://..."
                    />
                </div>
                <button onClick={handleMintNFT} disabled={!tokenUri || isMintingNFT}>
                    {isMintingNFT ? 'Minting...' : 'Mint NFT'}
                </button>
                {nftSuccess && (
                    <p className="success">✓ NFT minted! Tx: {nftHash}</p>
                )}
            </div>

            <div className="mint-section">
                <h3>Mint Tokens</h3>
                <div className="form-group">
                    <label>Amount:</label>
                    <input
                        type="text"
                        value={mintAmount}
                        onChange={(e) => setMintAmount(e.target.value)}
                        placeholder="1000"
                    />
                </div>
                <button onClick={handleMintToken} disabled={!mintAmount || isMintingToken}>
                    {isMintingToken ? 'Minting...' : 'Mint Tokens'}
                </button>
                {tokenSuccess && (
                    <p className="success">✓ Tokens minted! Tx: {tokenHash}</p>
                )}
            </div>
        </div>
    )
}
