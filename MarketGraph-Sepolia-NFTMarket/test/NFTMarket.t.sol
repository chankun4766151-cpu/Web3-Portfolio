// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/TestNFT.sol";
import "../src/TestERC20.sol";

contract NFTMarketSimpleTest is Test {
    NFTMarket public market;
    TestNFT public nft;
    TestERC20 public token;
    
    address public seller = address(0x1);
    address public buyer = address(0x2);
    address public feeRecipient = address(0x3);
    
    function setUp() public {
        market = new NFTMarket();
        nft = new TestNFT();
        token = new TestERC20("Test Token", "TT");
        market.updateFeeRecipient(feeRecipient);
        
        vm.deal(seller, 100 ether);
        vm.deal(buyer, 100 ether);
        token.mint(buyer, 1000 * 10**18);
    }
    
    function testSimpleList() public {
        vm.startPrank(seller);
        uint256 tokenId = nft.mint(seller, "ipfs://test");
        nft.approve(address(market), tokenId);
        market.list(address(nft), tokenId, address(0), 1 ether, block.timestamp + 1 days);
        vm.stopPrank();
    }
}
