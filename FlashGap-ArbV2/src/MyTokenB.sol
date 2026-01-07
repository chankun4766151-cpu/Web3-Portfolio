// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MyTokenB
 * @dev ERC20 token for flash swap arbitrage demo
 */
contract MyTokenB is ERC20 {
    constructor() ERC20("My Token B", "MTKB") {
        // Mint 1 million tokens to deployer
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
