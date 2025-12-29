// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyToken.sol";
import "../src/TokenBank.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MyToken token = new MyToken();
        TokenBank bank = new TokenBank(address(token));
        MyNFT nft = new MyNFT();
        NFTMarket market = new NFTMarket(address(token), address(nft));

        console.log("MyToken deployed at:", address(token));
        console.log("TokenBank deployed at:", address(bank));
        console.log("MyNFT deployed at:", address(nft));
        console.log("NFTMarket deployed at:", address(market));

        vm.stopBroadcast();
    }
}
