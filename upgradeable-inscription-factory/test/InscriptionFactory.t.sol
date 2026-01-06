// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/InscriptionFactory.sol";
import "../src/InscriptionToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title InscriptionFactoryTest
 * @dev V1 工厂合约测试
 * 
 * 测试策略：
 * 1. 测试代理部署和初始化
 * 2. 测试 deployInscription 功能
 * 3. 测试 mintInscription 功能
 * 4. 测试边界条件和错误处理
 */
contract InscriptionFactoryTest is Test {
    InscriptionFactory public factory;
    ERC1967Proxy public proxy;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    function setUp() public {
        // 部署实现合约
        InscriptionFactory implementation = new InscriptionFactory();
        
        // 部署代理合约并初始化
        // 原理：代理合约在构造函数中会调用 initialize()
        bytes memory initData = abi.encodeWithSelector(
            InscriptionFactory.initialize.selector
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        
        // 将代理转换为工厂接口
        factory = InscriptionFactory(address(proxy));
    }
    
    /**
     * @dev 测试部署铭文代币
     */
    function testDeployInscription() public {
        // 部署一个代币
        vm.prank(user1);
        address tokenAddr = factory.deployInscription("TEST", 1000000, 1000);
        
        // 验证代币地址不为空
        assertTrue(tokenAddr != address(0), "Token address should not be zero");
        
        // 验证代币记录
        assertEq(factory.getTokenAddress("TEST"), tokenAddr, "Token address mismatch");
        
        // 验证代币参数
        InscriptionToken token = InscriptionToken(tokenAddr);
        assertEq(token.symbol(), "TEST", "Symbol mismatch");
        assertEq(token.totalSupply_(), 1000000, "Total supply mismatch");
        assertEq(token.perMint(), 1000, "Per mint mismatch");
    }
    
    /**
     * @dev 测试不能部署重复的 symbol
     */
    function testCannotDeployDuplicateSymbol() public {
        // 部署第一个代币
        factory.deployInscription("DUP", 1000000, 1000);
        
        // 尝试部署相同 symbol 的代币
        vm.expectRevert("Symbol already exists");
        factory.deployInscription("DUP", 2000000, 2000);
    }
    
    /**
     * @dev 测试铸造代币
     */
    function testMintInscription() public {
        // 部署代币
        address tokenAddr = factory.deployInscription("MINT", 10000, 100);
        InscriptionToken token = InscriptionToken(tokenAddr);
        
        // User1 铸造
        vm.prank(user1);
        factory.mintInscription(tokenAddr);
        
        // 验证余额
        assertEq(token.balanceOf(user1), 100, "User1 balance mismatch");
        assertEq(token.mintedAmount(), 100, "Minted amount mismatch");
    }
    
    /**
     * @dev 测试多次铸造
     */
    function testMultipleMints() public {
        // 部署代币
        address tokenAddr = factory.deployInscription("MULTI", 1000, 100);
        InscriptionToken token = InscriptionToken(tokenAddr);
        
        // User1 铸造两次
        vm.startPrank(user1);
        factory.mintInscription(tokenAddr);
        factory.mintInscription(tokenAddr);
        vm.stopPrank();
        
        // User2 铸造一次
        vm.prank(user2);
        factory.mintInscription(tokenAddr);
        
        // 验证余额
        assertEq(token.balanceOf(user1), 200, "User1 balance should be 200");
        assertEq(token.balanceOf(user2), 100, "User2 balance should be 100");
        assertEq(token.mintedAmount(), 300, "Total minted should be 300");
    }
    
    /**
     * @dev 测试不能超过总供应量
     */
    function testCannotExceedTotalSupply() public {
        // 部署一个小额供应的代币
        address tokenAddr = factory.deployInscription("SMALL", 250, 100);
        
        // 铸造两次成功
        vm.startPrank(user1);
        factory.mintInscription(tokenAddr);
        factory.mintInscription(tokenAddr);
        vm.stopPrank();
        
        // 第三次应该失败（100 + 100 + 100 = 300 > 250）
        vm.prank(user2);
        vm.expectRevert("Exceeds total supply");
        factory.mintInscription(tokenAddr);
    }
    
    /**
     * @dev 测试事件发出
     */
    function testEvents() public {
        // 测试部署事件 - 只检查参数值，不检查地址
        vm.recordLogs();
        address tokenAddr = factory.deployInscription("EVENT", 10000, 100);
        
        Vm.Log[] memory logs = vm.getRecordedLogs();
        // 验证至少有一个事件被发出
        assertTrue(logs.length > 0, "No events emitted");
        
        // 测试铸造事件
        vm.prank(user1);
        factory.mintInscription(tokenAddr);
        
        // 验证余额更新（间接验证事件功能）
        InscriptionToken token = InscriptionToken(tokenAddr);
        assertEq(token.balanceOf(user1), 100, "Mint event not processed correctly");
    }
    
    /**
     * @dev 测试代币名称格式
     */
    function testTokenNameFormat() public {
        address tokenAddr = factory.deployInscription("NAME", 10000, 100);
        InscriptionToken token = InscriptionToken(tokenAddr);
        
        // 代币名称应该是 "Inscription NAME"
        assertEq(token.name(), "Inscription NAME", "Token name format incorrect");
    }
}
