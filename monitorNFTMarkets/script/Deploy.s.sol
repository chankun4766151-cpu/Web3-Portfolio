// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// 1) 你的 Market
import {NFTMarket} from "../src/NFTMarket_full.sol";

// 2) 你需要一个 ERC721 用来 mint NFT（示例：你自己仓库里若已有就替换）
import {MockERC721} from "../src/mocks/MockERC721.sol";

// 3) 你需要一个 ERC1363 Token（示例：你自己仓库里若已有就替换）
import {MockERC1363} from "../src/mocks/MockERC1363.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("ANVIL_PK");
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        // 部署支付 token（ERC1363）
        MockERC1363 payToken = new MockERC1363("PayToken", "PAY");


        // 部署 NFT（ERC721）
        MockERC721 nft = new MockERC721("MyNFT", "MNFT");

        // 部署 Market
        NFTMarket market = new NFTMarket();

        // mint: 给 deployer 一些 token & mint 一个 NFT
        payToken.mint(deployer, 1_000_000 ether);
        uint256 tokenId = nft.mint(deployer); // 你的 mint 如果签名不同就改一下

        vm.stopBroadcast();

        console2.log("payToken =", address(payToken));
        console2.log("nft      =", address(nft));
        console2.log("tokenId  =", tokenId);
        console2.log("market   =", address(market));
        console2.log("deployer =", deployer);
    }
}
