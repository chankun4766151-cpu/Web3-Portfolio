// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./MyToken.sol";
import "./MyNFT.sol";

contract NFTMarket {
    using ECDSA for bytes32;

    MyToken public token;
    MyNFT public nft;
    address public owner;
    uint256 public price = 100 * 10**18; // 100 Tokens to buy 1 NFT

    constructor(address _token, address _nft) {
        token = MyToken(_token);
        nft = MyNFT(_nft);
        owner = msg.sender;
    }

    function permitBuy(bytes calldata signature) public {
        // Verify whitelist signature
        // The message signed by owner should be the buyer's address (msg.sender)
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
        address signer = hash.recover(signature);
        
        require(signer == owner, "Invalid signature or not whitelisted");

        // Transfer tokens from buyer to this contract (or burn, or to owner)
        // Assuming user has already approved token transfer to Market (or we could use permit here too, but req says "permitBuy" is for whitelist check)
        // Let's assume standard approval for payment, but whitelist check via signature.
        // Wait, the requirement says "only whitelisted addresses can buy".
        
        token.transferFrom(msg.sender, address(this), price);
        nft.mint(msg.sender);
    }
}
