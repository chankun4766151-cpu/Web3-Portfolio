// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice 一个最小可测的 NFT 市场：
/// - 上架：卖家设定任意 ERC20 的 price（token + amount）
/// - 购买：买家用该 ERC20 支付恰好 amount，NFT 直接从卖家转给买家，ERC20 直接从买家转给卖家
/// - 设计为：Market 合约本身不托管 ERC20（可选不变量可测）
contract NFTMarket {
    using SafeERC20 for IERC20;

    struct Listing {
        address seller;
        address payToken;
        uint256 price;
        bool active;
    }

    // nft => tokenId => listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // ===== errors =====
    error NotNFTOwner();
    error NotApproved();
    error PriceZero();
    error AlreadyListed();
    error NotListed();
    error SellerCannotBuy();
    error WrongPaymentAmount(uint256 expected, uint256 got);

    // ===== events =====
    event Listed(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price
    );

    event Purchased(
        address indexed buyer,
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address seller
    );

    /// @notice 上架 NFT
    function list(address nft, uint256 tokenId, address payToken, uint256 price) external {
        if (price == 0) revert PriceZero();

        Listing storage cur = listings[nft][tokenId];
        if (cur.active) revert AlreadyListed();

        address owner = IERC721(nft).ownerOf(tokenId);
        if (owner != msg.sender) revert NotNFTOwner();

        // 需要 seller 给 Market 授权此 tokenId（approve 或 setApprovalForAll）
        if (
            IERC721(nft).getApproved(tokenId) != address(this) &&
            !IERC721(nft).isApprovedForAll(msg.sender, address(this))
        ) {
            revert NotApproved();
        }

        listings[nft][tokenId] = Listing({
            seller: msg.sender,
            payToken: payToken,
            price: price,
            active: true
        });

        emit Listed(msg.sender, nft, tokenId, payToken, price);
    }

    /// @notice 购买 NFT：必须 exactly payAmount == listing.price
    function buy(address nft, uint256 tokenId, uint256 payAmount) external {
        Listing storage it = listings[nft][tokenId];
        if (!it.active) revert NotListed();
        if (msg.sender == it.seller) revert SellerCannotBuy();
        if (payAmount != it.price) revert WrongPaymentAmount(it.price, payAmount);

        it.active = false; // 先置 false，防止重入/重复购买（以及测试“重复购买”）

        // ERC20：从买家 -> 卖家（Market 不持仓）
        IERC20(it.payToken).safeTransferFrom(msg.sender, it.seller, it.price);

        // NFT：从卖家 -> 买家（Market 作为 operator 执行 transferFrom）
        IERC721(nft).transferFrom(it.seller, msg.sender, tokenId);

        emit Purchased(msg.sender, nft, tokenId, it.payToken, it.price, it.seller);
    }

    /// @notice 方便 invariant 检查：合约不应持有 payToken
    function getListing(address nft, uint256 tokenId) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }
}
