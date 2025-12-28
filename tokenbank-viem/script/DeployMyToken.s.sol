// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyToken is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        MyToken token = new MyToken();

        vm.stopBroadcast();

        console2.log("MyToken deployed at:", address(token));
        console2.log("Deployer address:", vm.addr(pk));
    }
}
