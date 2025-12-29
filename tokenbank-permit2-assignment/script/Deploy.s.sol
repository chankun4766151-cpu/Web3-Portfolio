// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyToken.sol";
import "../src/TokenBank.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        MyToken token = new MyToken();
        TokenBank bank = new TokenBank(address(token));
        // 如果你要部署 V2：
        // TokenBankV2 bank = new TokenBankV2(address(token));  // 但前提是 Token 支持 callback

        vm.stopBroadcast();

        console2.log("Token:", address(token));
        console2.log("Bank :", address(bank));
    }
}
