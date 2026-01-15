# Flashbots Bundle 交易示例 - OpenspaceNFT

这个项目演示如何使用 Flashbots Bundle 在 Sepolia 测试网络上捆绑执行 OpenspaceNFT 合约的交易。

## 📚 项目概述

### 什么是 Flashbots？

Flashbots 是一个防止 MEV（矿工可提取价值）攻击的解决方案。通过 Flashbots，你可以：

- **捆绑交易**：将多个交易打包在一起，确保它们在同一个区块中执行
- **原子性**：所有交易要么全部成功，要么全部失败
- **隐私性**：交易在被包含到区块之前不会在公共内存池中可见
- **防抢跑**：避免被其他机器人或矿工抢先交易

### 本项目实现

本项目创建一个包含两个交易的 Bundle：
1. **交易 1**：调用 `enablePresale()` - owner 开启预售
2. **交易 2**：调用 `presale(1)` - 用户购买 1 个 NFT

这两个交易会被捆绑在一起，在同一个区块中执行。

## 🛠️ 环境准备

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

复制 `.env.example` 创建 `.env` 文件：

```bash
cp .env.example .env
```

然后编辑 `.env` 文件，填入以下信息：

```env
# Owner账户的私钥（用于部署合约和执行enablePresale）
OWNER_PRIVATE_KEY=你的owner私钥

# 用户账户的私钥（用于执行presale购买NFT）
USER_PRIVATE_KEY=你的user私钥

# Sepolia RPC URL
# Infura示例: https://sepolia.infura.io/v3/YOUR_API_KEY
# Alchemy示例: https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
SEPOLIA_RPC_URL=你的RPC_URL

# Flashbots认证密钥（可选，留空会自动生成）
FLASHBOTS_AUTH_KEY=
```

### 3. 获取测试币

两个钱包都需要 Sepolia ETH，可以从以下水龙头获取：

- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://sepolia-faucet.pk910.de/

## 📝 使用步骤

### 步骤 1: 部署 OpenspaceNFT 合约

```bash
npm run deploy
```

**操作说明：**
- 这个命令会使用 Owner 账户部署 OpenspaceNFT 合约
- 部署成功后会显示合约地址
- **重要：** 将合约地址复制到 `.env` 文件的 `CONTRACT_ADDRESS` 中

**预期输出：**
```
开始部署 OpenspaceNFT 合约到 Sepolia 网络...
部署账户地址: 0x...
账户余额: 0.5 ETH

正在部署合约...
✅ OpenspaceNFT 合约部署成功!
📝 合约地址: 0x...
🔗 Etherscan: https://sepolia.etherscan.io/address/0x...

📊 合约初始状态:
- 预售状态 (isPresaleActive): true
- 下一个 Token ID (nextTokenId): 1
- Owner 地址: 0x...
```

### 步骤 2: 执行 Flashbots Bundle

```bash
npm run bundle
```

**操作说明：**
- 这个命令会创建一个包含两个交易的 Bundle
- 第一个交易：enablePresale（虽然默认已经是 true，但这里演示如何调用）
- 第二个交易：presale(1) - 购买 1 个 NFT

**预期输出：**
```
============================================================
Flashbots Bundle 交易示例 - OpenspaceNFT
============================================================

📌 步骤 1: 初始化 Provider 和 Signer
✅ Owner 地址: 0x...
✅ User 地址: 0x...
💰 Owner 余额: 0.5 ETH
💰 User 余额: 0.5 ETH

📌 步骤 2: 初始化 Flashbots Provider
🔑 Flashbots 认证地址: 0x...
✅ Flashbots Provider 初始化成功

📌 步骤 3: 准备合约交互
📝 合约地址: 0x...
📊 当前预售状态: true

📌 步骤 4: 准备 Bundle 交易
🔢 当前区块: 12345
🎯 目标区块: 12347
⛽ Base Fee: 10.5 Gwei
⛽ Max Fee: 23.0 Gwei

🔨 准备交易 1: enablePresale()
  - Signer: Owner
  - Nonce: 5

🔨 准备交易 2: presale(1)
  - Signer: User
  - Nonce: 3
  - Value: 0.01 ETH

📌 步骤 5: 签名交易并创建 Bundle
✅ 交易签名完成
📦 Bundle 包含 2 个交易

📌 步骤 6: 提交 Bundle 到 Flashbots
✅ Bundle 提交成功
🔖 Bundle Hash: 0x...

📌 步骤 7: 等待 Bundle 被包含到区块中
⏳ 等待目标区块...
✅ Bundle 已被包含到区块中!

📌 步骤 8: 查询 Bundle Stats
📊 Bundle Stats:
{
  "isSimulated": true,
  "isHighPriority": false,
  "simulatedAt": "2026-01-15T07:28:00.000Z",
  "receivedAt": "2026-01-15T07:28:00.000Z"
}

============================================================
📋 最终结果汇总
============================================================

✅ 交易 1 (enablePresale):
   哈希: 0x...
   链接: https://sepolia.etherscan.io/tx/0x...

✅ 交易 2 (presale):
   哈希: 0x...
   链接: https://sepolia.etherscan.io/tx/0x...

🔖 Bundle Hash: 0x...

📌 步骤 10: 验证交易结果
✅ Transaction 1 状态: 成功
   区块号: 12347
✅ Transaction 2 状态: 成功
   区块号: 12347

🎉 用户 NFT 余额: 1

============================================================
✅ Flashbots Bundle 流程完成!
============================================================
```

