// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20WithCallback {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

interface ITokenReceiver {
    function tokensReceived(address operator, address from, uint256 value, bytes calldata data) external;
}

contract NFTMarket is IERC721Receiver, ITokenReceiver, ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    IERC20WithCallback public immutable paymentToken;

    // nft => tokenId => listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed seller, address indexed nft, uint256 indexed tokenId, uint256 price);
    event Unlisted(address indexed seller, address indexed nft, uint256 indexed tokenId);
    event Bought(address indexed buyer, address indexed nft, uint256 indexed tokenId, uint256 price);

    constructor(address paymentToken_) {
        require(paymentToken_ != address(0), "paymentToken is zero");
        paymentToken = IERC20WithCallback(paymentToken_);
    }

    /// @notice 上架：NFT 托管到市场合约，并设置价格（以 paymentToken 计价）
    /// @dev 卖家需提前 approve(tokenId) 或 setApprovalForAll(market,true)
    function list(address nft, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "price=0");

        IERC721 erc721 = IERC721(nft);
        require(erc721.ownerOf(tokenId) == msg.sender, "not owner");

        // 托管 NFT 到 Market
        erc721.safeTransferFrom(msg.sender, address(this), tokenId);

        listings[nft][tokenId] = Listing({seller: msg.sender, price: price, active: true});
        emit Listed(msg.sender, nft, tokenId, price);
    }

    /// @notice 下架：卖家取回 NFT
    function unlist(address nft, uint256 tokenId) external nonReentrant {
        Listing memory it = listings[nft][tokenId];
        require(it.active, "not listed");
        require(it.seller == msg.sender, "not seller");

        delete listings[nft][tokenId];
        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unlisted(msg.sender, nft, tokenId);
    }

    /// @notice 普通购买：买家先 approve 市场合约可花费 token，再调用 buyNFT
    function buyNFT(address nft, uint256 tokenId) external nonReentrant {
        Listing memory it = listings[nft][tokenId];
        require(it.active, "not listed");

        // 买家 -> 卖家
        require(paymentToken.transferFrom(msg.sender, it.seller, it.price), "pay failed");

        // NFT -> 买家
        delete listings[nft][tokenId];
        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Bought(msg.sender, nft, tokenId, it.price);
    }

    /// @notice 回调购买：token.transferWithCallback(market, price, abi.encode(nft, tokenId))
    /// @dev token 已经进到 market，所以 market 再把 token 转给卖家即可
    function tokensReceived(address /*operator*/, address from, uint256 value, bytes calldata data)
        external
        override
        nonReentrant
    {
        require(msg.sender == address(paymentToken), "only paymentToken");

        (address nft, uint256 tokenId) = abi.decode(data, (address, uint256));

        Listing memory it = listings[nft][tokenId];
        require(it.active, "not listed");
        require(value == it.price, "wrong amount");

        // payout：market -> 卖家
        require(paymentToken.transfer(it.seller, value), "payout failed");

        // NFT：market -> 买家(from)
        delete listings[nft][tokenId];
        IERC721(nft).safeTransferFrom(address(this), from, tokenId);

        emit Bought(from, nft, tokenId, value);
    }

    // ===== IERC721Receiver =====
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
