// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/InscriptionFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployV1
 * @dev 部署 V1 工厂合约脚本
 * 
 * 部署步骤：
 * 1. 部署实现合约（InscriptionFactory）
 * 2. 部署代理合约（ERC1967Proxy）
 * 3. 初始化代理
 * 
 * 运行命令：
 * forge script script/DeployV1.s.sol:DeployV1 --rpc-url sepolia --broadcast --verify -vvvv
 */
contract DeployV1 is Script {
    function run() external {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. 部署实现合约
        console.log("Deploying InscriptionFactory implementation...");
        InscriptionFactory implementation = new InscriptionFactory();
        console.log("Implementation deployed at:", address(implementation));
        
        // 2. 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            InscriptionFactory.initialize.selector
        );
        
        // 3. 部署代理合约
        console.log("Deploying ERC1967Proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        
        // 4. 获取代理接口
        InscriptionFactory factory = InscriptionFactory(address(proxy));
        console.log("Factory owner:", factory.owner());
        
        vm.stopBroadcast();
        
        // 输出重要地址
        console.log("\n=== Deployment Summary ===");
        console.log("Proxy Address (use this):", address(proxy));
        console.log("Implementation Address:", address(implementation));
        console.log("Owner:", factory.owner());
        console.log("\nSave these addresses for upgrade!");
    }
}
