import "dotenv/config";
import { createPublicClient, http, parseAbi } from "viem";

const RPC_URL = process.env.RPC_URL;          // 例如 http://127.0.0.1:8545 (anvil)
const MARKET = process.env.MARKET_ADDRESS;    // 你的 NFTMarket 部署地址

if (!RPC_URL || !MARKET) {
  console.error("Missing RPC_URL or MARKET_ADDRESS in .env");
  process.exit(1);
}

const client = createPublicClient({
  transport: http(RPC_URL),
});

// 只需要事件 ABI 就能监听，不必全量 ABI
const abi = parseAbi([
  "event Listed(address indexed seller, address indexed nft, uint256 indexed tokenId, address payToken, uint256 price)",
  "event Purchased(address indexed buyer, address indexed nft, uint256 indexed tokenId, address payToken, uint256 price, address seller)",
]);

console.log("Listening on:", MARKET);

client.watchContractEvent({
  address: MARKET,
  abi,
  eventName: "Listed",
  onLogs: (logs) => {
    for (const l of logs) {
      const a = l.args;
      console.log(
        `[LISTED] seller=${a.seller} nft=${a.nft} tokenId=${a.tokenId} payToken=${a.payToken} price=${a.price}`
      );
    }
  },
});

client.watchContractEvent({
  address: MARKET,
  abi,
  eventName: "Purchased",
  onLogs: (logs) => {
    for (const l of logs) {
      const a = l.args;
      console.log(
        `[PURCHASED] buyer=${a.buyer} seller=${a.seller} nft=${a.nft} tokenId=${a.tokenId} payToken=${a.payToken} price=${a.price}`
      );
    }
  },
});
