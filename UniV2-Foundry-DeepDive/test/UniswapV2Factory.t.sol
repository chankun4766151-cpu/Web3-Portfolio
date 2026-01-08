// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/core/UniswapV2Pair.sol";
import "../src/test/TestERC20.sol";

/**
 * @title UniswapV2FactoryTest
 * @notice 测试 UniswapV2Factory 合约
 */
contract UniswapV2FactoryTest is Test {
    UniswapV2Factory public factory;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    address public feeToSetter;

    function setUp() public {
        feeToSetter = address(this);
        factory = new UniswapV2Factory(feeToSetter);
        
        tokenA = new TestERC20("Token A", "TKNA", 1000000 ether);
        tokenB = new TestERC20("Token B", "TKNB", 1000000 ether);
    }

    /// @notice 测试创建交易对
    function test_CreatePair() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));
        
        // 验证交易对地址不为零
        assertTrue(pair != address(0), "Pair address should not be zero");
        
        // 验证可以通过 getPair 获取
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
        assertEq(factory.getPair(address(tokenB), address(tokenA)), pair);
        
        // 验证 allPairs
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.allPairs(0), pair);
    }

    /// @notice 测试创建重复交易对应该失败
    function test_RevertWhen_CreateDuplicatePair() public {
        factory.createPair(address(tokenA), address(tokenB));
        
        vm.expectRevert("UniswapV2: PAIR_EXISTS");
        factory.createPair(address(tokenA), address(tokenB));
    }

    /// @notice 测试使用相同地址创建交易对应该失败
    function test_RevertWhen_CreatePairWithSameToken() public {
        vm.expectRevert("UniswapV2: IDENTICAL_ADDRESSES");
        factory.createPair(address(tokenA), address(tokenA));
    }

    /// @notice 测试使用零地址创建交易对应该失败
    function test_RevertWhen_CreatePairWithZeroAddress() public {
        vm.expectRevert("UniswapV2: ZERO_ADDRESS");
        factory.createPair(address(0), address(tokenB));
    }

    /// @notice 测试设置 feeTo
    function test_SetFeeTo() public {
        address newFeeTo = makeAddr("newFeeTo");
        factory.setFeeTo(newFeeTo);
        assertEq(factory.feeTo(), newFeeTo);
    }

    /// @notice 测试非授权用户设置 feeTo 应该失败
    function test_RevertWhen_UnauthorizedSetFeeTo() public {
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert("UniswapV2: FORBIDDEN");
        factory.setFeeTo(attacker);
    }

    /// @notice 测试设置 feeToSetter
    function test_SetFeeToSetter() public {
        address newSetter = makeAddr("newSetter");
        factory.setFeeToSetter(newSetter);
        assertEq(factory.feeToSetter(), newSetter);
    }

    /// @notice 测试交易对正确初始化
    function test_PairInitialization() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // 验证 token0 和 token1 正确设置（已排序）
        (address token0, address token1) = address(tokenA) < address(tokenB) 
            ? (address(tokenA), address(tokenB)) 
            : (address(tokenB), address(tokenA));
        
        assertEq(pair.token0(), token0);
        assertEq(pair.token1(), token1);
        assertEq(pair.factory(), address(factory));
    }
}
