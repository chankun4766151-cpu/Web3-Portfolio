# NFT Market 部署和使用指南

## 前置准备

### 1. 获取 WalletConnect Project ID

1. 访问 [Reown Cloud](https://cloud.reown.com)
2. 注册/登录账号
3. 创建新项目
4. 复制 Project ID

### 2. 准备 Sepolia 测试网资源

- 私钥（用于部署合约）
- Sepolia 测试 ETH（从水龙头获取）
- Sepolia RPC URL（推荐使用 Infura 或 Alchemy）

## 步骤 1: 部署智能合约

### 1.1 配置环境变量

在项目根目录创建 `.env` 文件：

```bash
PRIVATE_KEY=你的私钥（不要包含0x前缀）
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
```

### 1.2 部署合约

```bash
# 确保在项目根目录
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY

# 或者使用 .env 中的变量
source .env
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

### 1.3 记录合约地址

部署完成后，记录以下合约地址：
- MyERC20 deployed at: `0x...`
- MyNFT deployed at: `0x...`
- NFTMarket deployed at: `0x...`

## 步骤 2: 配置前端

### 2.1 创建前端环境变量

在 `frontend/` 目录下创建 `.env` 文件：

```bash
cd frontend

# 创建 .env 文件
cat > .env << EOF
VITE_WALLETCONNECT_PROJECT_ID=你的WalletConnect项目ID
VITE_NFT_ADDRESS=上面部署的MyNFT合约地址
VITE_TOKEN_ADDRESS=上面部署的MyERC20合约地址
VITE_MARKET_ADDRESS=上面部署的NFTMarket合约地址
EOF
```

### 2.2 启动前端

```bash
npm run dev
```

前端将在 http://localhost:5173 启动

## 步骤 3: 测试功能

### 3.1 连接钱包（使用 WalletConnect）

1. 在手机上安装钱包应用（如 MetaMask Mobile、Rainbow 等）
2. 确保手机钱包切换到 Sepolia 测试网
3. 在浏览器中打开前端应用，点击 "Connect Wallet"
4. 使用手机钱包扫描二维码
5. 在手机上授权连接

### 3.2 铸造 NFT（账号 A）

1. 进入 "Mint" 页面
2. 在 "Mint NFT" 部分输入 Token URI，例如：
   ```
   ipfs://QmPK1s3pNYLi9ERiq3BDxKa4XosgWwFRQUydHUtz4YgpqB
   ```
3. 点击 "Mint NFT"
4. 在手机钱包上确认交易
5. 记录铸造的 Token ID（通常从 0 开始）

### 3.3 铸造代币（账号 B）

1. 切换到另一个账号（用于后续购买）
2. 在 "Mint Tokens" 部分输入数量，例如 `1000`
3. 点击 "Mint Tokens"
4. 在手机钱包上确认交易

### 3.4 上架 NFT（账号 A）

1. 确保当前连接的是拥有 NFT 的账号（账号 A）
2. 进入 "List NFT" 页面
3. 输入 NFT 合约地址（即部署的 MyNFT 地址）
4. 输入 Token ID（刚才铸造的 NFT ID）
5. 输入价格（例如 `100`，表示 100 个代币）
6. 点击 "Approve NFT"，在手机钱包确认
7. 等待交易确认后，点击 "List NFT"，在手机钱包确认
8. **截图保存**：上架成功后，截图保存页面

### 3.5 购买 NFT（账号 B）

1. 断开当前钱包连接
2. 使用另一个账号（账号 B）连接钱包
3. 进入 "Buy NFT" 页面
4. 可以看到刚才上架的 NFT
5. 点击 "Approve Tokens"，在手机钱包确认（授权代币）
6. 点击 "Buy NFT"，在手机钱包确认
7. 购买成功后可以看到 NFT 列表更新

## 步骤 4: 提交到 GitHub

### 4.1 初始化 Git 仓库

```bash
cd /d/ETHChiangmai/nftmarket-appkit-demo

git init
git add .
git commit -m "Initial commit: NFT Market with AppKit integration"
```

### 4.2 创建 GitHub 仓库

1. 访问 GitHub，创建新仓库
2. 复制仓库 URL

### 4.3 推送代码

```bash
git remote add origin https://github.com/你的用户名/nftmarket-appkit-demo.git
git branch -M main
git push -u origin main
```

### 4.4 添加截图到仓库

```bash
# 在项目根目录创建 screenshots 文件夹
mkdir screenshots

# 将上架截图复制到 screenshots 文件夹
# 然后提交
git add screenshots/
git commit -m "Add NFT listing screenshots"
git push
```

## 故障排查

### WalletConnect 连接失败
- 确保 Project ID 正确
- 检查手机和电脑在同一网络
- 尝试刷新页面重新生成 QR 码

### 交易失败
- 确保钱包有足够的 Sepolia ETH
- 检查合约地址是否正确
- 查看浏览器控制台错误信息

### NFT 不显示
- 确认 NFT 已成功上架
- 检查浏览器控制台是否有错误
- 刷新页面重新获取列表

## 合约验证（可选）

```bash
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 200 \
  --constructor-args $(cast abi-encode "constructor()") \
  --compiler-version v0.8.20 \
  合约地址 \
  src/MyERC20.sol:MyERC20 \
  --etherscan-api-key YOUR_ETHERSCAN_API_KEY
```

## 资源链接

- [Reown Cloud](https://cloud.reown.com) - 获取 WalletConnect Project ID
- [Sepolia Faucet](https://sepoliafaucet.com/) - 获取测试 ETH
- [Infura](https://infura.io/) - RPC 节点服务
- [Sepolia Etherscan](https://sepolia.etherscan.io/) - 区块链浏览器
