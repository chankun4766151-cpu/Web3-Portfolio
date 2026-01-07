// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyTokenA.sol";
import "../src/MyTokenB.sol";
import "../src/FlashSwapArbitrage.sol";
import "../src/SimpleUniswapV2.sol";

/**
 * @title FlashSwapArbitrageTest
 * @dev Comprehensive test suite for flash swap arbitrage
 */
contract FlashSwapArbitrageTest is Test {
    MyTokenA public tokenA;
    MyTokenB public tokenB;
    SimpleFactory public factoryA;
    SimpleFactory public factoryB;
    FlashSwapArbitrage public arbitrage;
    
    address public poolA;
    address public poolB;
    
    address public deployer = address(this);
    
    function setUp() public {
        // Deploy tokens
        tokenA = new MyTokenA();
        tokenB = new MyTokenB();
        
        // Deploy factories
        factoryA = new SimpleFactory(deployer);
        factoryB = new SimpleFactory(deployer);
        
        // Create Pool A with ratio 1:100 (1 TokenA = 100 TokenB)
        poolA = factoryA.createPair(address(tokenA), address(tokenB));
        
        uint256 amountA_PoolA = 5_000 * 10**18;
        uint256 amountB_PoolA = 500_000 * 10**18;  // Ratio: 1:100
        
        tokenA.transfer(poolA, amountA_PoolA);
        tokenB.transfer(poolA, amountB_PoolA);
        SimplePair(poolA).mint(deployer);
        
        // Create Pool B with ratio 1:150 (1 TokenA = 150 TokenB) - 50% higher price
        poolB = factoryB.createPair(address(tokenA), address(tokenB));
        
        uint256 amountA_PoolB = 3_000 * 10**18;
        uint256 amountB_PoolB = 450_000 * 10**18;  // Ratio: 1:150
        
        tokenA.transfer(poolB, amountA_PoolB);
        tokenB.transfer(poolB, amountB_PoolB);
        SimplePair(poolB).mint(deployer);
        
        // Deploy arbitrage contract
        arbitrage = new FlashSwapArbitrage();
    }
    
    function testDeployment() public view {
        assertEq(tokenA.totalSupply(), 1_000_000 * 10**18);
        assertEq(tokenB.totalSupply(), 1_000_000 * 10**18);
    }
    
    function testPoolCreation() public view {
        assertTrue(poolA != address(0));
        assertTrue(poolB != address(0));
        
        SimplePair pairA = SimplePair(poolA);
        SimplePair pairB = SimplePair(poolB);
        
        (uint112 reserveA0, uint112 reserveA1,) = pairA.getReserves();
        (uint112 reserveB0, uint112 reserveB1,) = pairB.getReserves();
        
        assertTrue(reserveA0 > 0);
        assertTrue(reserveA1 > 0);
        assertTrue(reserveB0 > 0);
        assertTrue(reserveB1 > 0);
    }
    
    function testPriceDifference() public view {
        SimplePair pairA = SimplePair(poolA);
        SimplePair pairB = SimplePair(poolB);
        
        (uint112 reserveA0, uint112 reserveA1,) = pairA.getReserves();
        (uint112 reserveB0, uint112 reserveB1,) = pairB.getReserves();
        
        // Note: token0 = TokenB (lower address), token1 = TokenA (higher address)
        // So reserve0 = TokenB reserve, reserve1 = TokenA reserve
        // Price = how much TokenB per TokenA = reserve0 / reserve1
        
        uint256 priceA = (uint256(reserveA0) * 1e18) / uint256(reserveA1);  // TokenB/TokenA in Pool A
        uint256 priceB = (uint256(reserveB0) * 1e18) / uint256(reserveB1);  // TokenB/TokenA in Pool B
        
        // Pool B should have higher TokenB per TokenA (TokenA is more valuable in Pool B)
        assertTrue(priceB > priceA, "Pool B should have higher TokenA value");
        
        console.log("Pool A price (TokenB per TokenA):", priceA / 1e18);
        console.log("Pool B price (TokenB per TokenA):", priceB / 1e18);
    }
    
    function testFlashSwapArbitrage() public {
        // Get initial state
        uint256 initialTokenA = arbitrage.getTokenBalance(address(tokenA));
        uint256 initialTokenB = arbitrage.getTokenBalance(address(tokenB));
        
        console.log("\n=== Initial Arbitrage Balances ===");
        console.log("TokenA:", initialTokenA / 10**18);
        console.log("TokenB:", initialTokenB / 10**18);
        
        // Print pool reserves before arbitrage
        printPoolReserves("Pool A (Before)", poolA);
        printPoolReserves("Pool B (Before)", poolB);
        
        // Execute arbitrage: borrow TokenA from Pool A (where it's cheaper)
        // Swap it to TokenB on Pool B (where TokenA is more valuable)
        // Repay Pool A with TokenB
        uint256 amountToBorrow = 100 * 10**18;
        
        console.log("\n=== Executing Arbitrage ===");
        console.log("Borrowing", amountToBorrow / 10**18, "TokenA from Pool A");
        
        arbitrage.executeArbitrage(
            poolA,
            poolB,
            address(tokenA),  // Borrow TokenA
            amountToBorrow
        );
        
        // Get final state
        uint256 finalTokenA = arbitrage.getTokenBalance(address(tokenA));
        uint256 finalTokenB = arbitrage.getTokenBalance(address(tokenB));
        
        console.log("\n=== Final Arbitrage Balances ===");
        console.log("TokenA:", finalTokenA / 10**18);
        console.log("TokenB:", finalTokenB / 10**18);
        
        // Print pool reserves after arbitrage
        printPoolReserves("Pool A (After)", poolA);
        printPoolReserves("Pool B (After)", poolB);
        
        // Verify profit was made
        uint256 profitTokenA = finalTokenA - initialTokenA;
        
        console.log("\n=== Profit ===");
        console.log("Profit in TokenA:", profitTokenA / 10**18);
        console.log("Total Profit TokenA:", arbitrage.totalProfitTokenA() / 10**18);
        
        assertTrue(profitTokenA > 0, "Should have profit in TokenA");
        assertEq(arbitrage.totalProfitTokenA(), profitTokenA, "Profit tracking mismatch");
    }
    
    function testProfitCalculation() public {
        uint256 borrowAmount = 50 * 10**18;
        
        // Execute arbitrage
        arbitrage.executeArbitrage(
            poolA,
            poolB,
            address(tokenA),  // Borrow TokenA
            borrowAmount
        );
        
        // Check that profit is tracked correctly
        uint256 profit = arbitrage.totalProfitTokenA();
        assertTrue(profit > 0, "Should track profit");
        
        console.log("Borrowed:", borrowAmount / 10**18, "TokenA");
        console.log("Profit:", profit / 10**18, "TokenA");
        
        // The profit should be reasonable
        assertTrue(profit < borrowAmount, "Profit should be less than borrowed amount");
    }
    
    function testMultipleArbitrages() public {
        // Execute arbitrage multiple times
        uint256 borrowAmount = 50 * 10**18;
        
        for (uint i = 0; i < 3; i++) {
            console.log("\n=== Arbitrage Round", i + 1, "===");
            
            uint256 beforeProfit = arbitrage.totalProfitTokenB();
            
            arbitrage.executeArbitrage(
                poolA,
                poolB,
                address(tokenA),  // Borrow TokenA
                borrowAmount
            );
            
            uint256 afterProfit = arbitrage.totalProfitTokenB();
            uint256 roundProfit = afterProfit - beforeProfit;
            
            console.log("Round profit:", roundProfit / 10**18, "TokenB");
            
            assertTrue(roundProfit > 0, "Each round should be profitable");
        }
        
        console.log("\n=== Total Profit ===");
        console.log("Total:", arbitrage.totalProfitTokenB() / 10**18, "TokenB");
    }
    
    function printPoolReserves(string memory name, address pool) internal view {
        SimplePair pair = SimplePair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        console.log(name);
        console.log("  Reserve0:", uint256(reserve0) / 10**18);
        console.log("  Reserve1:", uint256(reserve1) / 10**18);
    }
}
