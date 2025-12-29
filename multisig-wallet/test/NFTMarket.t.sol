// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract NFTMarketTest is Test {
    MyToken public token;
    MyNFT public nft;
    NFTMarket public market;

    address public owner;
    uint256 public ownerPrivateKey;
    
    address public buyer;
    uint256 public buyerPrivateKey;

    function setUp() public {
        ownerPrivateKey = 0xB0B;
        owner = vm.addr(ownerPrivateKey);
        
        buyerPrivateKey = 0xA11CE;
        buyer = vm.addr(buyerPrivateKey);

        vm.startPrank(owner);
        token = new MyToken();
        nft = new MyNFT();
        market = new NFTMarket(address(token), address(nft));
        // Transfer ownership of NFT contract to Market so it can mint? 
        // Or Market just calls mint. MyNFT.mint is public in my impl. 
        // Realistically it should have access control but for this homework public is fine or Ownable.
        // MyNFT.mint() in my impl is public.
        vm.stopPrank();

        token.mint(buyer, 1000 * 10**18);
    }

    function testPermitBuy() public {
        // 1. Owner signs whitelist for buyer
        // Message is simple: address of buyer
        bytes32 messageHash = keccak256(abi.encodePacked(buyer));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 2. Buyer approves token to market (or use permit, but here we test permitBuy whitelist logic mainly)
        vm.prank(buyer);
        token.approve(address(market), 100 * 10**18);

        // 3. Buyer calls permitBuy
        vm.prank(buyer);
        market.permitBuy(signature);

        // 4. Verify
        assertEq(nft.ownerOf(1), buyer);
        assertEq(token.balanceOf(address(market)), 100 * 10**18);
    }

    function test_PermitBuy_NotWhitelisted() public {
        bytes32 messageHash = keccak256(abi.encodePacked(buyer));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        
        // Signed by wrong person (buyer signs themselves, lol)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(buyer);
        token.approve(address(market), 100 * 10**18);

        // Should revert
        vm.expectRevert("Invalid signature or not whitelisted");
        market.permitBuy(signature);
    }
}
