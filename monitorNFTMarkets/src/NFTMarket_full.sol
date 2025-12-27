// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev 最小版 ERC1363 Receiver 接口（tokensReceived）
/// 一些实现使用 onTransferReceived / onApprovalReceived；
/// 你的作业点名 tokensReceived，所以我们按这个签名实现。
interface IERC1363Receiver {
    function tokensReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

/// @notice 一个最小可测的 NFT 市场：
/// - 上架：卖家设定任意 ERC20 / ERC1363 的 price（token + amount）
/// - 购买：
///   1) buyNFT：买家 approve 后，由 Market 使用 transferFrom 从买家把 ERC20 转给卖家
///   2) tokensReceived：买家用 ERC1363 的 transferAndCall，把 token 先转给 Market，再回调购买
/// - 设计目标：Market 不持有 ERC20（tokensReceived 路径会“短暂收到”，随后立刻转给卖家）
contract NFTMarket is IERC1363Receiver {
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
    error InvalidPayToken();

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

    // ===== core =====

    /// @notice 上架 NFT
    /// @dev 需要卖家提前 approve / setApprovalForAll 授权 Market 转走该 tokenId
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

        // ✅ 作业要求：上架函数里打事件
        emit Listed(msg.sender, nft, tokenId, payToken, price);
    }

    /// @notice buyNFT 购买入口（便捷版）：按 listing.price 支付
    function buyNFT(address nft, uint256 tokenId) external {
        Listing memory it = listings[nft][tokenId];
        _buyByTransferFrom(msg.sender, nft, tokenId, it.price);
    }

    /// @notice buyNFT 购买入口（测试版）：显式传 payAmount，用于测试“过多/过少”会 revert
    function buyNFT(address nft, uint256 tokenId, uint256 payAmount) public {
        _buyByTransferFrom(msg.sender, nft, tokenId, payAmount);
    }

    /// @dev ERC20 approve + transferFrom 路径购买
    function _buyByTransferFrom(address buyer, address nft, uint256 tokenId, uint256 payAmount) internal {
        Listing storage it = listings[nft][tokenId];
        if (!it.active) revert NotListed();
        if (buyer == it.seller) revert SellerCannotBuy();
        if (payAmount != it.price) revert WrongPaymentAmount(it.price, payAmount);

        // 先置 false / 清单无效，防止重入/重复购买
        it.active = false;

        // ERC20：从买家 -> 卖家（Market 不持仓）
        IERC20(it.payToken).safeTransferFrom(buyer, it.seller, it.price);

        // NFT：从卖家 -> 买家（Market 作为 operator 执行 transferFrom）
        IERC721(nft).transferFrom(it.seller, buyer, tokenId);

        // ✅ 作业要求：buyNFT 里打事件（我们在这条路径里统一打）
        emit Purchased(buyer, nft, tokenId, it.payToken, it.price, it.seller);
    }

    /// @notice ERC1363 回调购买入口：
    /// @dev 买家调用 payToken.transferAndCall(address(this), price, abi.encode(nft, tokenId))
    ///      token 会先到 Market，然后 token 合约回调本函数
    function tokensReceived(
        address /*operator*/,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        (address nft, uint256 tokenId) = abi.decode(data, (address, uint256));

        Listing storage it = listings[nft][tokenId];
        if (!it.active) revert NotListed();
        if (from == it.seller) revert SellerCannotBuy();

        // msg.sender 在回调里就是 payToken 合约地址：必须与 listing.payToken 一致
        if (msg.sender != it.payToken) revert InvalidPayToken();
        if (value != it.price) revert WrongPaymentAmount(it.price, value);

        // 先置 false，防止重入/重复购买
        it.active = false;

        // 此路径下 token 已经转到 Market 了：立刻转给卖家（避免 Market 持仓）
        IERC20(it.payToken).safeTransfer(it.seller, it.price);

        // NFT：从卖家 -> 买家
        IERC721(nft).transferFrom(it.seller, from, tokenId);

        // ✅ 作业要求：tokensReceived 里打事件
        emit Purchased(from, nft, tokenId, it.payToken, it.price, it.seller);

        return this.tokensReceived.selector;
    }

    /// @notice 方便读取 listing（也可用于 invariant 检查）
    function getListing(address nft, uint256 tokenId) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }
}
