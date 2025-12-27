// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract web3SuperNFT is Initializable, Ownable, ERC721Enumerable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ===== Executor =====
    mapping(address => bool) public executor;

    modifier onlyExecutor() {
        require(executor[msg.sender], "executor: caller is not the executor");
        _;
    }

    // ===== NFT Meta =====
    struct NftInfo {
        uint256 lv;     // 等级/级别（截图里有注释）
        string name;    // 名称
    }

    mapping(uint256 => NftInfo) internal _nftInfo;

    function nftInfo(uint256 _id) external view returns (NftInfo memory) {
        return _nftInfo[_id];
    }

    function _setNftInfo(
        uint256 _id,
        uint256 _lv,
        string memory _name
    ) internal returns (bool) {
        _nftInfo[_id] = NftInfo({lv: _lv, name: _name});
        return true;
    }

    function setNftInfo(
        uint256 _id,
        uint256 _lv,
        string memory _name
    ) public onlyExecutor returns (bool) {
        _setNftInfo(_id, _lv, _name);
        return true;
    }

    // ===== TokenId & BaseURI =====
    uint256 public tokenIdIndex;
    string public _baseURI_;

    function setBaseURI(string memory _str) public onlyOwner returns (bool) {
        _baseURI_ = _str;
        return true;
    }

    // ===== Constructor =====
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    // ===== Executor Admin =====
    function setExecutor(address _address, bool _type)
        external
        onlyOwner
        returns (bool)
    {
        executor[_address] = _type;
        return true;
    }

    // ===== Utils =====
    function integerToString(uint256 _i)
        internal
        pure
        returns (string memory)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 temp = _i;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (_i != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }

        return string(buffer);
    }

    // ===== tokenURI =====
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        return string(
            abi.encodePacked(_baseURI_, integerToString(tokenId))
        );
        // 示例： https://xxxx.com/3
    }

    // ===== Mint =====
    // 截图里有两种：mint(uint256 _lv,string _name) 和 mint(address _to,uint256 _lv,string _name)
    // 这里按你后面截图“带 _to”版本还原
    function mint(
        address _to,
        uint256 _lv,
        string memory _name
    ) public onlyExecutor returns (bool) {
        _setNftInfo(tokenIdIndex, _lv, _name);
        super._safeMint(_to, tokenIdIndex);
        tokenIdIndex = tokenIdIndex.add(1);
        return true;
    }

    // ===== Burn =====
    function burn(uint256 _id) public returns (bool) {
        require(msg.sender == ownerOf(_id));
        super._burn(_id);
        return true;
    }

    function burnFrom(address _user, uint256 _id)
        public
        onlyExecutor
        returns (bool)
    {
        require(_user == ownerOf(_id));
        super._burn(_id);
        return true;
    }

    // ===== ERC721Enumerable required overrides =====
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
