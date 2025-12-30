// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyToken.sol";
import "../src/TokenBankPermit2.sol";

/**
 * @title DeployPermit2
 * @dev 部署 TokenBankPermit2 系统的脚本
 * 
 * 部署内容：
 * 1. MyToken - ERC20 代币合约
 * 2. TokenBankPermit2 - 支持 Permit2 的银行合约
 * 
 * 注意：
 * - Permit2 合约已经由 Uniswap 官方部署，无需重复部署
 * - 我们只需要使用官方地址即可
 */
contract DeployPermit2 is Script {
    // Permit2 官方合约地址（Sepolia 测试网）
    // 这个地址在所有网络上都是相同的（通过 CREATE2 部署）
    // 主网、Sepolia、Goerli 等都使用同一个地址
    address constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /**
     * @dev 部署脚本主函数
     * 
     * 使用方法：
     * 
     * 1. 本地测试（使用 Anvil）:
     *    forge script script/DeployPermit2.s.sol --rpc-url http://localhost:8545 --broadcast
     * 
     * 2. Sepolia 测试网部署:
     *    forge script script/DeployPermit2.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --legacy
     * 
     * 说明：
     * - --broadcast: 实际广播交易到网络
     * - --legacy: 使用传统交易类型（兼容性更好）
     * - 需要在 .env 文件中设置 PRIVATE_KEY
     */
    function run() external {
        // 从环境变量读取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 步骤 1: 部署 MyToken
        // 初始供应量 1,000,000 个代币（会铸造给部署者）
        MyToken token = new MyToken();
        console.log("MyToken deployed successfully!");
        console.log("   Address:", address(token));
        console.log("   Initial supply: 1,000,000 MTK");

        // 步骤 2: 部署 TokenBankPermit2
        // 参数：MyToken 地址 和 Permit2 地址
        TokenBankPermit2 bank = new TokenBankPermit2(
            address(token),      // 银行接受的代币
            PERMIT2_ADDRESS      // 使用官方 Permit2 合约
        );
        console.log("\nTokenBankPermit2 deployed successfully!");
        console.log("   Address:", address(bank));
        console.log("   Accepted token:", address(token));
        console.log("   Using Permit2:", PERMIT2_ADDRESS);

        // 停止广播
        vm.stopBroadcast();

        // 打印部署摘要
        console.log("\n" "========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("MyToken address:", address(token));
        console.log("TokenBankPermit2 address:", address(bank));
        console.log("Permit2 address:", PERMIT2_ADDRESS);
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Copy the contract addresses above");
        console.log("2. If you have frontend, update the addresses in config");
        console.log("3. Start testing!");
    }
}
