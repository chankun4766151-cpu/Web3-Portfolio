// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    MyToken public token;
    TokenBank public bank;

    address public user;
    uint256 public userPrivateKey;

    function setUp() public {
        // 创建一个模拟用户及其私钥
        userPrivateKey = 0xABC123;
        user = vm.addr(userPrivateKey);

        // 部署合约
        token = new MyToken();
        bank = new TokenBank(address(token));

        // 给用户一些测试代币
        token.mint(user, 1000 * 10**18);
    }

    function testPermitDeposit() public {
        uint256 depositAmount = 100 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;

        // 1. 获取 nonce (ERC20Permit 内部维护)
        uint256 nonce = token.nonces(user);

        // 2. 构建 EIP-712 签名哈希
        // 结构化数据包括：owner, spender, value, nonce, deadline
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user,
                address(bank),
                depositAmount,
                nonce,
                deadline
            )
        );

        bytes32 hash = _computeDigest(token.DOMAIN_SEPARATOR(), structHash);

        // 3. 使用私钥签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, hash);

        // 4. 调用 permitDeposit
        console.log("Before Deposit - User Balance:", token.balanceOf(user) / 10**18, "MTK");
        console.log("Before Deposit - Bank Balance:", token.balanceOf(address(bank)) / 10**18, "MTK");
        
        vm.prank(user);
        bank.permitDeposit(depositAmount, deadline, v, r, s);

        console.log("After Deposit - User Balance:", token.balanceOf(user) / 10**18, "MTK");
        console.log("After Deposit - Bank Balance:", token.balanceOf(address(bank)) / 10**18, "MTK");

        // 5. 验证结果
        assertEq(token.balanceOf(address(bank)), depositAmount);
        assertEq(bank.balances(address(token), user), depositAmount);
        assertEq(token.balanceOf(user), 900 * 10**18);
    }

    // 辅助函数：计算 EIP-712 签名摘要
    function _computeDigest(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
