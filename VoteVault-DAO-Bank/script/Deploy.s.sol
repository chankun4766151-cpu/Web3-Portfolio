// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/VotingToken.sol";
import "../src/Bank.sol";
import "../src/MyGovernor.sol";

/**
 * @title DeployScript
 * @dev 部署脚本 - 用于将合约部署到测试网或主网
 * 
 * 使用方法:
 * forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployScript is Script {
    function run() external {
        // 从环境变量读取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Starting Deployment ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // 1. 部署 VotingToken
        console.log("\n1. Deploying VotingToken...");
        VotingToken token = new VotingToken();
        console.log("VotingToken deployed at:", address(token));
        console.log("Total Supply:", token.totalSupply() / 1e18, "VVT");

        // 2. 部署 MyGovernor
        console.log("\n2. Deploying MyGovernor...");
        MyGovernor governor = new MyGovernor(token);
        console.log("MyGovernor deployed at:", address(governor));
        console.log("Voting Delay:", governor.votingDelay(), "blocks");
        console.log("Voting Period:", governor.votingPeriod(), "blocks");

        // 3. 部署 Bank
        console.log("\n3. Deploying Bank...");
        Bank bank = new Bank(address(governor));
        console.log("Bank deployed at:", address(bank));
        console.log("Bank admin:", bank.admin());

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Remember to:");
        console.log("1. Fund the Bank with ETH");
        console.log("2. Delegate voting power: token.delegate(your_address)");
        console.log("3. Create proposals to manage Bank funds");
    }
}
