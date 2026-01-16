# 部署指南 (Deployment Guide)

本文档详细说明如何部署 NFTMarket 合约到 Sepolia 测试网，并创建 TheGraph 子图进行索引。

##  第一步：准备工作

### 1.1 获取 Sepolia 测试网 ETH

访问以下任意一个水龙头获取测试 ETH：
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://faucet.quicknode.com/ethereum/sepolia

### 1.2 获取 Alchemy API Key

1. 访问 https://www.alchemy.com/ 并注册
2. 创建新应用，选择 Sepolia 网络
3. 复制 HTTPS URL (格式: `https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY`)

### 1.3 获取 Etherscan API Key

1. 访问 https://etherscan.io/ 并注册
2. 进入 "API Keys" 页面
3. 创建新的 API Key

### 1.4 配置环境变量

复制 `.env.example` 到 `.env`：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=你的私钥（不要包含 0x 前缀）
ETHERSCAN_API_KEY=你的_Etherscan_API_Key
```

> ⚠️ **安全提示**: 永远不要将 `.env` 文件提交到 Git！

## 📝 第二步：部署智能合约

### 2.1 编译合约

```bash
forge build
```

预期输出：
```
[⠢] Compiling...
[⠆] Compiling 48 files with 0.8.25
[⠰] Solc 0.8.25 finished in XX.XXs
Compiler run successful!
```

### 2.2 运行测试

```bash
forge test -vv
```

确保所有测试通过。

### 2.3 部署到 Sepolia

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

**这个命令做了什么？**
- `source .env`: 加载环境变量
- `--rpc-url $SEPOLIA_RPC_URL`: 指定 Sepolia RPC 端点
- `--broadcast`: 实际广播交易到网络
- `--verify`: 在 Etherscan 上自动验证合约
- `-vvvv`: 详细输出模式

### 2.4 记录合约地址

部署成功后，你会看到类似的输出：

```
=== Deployment Summary ===
NFTMarket: 0x1234...
TestNFT: 0x5678...
TestERC20 (TUSDT): 0x9abc...
==========================
```

**重要**: 复制这些地址，我们后续需要用到！

### 2.5 验证合约已开源

访问 Etherscan Sepolia:
- NFTMarket: https://sepolia.etherscan.io/address/[你的合约地址]

确认显示绿色勾选 ✓ "Contract Source Code Verified"

## 🔍 第三步：创建 TheGraph 子图

### 3.1 注册 The Graph Studio

1. 访问 https://thegraph.com/studio/
2. 使用钱包连接（推荐使用 MetaMask）
3. 创建新子图，名称如：`nftmarket-sepolia`
4. 复制显示的 **Deploy Key**

### 3.2 准备子图文件

导出 ABI（在项目根目录）：

```bash
cd subgraph
mkdir -p abis
cd ..
forge inspect src/NFTMarket.sol:NFTMarket abi > subgraph/abis/NFTMarket.json
```

### 3.3 更新 subgraph.yaml

编辑 `subgraph/subgraph.yaml`，更新以下字段：

```yaml
source:
  address: "0x你的NFTMarket合约地址"  # 替换为第 2.4 步记录的地址
  startBlock: 你的部署区块号          # 可以在 Etherscan 查看部署交易所在区块
```

**如何查找 startBlock**：
1. 在 Etherscan 中打开合约地址
2. 查看 "Contract Creation" 交易
3. 使用该交易所在的区块号

### 3.4 安装依赖

```bash
cd subgraph
npm install
```

### 3.5 生成代码

```bash
npm run codegen
```

**这个命令做了什么？**
- 读取 ABI 和 schema
- 生成 TypeScript 类型定义
- 创建 `generated/` 目录

### 3.6 构建子图

```bash
npm run build
```

确保没有编译错误。

### 3.7 部署子图

使用之前复制的 Deploy Key：

```bash
graph auth --studio <YOUR_DEPLOY_KEY>
graph deploy --studio nftmarket-sepolia
```

部署成功后，会显示：
```
✔ Upload subgraph to IPFS
Build completed: QmXXXXX...

Deployed to https://thegraph.com/studio/subgraph/nftmarket-sepolia/

