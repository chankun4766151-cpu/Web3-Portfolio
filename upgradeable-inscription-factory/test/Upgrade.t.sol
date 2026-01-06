// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/InscriptionFactory.sol";
import "../src/InscriptionFactoryV2.sol";
import "../src/InscriptionToken.sol";
import "../src/InscriptionTokenV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title UpgradeTest
 * @dev 测试从 V1 升级到 V2 的完整流程
 * 
 * 测试策略：
 * 1. 部署 V1 并使用
 * 2. 升级到 V2
 * 3. 验证旧数据保持不变
 * 4. 验证新功能正常工作
 */
contract UpgradeTest is Test {
    InscriptionFactory public factoryV1;
    InscriptionFactoryV2 public factoryV2;
    ERC1967Proxy public proxy;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    address public tokenV1Addr1;
    address public tokenV1Addr2;
    
    function setUp() public {
        vm.startPrank(owner);
        
        // 1. 部署 V1 实现合约
        InscriptionFactory implementationV1 = new InscriptionFactory();
        
        // 2. 部署代理并初始化为 V1
        bytes memory initData = abi.encodeWithSelector(
            InscriptionFactory.initialize.selector
        );
        proxy = new ERC1967Proxy(address(implementationV1), initData);
        factoryV1 = InscriptionFactory(address(proxy));
        
        // 3. 使用 V1 部署一些代币
        tokenV1Addr1 = factoryV1.deployInscription("TOKEN1", 10000, 100);
        tokenV1Addr2 = factoryV1.deployInscription("TOKEN2", 20000, 200);
        
        vm.stopPrank();
        
        // 4. 用户铸造一些代币
        vm.prank(user1);
        factoryV1.mintInscription(tokenV1Addr1);
    }
    
    /**
     * @dev 测试升级过程
     */
    function testUpgradeToV2() public {
        vm.startPrank(owner);
        
        // 部署 V2 实现合约
        InscriptionFactoryV2 implementationV2 = new InscriptionFactoryV2();
        
        // 部署 TokenV2 实现合约（用于克隆）
        InscriptionTokenV2 tokenImplementation = new InscriptionTokenV2();
        
        // 执行升级
        factoryV1.upgradeToAndCall(
            address(implementationV2),
            abi.encodeWithSelector(
                InscriptionFactoryV2.initializeV2.selector,
                address(tokenImplementation)
            )
        );
        
        // 升级后，代理地址指向 V2
        factoryV2 = InscriptionFactoryV2(address(proxy));
        
        vm.stopPrank();
        
        // 验证升级成功
        assertEq(factoryV2.tokenImplementation(), address(tokenImplementation), "Token implementation not set");
        assertEq(factoryV2.collectedFees(), 0, "Collected fees should be 0");
    }
    
    /**
     * @dev 测试升级后旧数据保持不变
     */
    function testDataPersistsAfterUpgrade() public {
        // 先升级
        vm.startPrank(owner);
        InscriptionFactoryV2 implementationV2 = new InscriptionFactoryV2();
        InscriptionTokenV2 tokenImplementation = new InscriptionTokenV2();
        
        factoryV1.upgradeToAndCall(
            address(implementationV2),
            abi.encodeWithSelector(
                InscriptionFactoryV2.initializeV2.selector,
                address(tokenImplementation)
            )
        );
        factoryV2 = InscriptionFactoryV2(address(proxy));
        vm.stopPrank();
        
        // 验证旧的代币映射仍然存在
        assertEq(factoryV2.getTokenAddress("TOKEN1"), tokenV1Addr1, "TOKEN1 address lost");
        assertEq(factoryV2.getTokenAddress("TOKEN2"), tokenV1Addr2, "TOKEN2 address lost");
        
        // 验证旧代币余额保持不变
        InscriptionToken token1 = InscriptionToken(tokenV1Addr1);
        assertEq(token1.balanceOf(user1), 100, "User1 balance changed");
    }
    
    /**
     * @dev 测试升级后旧代币仍可铸造
     */
    function testOldTokensStillMintableAfterUpgrade() public {
        // 升级
        vm.startPrank(owner);
        InscriptionFactoryV2 implementationV2 = new InscriptionFactoryV2();
        InscriptionTokenV2 tokenImplementation = new InscriptionTokenV2();
        
        factoryV1.upgradeToAndCall(
            address(implementationV2),
            abi.encodeWithSelector(
                InscriptionFactoryV2.initializeV2.selector,
                address(tokenImplementation)
            )
        );
        factoryV2 = InscriptionFactoryV2(address(proxy));
        vm.stopPrank();
        
        // User2 通过 V2 工厂铸造 V1 代币
        // 注意：V1 代币没有 price，所以 price 应该是 0
        vm.prank(user2);
        factoryV2.mintInscription{value: 0}(tokenV1Addr1);
        
        // 验证铸造成功
        InscriptionToken token1 = InscriptionToken(tokenV1Addr1);
        assertEq(token1.balanceOf(user2), 100, "User2 should have 100 tokens");
    }
    
    /**
     * @dev 测试升级后新功能（带价格的部署）
     */
    function testNewFeaturesAfterUpgrade() public {
        // 升级
        vm.startPrank(owner);
        InscriptionFactoryV2 implementationV2 = new InscriptionFactoryV2();
        InscriptionTokenV2 tokenImplementation = new InscriptionTokenV2();
        
        factoryV1.upgradeToAndCall(
            address(implementationV2),
            abi.encodeWithSelector(
                InscriptionFactoryV2.initializeV2.selector,
                address(tokenImplementation)
            )
        );
        factoryV2 = InscriptionFactoryV2(address(proxy));
        vm.stopPrank();
        
        // 使用 V2 功能部署新代币（带价格）
        vm.prank(user1);
        address tokenV2Addr = factoryV2.deployInscription("NEWTOKEN", 10000, 100, 0.001 ether);
        
        // 验证代币部署成功
        assertEq(factoryV2.getTokenAddress("NEWTOKEN"), tokenV2Addr, "NEWTOKEN not deployed");
        assertEq(factoryV2.getTokenPrice(tokenV2Addr), 0.001 ether, "Token price not set");
        
        // 铸造需要支付费用
        vm.prank(user2);
        vm.deal(user2, 1 ether);
        factoryV2.mintInscription{value: 0.1 ether}(tokenV2Addr);  // 100 * 0.001 = 0.1
        
        // 验证费用收取
        assertEq(factoryV2.collectedFees(), 0.1 ether, "Fees not collected");
        
        // 验证铸造成功
        InscriptionTokenV2 tokenV2 = InscriptionTokenV2(tokenV2Addr);
        assertEq(tokenV2.balanceOf(user2), 100, "User2 should have 100 new tokens");
    }
    
    /**
     * @dev 测试所有者权限保持
     */
    function testOwnershipPersists() public {
        factoryV2 = InscriptionFactoryV2(address(proxy));
        
        // 验证所有者仍然是 owner
        assertEq(factoryV2.owner(), owner, "Owner changed");
        
        // 非所有者不能升级
        vm.prank(user1);
        vm.expectRevert();
        factoryV1.upgradeToAndCall(address(0), "");
    }
}
