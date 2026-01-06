import { useState, useEffect } from 'react'
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract, usePublicClient } from 'wagmi'
import { parseEther, formatEther } from 'viem'
import { NFT_ADDRESS, TOKEN_ADDRESS, MARKET_ADDRESS, NFT_ABI, TOKEN_ABI, MARKET_ABI } from '../config/contracts'

interface NFTListing {
    tokenId: string
    seller: string
    price: string
    tokenUri?: string
}

export default function BuyNFT() {
    const { address } = useAccount()
    const publicClient = usePublicClient()
    const [listings, setListings] = useState<NFTListing[]>([])
    const [selectedTokenId, setSelectedTokenId] = useState<string>('')
    const [selectedPrice, setSelectedPrice] = useState<string>('')

    const { writeContract: approveToken, data: approveHash } = useWriteContract()
    const { writeContract: buyNFT, data: buyHash } = useWriteContract()

    const { isLoading: isApproving } = useWaitForTransactionReceipt({
        hash: approveHash,
    })

    const { isLoading: isBuying, isSuccess: isBuySuccess } = useWaitForTransactionReceipt({
        hash: buyHash,
    })

    // Get user's token balance
    const { data: tokenBalance } = useReadContract({
        address: TOKEN_ADDRESS as `0x${string}`,
        abi: TOKEN_ABI,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
    })

    // Fetch listings from events
    useEffect(() => {
        const fetchListings = async () => {
            if (!publicClient) return

            try {
                const logs = await publicClient.getLogs({
                    address: MARKET_ADDRESS as `0x${string}`,
                    event: {
                        type: 'event',
                        name: 'NFTListed',
                        inputs: [
                            { type: 'address', name: 'nftAddress', indexed: true },
                            { type: 'uint256', name: 'tokenId', indexed: true },
                            { type: 'address', name: 'seller', indexed: true },
                            { type: 'uint256', name: 'price', indexed: false }
                        ]
                    },
                    fromBlock: 'earliest',
                    toBlock: 'latest'
                })

                const listingsData: NFTListing[] = []

                for (const log of logs) {
                    const tokenId = log.args.tokenId?.toString() || ''
                    const seller = log.args.seller || ''
                    const price = log.args.price?.toString() || ''

                    // Check if still listed
                    const listing = await publicClient.readContract({
                        address: MARKET_ADDRESS as `0x${string}`,
                        abi: MARKET_ABI,
                        functionName: 'getListing',
                        args: [NFT_ADDRESS as `0x${string}`, BigInt(tokenId)]
                    }) as [string, bigint]

                    if (listing[1] > 0n) {
                        listingsData.push({
                            tokenId,
                            seller,
                            price: formatEther(listing[1])
                        })
                    }
                }

                setListings(listingsData)
            } catch (error) {
                console.error('Error fetching listings:', error)
            }
        }

        fetchListings()
    }, [publicClient, isBuySuccess])

    const handleApproveToken = async (price: string) => {
        if (!price) return

        approveToken({
            address: TOKEN_ADDRESS as `0x${string}`,
            abi: TOKEN_ABI,
            functionName: 'approve',
            args: [MARKET_ADDRESS as `0x${string}`, parseEther(price)],
        })
    }

    const handleBuy = async (tokenId: string) => {
        if (!tokenId) return

        buyNFT({
            address: MARKET_ADDRESS as `0x${string}`,
            abi: MARKET_ABI,
            functionName: 'buyNFT',
            args: [NFT_ADDRESS as `0x${string}`, BigInt(tokenId)],
        })
    }

    if (!address) {
        return (
            <div className="container">
                <h2>Buy NFT</h2>
                <p>Please connect your wallet to buy NFTs</p>
            </div>
        )
    }

    return (
        <div className="container">
            <h2>Buy NFT</h2>

            {tokenBalance !== undefined && (
                <p className="balance">Your Token Balance: {formatEther(tokenBalance as bigint)} MTK</p>
            )}

            <div className="nft-grid">
                {listings.length === 0 ? (
                    <p>No NFTs listed for sale</p>
                ) : (
                    listings.map((listing) => (
                        <div key={listing.tokenId} className="nft-card">
                            <h3>Token ID: {listing.tokenId}</h3>
                            <p>Price: {listing.price} MTK</p>
                            <p className="seller">Seller: {listing.seller.slice(0, 6)}...{listing.seller.slice(-4)}</p>

                            {listing.seller.toLowerCase() === address.toLowerCase() ? (
                                <p className="info">This is your NFT</p>
                            ) : (
                                <div className="button-group">
                                    <button
                                        onClick={() => {
                                            setSelectedTokenId(listing.tokenId)
                                            setSelectedPrice(listing.price)
                                            handleApproveToken(listing.price)
                                        }}
                                        disabled={isApproving}
                                    >
                                        {isApproving && selectedTokenId === listing.tokenId ? 'Approving...' : 'Approve Tokens'}
                                    </button>

                                    <button
                                        onClick={() => {
                                            setSelectedTokenId(listing.tokenId)
                                            handleBuy(listing.tokenId)
                                        }}
                                        disabled={isBuying}
                                    >
                                        {isBuying && selectedTokenId === listing.tokenId ? 'Buying...' : 'Buy NFT'}
                                    </button>
                                </div>
                            )}
                        </div>
                    ))
                )}
            </div>

            {isBuySuccess && (
                <div className="success-message">
                    ✓ NFT purchased successfully! Transaction: {buyHash}
                </div>
            )}
        </div>
    )
}
