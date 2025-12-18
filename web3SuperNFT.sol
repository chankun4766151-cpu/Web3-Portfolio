// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract web3SuperNFT is Ownable, ERC721Enumerable {
    using Strings for uint256;

    // ===== Executor =====
    mapping(address => bool) public executor;

    modifier onlyExecutor() {
        require(executor[msg.sender], "executor: caller is not the executor");
        _;
    }

    function setExecutor(address _address, bool _type)
        external
        onlyOwner
        returns (bool)
    {
        executor[_address] = _type;
        return true;
    }

    // ===== NFT Meta =====
    struct NftInfo {
        uint256 lv;     // 等级/级别
        string name;    // 名称
    }

    mapping(uint256 => NftInfo) internal _nftInfo;

    function nftInfo(uint256 _id) external view returns (NftInfo memory) {
        return _nftInfo[_id];
    }

    function _setNftInfo(uint256 _id, uint256 _lv, string memory _name)
        internal
        returns (bool)
    {
        _nftInfo[_id] = NftInfo({lv: _lv, name: _name});
        return true;
    }

    function setNftInfo(uint256 _id, uint256 _lv, string memory _name)
        public
        onlyExecutor
        returns (bool)
    {
        _setNftInfo(_id, _lv, _name);
        return true;
    }

    // ===== TokenId & BaseURI =====
    uint256 public tokenIdIndex;
    string private _baseURI_;

    function setBaseURI(string memory _str) public onlyOwner returns (bool) {
        _baseURI_ = _str;
        return true;
    }

    // OZ 推荐：用 _baseURI() 让默认 tokenURI 工作
    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    // ===== Constructor (OZ 5.x Ownable 需要 initialOwner) =====
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {}

    // ===== tokenURI：保持你原意（baseURI + tokenId） =====
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // OZ 5.x：_requireOwned 会在不存在时 revert（等价于你原来的 require(_exists)）
        _requireOwned(tokenId);

        // 等价于 abi.encodePacked(_baseURI_, integerToString(tokenId))
        return string.concat(_baseURI_, tokenId.toString());
    }

    // ===== Mint：保持原意 =====
    function mint(address _to, uint256 _lv, string memory _name)
        public
        onlyExecutor
        returns (bool)
    {
        _setNftInfo(tokenIdIndex, _lv, _name);
        _safeMint(_to, tokenIdIndex);
        unchecked { tokenIdIndex++; } // 纯优化：不改变行为
        return true;
    }

    // ===== Burn：保持原意（必须 owner 才能 burn） =====
    function burn(uint256 _id) public returns (bool) {
        require(msg.sender == ownerOf(_id), "burn: caller is not owner");
        _burn(_id);
        return true;
    }

    // ===== BurnFrom：保持原意（executor + 必须是该 user 的 token） =====
    function burnFrom(address _user, uint256 _id)
        public
        onlyExecutor
        returns (bool)
    {
        require(_user == ownerOf(_id), "burnFrom: user is not owner");
        _burn(_id);
        return true;
    }
}
