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

    address public user;
    uint256 public userPrivateKey;

    function setUp() public {
        ownerPrivateKey = 0x123456;
        owner = vm.addr(ownerPrivateKey);

        userPrivateKey = 0xABC123;
        user = vm.addr(userPrivateKey);

        // owner 部署合约
        vm.startPrank(owner);
        token = new MyToken();
        nft = new MyNFT();
        market = new NFTMarket(address(token), address(nft));
        vm.stopPrank();

        // 给用户一些代币并授权给市场
        token.mint(user, 1000 * 10**18);
        vm.prank(user);
        token.approve(address(market), type(uint256).max);
    }

    function testPermitBuy() public {
        // 1. 项目方（owner）为用户（user）生成白名单签名
        // 消息内容是用户的地址
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 2. 用户持签名购买
        console.log("Before Buy - User Token Balance:", token.balanceOf(user) / 10**18, "MTK");
        console.log("Before Buy - User NFT Balance:", nft.balanceOf(user));

        vm.prank(user);
        market.permitBuy(signature);

        console.log("After Buy - User Token Balance:", token.balanceOf(user) / 10**18, "MTK");
        console.log("After Buy - User NFT Balance:", nft.balanceOf(user));
        console.log("NFT #1 Owner:", nft.ownerOf(1));

        // 3. 验证结果
        assertEq(nft.balanceOf(user), 1);
        assertEq(nft.ownerOf(1), user);
        assertEq(token.balanceOf(address(market)), market.price());
    }

    function testPermitBuyFailInvalidSignature() public {
        // 使用错误的私钥签名
        uint256 wrongPrivateKey = 0x999999;
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        vm.expectRevert("Only whitelisted users (with valid owner signature) can buy");
        market.permitBuy(signature);
    }
}
