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

    /**
     * @dev 只有白名单用户可以购买 NFT。
     * @param signature 项目方（owner）给用户的签名。
     * 逻辑：项目方对用户的地址进行签名，用户带上签名来购买。
     */
    function permitBuy(bytes calldata signature) public {
        // 1. 构建消息哈希（这里使用的是标准的以太坊签名消息格式）
        // 我们对 msg.sender (买家地址) 进行哈希，确保签名只能由该买家使用。
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        // 2. 恢复签名者地址
        address signer = ethSignedMessageHash.recover(signature);
        
        // 3. 验证签名者是否为项目方（owner）
        require(signer == owner, "Only whitelisted users (with valid owner signature) can buy");

        // 4. 支付代币（需要用户先授权，或者你可以进一步扩展同时支持 Token Permit）
        // 这里假设用户已经 approve 过了，或者余额足够且已授权。
        token.transferFrom(msg.sender, address(this), price);

        // 5. 铸造 NFT 给买家
        nft.mint(msg.sender);
    }
}
