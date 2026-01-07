# Meme LaunchPad TWAP Oracle

一个基于 Foundry 的智能合约项目，实现了 Meme 代币发射台和时间加权平均价格（TWAP）预言机系统。

## 项目概述

该项目包含三个核心合约：

1. **MemeToken.sol** - 标准 ERC20 代币合约，用于创建 Meme 代币
2. **TWAPOracle.sol** - 时间加权平均价格预言机，跟踪和计算代币价格
3. **MemeLaunchPad.sol** - 发射台工厂合约，集成 AMM 功能和 TWAP 预言机

## 功能特点

### TWAP 预言机
- ✅ 记录价格观察点（价格、时间戳、累积价格）
- ✅ 计算指定时间区间的 TWAP
- ✅ 支持查询当前价格和历史价格
- ✅ 每次交易自动更新价格

### LaunchPad 发射台
- ✅ 部署新的 Meme 代币
- ✅ 添加流动性（ETH + Token 池）
- ✅ AMM 交易功能（基于恒定乘积公式 x*y=k）
- ✅ 自动集成 TWAP 价格跟踪

### 测试覆盖
- ✅ 代币创建测试
- ✅ 流动性添加测试
- ✅ 交易功能测试
- ✅ **多时间点交易模拟测试**（核心功能）
- ✅ TWAP 精度验证测试
- ✅ 连续交易时间推进测试

## 项目结构

```
MemeLaunchPad-TWAP-Oracle/
├── src/
│   ├── MemeToken.sol           # ERC20 代币合约
│   ├── TWAPOracle.sol          # TWAP 预言机
│   └── MemeLaunchPad.sol       # 发射台工厂
├── test/
│   └── Counter.t.sol           # 综合测试套件
├── lib/                        # 依赖库
├── foundry.toml               # Foundry 配置
└── README.md                  # 项目文档
```

## 安装和使用

### 前置要求
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装依赖

```bash
# 克隆仓库
git clone <repository-url>
cd MemeLaunchPad-TWAP-Oracle

# 安装依赖
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
# 运行所有测试
forge test -vv

# 运行 TWAP 多时间点交易测试（核心测试）
forge test -vv --match-test test_TWAPMultipleTradesOverTime

# 运行测试并显示详细日志
forge test -vvv
```

## 核心测试说明

### test_TWAPMultipleTradesOverTime

该测试演示了 TWAP 预言机在不同时间点的价格跟踪功能：

1. **T0 (初始时间)**: 记录初始价格，用户1买入 1 ETH 的代币
2. **T1 (T0 + 1小时)**: 用户2买入 2 ETH 的代币，价格上涨
3. **T2 (T1 + 2小时)**: 用户1卖出代币，价格下跌
4. **T3 (T2 + 1小时)**: 用户2再次买入 0.5 ETH 的代币

测试验证：
- ✅ 价格在买入时上涨，卖出时下跌
- ✅ TWAP 计算不同时间区间（1小时、2小时、3小时、4小时）
- ✅ 价格观察点正确记录（共5个观察点）

## TWAP 计算原理

TWAP（时间加权平均价格）计算公式：

```
TWAP = Σ(price_i × duration_i) / total_duration
```

其中：
- `price_i` 是第 i 个时间段的价格
- `duration_i` 是第 i 个时间段的持续时间
- `total_duration` 是总时间区间

## 合约功能说明

### MemeLaunchPad

```solidity
// 创建新的 Meme 代币
function createMeme(string name, string symbol, uint256 initialSupply) external returns (address)

// 添加流动性
function addLiquidity(address token, uint256 tokenAmount) external payable

// 交易（买入/卖出）
function swap(address token, uint256 amountIn, bool isEthToToken) external payable returns (uint256)

// 获取当前价格
function getPrice(address token) external view returns (uint256)
```

### TWAPOracle

```solidity
// 更新价格
function update(address token, uint256 price) external

// 获取 TWAP
function getTWAP(address token, uint256 interval) external view returns (uint256)

// 获取当前价格
function getCurrentPrice(address token) external view returns (uint256)

// 获取观察点数量
function getObservationCount(address token) external view returns (uint256)
```

## 测试结果

所有测试均通过 ✅

```bash
Ran 8 tests for test/Counter.t.sol:MemeLaunchPadTest
[PASS] test_AddLiquidity()
[PASS] test_ConsecutiveSwapsWithTime()
[PASS] test_CreateMemeToken()
[PASS] test_OracleNoObservations()
[PASS] test_PriceUpdates()
[PASS] test_Swap()
[PASS] test_TWAPAccuracy()
[PASS] test_TWAPMultipleTradesOverTime() ⭐ (核心测试)
```

## 技术栈

- **Solidity** ^0.8.20
- **Foundry** - 开发框架
- **OpenZeppelin** - ERC20 和 Ownable 实现
- **Forge** - 测试框架

## 时间模拟

测试使用 Foundry 的 `vm.warp()` 功能模拟区块时间推进：

```solidity
vm.warp(block.timestamp + 1 hours);  // 时间推进1小时
vm.warp(block.timestamp + 2 hours);  // 时间推进2小时
```

这使得我们可以在测试中模拟真实世界中的时间流逝，验证 TWAP 计算的正确性。

## License

MIT

## 作者

Developed for ETH Chiang Mai Hackathon 2026
