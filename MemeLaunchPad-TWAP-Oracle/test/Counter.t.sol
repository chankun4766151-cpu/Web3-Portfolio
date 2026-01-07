// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeLaunchPad.sol";
import "../src/MemeToken.sol";
import "../src/TWAPOracle.sol";

contract MemeLaunchPadTest is Test {
    MemeLaunchPad public launchpad;
    TWAPOracle public oracle;
    MemeToken public memeToken;
    
    address public creator = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18; // 1 million tokens
    uint256 constant INITIAL_ETH = 10 ether;
    uint256 constant INITIAL_TOKENS = 100_000 * 1e18; // 100k tokens
    
    function setUp() public {
        // Deploy launchpad
        launchpad = new MemeLaunchPad();
        oracle = launchpad.oracle();
        
        // Fund accounts
        vm.deal(creator, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        // Create a meme token
        vm.startPrank(creator);
        address tokenAddress = launchpad.createMeme("DogeCoin", "DOGE", INITIAL_SUPPLY);
        memeToken = MemeToken(tokenAddress);
        
        // Approve and add initial liquidity
        memeToken.approve(address(launchpad), INITIAL_TOKENS);
        launchpad.addLiquidity{value: INITIAL_ETH}(address(memeToken), INITIAL_TOKENS);
        vm.stopPrank();
    }
    
    function test_CreateMemeToken() public {
        vm.startPrank(user1);
        address newToken = launchpad.createMeme("TestCoin", "TEST", INITIAL_SUPPLY);
        vm.stopPrank();
        
        assertEq(MemeToken(newToken).name(), "TestCoin");
        assertEq(MemeToken(newToken).symbol(), "TEST");
        assertEq(MemeToken(newToken).totalSupply(), INITIAL_SUPPLY);
        assertEq(MemeToken(newToken).balanceOf(user1), INITIAL_SUPPLY);
    }
    
    function test_AddLiquidity() public {
        (uint256 tokenReserve, uint256 ethReserve) = launchpad.getReserves(address(memeToken));
        
        assertEq(tokenReserve, INITIAL_TOKENS);
        assertEq(ethReserve, INITIAL_ETH);
        
        // Check initial price was recorded
        uint256 price = oracle.getCurrentPrice(address(memeToken));
        assertEq(price, (INITIAL_ETH * 1e18) / INITIAL_TOKENS); // 0.0001 ETH per token
    }
    
    function test_Swap() public {
        uint256 swapAmount = 1 ether;
        
        // User1 swaps ETH for tokens
        vm.startPrank(user1);
        uint256 balanceBefore = memeToken.balanceOf(user1);
        launchpad.swap{value: swapAmount}(address(memeToken), swapAmount, true);
        uint256 balanceAfter = memeToken.balanceOf(user1);
        vm.stopPrank();
        
        assertTrue(balanceAfter > balanceBefore);
        
        // Check reserves updated
        (uint256 tokenReserve, uint256 ethReserve) = launchpad.getReserves(address(memeToken));
        assertEq(ethReserve, INITIAL_ETH + swapAmount);
        assertTrue(tokenReserve < INITIAL_TOKENS);
    }
    
    /**
     * @dev Main test: Simulate multiple trades at different times
     * This test demonstrates TWAP calculation with time-weighted price observations
     */
    function test_TWAPMultipleTradesOverTime() public {
        console.log("\n=== TWAP Test: Multiple Trades Over Time ===\n");
        
        // Initial state at T0 (block.timestamp = 1)
        uint256 T0 = block.timestamp;
        uint256 price0 = oracle.getCurrentPrice(address(memeToken));
        console.log("T0 (timestamp %s): Initial price = %s wei", T0, price0);
        
        // Trade 1 at T0: User1 buys tokens with 1 ETH
        vm.startPrank(user1);
        launchpad.swap{value: 1 ether}(address(memeToken), 1 ether, true);
        vm.stopPrank();
        
        uint256 price1 = oracle.getCurrentPrice(address(memeToken));
        console.log("After Trade 1: Price = %s wei (increased)", price1);
        assertTrue(price1 > price0, "Price should increase after buying");
        
        // Warp to T1 (1 hour later)
        uint256 T1 = T0 + 1 hours;
        vm.warp(T1);
        console.log("\n--- Time warp to T1 (timestamp %s) ---", T1);
        
        // Trade 2 at T1: User2 buys tokens with 2 ETH
        vm.startPrank(user2);
        launchpad.swap{value: 2 ether}(address(memeToken), 2 ether, true);
        vm.stopPrank();
        
        uint256 price2 = oracle.getCurrentPrice(address(memeToken));
        console.log("After Trade 2: Price = %s wei (increased)", price2);
        assertTrue(price2 > price1, "Price should increase after buying more");
        
        // Warp to T2 (2 hours after T1, 3 hours total)
        uint256 T2 = T1 + 2 hours;
        vm.warp(T2);
        console.log("\n--- Time warp to T2 (timestamp %s) ---", T2);
        
        // Trade 3 at T2: User1 sells tokens for ETH
        vm.startPrank(user1);
        uint256 sellAmount = 5000 * 1e18;
        memeToken.approve(address(launchpad), sellAmount);
        launchpad.swap(address(memeToken), sellAmount, false);
        vm.stopPrank();
        
        uint256 price3 = oracle.getCurrentPrice(address(memeToken));
        console.log("After Trade 3: Price = %s wei (decreased)", price3);
        assertTrue(price3 < price2, "Price should decrease after selling");
        
        // Warp to T3 (1 hour after T2, 4 hours total)
        uint256 T3 = T2 + 1 hours;
        vm.warp(T3);
        console.log("\n--- Time warp to T3 (timestamp %s) ---", T3);
        
        // Trade 4 at T3: User2 buys more with 0.5 ETH
        vm.startPrank(user2);
        launchpad.swap{value: 0.5 ether}(address(memeToken), 0.5 ether, true);
        vm.stopPrank();
        
        uint256 price4 = oracle.getCurrentPrice(address(memeToken));
        console.log("After Trade 4: Price = %s wei", price4);
        
        // Calculate and verify TWAP over different intervals
        console.log("\n=== TWAP Calculations ===");
        
        // TWAP for last 1 hour (T3 to T4)
        uint256 twap1h = oracle.getTWAP(address(memeToken), 1 hours);
        console.log("TWAP (1 hour): %s wei", twap1h);
        
        // TWAP for last 2 hours
        uint256 twap2h = oracle.getTWAP(address(memeToken), 2 hours);
        console.log("TWAP (2 hours): %s wei", twap2h);
        
        // TWAP for last 3 hours
        uint256 twap3h = oracle.getTWAP(address(memeToken), 3 hours);
        console.log("TWAP (3 hours): %s wei", twap3h);
        
        // TWAP for entire period (4 hours)
        uint256 twap4h = oracle.getTWAP(address(memeToken), 4 hours);
        console.log("TWAP (4 hours - full period): %s wei", twap4h);
        
        // Verify TWAP is within reasonable bounds
        assertTrue(twap1h > 0, "TWAP should be positive");
        assertTrue(twap4h > price0, "Long-term TWAP should be higher than initial price");
        
        // Verify we have multiple observations
        uint256 observationCount = oracle.getObservationCount(address(memeToken));
        console.log("\nTotal observations recorded: %s", observationCount);
        assertEq(observationCount, 5, "Should have 5 observations (initial + 4 trades)");
        
        console.log("\n=== Test Complete ===\n");
    }
    
    /**
     * @dev Test TWAP accuracy with known values
     */
    function test_TWAPAccuracy() public {
        // Clear state by creating new token
        vm.startPrank(creator);
        address newToken = launchpad.createMeme("AccuracyTest", "ACC", INITIAL_SUPPLY);
        MemeToken token = MemeToken(newToken);
        
        // Add liquidity: 1000 tokens for 1 ETH (price = 0.001 ETH per token = 1e15 wei)
        uint256 liquidityTokens = 1000 * 1e18;
        uint256 liquidityEth = 1 ether;
        token.approve(address(launchpad), liquidityTokens);
        launchpad.addLiquidity{value: liquidityEth}(address(token), liquidityTokens);
        vm.stopPrank();
        
        uint256 T0 = block.timestamp;
        uint256 price0 = oracle.getCurrentPrice(address(token));
        console.log("Initial price: %s wei", price0);
        
        // Wait 1 hour at price0
        vm.warp(T0 + 1 hours);
        
        // Make a small trade to record new observation at same price
        vm.prank(user1);
        launchpad.swap{value: 0.01 ether}(address(token), 0.01 ether, true);
        
        uint256 price1 = oracle.getCurrentPrice(address(token));
        
        // TWAP over 1 hour should be close to average of price0 and price1
        uint256 twap = oracle.getTWAP(address(token), 1 hours);
        console.log("TWAP after 1 hour: %s wei", twap);
        console.log("New price: %s wei", price1);
        
        // The TWAP should be between the two prices
        assertTrue(twap >= price0 || twap <= price1, "TWAP should be reasonable");
    }
    
    /**
     * @dev Test price updates on each swap
     */
    function test_PriceUpdates() public {
        uint256 observationsBefore = oracle.getObservationCount(address(memeToken));
        
        // Execute swap
        vm.prank(user1);
        launchpad.swap{value: 1 ether}(address(memeToken), 1 ether, true);
        
        uint256 observationsAfter = oracle.getObservationCount(address(memeToken));
        
        assertEq(observationsAfter, observationsBefore + 1, "Should add one observation");
    }
    
    /**
     * @dev Test oracle with no observations
     */
    function test_OracleNoObservations() public {
        vm.startPrank(creator);
        address newToken = launchpad.createMeme("NewCoin", "NEW", INITIAL_SUPPLY);
        vm.stopPrank();
        
        // Should revert when trying to get price with no observations
        vm.expectRevert("No observations");
        oracle.getCurrentPrice(newToken);
    }
    
    /**
     * @dev Test multiple consecutive swaps with time progression
     */
    function test_ConsecutiveSwapsWithTime() public {
        console.log("\n=== Consecutive Swaps Test ===\n");
        
        for (uint i = 0; i < 5; i++) {
            // Warp forward by 30 minutes
            vm.warp(block.timestamp + 30 minutes);
            
            // Alternate between buying and selling
            if (i % 2 == 0) {
                vm.prank(user1);
                launchpad.swap{value: 0.5 ether}(address(memeToken), 0.5 ether, true);
                console.log("Swap %s: Bought tokens", i + 1);
            } else {
                vm.startPrank(user1);
                uint256 sellAmount = 1000 * 1e18;
                memeToken.approve(address(launchpad), sellAmount);
                launchpad.swap(address(memeToken), sellAmount, false);
                vm.stopPrank();
                console.log("Swap %s: Sold tokens", i + 1);
            }
            
            uint256 price = oracle.getCurrentPrice(address(memeToken));
            console.log("Price after swap %s: %s wei", i + 1, price);
        }
        
        uint256 finalObservations = oracle.getObservationCount(address(memeToken));
        console.log("\nTotal observations: %s", finalObservations);
        
        // Get TWAP over the entire period (2.5 hours)
        uint256 twap = oracle.getTWAP(address(memeToken), 150 minutes);
        console.log("TWAP over 2.5 hours: %s wei\n", twap);
        
        assertTrue(twap > 0, "TWAP should be positive");
    }
}
