// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyERC20.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    MyERC20 public token;
    MyNFT public nft;
    NFTMarket public market;

    address public seller = address(0x1);
    address public buyer = address(0x2);

    function setUp() public {
        token = new MyERC20();
        nft = new MyNFT();
        market = new NFTMarket(address(token));

        // Give tokens to buyer
        token.transfer(buyer, 10000 * 10 ** 18);
    }

    function testListNFT() public {
        // Mint NFT to seller
        vm.prank(seller);
        uint256 tokenId = nft.mint(seller, "ipfs://test-uri");

        // Approve market to transfer NFT
        vm.prank(seller);
        nft.approve(address(market), tokenId);

        // List NFT
        vm.prank(seller);
        market.list(address(nft), tokenId, 100 * 10 ** 18);

        // Check listing
        (address listingSeller, uint256 listingPrice) = market.getListing(address(nft), tokenId);
        assertEq(listingSeller, seller);
        assertEq(listingPrice, 100 * 10 ** 18);
        
        // NFT should be in market contract
        assertEq(nft.ownerOf(tokenId), address(market));
    }

    function testBuyNFT() public {
        // Mint and list NFT
        vm.prank(seller);
        uint256 tokenId = nft.mint(seller, "ipfs://test-uri");
        
        vm.prank(seller);
        nft.approve(address(market), tokenId);
        
        vm.prank(seller);
        market.list(address(nft), tokenId, 100 * 10 ** 18);

        // Buyer approves market to spend tokens
        vm.prank(buyer);
        token.approve(address(market), 100 * 10 ** 18);

        // Buyer purchases NFT
        vm.prank(buyer);
        market.buyNFT(address(nft), tokenId);

        // Check NFT ownership transferred
        assertEq(nft.ownerOf(tokenId), buyer);

        // Check seller received payment
        assertEq(token.balanceOf(seller), 100 * 10 ** 18);

        // Check listing cleared
        (address listingSeller, uint256 listingPrice) = market.getListing(address(nft), tokenId);
        assertEq(listingSeller, address(0));
        assertEq(listingPrice, 0);
    }

    function testCannotBuyOwnNFT() public {
        // Mint and list NFT
        vm.prank(seller);
        uint256 tokenId = nft.mint(seller, "ipfs://test-uri");
        
        vm.prank(seller);
        nft.approve(address(market), tokenId);
        
        vm.prank(seller);
        market.list(address(nft), tokenId, 100 * 10 ** 18);

        // Seller tries to buy their own NFT
        vm.prank(seller);
        token.approve(address(market), 100 * 10 ** 18);
        
        vm.prank(seller);
        vm.expectRevert("Cannot buy your own NFT");
        market.buyNFT(address(nft), tokenId);
    }
}
