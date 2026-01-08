// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/core/UniswapV2Pair.sol";
import "../src/core/libraries/Math.sol";
import "../src/test/TestERC20.sol";

/**
 * @title UniswapV2PairTest
 * @notice 测试 UniswapV2Pair 合约的核心功能
 * @dev 包括 mint、burn、swap 功能测试
 */
contract UniswapV2PairTest is Test {
    UniswapV2Factory public factory;
    UniswapV2Pair public pair;
    TestERC20 public token0;
    TestERC20 public token1;
    
    address public user1;
    address public user2;
    
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        factory = new UniswapV2Factory(address(this));
        
        TestERC20 tokenA = new TestERC20("Token A", "TKNA", 1000000 ether);
        TestERC20 tokenB = new TestERC20("Token B", "TKNB", 1000000 ether);
        
        // 创建交易对
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        pair = UniswapV2Pair(pairAddress);
        
        // 确定 token0 和 token1
        (token0, token1) = address(tokenA) < address(tokenB) 
            ? (tokenA, tokenB) 
            : (tokenB, tokenA);
        
        // 给用户分配代币
        token0.mint(user1, 100000 ether);
        token1.mint(user1, 100000 ether);
        token0.mint(user2, 100000 ether);
        token1.mint(user2, 100000 ether);
    }

    /// @notice 测试首次添加流动性
    function test_Mint_FirstLiquidity() public {
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        
        uint256 liquidity = pair.mint(user1);
        vm.stopPrank();
        
        // 首次添加流动性：liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
        uint256 expectedLiquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        assertEq(liquidity, expectedLiquidity, "Wrong liquidity minted");
        
        // 验证 LP Token 余额
        assertEq(pair.balanceOf(user1), expectedLiquidity, "Wrong LP balance");
        
        // 验证锁定的最小流动性
        assertEq(pair.balanceOf(address(0)), MINIMUM_LIQUIDITY, "MINIMUM_LIQUIDITY not locked");
        
        // 验证储备量
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, amount0, "Wrong reserve0");
        assertEq(reserve1, amount1, "Wrong reserve1");
    }

    /// @notice 测试后续添加流动性
    function test_Mint_SubsequentLiquidity() public {
        // 首次添加流动性
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(user1);
        vm.stopPrank();
        
        // 第二次添加流动性
        uint256 amount0_2 = 500 ether;
        uint256 amount1_2 = 500 ether;
        
        vm.startPrank(user2);
        token0.transfer(address(pair), amount0_2);
        token1.transfer(address(pair), amount1_2);
        
        uint256 totalSupplyBefore = pair.totalSupply();
        uint256 liquidity = pair.mint(user2);
        vm.stopPrank();
        
        // 后续添加：liquidity = min(amount0/reserve0, amount1/reserve1) * totalSupply
        uint256 expectedLiquidity = Math.min(
            amount0_2 * totalSupplyBefore / amount0,
            amount1_2 * totalSupplyBefore / amount1
        );
        assertEq(liquidity, expectedLiquidity, "Wrong subsequent liquidity");
    }

    /// @notice 测试移除流动性
    function test_Burn() public {
        // 首先添加流动性
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        uint256 liquidity = pair.mint(user1);
        
        // 记录移除前的余额
        uint256 token0BalanceBefore = token0.balanceOf(user1);
        uint256 token1BalanceBefore = token1.balanceOf(user1);
        
        // 移除流动性
        pair.transfer(address(pair), liquidity);
        (uint256 amount0Out, uint256 amount1Out) = pair.burn(user1);
        vm.stopPrank();
        
        // 验证返还的代币数量
        assertEq(token0.balanceOf(user1) - token0BalanceBefore, amount0Out, "Wrong token0 returned");
        assertEq(token1.balanceOf(user1) - token1BalanceBefore, amount1Out, "Wrong token1 returned");
        
        // 验证 LP Token 已销毁
        assertEq(pair.balanceOf(user1), 0, "LP tokens not burned");
    }

    /// @notice 测试代币交换
    function test_Swap() public {
        // 首先添加流动性
        uint256 amount0 = 10000 ether;
        uint256 amount1 = 10000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(user1);
        vm.stopPrank();
        
        // 执行交换：用 token0 换 token1
        uint256 swapAmount0In = 100 ether;
        
        // 计算预期输出（考虑 0.3% 手续费）
        // amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
        uint256 expectedAmount1Out = (swapAmount0In * 997 * amount1) / (amount0 * 1000 + swapAmount0In * 997);
        
        vm.startPrank(user2);
        token0.transfer(address(pair), swapAmount0In);
        
        uint256 token1BalanceBefore = token1.balanceOf(user2);
        pair.swap(0, expectedAmount1Out, user2, "");
        vm.stopPrank();
        
        // 验证输出
        assertEq(token1.balanceOf(user2) - token1BalanceBefore, expectedAmount1Out, "Wrong swap output");
    }

    /// @notice 测试交换时 k 值不能减少
    function test_RevertWhen_SwapViolatesK() public {
        // 添加流动性
        uint256 amount0 = 10000 ether;
        uint256 amount1 = 10000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(user1);
        vm.stopPrank();
        
        // 尝试取出超过允许的数量（违反 k 值）
        vm.startPrank(user2);
        token0.transfer(address(pair), 100 ether);
        
        // 尝试取出比计算值更多的代币
        vm.expectRevert("UniswapV2: K");
        pair.swap(0, 100 ether, user2, "");
        vm.stopPrank();
    }

    /// @notice 测试 sync 函数
    function test_Sync() public {
        // 添加流动性
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(user1);
        
        // 直接转入额外代币（不通过正常流程）
        uint256 extraAmount = 100 ether;
        token0.transfer(address(pair), extraAmount);
        
        // 储备量应该还是旧值
        (uint112 reserve0Before,,) = pair.getReserves();
        assertEq(reserve0Before, amount0, "Reserve should be unchanged before sync");
        
        // 调用 sync
        pair.sync();
        
        // 储备量应该更新
        (uint112 reserve0After,,) = pair.getReserves();
        assertEq(reserve0After, amount0 + extraAmount, "Reserve should be updated after sync");
        vm.stopPrank();
    }

    /// @notice 测试 skim 函数
    function test_Skim() public {
        // 添加流动性
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 1000 ether;
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(user1);
        
        // 直接转入额外代币
        uint256 extraAmount = 100 ether;
        token0.transfer(address(pair), extraAmount);
        
        // skim 到 user2
        uint256 user2BalanceBefore = token0.balanceOf(user2);
        pair.skim(user2);
        
        // 验证 user2 收到了多余的代币
        assertEq(token0.balanceOf(user2) - user2BalanceBefore, extraAmount, "Skim failed");
        vm.stopPrank();
    }

    /// @notice 测试价格累积（用于 TWAP）
    function test_PriceAccumulation() public {
        // 添加流动性
        uint256 amount0 = 1000 ether;
        uint256 amount1 = 2000 ether; // 价格比例 1:2
        
        vm.startPrank(user1);
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(user1);
        vm.stopPrank();
        
        uint256 price0CumulativeBefore = pair.price0CumulativeLast();
        uint256 price1CumulativeBefore = pair.price1CumulativeLast();
        
        // 推进时间
        vm.warp(block.timestamp + 1 hours);
        
        // 触发价格更新（通过 sync）
        pair.sync();
        
        // 验证价格累积已更新
        assertTrue(pair.price0CumulativeLast() > price0CumulativeBefore, "price0Cumulative not updated");
        assertTrue(pair.price1CumulativeLast() > price1CumulativeBefore, "price1Cumulative not updated");
    }
}
