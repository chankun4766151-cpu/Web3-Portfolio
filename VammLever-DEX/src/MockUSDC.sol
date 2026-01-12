// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @dev 用于测试的模拟 USDC 代币
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        // 初始铸造 1,000,000 USDC 给部署者
        _mint(msg.sender, 1_000_000 * 10**18);
    }

    /**
     * @dev 允许任何人铸造代币（仅用于测试）
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
