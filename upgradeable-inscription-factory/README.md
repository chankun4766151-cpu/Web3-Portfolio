# Upgradeable Inscription Factory

可升级的铭文工厂合约项目 - 学习可升级合约、最小代理和铭文机制的完整示例

## 项目简介

这是一个实现了可升级工厂合约的项目，用于创建和铸造 ERC20 铭文代币。项目包含两个版本：

- **V1版本**：使用传统的 `new` 关键字部署 ERC20 代币
- **V2版本**：使用最小代理（EIP-1167）模式部署，并增加价格机制

## 核心概念

### 1. 铭文（Inscription）机制
- 模拟比特币 Ordinals 的公平发行
- 固定总供应量和每次铸造数量
- 先到先得，防止巨鲸垄断

### 2. 可升级合约（UUPS）
- 使用代理模式实现合约升级
- 保持地址不变，业务逻辑可更新
- 存储布局兼容性保证

### 3. 最小代理（Minimal Proxy - EIP-1167）
- 部署成本降低 90%+
- 约 55 字节的极小代理合约
- 通过 delegatecall 转发到实现合约

## 合约地址

| 合约类型 | 地址 | Etherscan |
|---------|------|-----------|
| 代理合约 (Proxy) | `待部署` | [查看](https://sepolia.etherscan.io/address/) |
| V1 实现合约 | `待部署` | [查看](https://sepolia.etherscan.io/address/) |
| V2 实现合约 | `待部署` | [查看](https://sepolia.etherscan.io/address/) |
| V2 Token 实现 | `待部署` | [查看](https://sepolia.etherscan.io/address/) |

## 项目结构

```
upgradeable-inscription-factory/
├── src/
│   ├── InscriptionToken.sol          # V1 ERC20 代币
│   ├── InscriptionTokenV2.sol        # V2 可初始化代币
│   ├── InscriptionFactory.sol        # V1 工厂（使用 new）
│   └── InscriptionFactoryV2.sol      # V2 工厂（使用 Clones）
├── test/
│   ├── InscriptionFactory.t.sol      # V1 功能测试
│   └── Upgrade.t.sol                 # 升级测试
├── script/
│   ├── DeployV1.s.sol                # V1 部署脚本
│   └── UpgradeToV2.s.sol             # V2 升级脚本
└── README.md
```

## 安装和使用

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd upgradeable-inscription-factory
```

### 2. 安装依赖

```bash
forge install
```

### 3. 运行测试

```bash
# 运行所有测试
forge test -vv

# 运行 V1 测试
forge test --match-contract InscriptionFactoryTest -vv

# 运行升级测试
forge test --match-contract UpgradeTest -vv
```

### 4. 部署到 Sepolia

#### 配置环境变量

创建 `.env` 文件：
```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR-PROJECT-ID
ETHERSCAN_API_KEY=your_etherscan_api_key
```

#### 部署 V1

```bash
source .env
forge script script/DeployV1.s.sol:DeployV1 \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

#### 测试 V1 功能

部署一个测试代币并铸造：
```bash
# 使用 cast 交互
cast send <PROXY_ADDRESS> \
  "deployInscription(string,uint256,uint256)" \
  "TEST" 1000000 1000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 铸造代币
cast send <PROXY_ADDRESS> \
  "mintInscription(address)" \
  <TOKEN_ADDRESS> \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### 升级到 V2

```bash
export PROXY_ADDRESS=<your_proxy_address>
forge script script/UpgradeToV2.s.sol:UpgradeToV2 \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

## 测试结果

所有测试通过截图：

![Test Results](./test-results.png)

```
Running 12 tests:
✅ V1 Tests (7/7)
  - testDeployInscription
  - testCannotDeployDuplicateSymbol  
  - testMintInscription
  - testMultipleMints
  - testCannotExceedTotalSupply
  - testEvents
  - testTokenNameFormat

✅ Upgrade Tests (5/5)
  - testUpgradeToV2
  - testDataPersistsAfterUpgrade
  - testOldTokensStillMintableAfterUpgrade
  - testNewFeaturesAfterUpgrade
  - testOwnershipPersists
```

## 核心功能

### V1 功能

```solidity
// 部署铭文代币
function deployInscription(
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint
) external returns (address tokenAddress);

// 铸造代币
function mintInscription(address tokenAddr) external;
```

### V2 新增功能

```solidity
// 部署铭文代币（带价格）
function deployInscription(
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint,
    uint256 price  // 新增：每个 token 的价格
) external returns (address tokenAddress);

// 铸造代币（需要支付 ETH）
function mintInscription(address tokenAddr) external payable;

// 提取收取的费用
function withdrawFees() external onlyOwner;
```

## Gas 对比

| 操作 | V1 (new) | V2 (clone) | 节省 |
|------|----------|------------|------|
| 部署代币 | ~1,000,000 gas | ~40,000 gas | 96% |

## 学习要点

通过这个项目，你将学习到：

1. **可升级合约模式**
   - 代理合约与实现合约的分离
   - UUPS 升级模式的原理
   - 存储布局兼容性的重要性

2. **最小代理（EIP-1167）**
   - Clones 库的使用
   - 极致的 gas 优化
   - 适用场景和限制

3. **铭文机制**
   - 公平发行的设计理念
   - 供应量和铸造控制
   - 防垄断机制

4. **Foundry 开发**
   - 测试驱动开发（TDD）
   - 部署脚本编写
   - 合约验证流程

## 作者

这是一个 Web3 学习项目，作为区块链开发的学习案例。

## 许可

MIT License
