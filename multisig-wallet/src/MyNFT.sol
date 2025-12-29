// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint256 public currentTokenId;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(address to) public returns (uint256) {
        currentTokenId++;
        _mint(to, currentTokenId);
        return currentTokenId;
    }
}
