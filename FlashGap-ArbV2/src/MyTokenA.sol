// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MyTokenA
 * @dev ERC20 token for flash swap arbitrage demo
 */
contract MyTokenA is ERC20 {
    constructor() ERC20("My Token A", "MTKA") {
        // Mint 1 million tokens to deployer
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
