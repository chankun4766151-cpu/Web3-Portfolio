// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTMarket is IERC721Receiver {
    IERC20 public paymentToken;

    struct Listing {
        address seller;
        uint256 price;
    }

    // NFT contract address => token ID => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event NFTSold(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint256 price
    );

    constructor(address _paymentToken) {
        paymentToken = IERC20(_paymentToken);
    }

    function list(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than 0");
        
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Market not approved"
        );

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        // Transfer NFT to market
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(nftAddress, tokenId, msg.sender, price);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.price > 0, "NFT not listed");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        // Transfer payment token from buyer to seller
        require(
            paymentToken.transferFrom(msg.sender, listing.seller, listing.price),
            "Payment failed"
        );

        // Transfer NFT from market to buyer
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTSold(nftAddress, tokenId, msg.sender, listing.seller, listing.price);

        // Clear listing
        delete listings[nftAddress][tokenId];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (address seller, uint256 price)
    {
        Listing memory listing = listings[nftAddress][tokenId];
        return (listing.seller, listing.price);
    }
}
