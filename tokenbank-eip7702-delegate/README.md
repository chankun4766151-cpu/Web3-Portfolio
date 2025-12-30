# TokenBank Permit2 作业项目

这是一个使用 Permit2 技术实现代币签名授权的去中心化银行项目。

---

## 📚 项目简介

### 什么是 Permit2？

Permit2 是 Uniswap 开发的通用授权合约，解决了传统 ERC20 授权的问题：

**传统方式的问题：**
- 每次使用新的 DApp，都要单独 approve（花费 gas）
- 需要两次交易：approve + 实际操作
- 授权管理复杂

**Permit2 的优势：**
- ✅ 一次性授权 Permit2，所有 DApp 都能用
- ✅ 使用签名代替 approve 交易（签名不花 gas）
- ✅ 更好的安全性和用户体验

---

## 🏗️ 项目结构

```
tokenbank-permit2-assignment/
├── src/                          # 智能合约源代码
│   ├── MyToken.sol              # ERC20 代币合约
│   ├── TokenBank.sol            # 原始银行合约
│   ├── IPermit2.sol             # Permit2 接口
│   └── TokenBankPermit2.sol     # 支持 Permit2 的银行合约
├── script/                       # 部署脚本
│   ├── Deploy.s.sol             # 原始部署脚本
│   └── DeployPermit2.s.sol      # Permit2 部署脚本
├── frontend/                     # 前端应用
│   ├── app/                     # Next.js 页面
│   ├── constants/               # 合约地址和 ABI
│   └── lib/                     # 工具函数和配置
└── foundry.toml                 # Foundry 配置文件
```

---

## 🚀 快速开始

### 第一步：安装依赖

#### 1. Foundry (智能合约开发)

如果还没安装 Foundry：
```bash
# Windows 用户
# 下载并安装：https://book.getfoundry.sh/getting-started/installation
```

#### 2. Node.js (前端开发)

确保安装了 Node.js 18+：
```bash
node --version  # 应该 >= 18.0.0
```

#### 3. 安装前端依赖

```bash
cd frontend
npm install
```

---

### 第二步：编译合约

```bash
# 在项目根目录
forge build
```

如果编译成功，你会看到 `Compiler run successful!`

---

### 第三步：部署合约到 Sepolia 测试网

#### 1. 准备工作

- 确保 `.env` 文件中有你的私钥和 RPC URL
- 确保钱包有 Sepolia 测试网的 ETH（用于 gas 费）
  - 获取测试 ETH：https://sepoliafaucet.com/

#### 2. 部署命令

```bash
forge script script/DeployPermit2.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --legacy
```

#### 3. 记录合约地址

部署成功后，你会看到：
```
MyToken deployed successfully!
   Address: 0x...（你的 MyToken 地址）

TokenBankPermit2 deployed successfully!
   Address: 0x...（你的 TokenBankPermit2 地址）
```

**📝 重要：复制这两个地址，稍后需要更新到前端配置中！**

---

### 第四步：配置前端

#### 1. 更新合约地址

编辑 `frontend/constants/addresses.ts`：

```typescript
export const CONTRACTS = {
  MyToken: '0x你的MyToken地址',              // 👈 替换这里
  TokenBankPermit2: '0x你的TokenBank地址',   // 👈 替换这里
  Permit2: '0x000000000022D473030F116dDEE9F6B43aC78BA3', // ✅ 官方地址，不用改
} as const;
```

#### 2. 获取 WalletConnect Project ID

1. 访问：https://cloud.walletconnect.com/
2. 注册并创建新项目
3. 复制 Project ID

编辑 `frontend/lib/wagmi.tsx`：

```typescript
const config = getDefaultConfig({
  appName: 'TokenBank Permit2',
  projectId: '你的_PROJECT_ID',  // 👈 替换这里
  chains: [sepolia],
  // ...
});
```

---

### 第五步：运行前端

```bash
cd frontend
npm run dev
```

打开浏览器访问：http://localhost:3000

---

## 📖 使用教程

### 1. 连接钱包

- 点击 "Connect Wallet" 按钮
- 选择你的钱包（MetaMask, WalletConnect等）
- 确保切换到 **Sepolia 测试网**

### 2. 获取测试代币

如果你的钱包没有 MyToken：

