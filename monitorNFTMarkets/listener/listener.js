import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { ethers } from 'ethers';

const { WS_RPC_URL, MARKET_ADDRESS } = process.env;

if (!WS_RPC_URL || !MARKET_ADDRESS) {
  console.error('❌ Missing env: WS_RPC_URL / MARKET_ADDRESS');
  console.error('   Example .env:');
  console.error('   WS_RPC_URL=ws://127.0.0.1:8545');
  console.error('   MARKET_ADDRESS=0x...');
  process.exit(1);
}

// ========== 路径：永远以当前文件所在目录(listener/)为准 ==========
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// listener/../out/NFTMarket.sol/NFTMarket.json  (Foundry 默认 out 在项目根目录)
const artifactPath = path.resolve(
  __dirname,
  '../out',
  'NFTMarket_full.sol',
  'NFTMarket.json'
);

if (!fs.existsSync(artifactPath)) {
  console.error('❌ ABI artifact not found:');
  console.error('   ', artifactPath);
  console.error('\n✅ Fix: run `forge build` at project root, then ensure file exists at:');
  console.error('   <projectRoot>/out/NFTMarket.sol/NFTMarket.json');
  process.exit(1);
}

const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
const abi = artifact.abi;

// ========== 连接 & 监听（带简单重连） ==========
let provider;
let market;

function attachListeners() {
  console.log('✅ Listening...');
  console.log('   WS_RPC_URL   =', WS_RPC_URL);
  console.log('   MARKET_ADDR  =', MARKET_ADDRESS);
  console.log('   ABI_PATH     =', artifactPath);

  // 你合约事件名是 Listed / Purchased 就用这两个
  // 如果你合约用的是 NFTListed / NFTPurchased，可把下面的 eventName 改一下（我做了 fallback）
  const LISTED_EVENTS = ['Listed', 'NFTListed'];
  const PURCHASED_EVENTS = ['Purchased', 'NFTPurchased'];

  // Listed
  for (const eventName of LISTED_EVENTS) {
    try {
      market.on(eventName, (seller, nft, tokenId, payToken, price, event) => {
        console.log('---');
        console.log(`📌 ${eventName}`);
        console.log('txHash   :', event?.log?.transactionHash ?? '(no txHash)');
        console.log('seller   :', seller);
        console.log('nft      :', nft);
        console.log('tokenId  :', tokenId.toString());
        console.log('payToken :', payToken);
        console.log('price    :', price.toString());
      });
      // 绑定成功就不必重复绑定另一个同类型事件名
      break;
    } catch (_) {}
  }

  // Purchased
  for (const eventName of PURCHASED_EVENTS) {
    try {
      market.on(eventName, (buyer, nft, tokenId, payToken, price, seller, event) => {
        console.log('---');
        console.log(`💰 ${eventName}`);
        console.log('txHash   :', event?.log?.transactionHash ?? '(no txHash)');
        console.log('buyer    :', buyer);
        console.log('seller   :', seller);
        console.log('nft      :', nft);
        console.log('tokenId  :', tokenId.toString());
        console.log('payToken :', payToken);
        console.log('price    :', price.toString());
      });
      break;
    } catch (_) {}
  }

  // WS 事件（ethers v6 的 provider 有 websocket 实例）
  const ws = provider.websocket;

  ws.on('close', () => {
    console.error('❌ WS closed. Reconnecting in 2s...');
    cleanup();
    setTimeout(connect, 2000);
  });

  ws.on('error', (err) => {
    console.error('❌ WS error:', err);
  });
}

function cleanup() {
  try {
    if (market) market.removeAllListeners();
  } catch (_) {}
  try {
    if (provider) provider.destroy(); // ethers v6
  } catch (_) {}
  provider = undefined;
  market = undefined;
}

function connect() {
  provider = new ethers.WebSocketProvider(WS_RPC_URL);
  market = new ethers.Contract(MARKET_ADDRESS, abi, provider);
  attachListeners();
}

connect();
