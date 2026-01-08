// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KKToken.sol";
import "../src/StakingPool.sol";

/**
 * @title StakingPoolTest - 质押合约测试
 * @notice 全面测试 StakingPool 的各项功能
 * 
 * 测试场景覆盖：
 * 1. 基础功能测试（stake、unstake、claim）
 * 2. 奖励计算正确性验证
 * 3. 多用户公平分配验证
 * 4. 边界情况测试
 */
contract StakingPoolTest is Test {
    KKToken public kkToken;
    StakingPool public stakingPool;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    // 每区块奖励：10 KK Token
    uint256 constant REWARD_PER_BLOCK = 10 ether;

    function setUp() public {
        // 1. 部署 KKToken
        kkToken = new KKToken(address(this));
        
        // 2. 部署 StakingPool
        stakingPool = new StakingPool(address(kkToken));
        
        // 3. 设置 StakingPool 为 minter
        kkToken.setMinter(address(stakingPool));

        // 4. 给测试账户分配 ETH
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
    }

    // ============ 基础功能测试 ============

    /**
     * @dev 测试基本质押功能
     * 验证：
     * - 质押后用户余额正确
     * - 总质押量正确
     */
    function testBasicStake() public {
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        assertEq(stakingPool.balanceOf(alice), 1 ether, "Alice balance should be 1 ETH");
        assertEq(stakingPool.totalStaked(), 1 ether, "Total staked should be 1 ETH");
    }

    /**
     * @dev 测试基本赎回功能
     * 验证：
     * - 赎回后用户余额减少
     * - 用户收到 ETH
     */
    function testBasicUnstake() public {
        // 先质押
        vm.prank(alice);
        stakingPool.stake{value: 2 ether}();

        uint256 aliceBalanceBefore = alice.balance;

        // 赎回一半
        vm.prank(alice);
        stakingPool.unstake(1 ether);

        assertEq(stakingPool.balanceOf(alice), 1 ether, "Alice staked balance should be 1 ETH");
        assertEq(alice.balance, aliceBalanceBefore + 1 ether, "Alice should receive 1 ETH");
    }

    /**
     * @dev 测试质押后赎回全部
     */
    function testFullUnstake() public {
        vm.prank(alice);
        stakingPool.stake{value: 5 ether}();

        // 前进几个区块
        vm.roll(block.number + 10);

        vm.prank(alice);
        stakingPool.unstake(5 ether);

        assertEq(stakingPool.balanceOf(alice), 0, "Alice staked balance should be 0");
        assertEq(stakingPool.totalStaked(), 0, "Total staked should be 0");
    }

    // ============ 奖励计算测试 ============

    /**
     * @dev 测试单用户奖励计算
     * 
     * 场景：
     * - 区块 N：Alice 质押 1 ETH
     * - 区块 N+10：Alice 领取奖励
     * - 预期奖励：10 区块 * 10 KK/区块 = 100 KK Token
     */
    function testSingleUserReward() public {
        // Alice 质押
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        // 前进 10 个区块
        vm.roll(block.number + 10);

        // 检查预期奖励
        uint256 expectedReward = 10 * REWARD_PER_BLOCK;
        assertEq(stakingPool.earned(alice), expectedReward, "Alice should have earned 100 KK");

        // 领取奖励
        vm.prank(alice);
        stakingPool.claim();

        // 验证 KK Token 余额
        assertEq(kkToken.balanceOf(alice), expectedReward, "Alice should receive 100 KK Token");
    }

    /**
     * @dev 测试多用户公平分配
     * 
     * 场景：
     * - 区块 100：Alice 质押 1 ETH
     * - 区块 110：Bob 质押 2 ETH
     * - 区块 120：两人都领取奖励
     * 
     * 预期：
     * - 区块 100-110：100 KK 全归 Alice
     * - 区块 110-120：100 KK 按 1:2 分配
     *   - Alice: 100/3 ≈ 33.33 KK
     *   - Bob: 200/3 ≈ 66.67 KK
     * - 总计：Alice = 133.33 KK, Bob = 66.67 KK
     */
    function testMultipleUsersRewardDistribution() public {
        // 设置起始区块
        vm.roll(100);

        // Alice 在区块 100 质押 1 ETH
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        // 前进到区块 110
        vm.roll(110);

        // Bob 在区块 110 质押 2 ETH
        vm.prank(bob);
        stakingPool.stake{value: 2 ether}();

        // 前进到区块 120
        vm.roll(120);

        // 计算预期奖励
        // Alice: 10 * 10 (区块 100-110) + 10 * 10 * 1/3 (区块 110-120)
        // = 100 + 33.33... = 133.33... KK
        uint256 aliceExpected = 10 * REWARD_PER_BLOCK + (10 * REWARD_PER_BLOCK * 1 ether) / (3 ether);
        
        // Bob: 10 * 10 * 2/3 (区块 110-120) = 66.66... KK
        uint256 bobExpected = (10 * REWARD_PER_BLOCK * 2 ether) / (3 ether);

        // 检查 earned 函数返回值
        assertApproxEqRel(stakingPool.earned(alice), aliceExpected, 0.001e18, "Alice earned calculation");
        assertApproxEqRel(stakingPool.earned(bob), bobExpected, 0.001e18, "Bob earned calculation");

        // Alice 领取
        vm.prank(alice);
        stakingPool.claim();

        // Bob 领取
        vm.prank(bob);
        stakingPool.claim();

        // 验证 KK Token 分配
        assertApproxEqRel(kkToken.balanceOf(alice), aliceExpected, 0.001e18, "Alice token balance");
        assertApproxEqRel(kkToken.balanceOf(bob), bobExpected, 0.001e18, "Bob token balance");

        // 验证总分配接近 200 KK（20 区块 * 10 KK/区块）
        uint256 totalDistributed = kkToken.balanceOf(alice) + kkToken.balanceOf(bob);
        assertApproxEqRel(totalDistributed, 200 ether, 0.001e18, "Total distributed should be ~200 KK");
    }

    /**
     * @dev 测试用户在不同时间点多次质押
     * 
     * 场景：
     * - 区块 N：Alice 质押 1 ETH
     * - 区块 N+5：Alice 再质押 1 ETH
     * - 区块 N+10：Alice 领取奖励
     */
    function testMultipleStakes() public {
        // 第一次质押
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        // 前进 5 个区块
        vm.roll(block.number + 5);

        // 第二次质押
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        // 再前进 5 个区块
        vm.roll(block.number + 5);

        // 计算预期奖励
        // 区块 1-5：5 * 10 = 50 KK（只有 1 ETH 质押）
        // 区块 6-10：5 * 10 = 50 KK（2 ETH 质押，全归 Alice）
        // 总计：100 KK
        uint256 expectedReward = 100 ether;

        assertEq(stakingPool.earned(alice), expectedReward, "Alice should have 100 KK");

        // 领取
        vm.prank(alice);
        stakingPool.claim();

        assertEq(kkToken.balanceOf(alice), expectedReward, "Alice should receive 100 KK Token");
    }

    /**
     * @dev 测试赎回时奖励正确结算
     */
    function testUnstakeSettlesRewards() public {
        vm.prank(alice);
        stakingPool.stake{value: 2 ether}();

        // 前进 10 区块
        vm.roll(block.number + 10);

        // 赎回一半（会触发奖励结算）
        vm.prank(alice);
        stakingPool.unstake(1 ether);

        // 此时应该有 100 KK 待领取（已结算到 pendingRewards）
        assertEq(stakingPool.earned(alice), 100 ether, "Alice should have 100 KK pending");

        // 再前进 10 区块
        vm.roll(block.number + 10);

        // 总共应该有 100 + 100 = 200 KK
        assertEq(stakingPool.earned(alice), 200 ether, "Alice should have 200 KK total");

        // 领取全部
        vm.prank(alice);
        stakingPool.claim();

        assertEq(kkToken.balanceOf(alice), 200 ether, "Alice should receive 200 KK Token");
    }

    // ============ 边界情况测试 ============

    /**
     * @dev 测试零值质押应该失败
     */
    function testZeroStakeFails() public {
        vm.prank(alice);
        vm.expectRevert(StakingPool.ZeroAmount.selector);
        stakingPool.stake{value: 0}();
    }

    /**
     * @dev 测试超额赎回应该失败
     */
    function testOverUnstakeFails() public {
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        vm.prank(alice);
        vm.expectRevert(StakingPool.InsufficientBalance.selector);
        stakingPool.unstake(2 ether);
    }

    /**
     * @dev 测试无奖励时领取应该失败
     */
    function testClaimWithNoRewardsFails() public {
        // 质押但不前进区块
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        vm.prank(alice);
        vm.expectRevert(StakingPool.ZeroAmount.selector);
        stakingPool.claim();
    }

    /**
     * @dev 测试没有质押时的奖励计算
     */
    function testNoStakersRewardAccumulation() public {
        // 前进 100 个区块但没有人质押
        vm.roll(block.number + 100);

        // Alice 现在质押
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        // 再前进 10 个区块
        vm.roll(block.number + 10);

        // Alice 应该只能获得质押后 10 个区块的奖励
        assertEq(stakingPool.earned(alice), 100 ether, "Alice should only get rewards after staking");
    }

    /**
     * @dev 测试三个用户的复杂场景
     */
    function testThreeUsersComplexScenario() public {
        vm.roll(1000);

        // 区块 1000：Alice 质押 1 ETH
        vm.prank(alice);
        stakingPool.stake{value: 1 ether}();

        // 区块 1010：Bob 质押 1 ETH
        vm.roll(1010);
        vm.prank(bob);
        stakingPool.stake{value: 1 ether}();

        // 区块 1020：Charlie 质押 2 ETH
        vm.roll(1020);
        vm.prank(charlie);
        stakingPool.stake{value: 2 ether}();

        // 区块 1040：所有人领取
        vm.roll(1040);

        // 计算预期奖励
        // 区块 1000-1010 (10块)：100 KK，全归 Alice
        // 区块 1010-1020 (10块)：100 KK，Alice:Bob = 1:1 = 50:50
        // 区块 1020-1040 (20块)：200 KK，Alice:Bob:Charlie = 1:1:2 = 50:50:100

        uint256 aliceExpected = 100 ether + 50 ether + 50 ether; // 200 KK
        uint256 bobExpected = 50 ether + 50 ether; // 100 KK  
        uint256 charlieExpected = 100 ether; // 100 KK

        assertEq(stakingPool.earned(alice), aliceExpected, "Alice expected 200 KK");
        assertEq(stakingPool.earned(bob), bobExpected, "Bob expected 100 KK");
        assertEq(stakingPool.earned(charlie), charlieExpected, "Charlie expected 100 KK");

        // 所有人领取
        vm.prank(alice);
        stakingPool.claim();
        vm.prank(bob);
        stakingPool.claim();
        vm.prank(charlie);
        stakingPool.claim();

        // 验证总分配 = 400 KK (40 区块 * 10 KK/区块)
        uint256 total = kkToken.balanceOf(alice) + kkToken.balanceOf(bob) + kkToken.balanceOf(charlie);
        assertEq(total, 400 ether, "Total should be 400 KK");
    }

    // ============ Fuzz 测试 ============

    /**
     * @dev 模糊测试：任意金额质押和赎回
     */
    function testFuzz_StakeAndUnstake(uint256 stakeAmount, uint256 unstakeAmount) public {
        // 限制金额范围
        stakeAmount = bound(stakeAmount, 0.01 ether, 50 ether);
        unstakeAmount = bound(unstakeAmount, 0.001 ether, stakeAmount);

        vm.prank(alice);
        stakingPool.stake{value: stakeAmount}();

        vm.roll(block.number + 5);

        vm.prank(alice);
        stakingPool.unstake(unstakeAmount);

        assertEq(stakingPool.balanceOf(alice), stakeAmount - unstakeAmount);
    }
}
