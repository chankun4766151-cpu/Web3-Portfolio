// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @dev Simple ERC20 token for cross-chain bridging demonstration
 * This token will be deployed on Ethereum Sepolia (L1) and bridged to Optimism Sepolia (L2)
 */
contract MyToken is ERC20, Ownable {
    /**
     * @dev Constructor that mints initial supply to the deployer
     * @param initialSupply The initial token supply (in wei, 18 decimals)
     */
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows owner to mint additional tokens
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
