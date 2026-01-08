// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/core/UniswapV2Pair.sol";
import "../src/periphery/UniswapV2Router02.sol";
import "../src/periphery/WETH9.sol";
import "../src/test/TestERC20.sol";

/**
 * @title UniswapV2RouterTest
 * @notice 测试 UniswapV2Router02 合约
 * @dev 包括添加/移除流动性和交换功能测试
 */
contract UniswapV2RouterTest is Test {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    WETH9 public weth;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    
    address public user1;
    address public user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 给用户一些 ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        // 部署合约
        factory = new UniswapV2Factory(address(this));
        weth = new WETH9();
        router = new UniswapV2Router02(address(factory), address(weth));
        
        tokenA = new TestERC20("Token A", "TKNA", 1000000 ether);
        tokenB = new TestERC20("Token B", "TKNB", 1000000 ether);
        
        // 给用户分配代币
        tokenA.mint(user1, 100000 ether);
        tokenB.mint(user1, 100000 ether);
        tokenA.mint(user2, 100000 ether);
        tokenB.mint(user2, 100000 ether);
    }

    // ==================== 添加流动性测试 ====================
    
    /// @notice 测试添加流动性（两个 ERC20）
    function test_AddLiquidity() public {
        uint256 amountA = 10000 ether;
        uint256 amountB = 10000 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertEq(actualAmountA, amountA, "Wrong amountA");
        assertEq(actualAmountB, amountB, "Wrong amountB");
        assertTrue(liquidity > 0, "No liquidity minted");
        
        // 验证交易对创建
        address pair = factory.getPair(address(tokenA), address(tokenB));
        assertTrue(pair != address(0), "Pair not created");
    }

    /// @notice 测试添加 ETH 流动性
    function test_AddLiquidityETH() public {
        uint256 amountToken = 10000 ether;
        uint256 amountETH = 10 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountToken);
        
        (uint256 actualAmountToken, uint256 actualAmountETH, uint256 liquidity) = router.addLiquidityETH{value: amountETH}(
            address(tokenA),
            amountToken,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertEq(actualAmountToken, amountToken, "Wrong token amount");
        assertEq(actualAmountETH, amountETH, "Wrong ETH amount");
        assertTrue(liquidity > 0, "No liquidity minted");
        
        // 验证交易对创建
        address pair = factory.getPair(address(tokenA), address(weth));
        assertTrue(pair != address(0), "WETH pair not created");
    }

    // ==================== 移除流动性测试 ====================
    
    /// @notice 测试移除流动性
    function test_RemoveLiquidity() public {
        // 先添加流动性
        uint256 amountA = 10000 ether;
        uint256 amountB = 10000 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        (,, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        
        // 获取 pair 地址并授权
        address pair = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair(pair).approve(address(router), liquidity);
        
        // 记录移除前余额
        uint256 tokenABefore = tokenA.balanceOf(user1);
        uint256 tokenBBefore = tokenB.balanceOf(user1);
        
        // 移除流动性
        (uint256 amountAOut, uint256 amountBOut) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证收到代币
        assertEq(tokenA.balanceOf(user1) - tokenABefore, amountAOut, "Wrong tokenA returned");
        assertEq(tokenB.balanceOf(user1) - tokenBBefore, amountBOut, "Wrong tokenB returned");
    }

    // ==================== 交换测试 ====================
    
    /// @notice 测试精确输入交换
    function test_SwapExactTokensForTokens() public {
        // 先添加流动性
        uint256 amountA = 10000 ether;
        uint256 amountB = 10000 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // user2 交换
        uint256 swapAmountIn = 100 ether;
        
        vm.startPrank(user2);
        tokenA.approve(address(router), swapAmountIn);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint256 tokenBBefore = tokenB.balanceOf(user2);
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmountIn,
            0, // 接受任何数量的输出
            path,
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertEq(amounts[0], swapAmountIn, "Wrong input amount");
        assertTrue(amounts[1] > 0, "No output");
        assertEq(tokenB.balanceOf(user2) - tokenBBefore, amounts[1], "Wrong output received");
    }

    /// @notice 测试精确输出交换
    function test_SwapTokensForExactTokens() public {
        // 先添加流动性
        uint256 amountA = 10000 ether;
        uint256 amountB = 10000 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // user2 交换
        uint256 swapAmountOut = 100 ether;
        uint256 maxAmountIn = 200 ether;
        
        vm.startPrank(user2);
        tokenA.approve(address(router), maxAmountIn);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint256 tokenABefore = tokenA.balanceOf(user2);
        uint256 tokenBBefore = tokenB.balanceOf(user2);
        
        uint256[] memory amounts = router.swapTokensForExactTokens(
            swapAmountOut,
            maxAmountIn,
            path,
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertEq(amounts[amounts.length - 1], swapAmountOut, "Wrong output amount");
        assertEq(tokenABefore - tokenA.balanceOf(user2), amounts[0], "Wrong input used");
        assertEq(tokenB.balanceOf(user2) - tokenBBefore, swapAmountOut, "Wrong output received");
    }

    /// @notice 测试 ETH -> Token 交换
    function test_SwapExactETHForTokens() public {
        // 先添加 ETH/Token 流动性
        uint256 amountToken = 10000 ether;
        uint256 amountETH = 10 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountToken);
        
        router.addLiquidityETH{value: amountETH}(
            address(tokenA),
            amountToken,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // user2 用 ETH 换 Token
        uint256 swapAmountIn = 1 ether;
        
        vm.startPrank(user2);
        
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(tokenA);
        
        uint256 tokenABefore = tokenA.balanceOf(user2);
        
        uint256[] memory amounts = router.swapExactETHForTokens{value: swapAmountIn}(
            0,
            path,
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertTrue(amounts[1] > 0, "No tokens received");
        assertEq(tokenA.balanceOf(user2) - tokenABefore, amounts[1], "Wrong token amount received");
    }

    /// @notice 测试 Token -> ETH 交换
    function test_SwapExactTokensForETH() public {
        // 先添加 ETH/Token 流动性
        uint256 amountToken = 10000 ether;
        uint256 amountETH = 10 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountToken);
        
        router.addLiquidityETH{value: amountETH}(
            address(tokenA),
            amountToken,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // user2 用 Token 换 ETH
        uint256 swapAmountIn = 100 ether;
        
        vm.startPrank(user2);
        tokenA.approve(address(router), swapAmountIn);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(weth);
        
        uint256 ethBefore = user2.balance;
        
        uint256[] memory amounts = router.swapExactTokensForETH(
            swapAmountIn,
            0,
            path,
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertTrue(amounts[1] > 0, "No ETH received");
        assertEq(user2.balance - ethBefore, amounts[1], "Wrong ETH amount received");
    }

    /// @notice 测试多跳交换
    function test_MultiHopSwap() public {
        // 创建两个交易对：A-B 和 B-C
        TestERC20 tokenC = new TestERC20("Token C", "TKNC", 1000000 ether);
        tokenC.mint(user1, 100000 ether);
        
        vm.startPrank(user1);
        
        // A-B 流动性
        tokenA.approve(address(router), 10000 ether);
        tokenB.approve(address(router), 10000 ether);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            10000 ether,
            10000 ether,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        
        // B-C 流动性
        tokenB.approve(address(router), 10000 ether);
        tokenC.approve(address(router), 10000 ether);
        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            10000 ether,
            10000 ether,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // user2: A -> B -> C 多跳交换
        uint256 swapAmountIn = 100 ether;
        
        vm.startPrank(user2);
        tokenA.approve(address(router), swapAmountIn);
        
        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);
        
        uint256 tokenCBefore = tokenC.balanceOf(user2);
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            path,
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 验证
        assertEq(amounts.length, 3, "Wrong amounts length");
        assertEq(amounts[0], swapAmountIn, "Wrong input amount");
        assertTrue(amounts[1] > 0, "No B output");
        assertTrue(amounts[2] > 0, "No C output");
        assertEq(tokenC.balanceOf(user2) - tokenCBefore, amounts[2], "Wrong C received");
    }

    /// @notice 测试过期交易应该失败
    function test_RevertWhen_Expired() public {
        vm.startPrank(user1);
        tokenA.approve(address(router), 1000 ether);
        tokenB.approve(address(router), 1000 ether);
        
        // 使用过去的 deadline
        vm.expectRevert("UniswapV2Router: EXPIRED");
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 ether,
            1000 ether,
            0,
            0,
            user1,
            block.timestamp - 1 // 过期
        );
        vm.stopPrank();
    }

    /// @notice 测试滑点保护
    function test_RevertWhen_InsufficientOutput() public {
        // 先添加流动性
        uint256 amountA = 10000 ether;
        uint256 amountB = 10000 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            user1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // 尝试交换，但设置很高的最小输出
        uint256 swapAmountIn = 100 ether;
        
        vm.startPrank(user2);
        tokenA.approve(address(router), swapAmountIn);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        vm.expectRevert("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        router.swapExactTokensForTokens(
            swapAmountIn,
            1000 ether, // 不可能达到的输出
            path,
            user2,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
    }
}
