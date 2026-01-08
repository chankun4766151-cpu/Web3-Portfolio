// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/periphery/WETH9.sol";
import "../src/periphery/UniswapV2Router02.sol";
import "../src/test/TestERC20.sol";

/**
 * @title DeployUniswapV2
 * @notice 部署完整的 Uniswap V2 协议到本地
 * @dev 包括 Factory、WETH、Router 和测试代币
 * 
 * 部署步骤：
 * 1. 启动本地节点：anvil
 * 2. 运行部署脚本：
 *    forge script script/DeployUniswapV2.s.sol --rpc-url http://localhost:8545 --broadcast
 */
contract DeployUniswapV2 is Script {
    function run() external {
        // 获取部署者私钥（Anvil 默认第一个账户）
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        vm.startBroadcast(deployerPrivateKey);
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("===========================================");
        console.log("Deploying Uniswap V2 Protocol");
        console.log("Deployer:", deployer);
        console.log("===========================================");
        
        // 1. 部署 WETH
        WETH9 weth = new WETH9();
        console.log("WETH9 deployed at:", address(weth));
        
        // 2. 部署 Factory
        UniswapV2Factory factory = new UniswapV2Factory(deployer);
        console.log("UniswapV2Factory deployed at:", address(factory));
        
        // 3. 部署 Router
        UniswapV2Router02 router = new UniswapV2Router02(address(factory), address(weth));
        console.log("UniswapV2Router02 deployed at:", address(router));
        
        // 4. 部署测试代币
        TestERC20 tokenA = new TestERC20("Token A", "TKNA", 1000000 ether);
        TestERC20 tokenB = new TestERC20("Token B", "TKNB", 1000000 ether);
        console.log("Token A deployed at:", address(tokenA));
        console.log("Token B deployed at:", address(tokenB));
        
        // 5. 创建交易对
        address pair = factory.createPair(address(tokenA), address(tokenB));
        console.log("Pair (TKNA/TKNB) created at:", pair);

        console.log("===========================================");
        console.log("Deployment Complete!");
        console.log("===========================================");
        
        vm.stopBroadcast();
    }
}
