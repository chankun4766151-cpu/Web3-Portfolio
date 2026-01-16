// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/NFTMarket.sol";
import "../src/TestNFT.sol";
import "../src/TestERC20.sol";

/**
 * @title Deploy
 * @dev 部署脚本 - 部署 NFTMarket、TestNFT 和 TestERC20 到 Sepolia
 * 
 * 运行命令：
 * source .env
 * forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. 部署 NFTMarket
        NFTMarket market = new NFTMarket();
        console.log("NFTMarket deployed at:", address(market));
        
        // 2. 部署 TestNFT (用于测试和演示)
        TestNFT nft = new TestNFT();
        console.log("TestNFT deployed at:", address(nft));
        
        // 3. 部署 TestERC20 (用于测试 ERC20 支付)
        TestERC20 token = new TestERC20("Test USDT", "TUSDT");
        console.log("TestERC20 deployed at:", address(token));
        
        // 4. 铸造一些测试 NFT
        address deployer = vm.addr(deployerPrivateKey);
        uint256 tokenId1 = nft.mint(deployer, "ipfs://QmTest1");
        uint256 tokenId2 = nft.mint(deployer, "ipfs://QmTest2");
        uint256 tokenId3 = nft.mint(deployer, "ipfs://QmTest3");
        console.log("Minted NFT tokenIds:", tokenId1, tokenId2, tokenId3);
        
        // 5. 授权并创建一个示例上架 (使用 ETH)
        nft.approve(address(market), tokenId1);
        market.list(
            address(nft),
            tokenId1,
            address(0), // ETH
            0.001 ether, // 价格
            block.timestamp + 30 days // 30 天有效期
        );
        console.log("Listed NFT tokenId:", tokenId1, "for 0.001 ETH");
        
        // 6. 授权并创建一个示例上架 (使用 ERC20)
        nft.approve(address(market), tokenId2);
        market.list(
            address(nft),
            tokenId2,
            address(token), // TUSDT
            100 * 10**18, // 100 TUSDT
            block.timestamp + 30 days
        );
        console.log("Listed NFT tokenId:", tokenId2, "for 100 TUSDT");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("NFTMarket:", address(market));
        console.log("TestNFT:", address(nft));
        console.log("TestERC20 (TUSDT):", address(token));
        console.log("==========================\n");
    }
}
