// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockERC721} from "../src/mocks/MockERC721.sol";

contract NFTMarketTest is Test {
    NFTMarket market;
    MockERC20 token;
    MockERC721 nft;

    address seller = makeAddr("seller");
    address buyer  = makeAddr("buyer");
    address other  = makeAddr("other");

    function setUp() public {
        market = new NFTMarket();
        token  = new MockERC20("PAY", "PAY");
        nft    = new MockERC721("NFT", "NFT");

        // 给 seller/buyer 都发点 token
        token.mint(seller, 1_000_000 ether);
        token.mint(buyer,  1_000_000 ether);
        token.mint(other,  1_000_000 ether);

        // seller 铸造一个 nft
        vm.startPrank(seller);
        uint256 tokenId = nft.mint(seller);
        nft.approve(address(market), tokenId);
        vm.stopPrank();
    }

    function _mintAndApproveSeller() internal returns (uint256 tokenId) {
        vm.startPrank(seller);
        tokenId = nft.mint(seller);
        nft.approve(address(market), tokenId);
        vm.stopPrank();
    }

    // ========= List =========

    function test_List_Success_Emit() public {
        uint256 tokenId = _mintAndApproveSeller();
        uint256 price = 100 ether;

        vm.startPrank(seller);

        vm.expectEmit(true, true, true, true);
        emit NFTMarket.Listed(seller, address(nft), tokenId, address(token), price);

        market.list(address(nft), tokenId, address(token), price);

        (address s, address payToken, uint256 p, bool active) = market.listings(address(nft), tokenId);
        assertEq(s, seller);
        assertEq(payToken, address(token));
        assertEq(p, price);
        assertTrue(active);

        vm.stopPrank();
    }

    function test_List_RevertWhenPriceZero() public {
        uint256 tokenId = _mintAndApproveSeller();

        vm.startPrank(seller);
        vm.expectRevert(NFTMarket.PriceZero.selector);
        market.list(address(nft), tokenId, address(token), 0);
        vm.stopPrank();
    }

    function test_List_RevertWhenNotOwner() public {
        uint256 tokenId = _mintAndApproveSeller();

        vm.startPrank(other);
        vm.expectRevert(NFTMarket.NotNFTOwner.selector);
        market.list(address(nft), tokenId, address(token), 1 ether);
        vm.stopPrank();
    }

    function test_List_RevertWhenNotApproved() public {
        vm.startPrank(seller);
        uint256 tokenId = nft.mint(seller);
        // 不 approve market
        vm.expectRevert(NFTMarket.NotApproved.selector);
        market.list(address(nft), tokenId, address(token), 1 ether);
        vm.stopPrank();
    }

    function test_List_RevertWhenAlreadyListed() public {
        uint256 tokenId = _mintAndApproveSeller();

        vm.startPrank(seller);
        market.list(address(nft), tokenId, address(token), 10 ether);

        vm.expectRevert(NFTMarket.AlreadyListed.selector);
        market.list(address(nft), tokenId, address(token), 10 ether);
        vm.stopPrank();
    }

    // ========= Buy =========

    function test_Buy_Success_Emit_AndTransfers() public {
        uint256 tokenId = _mintAndApproveSeller();
        uint256 price = 123 ether;

        vm.prank(seller);
        market.list(address(nft), tokenId, address(token), price);

        uint256 sellerTokenBefore = token.balanceOf(seller);
        uint256 buyerTokenBefore  = token.balanceOf(buyer);

        vm.startPrank(buyer);
        token.approve(address(market), price);

        vm.expectEmit(true, true, true, true);
        emit NFTMarket.Purchased(buyer, address(nft), tokenId, address(token), price, seller);

        market.buy(address(nft), tokenId, price);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), buyer);

        assertEq(token.balanceOf(seller), sellerTokenBefore + price);
        assertEq(token.balanceOf(buyer), buyerTokenBefore - price);

        // listing inactive
        (, , , bool active) = market.listings(address(nft), tokenId);
        assertFalse(active);
    }

    function test_Buy_RevertWhenSellerBuysSelf() public {
        uint256 tokenId = _mintAndApproveSeller();
        uint256 price = 10 ether;

        vm.prank(seller);
        market.list(address(nft), tokenId, address(token), price);

        vm.startPrank(seller);
        token.approve(address(market), price);
        vm.expectRevert(NFTMarket.SellerCannotBuy.selector);
        market.buy(address(nft), tokenId, price);
        vm.stopPrank();
    }

    function test_Buy_RevertWhenNotListedOrAlreadyBought() public {
        uint256 tokenId = _mintAndApproveSeller();
        uint256 price = 10 ether;

        // not listed
        vm.startPrank(buyer);
        token.approve(address(market), price);
        vm.expectRevert(NFTMarket.NotListed.selector);
        market.buy(address(nft), tokenId, price);
        vm.stopPrank();

        // list then buy once
        vm.prank(seller);
        market.list(address(nft), tokenId, address(token), price);

        vm.startPrank(buyer);
        token.approve(address(market), price);
        market.buy(address(nft), tokenId, price);

        // buy again => NotListed (因为 active=false)
        vm.expectRevert(NFTMarket.NotListed.selector);
        market.buy(address(nft), tokenId, price);
        vm.stopPrank();
    }

    function test_Buy_RevertWhenPayTooMuchOrTooLittle() public {
        uint256 tokenId = _mintAndApproveSeller();
        uint256 price = 10 ether;

        vm.prank(seller);
        market.list(address(nft), tokenId, address(token), price);

        // too little
        vm.startPrank(buyer);
        token.approve(address(market), price);
        vm.expectRevert(abi.encodeWithSelector(NFTMarket.WrongPaymentAmount.selector, price, price - 1));
        market.buy(address(nft), tokenId, price - 1);

        // too much
        vm.expectRevert(abi.encodeWithSelector(NFTMarket.WrongPaymentAmount.selector, price, price + 1));
        market.buy(address(nft), tokenId, price + 1);

        vm.stopPrank();
    }

    // ========= Fuzz =========
    // 随机价格范围 0.01 - 10000 Token
    // 随机买家地址（任意 address）
    // 用 bound/assume 控制范围与非法输入（课件示例同理）:contentReference[oaicite:3]{index=3}
    function testFuzz_ListAndBuy(address fuzzBuyer, uint256 rawPrice) public {
        vm.assume(fuzzBuyer != address(0));
        vm.assume(fuzzBuyer != seller);

        uint256 tokenId = _mintAndApproveSeller();

        // price in [0.01, 10000] token, 18 decimals
        uint256 minP = 0.01 ether;
        uint256 maxP = 10_000 ether;
        uint256 price = bound(rawPrice, minP, maxP);

        vm.prank(seller);
        market.list(address(nft), tokenId, address(token), price);

        // 给 fuzzBuyer 足够余额 & 授权
        token.mint(fuzzBuyer, price);
        vm.startPrank(fuzzBuyer);
        token.approve(address(market), price);

        market.buy(address(nft), tokenId, price);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), fuzzBuyer);
    }
}
