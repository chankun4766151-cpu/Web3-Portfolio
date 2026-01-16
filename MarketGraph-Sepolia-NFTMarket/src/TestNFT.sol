// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TestNFT
 * @dev 测试用的 NFT 合约，支持任何人铸造
 */
contract TestNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    
    constructor() ERC721("Test NFT", "TNFT") Ownable(msg.sender) {}
    
    /**
     * @dev 铸造 NFT
     * @param to 接收者地址
     * @param uri Token URI (元数据)
     * @return tokenId 新铸造的 Token ID
     */
    function mint(address to, string memory uri) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }
    
    // Override required functions
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
