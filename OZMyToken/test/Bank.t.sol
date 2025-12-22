// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/bank.sol";

contract BankTest is Test {
    Bank bank;

    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");
    address carol = makeAddr("carol");
    address dave  = makeAddr("dave");

    address admin;

function setUp() public {
    admin = makeAddr("admin");
    vm.deal(admin, 100 ether);

    vm.prank(admin);
    bank = new Bank();

    vm.deal(alice, 100 ether);
    vm.deal(bob,   100 ether);
    vm.deal(carol, 100 ether);
    vm.deal(dave,  100 ether);
}


    // ---------- helpers ----------
    function _topUsers() internal view returns (address[3] memory arr) {
        arr[0] = bank.topUsers(0);
        arr[1] = bank.topUsers(1);
        arr[2] = bank.topUsers(2);
    }

    // ========== 1) 断言：存款前后用户在 Bank 中的存款额是否正确 ==========
    function test_Deposit_UpdatesBalanceCorrectly() public {
        assertEq(bank.balances(alice), 0);

        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        assertEq(bank.balances(alice), 1 ether);

        vm.prank(alice);
        bank.deposit{value: 2 ether}();
        assertEq(bank.balances(alice), 3 ether);

        // 合约 ETH 余额也应等于总存款（这里只有 alice）
        assertEq(address(bank).balance, 3 ether);
    }

    function test_Deposit_RevertWhenAmountZero() public {
        vm.prank(alice);
        vm.expectRevert(bytes("amount = 0"));
        bank.deposit{value: 0}();
    }

    // ========== 2) Top3：检查存款金额前 3 名用户（1/2/3/4 用户 + 同一用户多次存款） ==========

    function test_Top3_With1User() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        address[3] memory tops = _topUsers();
        assertEq(tops[0], alice);
        assertEq(tops[1], address(0));
        assertEq(tops[2], address(0));
    }

    function test_Top3_With2Users() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        address[3] memory tops = _topUsers();
        assertEq(tops[0], bob);
        assertEq(tops[1], alice);
        assertEq(tops[2], address(0));
    }

    function test_Top3_With3Users() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.prank(carol);
        bank.deposit{value: 1.5 ether}();

        address[3] memory tops = _topUsers();
        assertEq(tops[0], bob);    // 2
        assertEq(tops[1], carol);  // 1.5
        assertEq(tops[2], alice);  // 1
    }

    function test_Top3_With4Users() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.prank(carol);
        bank.deposit{value: 1.5 ether}();

        vm.prank(dave);
        bank.deposit{value: 3 ether}();

        address[3] memory tops = _topUsers();
        assertEq(tops[0], dave);   // 3
        assertEq(tops[1], bob);    // 2
        assertEq(tops[2], carol);  // 1.5 （alice 被挤出 Top3）
    }

    function test_Top3_SameUserMultipleDeposits() public {
        // 初始 3 人
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.prank(carol);
        bank.deposit{value: 1.5 ether}();

        // alice 再存一次，余额变 4，应成为第 1
        vm.prank(alice);
        bank.deposit{value: 3 ether}();
        assertEq(bank.balances(alice), 4 ether);

        address[3] memory tops = _topUsers();
        assertEq(tops[0], alice);  // 4
        assertEq(tops[1], bob);    // 2
        assertEq(tops[2], carol);  // 1.5
    }

    // ========== 3) 取款权限：只有管理员可取款，其他人不可以 ==========

    function test_Withdraw_OnlyOwnerCanWithdraw() public {
    vm.prank(alice);
    bank.deposit{value: 5 ether}();
    assertEq(address(bank).balance, 5 ether);

    // 非 owner 取款应 revert
    vm.prank(alice);
    vm.expectRevert(bytes("not owner"));
    bank.withdraw(1 ether);

    // owner(admin) 取款成功
    uint256 adminBalBefore = admin.balance;

    vm.prank(admin);
    bank.withdraw(2 ether);

    assertEq(address(bank).balance, 3 ether);
    assertEq(admin.balance, adminBalBefore + 2 ether);
}

    function test_Withdraw_RevertWhenInsufficientBankBalance() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.expectRevert(bytes("not owner"));
        bank.withdraw(2 ether);
    }
}