**方法 1：使用 Foundry 脚本发送**
```bash
cast send 你的MyToken地址 "mint(address,uint256)" 你的钱包地址 1000000000000000000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

**方法 2：使用 Etherscan**
1. 在 Etherscan 上找到你的 MyToken 合约
2. 使用 "Write Contract" 功能
3. 调用 `mint` 函数给自己铸造代币

### 3. 初始化 Permit2（一次性操作）

首次使用需要授权 Permit2 合约：

1. 在前端看到黄色提示框："初始化设置"
2. 点击 "授权 Permit2 合约"
3. 在钱包中确认交易
4. 等待交易确认

✅ 完成后，这个授权**永久有效**，之后所有支持 Permit2 的 DApp 都能使用！

### 4. 使用 Permit2 签名存款 ⭐

这是本项目的核心功能！

1. 在 "Permit2 签名存款" 区域输入金额（比如 10）
2. 点击 "签名并存款"
3. 钱包会弹出**签名请求**（注意：这不是交易，不花 gas！）
4. 确认签名
5. 等待存款交易完成

**对比传统方式：**
- 传统方式：需要 2 次交易（approve + deposit）
- Permit2 方式：只需 1 次签名 + 1 次交易

### 5. 取款

1. 在 "取款" 区域输入金额
2. 点击 "取款"
3. 确认交易

---

## 🔍 核心代码解析

### 智能合约部分

#### IPermit2.sol
```solidity
// Permit2 接口，定义签名转账的数据结构
interface IPermit2 {
    struct PermitTransferFrom {
        TokenPermissions permitted;  // 允许的代币和金额
        uint256 nonce;              // 防重放攻击
        uint256 deadline;           // 签名截止时间
    }
    
    function permitTransferFrom(...) external;  // 验证签名并转账
}
```

#### TokenBankPermit2.sol
```solidity
// 核心函数：使用 Permit2 签名进行存款
function depositWithPermit2(
    IPermit2.PermitTransferFrom calldata permitTransfer,
    address owner,
    bytes calldata signature
) external nonReentrant {
    // 1. 验证金额和代币
    // 2. 调用 Permit2 验证签名并转账
    permit2.permitTransferFrom(permitTransfer, transferDetails, owner, signature);
    // 3. 更新用户余额
    balances[owner] += permitTransfer.permitted.amount;
}
```

### 前端部分

#### 签名逻辑 (page.tsx)
```typescript
// Step 1: 构造签名数据
const permitData = {
    permitted: { token, amount },
    spender: TokenBankAddress,
    nonce,
    deadline
};

// Step 2: 用户签名（EIP-712）
const signature = await walletClient.signTypedData({
    domain, types, primaryType: 'PermitTransferFrom',
    message: permitData
});

// Step 3: 调用合约
await depositWithPermit2(permitData, userAddress, signature);
```

---

## 🎓 学习要点

通过这个项目，你学到了：

### 1. Permit2 技术
- ✅ 什么是通用授权
- ✅ 如何使用签名代替交易
- ✅ EIP-712 签名标准
- ✅ 防重放攻击（nonce 机制）

### 2. 智能合约开发
- ✅ 如何集成第三方合约（Permit2）
- ✅ 安全编程实践（ReentrancyGuard, SafeERC20）
- ✅ Gas 优化（使用 custom errors）

### 3. DApp 开发
- ✅ Next.js + wagmi + viem 技术栈
- ✅ 钱包连接（RainbowKit）
- ✅ 合约交互和状态管理
- ✅ 用户体验设计

---

## 🐛 常见问题

### Q1: 编译失败怎么办？

```bash
# 确保依赖已安装
ls lib/  # 应该看到 forge-std 和 openzeppelin-contracts

# 如果没有，重新克隆
git clone https://github.com/foundry-rs/forge-std.git lib/forge-std
git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts
```

### Q2: 部署失败怎么办？

- 检查 `.env` 文件中的私钥和 RPC URL
- 确保钱包有足够的 Sepolia ETH
- 尝试使用 `--legacy` 标志

### Q3: 前端无法连接钱包？

- 确保安装了 MetaMask 或其他钱包扩展
- 确保钱包已切换到 Sepolia 测试网
- 检查 WalletConnect Project ID 是否正确配置

### Q4: Permit2 授权后还是提示要授权？

- 刷新页面
- 检查合约地址配置是否正确
- 查看浏览器控制台是否有错误

### Q5: 签名存款失败？

- 确保已经授权 Permit2 合约
- 确保钱包有足够的代币余额
- 检查金额是否正确（不要输入超过余额的金额）

---

## 📚 参考资料

- [Uniswap Permit2 Documentation](https://github.com/Uniswap/permit2)
- [EIP-712 Typed Data Standard](https://eips.ethereum.org/EIPS/eip-712)
- [Foundry Book](https://book.getfoundry.sh/)
- [wagmi Documentation](https://wagmi.sh/)
- [RainbowKit Documentation](https://www.rainbowkit.com/)

---

## ✅ 作业检查清单

完成以下所有项目：

- [ ] ✅ 智能合约编译成功
- [ ] ✅ 合约部署到 Sepolia 测试网
- [ ] ✅ 前端可以正常运行
- [ ] ✅ 成功授权 Permit2 合约
- [ ] ✅ 成功使用 Permit2 签名进行存款
- [ ] ✅ 成功取款
- [ ] ✅ 理解 Permit2 的工作原理
- [ ] ✅ 在 Etherscan 上查看了交易记录

---

## 🎉 恭喜！

如果你完成了所有步骤，说明你已经掌握了：
- Permit2 技术的核心概念
- 完整的 DApp 开发流程
- Web3 前端开发技能

继续加油！🚀
