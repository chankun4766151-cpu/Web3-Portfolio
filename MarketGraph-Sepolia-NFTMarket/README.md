# NFTMarket with TheGraph Indexing

这是一个完整的 NFT 市场智能合约项目，部署在 Sepolia 测试网，并使用 TheGraph 进行事件索引。

## 项目概述

本项目实现了一个功能完整的 NFT 市场，支持：
- ✅ NFT 上架（支持 ETH 和 ERC20 代币支付）
- ✅ 取消上架  
- ✅ 购买 NFT
- ✅ 更新价格
- ✅ 2.5% 平台手续费
- ✅ 合约开源验证
- ✅ TheGraph 子图索引

## 技术栈

- **智能合约**: Solidity ^0.8.25
- **开发框架**: Foundry
- **索引协议**: The Graph
- **测试网**: Sepolia
- **合约验证**: Etherscan

## 合约地址 (Sepolia)

> 部署后填写:

- **NFTMarket**: `0x...`
- **TestNFT**: `0x...`
- **TestERC20 (TUSDT)**: `0x...`

## 项目结构

```
├── src/
│   ├── NFTMarket.sol      # 核心市场合约
│   ├── TestNFT.sol         # 测试 NFT 合约
│   └── TestERC20.sol       # 测试 ERC20 代币
├── test/
│   └── NFTMarket.t.sol     # 测试套件
├── script/
│   └── Deploy.s.sol        # 部署脚本
└── subgraph/
    ├── schema.graphql      # GraphQL Schema
    ├── subgraph.yaml       # 子图配置
    └── src/
        └── nft-market.ts   # 事件处理逻辑
```

## 快速开始

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd MarketGraph-Sepolia-NFTMarket
```

### 2. 安装依赖

```bash
# 安装 Foundry 依赖
forge install

# 安装 Graph CLI (如需部署子图)
npm install -g @graphprotocol/graph-cli
```

### 3. 配置环境变量

复制 `.env.example` 到 `.env` 并填写:

```bash
cp .env.example .env
```

编辑 `.env`:
```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 4. 编译合约

```bash
forge build
```

### 5. 运行测试

```bash
forge test -vv
```

### 6. 部署到 Sepolia

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

部署成功后，记录合约地址并更新本 README。

## TheGraph 子图部署

### 1. 初始化子图

```bash
cd subgraph
graph init --from-contract <NFTMarket_ADDRESS> --network sepolia --contract-name NFTMarket nftmarket-sepolia
```

### 2. 生成代码

```bash
graph codegen
```

### 3. 构建子图

```bash
graph build
```

### 4. 部署到 The Graph Studio

首先在 [The Graph Studio](https://thegraph.com/studio/) 创建子图，然后：

```bash
graph auth --studio <DEPLOY_KEY>
graph deploy --studio nftmarket-sepolia
```

## GraphQL 查询示例

### 查询所有上架记录

```graphql
{
  lists(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    nft
    tokenId
    tokenURL
    seller
    payToken
    price
    deadline
    cancelTxHash
    filledTxHash
    blockTimestamp
  }
}
```

### 查询所有已售出记录及关联的上架信息

```graphql
{
  solds(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    buyer
    fee
    blockTimestamp
    transactionHash
    list {
      id
      nft
      tokenId
      tokenURL
      seller
      price
      payToken
    }
  }
}
```

### 查询特定卖家的所有上架

```graphql
{
  lists(where: { seller: "0x..." }) {
    id
    tokenId
    price
    deadline
    cancelTxHash
    filledTxHash
  }
}
```

## 核心功能说明

### 1. 上架 NFT (list)

卖家可以上架 NFT，设置价格、支付代币和截止时间：

```solidity
function list(
    address nft,
    uint256 tokenId,
    address payToken,  // address(0) 表示使用 ETH
    uint256 price,
    uint256 deadline
) external
```

**触发事件**: `Listed(id, nft, tokenId, tokenURI, seller, payToken, price, deadline)`

### 2. 取消上架 (cancel)

卖家可以取消未成交的上架：

```solidity
function cancel(bytes32 listingId) external
```

**触发事件**: `Canceled(id)`

### 3. 购买 NFT (buy)

买家支付对应价格购买 NFT：

```solidity
function buy(bytes32 listingId) external payable
```

- 平台收取 2.5% 手续费
- 卖家收到 97.5% 的价格

**触发事件**: `Sold(id, buyer, fee)`

### 4. 更新价格 (updatePrice)

卖家可以更新上架价格：

```solidity
function updatePrice(bytes32 listingId, uint256 newPrice) external
```

**触发事件**: `PriceUpdated(id, newPrice)`

## TheGraph 数据模型

### List 实体

记录所有上架信息，包括取消和成交状态：

- `id`: 上架唯一标识
- `nft`: NFT 合约地址
- `tokenId`: NFT Token ID
- `tokenURL`: NFT 元数据 URI
- `seller`: 卖家地址
- `payToken`: 支付代币地址
- `price`: 价格
- `deadline`: 截止时间
- `cancelTxHash`: 取消交易哈希（如已取消）
- `filledTxHash`: 成交交易哈希（如已成交）

### Sold 实体

记录所有成交信息，并关联到对应的 List：

- `id`: 成交唯一标识
- `buyer`: 买家地址
- `fee`: 平台手续费
- `list`: 关联的上架信息 (List 实体)
- `transactionHash`: 交易哈希

## 学习要点

### 为什么需要 TheGraph？

智能合约的状态和事件存储在区块链上，直接查询非常慢且复杂。TheGraph 通过监听事件并建立索引，将数据存储在可快速查询的 GraphQL 数据库中。

### List 和 Sold 如何关联？

通过使用相同的上架 ID:
1. `Listed` 事件创建 `List` 实体，使用 `keccak256(nft, tokenId, seller, timestamp)` 作为 ID
2. `Sold` 事件创建 `Sold` 实体，同时引用相同的 ID 关联到 `List`
3. 在 schema 中定义 `list: List` 字段建立关系

### NFT 上架生命周期

1. **上架**: 触发 `Listed` 事件，创建 `List` 实体
2. **取消**: 触发 `Canceled` 事件，更新 `List.cancelTxHash`
3. **成交**: 触发 `Sold` 事件，创建 `Sold` 实体并更新 `List.filledTxHash`

## 许可证

MIT

## 作者

[Your Name]

---

## 提交清单

- [x] NFTMarket 合约实现
- [x] 测试合约 (TestNFT, TestERC20)
- [x] 完整测试套件
- [x] 部署脚本
- [ ] 部署到 Sepolia 测试网
- [ ] Etherscan 合约验证
- [ ] TheGraph 子图实现
- [ ] TheGraph 子图部署
- [ ] GraphQL 查询截图
- [ ] GitHub 仓库
```

