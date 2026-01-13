// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EthCallOption.sol";
import "../src/MockUSDT.sol";

/**
 * @title EthCallOptionTest
 * @notice Complete test suite for option issuance, exercise, and expiry
 */
contract EthCallOptionTest is Test {
    // Test contracts
    EthCallOption public option;
    MockUSDT public usdt;
    
    // Test accounts
    address public owner;      // Project owner
    address public user1;      // User 1
    address public user2;      // User 2
    
    // Option parameters
    uint256 public constant STRIKE_PRICE = 2000 * 10**18;  // 2000 USDT per ETH
    uint256 public expiryDate;                              // Expiry date (7 days later)
    
    // Event definitions (for testing)
    event OptionIssued(address indexed issuer, uint256 ethAmount, uint256 optionTokenAmount);
    event OptionExercised(address indexed holder, uint256 optionAmount, uint256 ethReceived, uint256 usdtPaid);
    event OptionExpired(address indexed owner, uint256 ethRedeemed);
    
    /**
     * @notice Test initialization
     */
    function setUp() public {
        // Setup test accounts
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Give test accounts ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        // Deploy USDT
        usdt = new MockUSDT();
        
        // Set expiry date to 7 days later
        expiryDate = block.timestamp + 7 days;
        
        // Deploy option contract
        option = new EthCallOption(STRIKE_PRICE, expiryDate, address(usdt));
        
        console.log("=== Test Environment Initialized ===");
        console.log("Owner address:", owner);
        console.log("User1 address:", user1);
        console.log("User2 address:", user2);
        console.log("Strike price:", STRIKE_PRICE / 10**18, "USDT per ETH");
        console.log("Expiry date:", expiryDate);
        console.log("");
    }
    
    /**
     * @notice Test 1: Option issuance process
     */
    function test_Issue() public {
        console.log("=== Test 1: Issue Options ===");
        
        uint256 issueAmount = 10 ether;
        
        console.log("Step 1: Owner deposits", issueAmount / 10**18, "ETH");
        
        // Record state before issuance
        uint256 ownerBalanceBefore = option.balanceOf(owner);
        uint256 contractEthBefore = address(option).balance;
        
        // Issue options
        vm.expectEmit(true, false, false, true);
        emit OptionIssued(owner, issueAmount, issueAmount);
        option.issue{value: issueAmount}();
        
        // Verify results
        assertEq(option.balanceOf(owner), ownerBalanceBefore + issueAmount, "Option token balance error");
        assertEq(address(option).balance, contractEthBefore + issueAmount, "Contract ETH balance error");
        
        console.log("Step 2: Verify option token minting");
        console.log("  - Owner option token balance:", option.balanceOf(owner) / 10**18);
        console.log("  - Contract ETH balance:", address(option).balance / 10**18);
        console.log("Issuance successful!");
        console.log("");
    }
    
    /**
     * @notice Test 2: Complete issuance and exercise process
     */
    function test_IssueAndExercise() public {
        console.log("=== Test 2: Complete Issuance and Exercise Process ===");
        
        // ========== Phase 1: Owner issues options ==========
        console.log("Phase 1: Owner issues options");
        uint256 issueAmount = 10 ether;
        option.issue{value: issueAmount}();
        console.log("  - Owner deposits:", issueAmount / 10**18, "ETH");
        console.log("  - Minted option tokens:", option.balanceOf(owner) / 10**18);
        console.log("");
        
        // ========== Phase 2: User purchases options (simulated) ==========
        console.log("Phase 2: User purchases options (simulated transfer)");
        uint256 user1OptionAmount = 5 ether;
        option.transfer(user1, user1OptionAmount);
        console.log("  - User1 receives option tokens:", option.balanceOf(user1) / 10**18);
        console.log("");
        
        // ========== Phase 3: Prepare for exercise ==========
        console.log("Phase 3: Fast forward to expiry date");
        vm.warp(expiryDate);
        console.log("  - Current time:", block.timestamp);
        console.log("  - Expiry date:", expiryDate);
        console.log("");
        
        // Mint USDT for user1
        uint256 usdtNeeded = option.calculateExerciseCost(user1OptionAmount);
        usdt.mint(user1, usdtNeeded);
        console.log("Phase 4: User1 prepares USDT");
        console.log("  - User1 USDT balance:", usdt.balanceOf(user1) / 10**18);
        console.log("  - USDT needed for exercise:", usdtNeeded / 10**18);
        console.log("");
        
        // ========== Phase 5: User exercises ==========
        console.log("Phase 5: User1 exercises");
        
        // User1 approves option contract to use USDT
        vm.startPrank(user1);
        usdt.approve(address(option), usdtNeeded);
        
        uint256 user1EthBefore = user1.balance;
        uint256 user1UsdtBefore = usdt.balanceOf(user1);
        
        // Exercise
        vm.expectEmit(true, false, false, true);
        emit OptionExercised(user1, user1OptionAmount, user1OptionAmount, usdtNeeded);
        option.exercise(user1OptionAmount);
        vm.stopPrank();
        
        // Verify results
        assertEq(option.balanceOf(user1), 0, "Option tokens should be burned");
        assertEq(user1.balance, user1EthBefore + user1OptionAmount, "ETH balance error");
        assertEq(usdt.balanceOf(user1), user1UsdtBefore - usdtNeeded, "USDT balance error");
        
        console.log("  - User1 pays USDT:", usdtNeeded / 10**18);
        console.log("  - User1 receives ETH:", user1OptionAmount / 10**18);
        console.log("  - User1 remaining option tokens:", option.balanceOf(user1));
        console.log("Exercise successful!");
        console.log("");
    }
    
    /**
     * @notice Test 3: Expiry and redeem process
     */
    function test_ExpireAndRedeem() public {
        console.log("=== Test 3: Expiry and Redeem Process ===");
        
        // Issue 10 ETH of options
        uint256 issueAmount = 10 ether;
        option.issue{value: issueAmount}();
        console.log("Step 1: Owner issues", issueAmount / 10**18, "ETH options");
        
        // User1 exercises 3 ETH
        uint256 user1OptionAmount = 3 ether;
        option.transfer(user1, user1OptionAmount);
        
        // Fast forward to expiry date
        vm.warp(expiryDate);
        
        // User1 exercises
        uint256 usdtNeeded = option.calculateExerciseCost(user1OptionAmount);
        usdt.mint(user1, usdtNeeded);
        vm.startPrank(user1);
        usdt.approve(address(option), usdtNeeded);
        option.exercise(user1OptionAmount);
        vm.stopPrank();
        
        console.log("Step 2: User1 exercised", user1OptionAmount / 10**18, "ETH");
        console.log("  - Contract received USDT:", usdtNeeded / 10**18);
        console.log("");
        
        // Fast forward past expiry date
        vm.warp(expiryDate + 2 days);
        console.log("Step 3: Fast forward past expiry date");
        console.log("  - Current time:", block.timestamp);
        console.log("");
        
        // Owner expires and redeems
        uint256 ownerEthBefore = owner.balance;
        uint256 ownerUsdtBefore = usdt.balanceOf(owner);
        uint256 contractEthBalance = address(option).balance;
        uint256 contractUsdtBalance = option.getUsdtBalance();
        
        console.log("Step 4: Owner executes expiry and redeem");
        console.log("  - Contract ETH balance:", contractEthBalance / 10**18);
        console.log("  - Contract USDT balance:", contractUsdtBalance / 10**18);
        
        vm.expectEmit(true, false, false, true);
        emit OptionExpired(owner, contractEthBalance);
        option.expireAndRedeem();
        
        // Verify results
        assertEq(option.isExpired(), true, "Should be marked as expired");
        assertEq(owner.balance, ownerEthBefore + contractEthBalance, "ETH balance error");
        assertEq(usdt.balanceOf(owner), ownerUsdtBefore + contractUsdtBalance, "USDT balance error");
        
        console.log("Step 5: Verify redemption results");
        console.log("  - Owner redeemed ETH:", contractEthBalance / 10**18);
        console.log("  - Owner redeemed USDT:", contractUsdtBalance / 10**18);
        console.log("Expiry and redeem successful!");
        console.log("");
    }
    
    /**
     * @notice Test 4: Cannot exercise before expiry date
     */
    function testFail_ExerciseBeforeExpiryDate() public {
        // Issue options
        option.issue{value: 5 ether}();
        option.transfer(user1, 1 ether);
        
        // Prepare USDT
        uint256 usdtNeeded = option.calculateExerciseCost(1 ether);
        usdt.mint(user1, usdtNeeded);
        
        // Try to exercise before expiry date (should fail)
        vm.startPrank(user1);
        usdt.approve(address(option), usdtNeeded);
        option.exercise(1 ether);  // This will fail
        vm.stopPrank();
    }
    
    /**
     * @notice Test 5: Non-owner cannot issue
     */
    function testFail_NonOwnerIssue() public {
        vm.prank(user1);
        option.issue{value: 1 ether}();  // Should fail
    }
    
    /**
     * @notice Test 6: Non-owner cannot expire
     */
    function testFail_NonOwnerExpire() public {
        vm.warp(expiryDate + 2 days);
        vm.prank(user1);
        option.expireAndRedeem();  // Should fail
    }
    
    /**
     * @notice Test 7: Multi-user exercise scenario
     */
    function test_MultiUserExercise() public {
        console.log("=== Test 7: Multi-User Exercise Scenario ===");
        
        // Issue 20 ETH
        option.issue{value: 20 ether}();
        console.log("Owner issues 20 ETH options");
        
        // Distribute to two users
        option.transfer(user1, 8 ether);
        option.transfer(user2, 5 ether);
        console.log("  - User1 receives:", option.balanceOf(user1) / 10**18, "options");
        console.log("  - User2 receives:", option.balanceOf(user2) / 10**18, "options");
        console.log("");
        
        // Fast forward to expiry date
        vm.warp(expiryDate);
        
        // User1 exercises
        uint256 user1Amount = 8 ether;
        uint256 user1Usdt = option.calculateExerciseCost(user1Amount);
        usdt.mint(user1, user1Usdt);
        vm.startPrank(user1);
        usdt.approve(address(option), user1Usdt);
        option.exercise(user1Amount);
        vm.stopPrank();
        console.log("User1 exercises:", user1Amount / 10**18, "ETH, pays:", user1Usdt / 10**18, "USDT");
        
        // User2 exercises
        uint256 user2Amount = 5 ether;
        uint256 user2Usdt = option.calculateExerciseCost(user2Amount);
        usdt.mint(user2, user2Usdt);
        vm.startPrank(user2);
        usdt.approve(address(option), user2Usdt);
        option.exercise(user2Amount);
        vm.stopPrank();
        console.log("User2 exercises:", user2Amount / 10**18, "ETH, pays:", user2Usdt / 10**18, "USDT");
        console.log("");
        
        console.log("Verify results:");
        console.log("  - Contract remaining ETH:", address(option).balance / 10**18);
        console.log("  - Contract received USDT:", option.getUsdtBalance() / 10**18);
        console.log("Multi-user exercise successful!");
        console.log("");
    }
}