Subgraph endpoints:
Queries (HTTP):     https://api.studio.thegraph.com/query/<id>/nftmarket-sepolia/version/latest
```

**记录这个查询端点！**

## 🎯 第四步：测试子图

### 4.1 创建测试交易

在 Etherscan 上调用合约创建一些测试交易：

1. **上架 NFT**: 调用 `list()` 函数
2. **购买 NFT**: 调用 `buy()` 函数
3. **取消上架**: 调用 `cancel()` 函数

### 4.2 等待索引

- 打开 The Graph Studio 面板
- 等待 "Syncing" 状态变为 "Synced"
- 通常需要几分钟

### 4.3 执行 GraphQL 查询

打开 Playground (在 The Graph Studio 中)，执行以下查询：

#### 查询 1: 所有上架记录

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
    transactionHash
  }
}
```

#### 查询 2: 所有已售出记录及关联信息

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
      deadline
    }
  }
}
```

#### 查询 3: 特定卖家的上架

```graphql
{
  lists(where: { seller: "0x你的钱包地址" }) {
    id
    tokenId
    price
    deadline
    cancelTxHash
    filledTxHash
  }
}
```

### 4.4 截图

对查询结果截图，包括：
1. GraphQL 查询代码
2. 返回的 JSON 数据
3. The Graph Studio URL

## 📦 第五步：GitHub 提交

### 5.1 初始化 Git 仓库

```bash
git init
git add .
git commit -m "Initial commit: NFTMarket with TheGraph indexing"
```

### 5.2 创建 GitHub 仓库

1. 访问 https://github.com/new  
2. 创建新仓库（如 `nftmarket-sepolia-graph`）
3. 不要初始化 README（我们已经有了）

### 5.3 推送到 GitHub

```bash
git remote add origin https://github.com/你的用户名/仓库名.git
git branch -M main
git push -u origin main
```

### 5.4 更新 README

编辑 `README.md`，填写：
- 实际的合约地址
- The Graph 子图 URL
- 添加查询截图到项目（放在 `screenshots/` 目录）

### 5.5 最终提交

```bash
git add README.md screenshots/
git commit -m "Add deployment addresses and query screenshots"
git push
```

## ✅ 验收清单

确保完成以下所有项：

- [ ] NFTMarket 合约部署到 Sepolia
- [ ] 合约在 Etherscan 上已验证（开源）
- [ ] TheGraph 子图已部署并同步
- [ ] 可以成功查询 List 和 Sold 数据
- [ ] List 和 Sold 之间的关联正常工作
- [ ] 有查询结果截图
- [ ] GitHub 仓库包含所有代码
- [ ] README 包含合约地址和子图链接

## 🎓 学习总结

### TheGraph 工作原理

1. **监听事件**: 子图监听智能合约的事件（Listed, Canceled, Sold）
2. **处理数据**: 映射函数（mapping）处理事件数据并创建/更新实体
3. **存储索引**: 数据存储在 Graph Node 的数据库中
4. **提供查询**: 通过 GraphQL API 提供快速查询

### 关键概念

- **Entity（实体）**: 数据模型，如 List 和 Sold
- **Mapping（映射）**: 事件处理函数，如 handleListed
- **Schema（模式）**: GraphQL 数据结构定义
- **Subgraph（子图）**: 完整的索引项目

### 为什么要建立 List 和 Sold 的关联？

通过关联，我们可以：
- 在查询 Sold 时直接获取上架详情
- 追踪完整的交易历史
- 分析卖家的销售数据
- 构建更丰富的前端界面

## 🐛 常见问题

### Q: 部署时提示 "insufficient funds"
A: 确保你的钱包有足够的 Sepolia ETH（建议至少 0.1 ETH）

### Q: 合约验证失败
A: 检查 `.env` 中的 `ETHERSCAN_API_KEY` 是否正确

### Q: 子图一直显示 "Failed"
A: 检查 `subgraph.yaml` 中的合约地址和 startBlock 是否正确

### Q: 查询返回空数据
A: 确保：
1. 子图已同步完成
2. 有实际的交易发生
3. 查询语法正确

## 📚 参考资料

- [Foundry Book](https://book.getfoundry.sh/)
- [The Graph Docs](https://thegraph.com/docs/en/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Solidity Documentation](https://docs.soliditylang.org/)

---

**完成后记得截图并提交作业！** 🎉
