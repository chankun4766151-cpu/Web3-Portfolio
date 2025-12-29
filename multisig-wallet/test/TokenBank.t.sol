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
        userPrivateKey = 0xA11CE;
        user = vm.addr(userPrivateKey);

        token = new MyToken();
        bank = new TokenBank(address(token));

        token.mint(user, 1000 * 10**18);
    }

    function testPermitDeposit() public {
        uint256 amount = 100 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;

        // 1. Generate Permit Signature
        bytes32 DOMAIN_SEPARATOR = token.DOMAIN_SEPARATOR();
        bytes32 PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        uint256 nonce = token.nonces(user);

        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            user,
            address(bank),
            amount,
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            structHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        // 2. Call permitDeposit
        vm.prank(user);
        bank.permitDeposit(amount, deadline, v, r, s);

        // 3. Verify balances
        assertEq(token.balanceOf(address(bank)), amount);
        assertEq(bank.balances(address(token), user), amount);
        assertEq(token.balanceOf(user), 900 * 10**18);
    }
}
