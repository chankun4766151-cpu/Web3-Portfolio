// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDT
 * @notice 模拟 USDT Token，用于测试
 * @dev 简单的 ERC20 实现，任何人都可以铸造（仅用于测试）
 */
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {
        // 给部署者铸造 100万 USDT 用于测试
        _mint(msg.sender, 1_000_000 * 10**18);
    }
    
    /**
     * @notice 铸造 USDT（仅用于测试）
     * @param to 接收地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