## 📊 关键概念解释

### 1. Bundle 是什么？

Bundle 是一组交易的集合，这些交易：
- 必须在同一个区块中执行
- 按照 Bundle 中的顺序执行
- 要么全部成功，要么全部失败

### 2. Flashbots Provider 的作用

`FlashbotsBundleProvider` 是一个特殊的 ethers.js provider，它：
- 连接到 Flashbots Relay（中继服务器）
- 提供 `sendRawBundle()` 方法来提交交易捆绑
- 提供 `getBundleStats()` 方法来查询捆绑状态

### 3. 为什么需要两个 Signer？

在这个示例中：
- **Owner Signer**：拥有合约的 owner 权限，可以调用 `enablePresale()`
- **User Signer**：普通用户，调用 `presale()` 购买 NFT

两个不同的账户签名不同的交易，然后打包成一个 Bundle。

### 4. Gas 费用设置

使用 EIP-1559 交易类型：
- `maxFeePerGas`: 你愿意支付的最高 gas 价格
- `maxPriorityFeePerGas`: 给矿工/验证者的小费

计算公式：
```
maxFeePerGas = baseFeePerGas * 2 + maxPriorityFeePerGas
```

### 5. Nonce 管理

每个账户的 nonce 是独立的：
- Owner 账户有自己的 nonce
- User 账户有自己的 nonce

在创建交易时，需要为每个账户获取正确的 nonce。

### 6. Bundle Stats

`getBundleStats()` 返回的信息包括：
- `isSimulated`: Bundle 是否通过模拟
- `isHighPriority`: 是否高优先级
- `receivedAt`: Flashbots 收到 Bundle 的时间
- `simulatedAt`: 模拟执行的时间

## 🔍 验证结果

### 在 Etherscan 上查看

1. 访问输出中的交易链接
2. 确认两个交易在同一个区块中
3. 确认交易状态都是 Success

### 查看 NFT

你可以在 Etherscan 上查看 User 地址，确认收到了 NFT。

## ⚠️ 重要提示

### Sepolia 网络的限制

Flashbots 主要为以太坊主网设计，在 Sepolia 测试网上：
- 某些功能可能不完全支持
- Bundle 可能不保证被包含
- Stats 查询可能返回有限信息

这是正常的，主要用于学习和测试。

### 安全注意事项

- **永远不要**将真实的私钥提交到 Git
- `.env` 文件已在 `.gitignore` 中，确保不会被提交
- 只在测试网络上使用测试私钥

## 📁 项目结构

```
OSNFT-FlashBundle-Sepolia/
├── contracts/
│   └── OpenspaceNFT.sol          # NFT 合约
├── scripts/
│   ├── deploy.js                  # 部署脚本
│   └── flashbots-bundle.js        # Flashbots bundle 脚本
├── hardhat.config.js              # Hardhat 配置
├── package.json                   # 依赖配置
├── .env.example                   # 环境变量模板
├── .gitignore                     # Git 忽略文件
└── README.md                      # 本文件
```

## 🎓 学习要点总结

通过本项目，你学习了：

1. ✅ 如何部署 ERC721 NFT 合约
2. ✅ 如何使用 `@flashbots/ethers-provider-bundle`
3. ✅ 如何创建和签名多个交易
4. ✅ 如何使用 `eth_sendBundle` 提交交易捆绑
5. ✅ 如何使用 `flashbots_getBundleStats` 查询状态
6. ✅ 如何管理多个 Signer 的 nonce
7. ✅ 如何设置 EIP-1559 gas 费用
8. ✅ 如何验证交易结果

## 🔗 相关资源

- [Flashbots 官方文档](https://docs.flashbots.net/)
- [Flashbots Bundle Provider](https://github.com/flashbots/ethers-provider-flashbots-bundle)
- [Hardhat 文档](https://hardhat.org/docs)
- [Sepolia 浏览器](https://sepolia.etherscan.io/)

## 📝 作业提交内容

完成后，你需要提交：

1. ✅ Flashbots 交互代码（scripts/flashbots-bundle.js）
2. ✅ enablePresale 交易哈希
3. ✅ presale 交易哈希
4. ✅ flashbots_getBundleStats 返回的信息

祝学习愉快！🎉
