// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RebaseShrinkToken.sol";

/**
 * @title RebaseShrinkToken 测试合约
 * @dev 测试 rebase 通缩机制的正确性
 */
contract RebaseShrinkTokenTest is Test {
    RebaseShrinkToken public token;
    
    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18;

    function setUp() public {
        token = new RebaseShrinkToken();
    }

    /**
     * @dev 测试初始状态
     * 验证：初始供应量为 1 亿，部署者拥有全部代币
     */
    function testInitialState() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Initial supply should be 100 million");
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY, "Owner should have all tokens");
        assertEq(token.totalShares(), INITIAL_SUPPLY, "Total shares should equal initial supply");
        assertEq(token.sharesOf(owner), INITIAL_SUPPLY, "Owner should have all shares");
        assertEq(token.rebaseCount(), 0, "Rebase count should be 0");
    }

    /**
     * @dev 测试单次 rebase
     * 验证：rebase 后总供应量减少 1%
     */
    function testSingleRebase() public {
        console.log("=== Test: Single Rebase ===");
        console.log("Initial total supply:", token.totalSupply());
        console.log("Initial owner balance:", token.balanceOf(owner));
        
        // 执行 rebase
        token.rebase();
        
        // 验证总供应量减少 1%（即变为 99%）
        uint256 expectedSupply = INITIAL_SUPPLY * 99 / 100;
        assertEq(token.totalSupply(), expectedSupply, "Supply should decrease by 1%");
        
        // 验证用户余额也相应减少
        assertEq(token.balanceOf(owner), expectedSupply, "Owner balance should decrease by 1%");
        
        // 验证份额不变（这是关键！份额保持不变，只是每份额对应的价值变了）
        assertEq(token.sharesOf(owner), INITIAL_SUPPLY, "Shares should remain unchanged");
        
        console.log("After rebase total supply:", token.totalSupply());
        console.log("After rebase owner balance:", token.balanceOf(owner));
        console.log("Owner shares (unchanged):", token.sharesOf(owner));
    }

    /**
     * @dev 测试多次 rebase（模拟多年通缩）
     * 验证：每次 rebase 都在上一次基础上减少 1%
     */
    function testMultipleRebases() public {
        console.log("=== Test: Multiple Rebases (5 years) ===");
        
        uint256 currentSupply = INITIAL_SUPPLY;
        
        for (uint256 i = 1; i <= 5; i++) {
            token.rebase();
            currentSupply = currentSupply * 99 / 100;
            
            console.log("Year", i, "- Supply:", token.totalSupply());
            console.log("Year", i, "- Balance:", token.balanceOf(owner));
            
            assertEq(token.totalSupply(), currentSupply, "Supply should compound correctly");
            assertEq(token.balanceOf(owner), currentSupply, "Balance should match supply");
            assertEq(token.rebaseCount(), i, "Rebase count should increment");
        }
        
        // 5年后的预期值：初始值 × 0.99^5 ≈ 0.9509900499
        uint256 expected5Years = INITIAL_SUPPLY;
        for (uint256 i = 0; i < 5; i++) {
            expected5Years = expected5Years * 99 / 100;
        }
        assertEq(token.totalSupply(), expected5Years, "5-year compound should be correct");
        
        console.log("After 5 years, supply is approximately", token.totalSupply() * 100 / INITIAL_SUPPLY, "% of initial");
    }

    /**
     * @dev 测试 rebase 后的转账
     * 验证：rebase 后转账金额和余额都正确
     */
    function testTransferAfterRebase() public {
        console.log("=== Test: Transfer After Rebase ===");
        
        // 先转一半给 Alice
        uint256 halfInitial = INITIAL_SUPPLY / 2;
        token.transfer(alice, halfInitial);
        
        console.log("Before rebase:");
        console.log("  Owner balance:", token.balanceOf(owner));
        console.log("  Alice balance:", token.balanceOf(alice));
        
        assertEq(token.balanceOf(owner), halfInitial, "Owner should have half");
        assertEq(token.balanceOf(alice), halfInitial, "Alice should have half");
        
        // 执行 rebase
        token.rebase();
        
        // rebase 后，两人余额都应该减少 1%
        uint256 expectedAfterRebase = halfInitial * 99 / 100;
        
        console.log("After rebase:");
        console.log("  Owner balance:", token.balanceOf(owner));
        console.log("  Alice balance:", token.balanceOf(alice));
        console.log("  Total supply:", token.totalSupply());
        
        assertEq(token.balanceOf(owner), expectedAfterRebase, "Owner balance should decrease 1%");
        assertEq(token.balanceOf(alice), expectedAfterRebase, "Alice balance should decrease 1%");
        
        // 验证转账后的份额
        assertEq(token.sharesOf(owner), halfInitial, "Owner shares unchanged");
        assertEq(token.sharesOf(alice), halfInitial, "Alice shares unchanged");
    }

    /**
     * @dev 测试 rebase 后的转账操作
     * 验证：rebase 后仍可正常转账，金额正确
     */
    function testTransferBetweenUsersAfterRebase() public {
        console.log("=== Test: Transfer Between Users After Rebase ===");
        
        // Owner 转账给 Alice
        token.transfer(alice, INITIAL_SUPPLY / 2);
        
        // 执行 rebase
        token.rebase();
        
        // Alice 转一部分给 Bob
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        uint256 transferAmount = aliceBalanceBefore / 4;
        
        vm.prank(alice);
        token.transfer(bob, transferAmount);
        
        console.log("Alice balance after transfer:", token.balanceOf(alice));
        console.log("Bob balance after transfer:", token.balanceOf(bob));
        
        // 验证余额
        assertEq(token.balanceOf(bob), transferAmount, "Bob should receive correct amount");
        // 注意：由于整数除法，可能有微小误差
        assertApproxEqAbs(
            token.balanceOf(alice), 
            aliceBalanceBefore - transferAmount, 
            1, // 允许 1 wei 的误差
            "Alice balance should decrease correctly"
        );
    }

    /**
     * @dev 测试只有 owner 可以 rebase
     */
    function testOnlyOwnerCanRebase() public {
        vm.prank(alice);
        vm.expectRevert(); // 预期会 revert
        token.rebase();
    }

    /**
     * @dev 测试 10 年后的复利效应
     * 验证：理解复利通缩的效果
     */
    function testTenYearsDeflation() public {
        console.log("=== Test: 10 Years Deflation Compound Effect ===");
        console.log("Initial supply:", INITIAL_SUPPLY / 10**18, "tokens");
        
        for (uint256 i = 0; i < 10; i++) {
            token.rebase();
        }
        
        uint256 finalSupply = token.totalSupply();
        console.log("After 10 years supply:", finalSupply / 10**18, "tokens");
        
        // 10年后的理论值：初始值 × 0.99^10 ≈ 0.9043820750
        // 即大约减少了 9.56%
        uint256 expected10Years = INITIAL_SUPPLY;
        for (uint256 i = 0; i < 10; i++) {
            expected10Years = expected10Years * 99 / 100;
        }
        
        assertEq(finalSupply, expected10Years, "10-year compound should be correct");
        
        // 计算保留百分比
        uint256 retainedPercentage = finalSupply * 10000 / INITIAL_SUPPLY;
        console.log("Retained percentage (in basis points):", retainedPercentage);
        console.log("That means approximately", retainedPercentage / 100, "% retained");
    }

    /**
     * @dev 测试授权和 transferFrom
     */
    function testApproveAndTransferFrom() public {
        // Owner 授权 Alice
        token.approve(alice, INITIAL_SUPPLY);
        assertEq(token.allowance(owner, alice), INITIAL_SUPPLY);
        
        // 执行 rebase
        token.rebase();
        
        // Alice 使用授权转账给 Bob
        uint256 amount = 1000 * 10**18;
        vm.prank(alice);
        token.transferFrom(owner, bob, amount);
        
        assertApproxEqAbs(token.balanceOf(bob), amount, 1, "Bob should receive tokens");
    }
}
