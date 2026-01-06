// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/InscriptionFactory.sol";
import "../src/InscriptionFactoryV2.sol";
import "../src/InscriptionTokenV2.sol";

/**
 * @title UpgradeToV2
 * @dev 升级到 V2 的脚本
 * 
 * 升级步骤：
 * 1. 部署 V2 实现合约（InscriptionFactoryV2）
 * 2. 部署 Token 实现合约（InscriptionTokenV2）
 * 3. 调用代理的 upgradeToAndCall 进行升级
 * 
 * 运行命令：
 * forge script script/UpgradeToV2.s.sol:UpgradeToV2 --rpc-url sepolia --broadcast --verify -vvvv
 */
contract UpgradeToV2 is Script {
    function run() external {
        // 从环境变量获取地址和私钥
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Upgrading proxy at:", proxyAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. 部署 V2 实现合约
        console.log("Deploying InscriptionFactoryV2 implementation...");
        InscriptionFactoryV2 implementationV2 = new InscriptionFactoryV2();
        console.log("V2 Implementation deployed at:", address(implementationV2));
        
        // 2. 部署 Token 实现合约（用于克隆）
        console.log("Deploying InscriptionTokenV2 implementation...");
        InscriptionTokenV2 tokenImplementation = new InscriptionTokenV2();
        console.log("Token Implementation deployed at:", address(tokenImplementation));
        
        // 3. 执行升级
        console.log("Upgrading proxy to V2...");
        InscriptionFactory factory = InscriptionFactory(proxyAddress);
        factory.upgradeToAndCall(
            address(implementationV2),
            abi.encodeWithSelector(
                InscriptionFactoryV2.initializeV2.selector,
                address(tokenImplementation)
            )
        );
        
        // 4. 验证升级
        InscriptionFactoryV2 factoryV2 = InscriptionFactoryV2(proxyAddress);
        console.log("Upgrade successful!");
        console.log("Token Implementation set to:", factoryV2.tokenImplementation());
        
        vm.stopBroadcast();
        
        // 输出重要地址
        console.log("\n=== Upgrade Summary ===");
        console.log("Proxy Address (unchanged):", proxyAddress);
        console.log("V2 Implementation Address:", address(implementationV2));
        console.log("Token Implementation Address:", address(tokenImplementation));
        console.log("Owner:", factoryV2.owner());
    }
}
