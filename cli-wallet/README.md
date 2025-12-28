# CLI 钱包 - Sepolia 测试网

一个基于 Viem.js 的命令行以太坊钱包工具，支持私钥管理、余额查询和 ERC20 代币转账（EIP-1559）。

## 功能特性

✅ 生成和管理以太坊钱包（私钥/地址）  
✅ 查询 ETH 和 ERC20 代币余额  
✅ 构建并发送 ERC20 转账交易（EIP-1559 标准）  
✅ 交易签名和广播到 Sepolia 测试网  
✅ 用户友好的命令行交互界面

## 技术栈

- **Viem.js** - 现代化的以太坊交互库
- **Node.js** - JavaScript 运行时
- **readline-sync** - 命令行交互
- **dotenv** - 环境变量管理

## 安装步骤

### 1. 克隆或下载项目

```bash
cd cli-wallet
```

### 2. 安装依赖

```bash
npm install
```

### 3. 配置环境变量

项目中的 `.env` 文件已经配置好了：
- Sepolia RPC URL: `https://rpc.sepolia.org`
- ERC20 合约地址: `0xB79835DAc52673DCE45F9a6f65915e6a41ED82F0`

## 使用方法

### 启动钱包

```bash
npm start
```

### 功能说明

#### 1️⃣ 生成新钱包
- 生成随机私钥和对应地址
- 自动保存私钥到 `.env` 文件
- 显示钱包地址和余额

#### 2️⃣ 查询余额
- 查询 ETH 余额
- 查询 ERC20 代币余额
- 显示代币符号

#### 3️⃣ 发送 ERC20 代币
- 输入接收地址和金额
- 自动构建 EIP-1559 交易
- 显示 Gas 价格信息（Base Fee、Priority Fee）
- 签名并发送交易
- 返回交易哈希和浏览器链接

#### 4️⃣ 查看当前地址
- 显示钱包地址和私钥

## 获取测试资金

### Sepolia ETH 水龙头
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

### 注意事项
- 需要先获取 Sepolia ETH 才能支付 Gas 费用
- 确保钱包有足够的 ERC20 代币才能进行转账测试

## 项目结构

```
cli-wallet/
├── src/
│   ├── wallet.js      # 钱包核心功能
│   ├── erc20.js       # ERC20 交互功能
│   └── cli.js         # 命令行界面
├── .env               # 环境变量配置
├── .gitignore         # Git 忽略文件
├── package.json       # 项目配置
└── README.md          # 使用说明
```

## EIP-1559 交易说明

本项目使用 EIP-1559 交易格式，包含以下特性：

- **Base Fee**: 由网络自动计算的基础费用
- **Max Priority Fee**: 给矿工的小费（本项目设置为 2 Gwei）
- **Max Fee**: 愿意支付的最大 Gas 费用

交易会自动优化 Gas 费用，只支付实际需要的金额。

## 安全提示

⚠️ **重要提示**：
- 私钥保存在 `.env` 文件中，仅适合测试环境
- 请勿在生产环境使用此方式存储私钥
- 请勿将 `.env` 文件提交到 Git 仓库
- 仅在 Sepolia 测试网使用，切勿使用主网

## 交易记录

### 测试交易链接
<!-- 在这里记录你的交易链接 -->
- 交易 1: https://sepolia.etherscan.io/tx/0x0d3ebe57a82064d8929ca40ae67b019ce20a129657ffc5dfff50abc19049bb66

## 作业完成检查清单

- [x] ✅ 生成私钥功能
- [x] ✅ 查询余额功能（ETH 和 ERC20）
- [x] ✅ 构建 ERC20 转账的 EIP-1559 交易
- [x] ✅ 使用生成的账号对交易进行签名
- [x] ✅ 发送交易到 Sepolia 网络
- [ ] 📝 提交代码仓库
- [ ] 🔗 添加交易浏览器链接

## 问题排查

### 问题 1: 交易失败
- 检查钱包是否有足够的 ETH 支付 Gas
- 检查 ERC20 代币余额是否充足
- 确认接收地址格式正确

### 问题 2: RPC 连接失败
- 检查网络连接
- 尝试更换其他 RPC URL（如 Infura 或 Alchemy）

### 问题 3: 合约交互失败
- 确认合约地址正确
- 检查合约是否部署在 Sepolia 网络

## 许可证

ISC
