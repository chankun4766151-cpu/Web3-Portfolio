// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FlashSwapArbitrage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/**
 * @title ExecuteArbitrageScript
 * @dev Script to execute flash swap arbitrage
 * 
 * IMPORTANT: Update the addresses below after running Deploy.s.sol
 */
contract ExecuteArbitrageScript is Script {
    // UPDATE THESE ADDRESSES AFTER DEPLOYMENT
    address constant ARBITRAGE_CONTRACT = address(0); // FlashSwapArbitrage address
    address constant POOL_A = address(0); // Pool A address
    address constant POOL_B = address(0); // Pool B address
    address constant TOKEN_A = address(0); // TokenA address
    address constant TOKEN_B = address(0); // TokenB address
    
    function run() external {
        require(ARBITRAGE_CONTRACT != address(0), "Update ARBITRAGE_CONTRACT address");
        require(POOL_A != address(0), "Update POOL_A address");
        require(POOL_B != address(0), "Update POOL_B address");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("========================================");
        console.log("EXECUTING FLASH SWAP ARBITRAGE");
        console.log("========================================");
        
        FlashSwapArbitrage arbitrage = FlashSwapArbitrage(ARBITRAGE_CONTRACT);
        
        // Print initial balances
        console.log("\n=== Initial State ===");
        printPoolInfo(POOL_A, "Pool A");
        printPoolInfo(POOL_B, "Pool B");
        printArbitrageBalance();
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Execute arbitrage
        // We'll borrow TokenB from Pool A because it has lower value in Pool A
        // Then swap it for TokenA in Pool B where TokenB has higher value
        // Borrow amount: 1000 TokenB
        uint256 amountToBorrow = 1000 * 10**18;
        
        console.log("\n=== Executing Arbitrage ===");
        console.log("Borrowing", amountToBorrow / 10**18, "TokenB from Pool A");
        console.log("Will swap on Pool B and repay Pool A with TokenA");
        
        arbitrage.executeArbitrage(
            POOL_A,
            POOL_B,
            TOKEN_B, // Borrow TokenB
            amountToBorrow
        );
        
        vm.stopBroadcast();
        
        // Print final balances
        console.log("\n=== Final State ===");
        printPoolInfo(POOL_A, "Pool A");
        printPoolInfo(POOL_B, "Pool B");
        printArbitrageBalance();
        
        console.log("\n=== Arbitrage Complete! ===");
        console.log("Check the transaction on Etherscan to see the flash swap events");
    }
    
    function printPoolInfo(address pool, string memory name) internal view {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console.log(name, "reserves:");
        console.log("  Token0:", pair.token0(), "=", uint256(reserve0) / 10**18);
        console.log("  Token1:", pair.token1(), "=", uint256(reserve1) / 10**18);
    }
    
    function printArbitrageBalance() internal view {
        FlashSwapArbitrage arbitrage = FlashSwapArbitrage(ARBITRAGE_CONTRACT);
        console.log("Arbitrage contract balances:");
        console.log("  TokenA:", arbitrage.getTokenBalance(TOKEN_A) / 10**18);
        console.log("  TokenB:", arbitrage.getTokenBalance(TOKEN_B) / 10**18);
        console.log("  Total Profit TokenA:", arbitrage.totalProfitTokenA() / 10**18);
        console.log("  Total Profit TokenB:", arbitrage.totalProfitTokenB() / 10**18);
    }
}
