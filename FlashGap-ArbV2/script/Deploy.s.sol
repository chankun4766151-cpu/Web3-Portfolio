// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MyTokenA.sol";
import "../src/MyTokenB.sol";
import "../src/FlashSwapArbitrage.sol";
import "../src/SimpleUniswapV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployScript
 * @dev Complete deployment script for flash swap arbitrage demo
 * 
 * This script:
 * 1. Deploys two ERC20 tokens (TokenA and TokenB)
 * 2. Deploys two Uniswap V2 Factories
 * 3. Creates two liquidity pools with different ratios (price difference)
 * 4. Deploys FlashSwapArbitrage contract
 */
contract DeployScript is Script {
    // Contracts to deploy
    MyTokenA public tokenA;
    MyTokenB public tokenB;
    SimpleFactory public factoryA;
    SimpleFactory public factoryB;
    FlashSwapArbitrage public arbitrage;
    
    // Pools
    address public poolA;
    address public poolB;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("========================================");
        console.log("Deployer address:", deployer);
        console.log("========================================");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy tokens
        console.log("\n=== Step 1: Deploying Tokens ===");
        tokenA = new MyTokenA();
        tokenB = new MyTokenB();
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
        
        // Step 2: Deploy Uniswap V2 Factories
        console.log("\n=== Step 2: Deploying Factories ===");
        factoryA = new SimpleFactory(deployer);
        factoryB = new SimpleFactory(deployer);
        console.log("Factory A deployed at:", address(factoryA));
        console.log("Factory B deployed at:", address(factoryB));
        
        // Step 3: Create Pool A (TokenA/TokenB ratio 1:100)
        console.log("\n=== Step 3: Creating Pool A ===");
        poolA = factoryA.createPair(address(tokenA), address(tokenB));
        console.log("Pool A created at:", poolA);
        
        // Add liquidity to Pool A: 10,000 TokenA : 1,000,000 TokenB (1:100 ratio)
        uint256 amountA_PoolA = 10_000 * 10**18;
        uint256 amountB_PoolA = 1_000_000 * 10**18;
        
        tokenA.transfer(poolA, amountA_PoolA);
        tokenB.transfer(poolA, amountB_PoolA);
        SimplePair(poolA).mint(deployer);
        
        console.log("Pool A liquidity added: 10,000 TokenA : 1,000,000 TokenB");
        
        // Step 4: Create Pool B (TokenA/TokenB ratio 1:120) - Higher TokenB price
        console.log("\n=== Step 4: Creating Pool B ===");
        poolB = factoryB.createPair(address(tokenA), address(tokenB));
        console.log("Pool B created at:", poolB);
        
        // Add liquidity to Pool B: 10,000 TokenA : 1,200,000 TokenB (1:120 ratio)
        uint256 amountA_PoolB = 10_000 * 10**18;
        uint256 amountB_PoolB = 1_200_000 * 10**18;
        
        tokenA.transfer(poolB, amountA_PoolB);
        tokenB.transfer(poolB, amountB_PoolB);
        SimplePair(poolB).mint(deployer);
        
        console.log("Pool B liquidity added: 10,000 TokenA : 1,200,000 TokenB");
        
        // Step 5: Deploy FlashSwapArbitrage contract
        console.log("\n=== Step 5: Deploying Arbitrage Contract ===");
        arbitrage = new FlashSwapArbitrage();
        console.log("FlashSwapArbitrage deployed at:", address(arbitrage));
        
        vm.stopBroadcast();
        
        // Print summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("Factory A:", address(factoryA));
        console.log("Factory B:", address(factoryB));
        console.log("Pool A:", poolA);
        console.log("Pool B:", poolB);
        console.log("Arbitrage:", address(arbitrage));
        console.log("========================================");
        
        // Print pool reserves for verification
        printPoolInfo(poolA, "Pool A");
        printPoolInfo(poolB, "Pool B");
        
        console.log("\n=== NEXT STEPS ===");
        console.log("1. Copy the contract addresses above");
        console.log("2. Update script/ExecuteArbitrage.s.sol with these addresses");
        console.log("3. Run: forge script script/ExecuteArbitrage.s.sol --rpc-url sepolia --broadcast");
    }
    
    function printPoolInfo(address pool, string memory name) internal view {
        SimplePair pair = SimplePair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console.log("\n", name, "info:");
        console.log("  Reserve0:", uint256(reserve0));
        console.log("  Reserve1:", uint256(reserve1));
        console.log("  Token0:", pair.token0());
        console.log("  Token1:", pair.token1());
    }
}
