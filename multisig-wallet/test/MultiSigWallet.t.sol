// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    
    // Test users
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address nonOwner = address(0x4);

    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        // Deploy wallet with 3 owners and 2 confirmations required
        vm.prank(owner1);
        wallet = new MultiSigWallet(owners, 2);
        
        // Fund the wallet
        vm.deal(address(wallet), 10 ether);
    }

    function test_Constructor() public {
        assertEq(wallet.owners(0), owner1);
        assertEq(wallet.owners(1), owner2);
        assertEq(wallet.owners(2), owner3);
        assertEq(wallet.numConfirmationsRequired(), 2);
    }

    function test_SubmitTransaction() public {
        vm.prank(owner1);
        
        address to = address(0x99);
        uint value = 1 ether;
        bytes memory data = "";

        vm.expectEmit(true, true, true, true);
        emit SubmitTransaction(owner1, 0, to, value, data);
        
        wallet.submitTransaction(to, value, data);

        (address _to, uint _value, bytes memory _data, bool _executed, uint _numConfirmations) = wallet.getTransaction(0);
        
        assertEq(_to, to);
        assertEq(_value, value);
        assertEq(_data, data);
        assertEq(_executed, false);
        assertEq(_numConfirmations, 0);
    }

    function test_SubmitTransactionRevertIfNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("not owner");
        wallet.submitTransaction(address(0x99), 1 ether, "");
    }

    function test_ConfirmTransaction() public {
        // First submit a tx
        vm.prank(owner1);
        wallet.submitTransaction(address(0x99), 1 ether, "");

        // Verify confirmation
        vm.prank(owner2);
        vm.expectEmit(true, true, false, false);
        emit ConfirmTransaction(owner2, 0);
        
        wallet.confirmTransaction(0);

        (,,,, uint numConfirmations) = wallet.getTransaction(0);
        assertEq(numConfirmations, 1);
        assertTrue(wallet.isConfirmed(0, owner2));
    }

    function test_ExecuteTransaction() public {
        address to = address(0x99);
        uint value = 1 ether;
        bytes memory data = "";
        uint initialBalance = to.balance;

        // 1. Submit
        vm.prank(owner1);
        wallet.submitTransaction(to, value, data);

        // 2. Confirm 1
        vm.prank(owner1);
        wallet.confirmTransaction(0);

        // 3. Confirm 2 (Threshold reached)
        vm.prank(owner2);
        wallet.confirmTransaction(0);

        // 4. Execute
        vm.prank(address(0x999)); // Anyone can execute
        vm.expectEmit(true, true, false, false);
        emit ExecuteTransaction(address(0x999), 0);
        
        wallet.executeTransaction(0);

        (,,, bool executed,) = wallet.getTransaction(0);
        assertTrue(executed);
        assertEq(to.balance, initialBalance + value);
    }

    function test_ExecuteTransactionFailBelowThreshold() public {
        // 1. Submit
        vm.prank(owner1);
        wallet.submitTransaction(address(0x99), 1 ether, "");

        // 2. Confirm 1 (Below threshold of 2)
        vm.prank(owner1);
        wallet.confirmTransaction(0);

        // 3. Try Execute
        vm.prank(nonOwner);
        vm.expectRevert("cannot execute tx");
        wallet.executeTransaction(0);
    }
}
