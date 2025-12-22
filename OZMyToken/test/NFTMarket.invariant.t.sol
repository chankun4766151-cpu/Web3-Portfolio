// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";

import {NFTMarket} from "../src/NFTMarket.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockERC721} from "../src/mocks/MockERC721.sol";

contract MarketHandler is Test {
    NFTMarket public market;
    MockERC20 public token;
    MockERC721 public nft;

    address public seller;
    uint256 public lastTokenId;

    constructor(NFTMarket _market, MockERC20 _token, MockERC721 _nft, address _seller) {
        market = _market;
        token = _token;
        nft = _nft;
        seller = _seller;

        token.mint(seller, 1_000_000 ether);
    }

    /// @dev 只负责上架（成功路径）
    function list(uint256 rawPrice) external {
        uint256 price = bound(rawPrice, 0.01 ether, 10_000 ether);

        vm.startPrank(seller);
        uint256 tokenId = nft.mint(seller);
        nft.approve(address(market), tokenId);
        market.list(address(nft), tokenId, address(token), price);
        vm.stopPrank();

        lastTokenId = tokenId;
    }

    /// @dev 只负责购买（成功路径），并且严格避免把 token mint 到任何合约地址
    function buy(address buyer) external {
        // 过滤掉所有“会破坏 invariant 语义”的地址
        vm.assume(buyer != address(0));
        vm.assume(buyer != seller);
        vm.assume(buyer != address(market));
        vm.assume(buyer != address(token));
        vm.assume(buyer != address(nft));
        vm.assume(buyer != address(this)); // handler 自己也排除

        if (lastTokenId == 0) return;

        (, , uint256 price, bool active) = market.listings(address(nft), lastTokenId);
        if (!active) return;

        // 关键：只 mint “刚好 price”，不多给 1e18，不做 try/catch 错误路径
        token.mint(buyer, price);

        vm.startPrank(buyer);
        token.approve(address(market), price);
        market.buy(address(nft), lastTokenId, price);
        vm.stopPrank();
    }
}

contract NFTMarketInvariantTest is StdInvariant, Test {
    NFTMarket market;
    MockERC20 token;
    MockERC721 nft;

    MarketHandler handler;
    address seller = makeAddr("seller");

   function setUp() public {
    market = new NFTMarket();
    token  = new MockERC20("PAY", "PAY");
    nft    = new MockERC721("NFT", "NFT");

    handler = new MarketHandler(market, token, nft, seller);

    // ⚠️ 只保留这一行
    targetContract(address(handler));
}


    function invariant_MarketShouldNotHoldToken() public view {
        assertEq(token.balanceOf(address(market)), 0);
    }
}
