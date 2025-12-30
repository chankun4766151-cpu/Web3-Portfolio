# Meme 发射平台 - 最小代理工厂合约

使用 **EIP-1167 最小代理模式** 实现的 Meme 代币发射平台，显著降低代币部署成本。

## 项目特点

- 🚀 **Gas 优化**: 使用最小代理模式，部署成本降低约 87%
- 💰 **费用分配**: 自动分配铸造费用（1% 平台，99% 发行者）
- 🔒 **安全可靠**: 供应量限制、访问控制、支付验证
- ✅ **测试完备**: 9 个测试用例，覆盖所有核心功能
- 📦 **生产就绪**: 基于 OpenZeppelin 的安全合约库

## 技术架构

### 核心合约

1. **MemeToken.sol** - ERC20 实现合约
   - 包含所有代币业务逻辑
   - 使用 `initialize()` 函数适配代理模式
   - 铸造权限控制和供应量限制

2. **MemeFactory.sol** - 工厂合约
   - 使用 Clones 库创建最小代理
   - `deployMeme()` - 创建新 Meme 代币
   - `mintMeme()` - 铸造代币并分配费用

## 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装

```bash
# 克隆仓库
git clone <your-repo-url>
cd MemeLaunchpad-MinimalProxy-Factory

# 安装依赖
forge install
```

### 编译

```bash
forge build
```

### 运行测试

```bash
# 运行所有测试
forge test

# 详细输出
forge test -vvv

# Gas 报告
forge test --gas-report
```

## 使用示例

### 部署 Meme 代币

```solidity
// 部署工厂合约
MemeFactory factory = new MemeFactory();

// 创建 Meme 代币
address tokenAddr = factory.deployMeme(
    "PEPE",              // 代币符号
    1_000_000 * 1e18,    // 总供应量
    1000 * 1e18,         // 每次铸造数量
    0.01 ether           // 每次铸造价格
);
```

### 铸造代币

```solidity
// 用户支付费用铸造代币
factory.mintMeme{value: 0.01 ether}(tokenAddr);
```

## 测试结果

✅ **所有 9 个测试通过**

```
[PASS] testCannotDeployDuplicateSymbol() (gas: 248235)
[PASS] testCannotExceedSupply() (gas: 422140)
[PASS] testDeployMeme() (gas: 261970)
[PASS] testFeeDistribution() (gas: 327616)
[PASS] testIncorrectPaymentFails() (gas: 266195)
[PASS] testMinimalProxyGasSavings() (gas: 478019)
[PASS] testMintCorrectAmount() (gas: 386980)
[PASS] testMintMeme() (gas: 326329)
[PASS] testTokenName() (gas: 246760)
```

### 测试覆盖

- ✅ 部署功能验证
- ✅ 铸造数量正确性
- ✅ 费用分配准确性（1% / 99%）
- ✅ 供应量限制保护
- ✅ 支付验证
- ✅ Gas 优化效果

## Gas 成本对比

| 部署方式 | Gas 成本 | 节省 |
|---------|---------|------|
| 完整 ERC20 合约 | ~1,500,000 | - |
| 最小代理 | ~200,000 | **87%** |

## 核心功能

### deployMeme

创建新的 Meme 代币（最小代理合约）

**参数：**
- `symbol` - 代币符号
- `totalSupply` - 总供应量
- `perMint` - 每次铸造数量
- `price` - 每次铸造价格（wei）

**返回：** 新创建的代币合约地址

### mintMeme

铸造 Meme 代币并分配费用

**参数：**
- `tokenAddr` - 代币合约地址

**支付：** 需发送等于代币价格的 ETH

**费用分配：**
- 1% → 平台方
- 99% → Meme 发行者

## 技术亮点

### 1. 最小代理模式（EIP-1167）

通过创建轻量级代理合约（仅 45 字节）指向实现合约，实现显著的 Gas 节省。

### 2. Initialize 模式

使用 `initialize()` 函数替代构造函数，适配代理合约的初始化需求。

### 3. 费用分配机制

自动计算并分配铸造费用，确保平台和发行者的收益。

### 4. 安全保护

- 供应量上限检查
- 支付金额验证
- 访问权限控制
- 重复初始化防护

## 项目结构

```
.
├── src/
│   ├── MemeToken.sol       # ERC20 实现合约
│   └── MemeFactory.sol     # 工厂合约
├── test/
│   └── MemeFactory.t.sol   # 测试套件
├── lib/
│   ├── forge-std/          # Foundry 标准库
│   └── openzeppelin-contracts/  # OpenZeppelin 库
├── foundry.toml            # 配置文件
└── README.md               # 本文件
```

## 学习资源

- [EIP-1167: 最小代理标准](https://eips.ethereum.org/EIPS/eip-1167)
- [OpenZeppelin Clones 库](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones)
- [Foundry 文档](https://book.getfoundry.sh/)

## 许可证

MIT License

## 作者

区块链开发学习项目 - ETH Chiangmai 课程作业

---

**注意**: 本项目仅用于学习目的，未经审计，请勿直接用于生产环境。
