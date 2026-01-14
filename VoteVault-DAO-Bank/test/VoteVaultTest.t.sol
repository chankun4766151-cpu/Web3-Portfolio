// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VotingToken.sol";
import "../src/Bank.sol";
import "../src/MyGovernor.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";

/**
 * @title VoteVaultTest
 * @dev Complete DAO governance system test suite
 * 
 * Test Coverage:
 * 1. Initial setup and deployment
 * 2. Voting power delegation mechanism
 * 3. Proposal creation
 * 4. Voting process
 * 5. Proposal execution
 * 6. Complete DAO workflow
 */
contract VoteVaultTest is Test {
    // Contract instances
    VotingToken public token;
    Bank public bank;
    MyGovernor public governor;

    // Test accounts
    address public owner;
    address public voter1;
    address public voter2;
    address public voter3;
    address public recipient;

    // Event definitions (for testing event emissions)
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    /**
     * @dev Setup test environment
     * @notice Executed before each test
     */
    function setUp() public {
        // Create test accounts
        owner = address(this);
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        recipient = makeAddr("recipient");

        // 1. Deploy VotingToken
        console.log("\n=== Deploying Contracts ===");
        token = new VotingToken();
        console.log("VotingToken deployed at:", address(token));
        console.log("Initial supply:", token.totalSupply() / 1e18, "VVT");

        // 2. Deploy Governor (needed first since Bank constructor needs admin address)
        governor = new MyGovernor(token);
        console.log("MyGovernor deployed at:", address(governor));

        // 3. Deploy Bank with Governor as admin
        bank = new Bank(address(governor));
        console.log("Bank deployed at:", address(bank));
        console.log("Bank admin:", bank.admin());

        // 4. Distribute tokens to voters
        console.log("\n=== Distributing Tokens ===");
        token.transfer(voter1, 300_000 * 1e18); // 30%
        token.transfer(voter2, 200_000 * 1e18); // 20%
        token.transfer(voter3, 100_000 * 1e18); // 10%
        // owner keeps 40%

        console.log("Owner balance:", token.balanceOf(owner) / 1e18, "VVT");
        console.log("Voter1 balance:", token.balanceOf(voter1) / 1e18, "VVT");
        console.log("Voter2 balance:", token.balanceOf(voter2) / 1e18, "VVT");
        console.log("Voter3 balance:", token.balanceOf(voter3) / 1e18, "VVT");

        // 5. Send some ETH to Bank
        vm.deal(owner, 100 ether);
        (bool success, ) = address(bank).call{value: 10 ether}("");
        require(success, "Failed to send ETH to Bank");
        console.log("\n=== Bank Initial State ===");
        console.log("Bank balance:", bank.getBalance() / 1e18, "ETH");
    }

    /**
     * @dev Test 1: Initial setup
     */
    function testInitialSetup() public view {
        // Verify token total supply
        assertEq(token.totalSupply(), 1_000_000 * 1e18, "Total supply should be 1,000,000");

        // Verify Governor is Bank admin
        assertEq(bank.admin(), address(governor), "Governor should be Bank admin");

        // Verify Bank balance
        assertEq(bank.getBalance(), 10 ether, "Bank should have 10 ETH");
    }

    /**
     * @dev Test 2: Voting power delegation
     * @notice Users must delegate to activate voting power
     */
    function testDelegation() public {
        console.log("\n=== Testing Voting Power Delegation ===");

        // Before delegation, voter1 has 0 voting power
        assertEq(token.getVotes(voter1), 0, "Voter1 should have 0 votes before delegation");

        // voter1 delegates to self
        vm.prank(voter1);
        token.delegate(voter1);

        // After delegation, voter1's voting power equals their token balance
        assertEq(
            token.getVotes(voter1), 
            300_000 * 1e18, 
            "Voter1 should have 300,000 votes after delegation"
        );
        console.log("Voter1 voting power:", token.getVotes(voter1) / 1e18, "votes");

        // voter2 also delegates to self
        vm.prank(voter2);
        token.delegate(voter2);
        console.log("Voter2 voting power:", token.getVotes(voter2) / 1e18, "votes");

        // voter3 delegates to voter1 (instead of self)
        vm.prank(voter3);
        token.delegate(voter1);

        // Now voter1's voting power = their own 300,000 + voter3's 100,000
        assertEq(
            token.getVotes(voter1), 
            400_000 * 1e18, 
            "Voter1 should have 400,000 votes after voter3 delegation"
        );
        console.log("Voter1 voting power (after voter3 delegation):", token.getVotes(voter1) / 1e18, "votes");
    }

    /**
     * @dev Test 3: Non-admin cannot withdraw directly from Bank
     */
    function testCannotWithdrawDirectly() public {
        vm.prank(voter1);
        vm.expectRevert("Bank: only admin can call");
        bank.withdraw(payable(voter1), 1 ether);
    }

    /**
     * @dev Test 4: Create proposal
     */
    function testCreateProposal() public {
        console.log("\n=== Testing Proposal Creation ===");

        // First need to delegate voting power
        vm.prank(owner);
        token.delegate(owner);
        vm.roll(block.number + 1); // Advance 1 block for delegation to take effect

        // Create proposal: Withdraw 1 ETH from Bank to recipient
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(bank);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "withdraw(address,uint256)", 
            payable(recipient), 
            1 ether
        );

        string memory description = "Proposal: Withdraw 1 ETH from Bank to recipient";

        // Create proposal
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        console.log("Proposal created with ID:", proposalId);

        // Verify proposal state is Pending
        IGovernor.ProposalState state = governor.state(proposalId);
        assertEq(uint(state), uint(IGovernor.ProposalState.Pending), "Proposal should be Pending");
        console.log("Proposal state: Pending");
    }

    /**
     * @dev Test 5: Complete proposal-voting-execution workflow
     * @notice This is the most important test, demonstrating the complete DAO workflow
     */
    function testCompleteDAOWorkflow() public {
        console.log("\n=== Complete DAO Workflow Test ===");

        // ========== Step 1: Delegate voting power ==========
        console.log("\n--- Step 1: Delegate Voting Power ---");
        vm.prank(owner);
        token.delegate(owner);

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        vm.roll(block.number + 1); // Advance block for delegation to take effect

        console.log("Owner voting power:", token.getVotes(owner) / 1e18, "votes");
        console.log("Voter1 voting power:", token.getVotes(voter1) / 1e18, "votes");
        console.log("Voter2 voting power:", token.getVotes(voter2) / 1e18, "votes");

        // ========== Step 2: Create proposal ==========
        console.log("\n--- Step 2: Create Proposal ---");
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(bank);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "withdraw(address,uint256)", 
            payable(recipient), 
            2 ether
        );

        string memory description = "Proposal: Withdraw 2 ETH from Bank";
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        console.log("Proposal ID:", proposalId);
        console.log("Proposal state: Pending");
        assertEq(
            uint(governor.state(proposalId)), 
            uint(IGovernor.ProposalState.Pending)
        );

        // ========== Step 3: Wait for voting period to start ==========
        console.log("\n--- Step 3: Wait for Voting Period ---");
        // votingDelay = 1 block, so advance 2 blocks to start voting
        vm.roll(block.number + 2);
        console.log("Current block:", block.number);
        console.log("Proposal state: Active");
        assertEq(
            uint(governor.state(proposalId)), 
            uint(IGovernor.ProposalState.Active)
        );

        // ========== Step 4: Vote ==========
        console.log("\n--- Step 4: Voting ---");
        // Vote types: 0 = Against, 1 = For, 2 = Abstain

        // owner votes For (40% voting power)
        vm.prank(owner);
        governor.castVote(proposalId, 1);
        console.log("Owner voted: For");

        // voter1 votes For (30% voting power)
        vm.prank(voter1);
        governor.castVote(proposalId, 1);
        console.log("Voter1 voted: For");

        // voter2 votes Against (20% voting power)
        vm.prank(voter2);
        governor.castVote(proposalId, 0);
        console.log("Voter2 voted: Against");

        // Get voting results
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = 
            governor.proposalVotes(proposalId);

        console.log("\nVoting Results:");
        console.log("- For:", forVotes / 1e18, "votes (70%)");
        console.log("- Against:", againstVotes / 1e18, "votes (20%)");
        console.log("- Abstain:", abstainVotes / 1e18, "votes (0%)");

        // ========== Step 5: Wait for voting period to end ==========
        console.log("\n--- Step 5: Wait for Voting to End ---");
        // votingPeriod = 50400 blocks, advance to end
        vm.roll(block.number + 50401);
        console.log("Current block:", block.number);

        // Verify proposal succeeded
        IGovernor.ProposalState state = governor.state(proposalId);
        console.log("Proposal state: Succeeded");
        assertEq(uint(state), uint(IGovernor.ProposalState.Succeeded));

        // ========== Step 6: Execute proposal ==========
        console.log("\n--- Step 6: Execute Proposal ---");

        // Record balances before execution
        uint256 bankBalanceBefore = bank.getBalance();
        uint256 recipientBalanceBefore = recipient.balance;

        console.log("Bank balance before:", bankBalanceBefore / 1e18, "ETH");
        console.log("Recipient balance before:", recipientBalanceBefore / 1e18, "ETH");

        // Execute proposal
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.execute(targets, values, calldatas, descriptionHash);

        // Verify proposal state is Executed
        assertEq(
            uint(governor.state(proposalId)), 
            uint(IGovernor.ProposalState.Executed)
        );
        console.log("Proposal state: Executed");

        // Verify fund transfer
        uint256 bankBalanceAfter = bank.getBalance();
        uint256 recipientBalanceAfter = recipient.balance;

        console.log("\nBank balance after:", bankBalanceAfter / 1e18, "ETH");
        console.log("Recipient balance after:", recipientBalanceAfter / 1e18, "ETH");

        assertEq(bankBalanceAfter, bankBalanceBefore - 2 ether, "Bank should have 2 ETH less");
        assertEq(recipientBalanceAfter, recipientBalanceBefore + 2 ether, "Recipient should have 2 ETH more");

        console.log("\n=== DAO Workflow Test Successful! ===");
    }

    /**
     * @dev Test 6: Proposal with sufficient quorum should succeed
     */
    function testProposalSucceedsWithQuorum() public {
        console.log("\n=== Testing Proposal With Quorum ===");

        // Only voter3 delegates (10% voting power, more than 4% quorum requirement)
        vm.prank(voter3);
        token.delegate(voter3);
        vm.roll(block.number + 1);

        // Create proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(bank);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "withdraw(address,uint256)", 
            payable(recipient), 
            1 ether
        );

        string memory description = "Proposal: Should succeed with quorum";
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Start voting period
        vm.roll(block.number + 2);

        // voter3 votes For (10% voting power, which exceeds 4% quorum)
        vm.prank(voter3);
        governor.castVote(proposalId, 1);

        console.log("10% voted For (exceeds 4% quorum requirement)");

        // End voting period
        vm.roll(block.number + 50401);

        // Verify proposal succeeded (met quorum and majority voted For)
        IGovernor.ProposalState state = governor.state(proposalId);
        assertEq(
            uint(state), 
            uint(IGovernor.ProposalState.Succeeded),
            "Proposal should Succeed with 10% For votes (exceeds 4% quorum)"
        );
        console.log("Proposal state: Succeeded (as expected)");
    }
}
