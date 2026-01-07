# Uniswap V2 Flash Swap Arbitrage Example

这是一个完整的 Uniswap V2 闪电兑换套利示例项目，展示如何利用两个流动池之间的价格差异进行套利。

## 📋 项目简介

本项目实现了以下功能：
- ✅ 两个 ERC20 代币（TokenA 和 TokenB）
- ✅ 简化的 Uniswap V2 Factory 和 Pair 实现（兼容 Solidity 0.8.20）
- ✅ 两个具有价格差异的流动池（PoolA 和 PoolB）
- ✅ 闪电兑换套利合约

## 🏗 架构设计

### 核心合约

1. **MyTokenA.sol** & **MyTokenB.sol**
   - 标准 ERC20 代币
   - 初始供应量：1,000,000 tokens

2. **SimpleUniswapV2.sol**
   - `SimpleFactory`: 创建和管理流动池
   - `SimplePair`: 实现 AMM 交易逻辑和闪电兑换

3. **FlashSwapArbitrage.sol**
   - 核心套利合约
   - 实现 `uniswapV2Call` 回调函数
   - 利用价格差异进行套利

## 💡 套利原理

### 价格设置
- **Pool A**: 1 TokenA = 100 TokenB
- **Pool B**: 1 TokenA = 150 TokenB

### 套利流程
1. 从 **PoolA** 发起闪电兑换，借出 TokenA
2. 在 **PoolB** 用借来的 TokenA 兑换 TokenB
3. 计算需要还给 PoolA 的数量（包含 0.3% 手续费）
4. 用 TokenB 还款给 PoolA
5. 剩余的代币即为套利利润

## 🚀 快速开始

### 环境要求
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装步骤

```bash
# 已完成依赖安装
# OpenZeppelin, Uniswap V2 Core/Periphery 已安装

# 编译合约
forge build

# 运行测试
forge test -vvv
```

### 环境配置

复制 `.env.example` 为 `.env` 并配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件：
```env
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

## 📜 部署步骤

### 1. 部署到测试网

```bash
# 部署所有合约并创建流动池
forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify -vvvv
```

部署脚本会：
1. 部署 TokenA 和 TokenB
2. 部署两个独立的 Factory  
3. 创建 PoolA 和 PoolB
4. 为两个池子添加流动性（不同比例）
5. 部署 FlashSwapArbitrage 合约

### 2. 更新执行脚本

部署完成后，将输出的合约地址复制到 `script/ExecuteArbitrage.s.sol` 中：

```solidity
address constant ARBITRAGE_CONTRACT = 0x...; // FlashSwapArbitrage 地址
address constant POOL_A = 0x...;             // Pool A 地址
address constant POOL_B = 0x...;             // Pool B 地址
address constant TOKEN_A = 0x...;            // TokenA 地址
address constant TOKEN_B = 0x...;            // TokenB 地址
```

### 3. 执行套利

```bash
forge script script/ExecuteArbitrage.s.sol --rpc-url sepolia --broadcast -vvvv
```

## 🔍 验证结果

### 在 Etherscan 上查看

1. 查找套利交易的 transaction hash
2. 在 [Sepolia Etherscan](https://sepolia.etherscan.io/) 搜索交易
3. 查看 Logs 标签页，应该看到：
   - `Swap` 事件（从 PoolA 借出）
   - `Swap` 事件（在 PoolB 交易）
   - `ArbitrageExecuted` 事件（显示利润）

### 关键事件

**ArbitrageExecuted 事件**:
```solidity
event ArbitrageExecuted(
    address indexed poolA,
    address indexed poolB,
    uint256 borrowedAmount,
    uint256 profit,
    address profitToken
);
```

## 📁 项目结构

```
FlashGap-ArbV2/
├── src/
│   ├── MyTokenA.sol              # ERC20 代币 A
│   ├── MyTokenB.sol              #  ERC20 代币 B
│   ├── SimpleUniswapV2.sol       # 简化的 Uniswap V2 实现
│   └── FlashSwapArbitrage.sol    # 闪电兑换套利合约
├── script/
│   ├── Deploy.s.sol              # 部署脚本
│   └── ExecuteArbitrage.s.sol    # 执行套利脚本
├── test/
│   └── FlashSwapArbitrage.t.sol  # 测试套件
├── foundry.toml                   # Foundry 配置
└── README.md                      # 项目文档
```

## ⚠️ 注意事项

### 当前状态
- ✅ 合约编译成功
- ✅ 基础测试通过
- ⚠️ 部分套利测试需要进一步调试（K值验证）

### 已知问题
由于 Uniswap V2 原版使用 Solidity 0.5.16/0.6.6，本项目使用了简化的 0.8.20 兼容版本。在测试中发现恒定乘积公式验证有时会失败，需要进一步调整：

1. **费用计算**：确保正确计算 0.3% 手续费
2. **还款逻辑**：验证借出和还款的代币类型匹配
3. **滑点保护**：添加最小输出金额检查

### 生产环境使用
本项目仅用于学习和演示目的。在生产环境中使用闪电兑换时，请注意：

1. **Gas 优化**：减少不必要的存储操作
2. **MEV 保护**：考虑使用 Flashbots 等服务  
3. **价格预言机**：添加价格验证避免被操纵
4. **紧急暂停**：实现紧急停止机制
5. **权限控制**：加强访问控制和多签机制

## 📚 学习资源

- [Uniswap V2 文档](https://docs.uniswap.org/protocol/V2/introduction)
- [Uniswap V2 白皮书](https://uniswap.org/whitepaper.pdf)
- [Flash Swaps 指南](https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps)
- [Foundry 书](https://book.getfoundry.sh/)

## 🤝 作业提交

### 要求
1. ✅ 贴出代码库链接  
2. ✅ 上传执行闪电兑换的日志

### 提交清单
- [ ] GitHub 仓库链接
- [ ] Sepolia 测试网部署地址
- [ ] 套利交易的 Etherscan 链接
- [ ] 交易日志截图（显示 ArbitrageExecuted 事件）

## 📝 License

MIT License

## 👨‍💻 作者

ETHChiangmai 学习示例项目
