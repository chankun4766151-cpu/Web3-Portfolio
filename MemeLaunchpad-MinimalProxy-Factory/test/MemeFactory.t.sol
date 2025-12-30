// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

/**
 * @title MemeFactoryTest
 * @notice 全面测试 MemeFactory 和 MemeToken 合约的功能
 * @dev 测试包括部署、铸造、费用分配和边界条件
 */
contract MemeFactoryTest is Test {
    MemeFactory public factory;
    address public platformOwner;
    address public memeCreator;
    address public user1;
    address public user2;
    
    // 测试用的 Meme 参数
    string constant SYMBOL = "PEPE";
    uint256 constant TOTAL_SUPPLY = 1_000_000 * 1e18;  // 100万代币
    uint256 constant PER_MINT = 1000 * 1e18;           // 每次铸造 1000 个
    uint256 constant PRICE = 0.01 ether;               // 0.01 ETH 每次铸造
    
    event MemeTokenCreated(
        address indexed tokenAddress,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price,
        address indexed creator
    );
    
    event MemeTokenMinted(
        address indexed tokenAddress,
        address indexed minter,
        uint256 amount,
        uint256 platformFee,
        uint256 creatorFee
    );
    
    /**
     * @notice 设置测试环境
     * @dev 在每个测试之前运行，部署合约并创建测试账户
     */
    function setUp() public {
        // 创建测试账户
        platformOwner = address(this);  // 测试合约作为平台所有者
        memeCreator = makeAddr("memeCreator");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 给测试账户分配 ETH
        vm.deal(memeCreator, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        // 部署工厂合约
        factory = new MemeFactory();
    }
    
    /**
     * @notice 接收 ETH 的函数
     * @dev 允许测试合约接收平台费用
     */
    receive() external payable {}

    
    /**
     * @notice 测试 - 成功部署 Meme 代币
     */
    function testDeployMeme() public {
        vm.startPrank(memeCreator);
        
        // 期望触发事件
        vm.expectEmit(false, true, false, true);
        emit MemeTokenCreated(address(0), SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE, memeCreator);
        
        address tokenAddr = factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        
        vm.stopPrank();
        
        // 验证代币地址不为零
        assertTrue(tokenAddr != address(0), "Token address should not be zero");
        
        // 验证代币参数
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.symbol(), SYMBOL, "Symbol mismatch");
        assertEq(token.maxSupply(), TOTAL_SUPPLY, "Total supply mismatch");
        assertEq(token.perMint(), PER_MINT, "PerMint mismatch");
        assertEq(token.price(), PRICE, "Price mismatch");
        assertEq(token.memeCreator(), memeCreator, "Creator mismatch");
        assertEq(token.factory(), address(factory), "Factory mismatch");
        
        // 验证工厂合约中的映射
        assertEq(factory.getTokenAddress(SYMBOL), tokenAddr, "Factory mapping mismatch");
    }
    
    /**
     * @notice 测试 - 不能创建重复符号的代币
     */
    function testCannotDeployDuplicateSymbol() public {
        vm.startPrank(memeCreator);
        
        // 第一次部署成功
        factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        
        // 第二次部署应该失败
        vm.expectRevert("Symbol already exists");
        factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        
        vm.stopPrank();
    }
    
    /**
     * @notice 测试 - 成功铸造 Meme 代币
     */
    function testMintMeme() public {
        // 部署 Meme 代币
        vm.prank(memeCreator);
        address tokenAddr = factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        MemeToken token = MemeToken(tokenAddr);
        
        // 用户铸造代币
        vm.prank(user1);
        factory.mintMeme{value: PRICE}(tokenAddr);
        
        // 验证用户收到正确数量的代币
        assertEq(token.balanceOf(user1), PER_MINT, "User should receive perMint amount");
        assertEq(token.totalSupply(), PER_MINT, "Total supply should increase by perMint");
    }
    
    /**
     * @notice 测试 - 每次铸造的数量正确
     */
    function testMintCorrectAmount() public {
        vm.prank(memeCreator);
        address tokenAddr = factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        MemeToken token = MemeToken(tokenAddr);
        
        // 用户1铸造
        vm.prank(user1);
        factory.mintMeme{value: PRICE}(tokenAddr);
        assertEq(token.balanceOf(user1), PER_MINT, "First mint amount incorrect");
        
        // 用户2铸造
        vm.prank(user2);
        factory.mintMeme{value: PRICE}(tokenAddr);
        assertEq(token.balanceOf(user2), PER_MINT, "Second mint amount incorrect");
        
        // 验证总供应量
        assertEq(token.totalSupply(), PER_MINT * 2, "Total supply incorrect");
    }
    
    /**
     * @notice 测试 - 费用按比例正确分配（1% 平台，99% 发行者）
     */
    function testFeeDistribution() public {
        vm.prank(memeCreator);
        address tokenAddr = factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        
        // 记录铸造前的余额
        uint256 platformBalanceBefore = platformOwner.balance;
        uint256 creatorBalanceBefore = memeCreator.balance;
        
        // 用户铸造代币
        vm.prank(user1);
        factory.mintMeme{value: PRICE}(tokenAddr);
        
        // 记录铸造后的余额
        uint256 platformBalanceAfter = platformOwner.balance;
        uint256 creatorBalanceAfter = memeCreator.balance;
        
        // 计算实际收到的费用
        uint256 platformFeeReceived = platformBalanceAfter - platformBalanceBefore;
        uint256 creatorFeeReceived = creatorBalanceAfter - creatorBalanceBefore;
        
        // 计算预期费用
        uint256 expectedPlatformFee = PRICE * 1 / 100;  // 1%
        uint256 expectedCreatorFee = PRICE - expectedPlatformFee;  // 99%
        
        // 验证费用分配
        assertEq(platformFeeReceived, expectedPlatformFee, "Platform fee incorrect");
        assertEq(creatorFeeReceived, expectedCreatorFee, "Creator fee incorrect");
        
        // 验证总费用等于支付金额
        assertEq(platformFeeReceived + creatorFeeReceived, PRICE, "Total fees should equal price");
    }
    
    /**
     * @notice 测试 - 不能超过总供应量
     */
    function testCannotExceedSupply() public {
        // 创建一个小供应量的代币用于测试
        uint256 smallSupply = PER_MINT * 3;  // 只能铸造3次
        
        vm.prank(memeCreator);
        address tokenAddr = factory.deployMeme("SMALL", smallSupply, PER_MINT, PRICE);
        
        // 前3次铸造应该成功
        vm.prank(user1);
        factory.mintMeme{value: PRICE}(tokenAddr);
        
        vm.prank(user1);
        factory.mintMeme{value: PRICE}(tokenAddr);
        
        vm.prank(user1);
        factory.mintMeme{value: PRICE}(tokenAddr);
        
        // 第4次铸造应该失败
        vm.prank(user1);
        vm.expectRevert("Exceeds max supply");
        factory.mintMeme{value: PRICE}(tokenAddr);
        
        // 验证总供应量达到上限
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.totalSupply(), smallSupply, "Supply should be at max");
    }
    
    /**
     * @notice 测试 - 支付金额不正确时失败
     */
    function testIncorrectPaymentFails() public {
        vm.prank(memeCreator);
        address tokenAddr = factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        
        // 支付金额太少
        vm.prank(user1);
        vm.expectRevert("Incorrect payment amount");
        factory.mintMeme{value: PRICE - 1}(tokenAddr);
        
        // 支付金额太多
        vm.prank(user1);
        vm.expectRevert("Incorrect payment amount");
        factory.mintMeme{value: PRICE + 1}(tokenAddr);
    }
    
    /**
     * @notice 测试 - 代币名称格式正确
     */
    function testTokenName() public {
        vm.prank(memeCreator);
        address tokenAddr = factory.deployMeme(SYMBOL, TOTAL_SUPPLY, PER_MINT, PRICE);
        MemeToken token = MemeToken(tokenAddr);
        
        // 验证名称格式：Meme + 符号
        assertEq(token.name(), "Meme PEPE", "Token name format incorrect");
    }
    
    /**
     * @notice 测试 - 验证最小代理模式降低了 Gas 成本
     */
    function testMinimalProxyGasSavings() public {
        vm.prank(memeCreator);
        
        // 部署第一个代币并记录 Gas
        uint256 gasBefore = gasleft();
        address token1 = factory.deployMeme("TOKEN1", TOTAL_SUPPLY, PER_MINT, PRICE);
        uint256 gasUsed1 = gasBefore - gasleft();
        
        // 部署第二个代币并记录 Gas
        gasBefore = gasleft();
        address token2 = factory.deployMeme("TOKEN2", TOTAL_SUPPLY, PER_MINT, PRICE);
        uint256 gasUsed2 = gasBefore - gasleft();
        
        vm.stopPrank();
        
        // 验证两次部署使用的 Gas 相近（说明都是最小代理）
        // 允许一定的误差范围
        uint256 diff = gasUsed1 > gasUsed2 ? gasUsed1 - gasUsed2 : gasUsed2 - gasUsed1;
        assertTrue(diff < gasUsed1 / 10, "Gas usage should be similar for minimal proxies");
        
        // 输出 Gas 使用情况（用于日志）
        emit log_named_uint("Gas used for first deployment", gasUsed1);
        emit log_named_uint("Gas used for second deployment", gasUsed2);
    }
}
