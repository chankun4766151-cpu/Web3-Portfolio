// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTMarket
 * @dev NFT 市场合约，支持上架、取消、购买功能
 * 
 * 核心功能：
 * 1. list() - 上架 NFT，设置价格和支付代币
 * 2. cancel() - 取消上架
 * 3. buy() - 购买已上架的 NFT
 * 4. updatePrice() - 更新上架价格
 * 
 * 事件：
 * - Listed: 当 NFT 被上架时触发
 * - Canceled: 当上架被取消时触发
 * - Sold: 当 NFT 被购买时触发
 */
contract NFTMarket is ReentrancyGuard {
    // 平台手续费率 (basis points, 250 = 2.5%)
    uint256 public constant FEE_RATE = 250;
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    // 平台手续费接收地址
    address public feeRecipient;
    
    /**
     * @dev 上架信息结构
     * @param nft NFT 合约地址
     * @param tokenId NFT Token ID
     * @param seller 卖家地址
     * @param payToken 支付代币地址 (address(0) 表示 ETH)
     * @param price 价格
     * @param deadline 到期时间戳
     */
    struct Listing {
        address nft;
        uint256 tokenId;
        address seller;
        address payToken;
        uint256 price;
        uint256 deadline;
        bool active;
    }
    
    // 上架 ID => 上架信息
    mapping(bytes32 => Listing) public listings;
    
    /**
     * @dev 上架事件
     * @param id 上架唯一标识符 (keccak256(nft, tokenId, seller))
     * @param nft NFT 合约地址
     * @param tokenId NFT Token ID
     * @param tokenURI NFT 的 tokenURI (元数据URI)
     * @param seller 卖家地址
     * @param payToken 支付代币地址
     * @param price 价格
     * @param deadline 到期时间
     */
    event Listed(
        bytes32 indexed id,
        address indexed nft,
        uint256 indexed tokenId,
        string tokenURI,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadline
    );
    
    /**
     * @dev 取消上架事件
     * @param id 上架 ID
     */
    event Canceled(bytes32 indexed id);
    
    /**
     * @dev 成交事件
     * @param id 上架 ID
     * @param buyer 买家地址
     * @param fee 平台手续费
     */
    event Sold(
        bytes32 indexed id,
        address indexed buyer,
        uint256 fee
    );
    
    /**
     * @dev 价格更新事件
     * @param id 上架 ID
     * @param newPrice 新价格
     */
    event PriceUpdated(bytes32 indexed id, uint256 newPrice);
    
    constructor() {
        feeRecipient = msg.sender;
    }
    
    /**
     * @dev 上架 NFT
     * @param nft NFT 合约地址
     * @param tokenId NFT Token ID
     * @param payToken 支付代币地址 (address(0) 表示 ETH)
     * @param price 价格
     * @param deadline 到期时间戳
     * 
     * 要求：
     * - 调用者必须是 NFT 的所有者
     * - NFT 必须已授权给本合约
     * - 价格必须大于 0
     * - 截止时间必须在未来
     */
    function list(
        address nft,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external {
        require(price > 0, "Price must be greater than 0");
        require(deadline > block.timestamp, "Deadline must be in the future");
        
        IERC721 nftContract = IERC721(nft);
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nftContract.getApproved(tokenId) == address(this) || 
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "NFT not approved"
        );
        
        // 生成唯一的上架 ID
        bytes32 listingId = keccak256(abi.encodePacked(nft, tokenId, msg.sender, block.timestamp));
        
        // 保存上架信息
        listings[listingId] = Listing({
            nft: nft,
            tokenId: tokenId,
            seller: msg.sender,
            payToken: payToken,
            price: price,
            deadline: deadline,
            active: true
        });
        
        // 获取 tokenURI
        string memory tokenURI = "";
        try IERC721Metadata(nft).tokenURI(tokenId) returns (string memory uri) {
            tokenURI = uri;
        } catch {
            // 如果获取失败，使用空字符串
        }
        
        // 触发事件
        emit Listed(listingId, nft, tokenId, tokenURI, msg.sender, payToken, price, deadline);
    }
    
    /**
     * @dev 取消上架
     * @param listingId 上架 ID
     * 
     * 要求：
     * - 上架必须存在且有效
     * - 调用者必须是卖家
     */
    function cancel(bytes32 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");
        
        listing.active = false;
        
        emit Canceled(listingId);
    }
    
    /**
     * @dev 购买 NFT
     * @param listingId 上架 ID
     * 
     * 要求：
     * - 上架必须存在且有效
     * - 未过期
     * - 如果使用 ETH 支付，msg.value 必须等于价格
     * - 如果使用 ERC20 支付，调用者必须有足够余额和授权
     * 
     * 流程：
     * 1. 验证上架有效性
     * 2. 计算平台手续费
     * 3. 转移支付代币（ETH 或 ERC20）
     * 4. 转移 NFT
     * 5. 标记上架为已成交
     */
    function buy(bytes32 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(block.timestamp <= listing.deadline, "Listing expired");
        
        uint256 price = listing.price;
        address seller = listing.seller;
        address payToken = listing.payToken;
        
        // 计算手续费
        uint256 fee = (price * FEE_RATE) / FEE_DENOMINATOR;
        uint256 sellerAmount = price - fee;
        
        // 处理支付
        if (payToken == address(0)) {
            // ETH 支付
            require(msg.value == price, "Incorrect ETH amount");
            
            // 转账给卖家
            (bool success1, ) = seller.call{value: sellerAmount}("");
            require(success1, "Transfer to seller failed");
            
            // 转账手续费
            (bool success2, ) = feeRecipient.call{value: fee}("");
            require(success2, "Transfer fee failed");
        } else {
            // ERC20 支付
            IERC20 token = IERC20(payToken);
            
            // 从买家转到卖家
            require(
                token.transferFrom(msg.sender, seller, sellerAmount),
                "Transfer to seller failed"
            );
            
            // 从买家转手续费
            require(
                token.transferFrom(msg.sender, feeRecipient, fee),
                "Transfer fee failed"
            );
        }
        
        // 转移 NFT
        IERC721(listing.nft).safeTransferFrom(seller, msg.sender, listing.tokenId);
        
        // 标记为已成交
        listing.active = false;
        
        // 触发事件
        emit Sold(listingId, msg.sender, fee);
    }
    
    /**
     * @dev 更新上架价格
     * @param listingId 上架 ID
     * @param newPrice 新价格
     * 
     * 要求：
     * - 上架必须存在且有效
     * - 调用者必须是卖家
     * - 新价格必须大于 0
     */
    function updatePrice(bytes32 listingId, uint256 newPrice) external {
        require(newPrice > 0, "Price must be greater than 0");
        
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");
        
        listing.price = newPrice;
        
        emit PriceUpdated(listingId, newPrice);
    }
    
    /**
     * @dev 更新手续费接收地址
     * @param newRecipient 新的接收地址
     */
    function updateFeeRecipient(address newRecipient) external {
        require(msg.sender == feeRecipient, "Only fee recipient");
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
    }
}
