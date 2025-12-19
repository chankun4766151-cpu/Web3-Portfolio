// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../src/usdcERC20.sol";

contract DeployMyToken is Script {
    function run() external returns (testERC20 token) {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);
        token = new testERC20("usdcERC20", "uERC20");
        vm.stopBroadcast();
    }
}
