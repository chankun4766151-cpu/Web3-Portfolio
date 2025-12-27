// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
    function approve(address to, uint256 tokenId) external;
}

interface INFTMarket {
    function list(address nft, uint256 tokenId, address payToken, uint256 price) external;
    function buyNFT(address nft, uint256 tokenId) external;
}

contract TriggerEvents is Script {
    // === 你部署输出的地址（已填好）===
    address constant PAY_TOKEN = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant NFT       = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant MARKET    = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;

    uint256 constant TOKEN_ID  = 2;
    uint256 constant PRICE     = 1 ether; // 1 PAY（18 decimals）

    function run() external {
        // 从环境变量读取私钥（避免写死在仓库里）
        // 你等下在命令行里 export PK1=... PK2=...
        uint256 pk1 = vm.envUint("PK1"); // 卖家
        uint256 pk2 = vm.envUint("PK2"); // 买家

        address seller = vm.addr(pk1);
        address buyer  = vm.addr(pk2);

        console2.log("seller =", seller);
        console2.log("buyer  =", buyer);
        console2.log("market =", MARKET);
        console2.log("nft    =", NFT);
        console2.log("token  =", PAY_TOKEN);
        console2.log("tokenId=", TOKEN_ID);
        console2.log("price  =", PRICE);

        // ---------- 1) 卖家 approve NFT 给 Market ----------
        vm.startBroadcast(pk1);
        IERC721(NFT).approve(MARKET, TOKEN_ID);
        vm.stopBroadcast();

        // ---------- 2) 卖家上架 list -> emit Listed ----------
        vm.startBroadcast(pk1);
        INFTMarket(MARKET).list(NFT, TOKEN_ID, PAY_TOKEN, PRICE);
        vm.stopBroadcast();

        // ---------- 3) 卖家给买家转钱（PAY） ----------
        vm.startBroadcast(pk1);
        IERC20(PAY_TOKEN).transfer(buyer, PRICE);
        vm.stopBroadcast();

        // ---------- 4) 买家 approve + buyNFT -> emit Purchased ----------
        vm.startBroadcast(pk2);
        IERC20(PAY_TOKEN).approve(MARKET, PRICE);
        INFTMarket(MARKET).buyNFT(NFT, TOKEN_ID);
        vm.stopBroadcast();

        console2.log("Done. Your listener should have printed Listed + Purchased.");
    }
}
