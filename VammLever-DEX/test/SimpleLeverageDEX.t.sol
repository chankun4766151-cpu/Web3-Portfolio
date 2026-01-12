// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SimpleLeverageDEX.sol";
import "../src/MockUSDC.sol";

/**
 * @title SimpleLeverageDEX 测试合约
 * @dev 测试杠杆 DEX 的各种场景
 */
contract SimpleLeverageDEXTest is Test {
    SimpleLeverageDEX public dex;
    MockUSDC public usdc;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public liquidator = address(0x3);
    
    // 初始化参数
    uint256 constant INITIAL_VETH = 1000 * 1e18;    // 1000 虚拟 ETH
    uint256 constant INITIAL_VUSDC = 100000 * 1e18; // 100000 虚拟 USDC
    // 初始价格 = 100000 / 1000 = 100 USDC/ETH
    
    function setUp() public {
        // 部署 USDC
        usdc = new MockUSDC();
        
        // 部署 DEX
        dex = new SimpleLeverageDEX(INITIAL_VETH, INITIAL_VUSDC, address(usdc));
        
        // 给测试用户分发 USDC
        usdc.mint(alice, 100000 * 1e18);
        usdc.mint(bob, 100000 * 1e18);
        
        // 给 DEX 合约一些 USDC 用于支付盈利
        usdc.mint(address(dex), 1000000 * 1e18);
        
        // 用户授权 DEX 使用 USDC
        vm.prank(alice);
        usdc.approve(address(dex), type(uint256).max);
        
        vm.prank(bob);
        usdc.approve(address(dex), type(uint256).max);
    }

    /**
     * ==================== 测试 1: 做多盈利场景 ====================
     * 场景: Alice 做多，价格上涨后平仓盈利
     */
    function test_LongPositionProfit() public {
        uint256 margin = 1000 * 1e18;  // 1000 USDC 保证金
        uint256 leverage = 2;           // 2x 杠杆
        
        // 记录初始价格
        uint256 initialPrice = dex.getPrice();
        emit log_named_uint("Initial Price", initialPrice / 1e18);
        
        // Alice 开多仓
        vm.prank(alice);
        dex.openPosition(margin, leverage, true);
        
        // 检查头寸
        (uint256 posMargin, uint256 posBorrowed,, int256 position) = dex.positions(alice);
        emit log_named_uint("Alice margin", posMargin / 1e18);
        emit log_named_uint("Alice borrowed", posBorrowed / 1e18);
        emit log_named_uint("Alice position ETH", uint256(position) / 1e18);
        
        assertEq(posMargin, margin);
        assertEq(posBorrowed, margin * (leverage - 1)); // borrowed = margin * (level - 1)
        assertTrue(position > 0); // 做多是正数头寸
        
        // 价格因为买入已经上涨
        uint256 newPrice = dex.getPrice();
        emit log_named_uint("Price after buy", newPrice / 1e18);
        assertTrue(newPrice > initialPrice);
        
        // 模拟价格进一步上涨 (另一个用户也做多)
        vm.prank(bob);
        dex.openPosition(5000 * 1e18, 2, true);
        
        uint256 priceAfterBob = dex.getPrice();
        emit log_named_uint("Price after Bob long", priceAfterBob / 1e18);
        
        // 计算 Alice 的 PnL
        int256 pnl = dex.calculatePnL(alice);
        emit log_named_int("Alice PnL", pnl / 1e18);
        assertTrue(pnl > 0); // 应该盈利
        
        // Alice 平仓
        uint256 balanceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        dex.closePosition();
        uint256 balanceAfter = usdc.balanceOf(alice);
        
        emit log_named_uint("Alice received", (balanceAfter - balanceBefore) / 1e18);
        assertTrue(balanceAfter > balanceBefore);
        
        // 验证头寸已清除
        (,,, int256 positionAfter) = dex.positions(alice);
        assertEq(positionAfter, 0);
    }

    /**
     * ==================== 测试 2: 做多亏损场景 ====================
     * 场景: Alice 做多，价格下跌后平仓亏损
     */
    function test_LongPositionLoss() public {
        uint256 margin = 1000 * 1e18;
        uint256 leverage = 3;  // 3x 杠杆，放大亏损
        
        uint256 initialPrice = dex.getPrice();
        emit log_named_uint("Initial Price", initialPrice / 1e18);
        
        // Alice 开多仓
        vm.prank(alice);
        dex.openPosition(margin, leverage, true);
        
        (,,, int256 position) = dex.positions(alice);
        emit log_named_uint("Alice position ETH", uint256(position) / 1e18);
        
        // Bob 做空，导致价格下跌
        vm.prank(bob);
        dex.openPosition(10000 * 1e18, 3, false);
        
        uint256 newPrice = dex.getPrice();
        emit log_named_uint("Price after Bob short", newPrice / 1e18);
        assertTrue(newPrice < initialPrice);
        
        // 计算 Alice 的 PnL
        int256 pnl = dex.calculatePnL(alice);
        emit log_named_int("Alice PnL", pnl / 1e18);
        assertTrue(pnl < 0); // 应该亏损
        
        // Alice 平仓
        uint256 balanceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        dex.closePosition();
        uint256 balanceAfter = usdc.balanceOf(alice);
        
        uint256 received = balanceAfter - balanceBefore;
        emit log_named_uint("Alice received USDC", received / 1e18);
    }

    /**
     * ==================== 测试 3: 做空盈利场景 ====================
     * 场景: Alice 做空，价格下跌后平仓盈利
     */
    function test_ShortPositionProfit() public {
        uint256 margin = 1000 * 1e18;
        uint256 leverage = 2;
        
        uint256 initialPrice = dex.getPrice();
        emit log_named_uint("Initial Price", initialPrice / 1e18);
        
        // Alice 开空仓
        vm.prank(alice);
        dex.openPosition(margin, leverage, false);
        
        (uint256 posMargin, ,, int256 position) = dex.positions(alice);
        emit log_named_uint("Alice margin", posMargin / 1e18);
        emit log_named_int("Alice position (negative=short)", position / 1e18);
        assertTrue(position < 0); // 做空是负数头寸
        
        // 价格因为卖出已经下跌
        uint256 newPrice = dex.getPrice();
        emit log_named_uint("Price after short", newPrice / 1e18);
        assertTrue(newPrice < initialPrice);
        
        // Bob 也做空，导致价格进一步下跌
        vm.prank(bob);
        dex.openPosition(5000 * 1e18, 2, false);
        
        uint256 priceAfterBob = dex.getPrice();
        emit log_named_uint("Price after Bob short", priceAfterBob / 1e18);
        
        // 计算 Alice 的 PnL
        int256 pnl = dex.calculatePnL(alice);
        emit log_named_int("Alice PnL", pnl / 1e18);
        assertTrue(pnl > 0); // 做空后价格下跌应该盈利
        
        // Alice 平仓
        uint256 balanceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        dex.closePosition();
        uint256 balanceAfter = usdc.balanceOf(alice);
        
        emit log_named_uint("Alice received", (balanceAfter - balanceBefore) / 1e18);
        assertTrue(balanceAfter - balanceBefore > margin); // 收回超过保证金 = 盈利
    }

    /**
     * ==================== 测试 4: 清算场景 ====================
     * 场景: Alice 做多但价格暴跌，亏损超过 80%，被清算
     */
    function test_Liquidation() public {
        uint256 margin = 1000 * 1e18;
        uint256 leverage = 5;  // 5x 高杠杆，更容易被清算
        
        // Alice 开多仓
        vm.prank(alice);
        dex.openPosition(margin, leverage, true);
        
        uint256 priceAfterAlice = dex.getPrice();
        emit log_named_uint("Price after Alice long", priceAfterAlice / 1e18);
        
        // Bob 大量做空，导致价格暴跌
        vm.prank(bob);
        dex.openPosition(50000 * 1e18, 5, false);
        
        uint256 priceAfterBob = dex.getPrice();
        emit log_named_uint("Price after Bob massive short", priceAfterBob / 1e18);
        
        // 计算 Alice 的 PnL
        int256 pnl = dex.calculatePnL(alice);
        emit log_named_int("Alice PnL (should be negative)", pnl / 1e18);
        
        // 检查是否满足清算条件 (亏损 > 80% 保证金)
        assertTrue(pnl < 0);
        uint256 loss = uint256(-pnl);
        emit log_named_uint("Loss percentage", loss * 100 / margin);
        assertTrue(loss > margin * 80 / 100);
        
        // 清算人尝试清算
        uint256 liquidatorBalanceBefore = usdc.balanceOf(liquidator);
        
        vm.prank(liquidator);
        dex.liquidatePosition(alice);
        
        uint256 liquidatorBalanceAfter = usdc.balanceOf(liquidator);
        uint256 liquidatorReward = liquidatorBalanceAfter - liquidatorBalanceBefore;
        emit log_named_uint("Liquidator reward", liquidatorReward / 1e18);
        
        // 验证 Alice 头寸已清除
        (,,, int256 positionAfter) = dex.positions(alice);
        assertEq(positionAfter, 0);
    }

    /**
     * ==================== 测试 5: 清算限制 ====================
     * 场景: 不满足清算条件时，清算应该失败
     */
    function test_LiquidationRevert() public {
        uint256 margin = 1000 * 1e18;
        uint256 leverage = 2;  // 低杠杆，不易被清算
        
        // Alice 开多仓
        vm.prank(alice);
        dex.openPosition(margin, leverage, true);
        
        // Bob 小量做空，价格小幅下跌
        vm.prank(bob);
        dex.openPosition(500 * 1e18, 1, false);
        
        int256 pnl = dex.calculatePnL(alice);
        emit log_named_int("Alice PnL", pnl / 1e18);
        
        // 尝试清算应该失败（亏损不够大）
        vm.prank(liquidator);
        vm.expectRevert("Position not liquidatable");
        dex.liquidatePosition(alice);
    }

    /**
     * ==================== 测试 6: 不能自我清算 ====================
     */
    function test_CannotSelfLiquidate() public {
        // Alice 开仓
        vm.prank(alice);
        dex.openPosition(1000 * 1e18, 5, true);
        
        // Bob 做空导致价格暴跌
        vm.prank(bob);
        dex.openPosition(50000 * 1e18, 5, false);
        
        // Alice 尝试自我清算应该失败
        vm.prank(alice);
        vm.expectRevert("Cannot liquidate yourself");
        dex.liquidatePosition(alice);
    }

    /**
     * ==================== 测试 7: 不能重复开仓 ====================
     */
    function test_CannotOpenDuplicatePosition() public {
        // Alice 开仓
        vm.prank(alice);
        dex.openPosition(1000 * 1e18, 2, true);
        
        // Alice 尝试再次开仓应该失败
        vm.prank(alice);
        vm.expectRevert("Position already open");
        dex.openPosition(500 * 1e18, 2, false);
    }
}
