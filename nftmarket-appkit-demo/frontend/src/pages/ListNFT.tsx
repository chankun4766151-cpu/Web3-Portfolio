import { useState } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { parseEther } from 'viem'
import { NFT_ADDRESS, TOKEN_ADDRESS, MARKET_ADDRESS, NFT_ABI, TOKEN_ABI, MARKET_ABI } from '../config/contracts'

export default function ListNFT() {
    const { address } = useAccount()
    const [nftAddress, setNftAddress] = useState(NFT_ADDRESS)
    const [tokenId, setTokenId] = useState('')
    const [price, setPrice] = useState('')
    const [step, setStep] = useState<'idle' | 'approving' | 'listing'>('idle')

    const { writeContract: approveNFT, data: approveHash } = useWriteContract()
    const { writeContract: listNFT, data: listHash } = useWriteContract()

    const { isLoading: isApproving } = useWaitForTransactionReceipt({
        hash: approveHash,
    })

    const { isLoading: isListing, isSuccess: isListingSuccess } = useWaitForTransactionReceipt({
        hash: listHash,
    })

    // Check NFT owner
    const { data: owner } = useReadContract({
        address: nftAddress as `0x${string}`,
        abi: NFT_ABI,
        functionName: 'ownerOf',
        args: tokenId ? [BigInt(tokenId)] : undefined,
    })

    const handleApprove = async () => {
        if (!tokenId || !nftAddress) return

        setStep('approving')
        approveNFT({
            address: nftAddress as `0x${string}`,
            abi: NFT_ABI,
            functionName: 'approve',
            args: [MARKET_ADDRESS as `0x${string}`, BigInt(tokenId)],
        })
    }

    const handleList = async () => {
        if (!tokenId || !price || !nftAddress) return

        setStep('listing')
        listNFT({
            address: MARKET_ADDRESS as `0x${string}`,
            abi: MARKET_ABI,
            functionName: 'list',
            args: [nftAddress as `0x${string}`, BigInt(tokenId), parseEther(price)],
        })
    }

    if (!address) {
        return (
            <div className="container">
                <h2>List NFT</h2>
                <p>Please connect your wallet to list NFTs</p>
            </div>
        )
    }

    return (
        <div className="container">
            <h2>List NFT for Sale</h2>

            <div className="form-group">
                <label>NFT Contract Address:</label>
                <input
                    type="text"
                    value={nftAddress}
                    onChange={(e) => setNftAddress(e.target.value)}
                    placeholder="0x..."
                />
            </div>

            <div className="form-group">
                <label>Token ID:</label>
                <input
                    type="number"
                    value={tokenId}
                    onChange={(e) => setTokenId(e.target.value)}
                    placeholder="0"
                />
            </div>

            {owner && address && (
                <p className={owner.toLowerCase() === address.toLowerCase() ? 'success' : 'error'}>
                    {owner.toLowerCase() === address.toLowerCase()
                        ? '✓ You own this NFT'
                        : '✗ You do not own this NFT'}
                </p>
            )}

            <div className="form-group">
                <label>Price (in tokens):</label>
                <input
                    type="text"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    placeholder="100"
                />
            </div>

            <div className="button-group">
                <button
                    onClick={handleApprove}
                    disabled={!tokenId || !nftAddress || isApproving || step !== 'idle'}
                >
                    {isApproving ? 'Approving...' : 'Approve NFT'}
                </button>

                <button
                    onClick={handleList}
                    disabled={!tokenId || !price || !nftAddress || isListing || step === 'idle'}
                >
                    {isListing ? 'Listing...' : 'List NFT'}
                </button>
            </div>

            {isListingSuccess && (
                <div className="success-message">
                    ✓ NFT listed successfully! Transaction: {listHash}
                </div>
            )}

            {approveHash && (
                <p className="tx-status">Approve tx: {approveHash}</p>
            )}
        </div>
    )
}
