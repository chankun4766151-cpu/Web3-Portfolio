// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyERC20.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ERC20 token
        MyERC20 token = new MyERC20();
        console.log("MyERC20 deployed at:", address(token));

        // Deploy NFT contract
        MyNFT nft = new MyNFT();
        console.log("MyNFT deployed at:", address(nft));

        // Deploy NFTMarket
        NFTMarket market = new NFTMarket(address(token));
        console.log("NFTMarket deployed at:", address(market));

        vm.stopBroadcast();
    }
}
