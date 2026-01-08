# Uniswap V2 Foundry Deep Dive

一个完整的 Uniswap V2 协议实现，使用 Foundry 框架构建，包含详细的中文代码注释。

## 📚 项目概述

本项目是 Uniswap V2 协议的完整实现，旨在帮助开发者深入理解 AMM（自动做市商）的核心原理。

### 包含内容

- ✅ Uniswap V2 Core 合约（Factory, Pair, ERC20）
- ✅ Uniswap V2 Periphery 合约（Router02, Library, WETH9）
- ✅ 详细的中文代码注释
- ✅ 完整的测试用例
- ✅ 本地部署脚本
- ✅ init_code_hash 自动计算

## 🏗️ 项目结构

```
UniV2-Foundry-DeepDive/
├── src/
│   ├── core/                   # Uniswap V2 核心合约
│   │   ├── UniswapV2Factory.sol    # 工厂合约
│   │   ├── UniswapV2Pair.sol       # 交易对合约 (AMM 核心)
│   │   ├── UniswapV2ERC20.sol      # LP Token 实现
│   │   ├── interfaces/             # 接口定义
│   │   └── libraries/              # 数学库
│   ├── periphery/              # Uniswap V2 周边合约
│   │   ├── UniswapV2Router02.sol   # 路由合约
│   │   ├── UniswapV2Library.sol    # 辅助库
│   │   ├── WETH9.sol               # Wrapped ETH
│   │   ├── interfaces/             # 接口定义
│   │   └── libraries/              # 工具库
│   └── test/                   # 测试用代币
├── script/
│   ├── DeployUniswapV2.s.sol       # 部署脚本
│   └── ComputeInitCodeHash.s.sol   # 计算 init_code_hash
├── test/                       # 测试文件
│   ├── UniswapV2Factory.t.sol
│   ├── UniswapV2Pair.t.sol
│   └── UniswapV2Router.t.sol
└── docs/
    └── UNISWAP_V2_ANALYSIS.md     # Uniswap V2 深度分析
```

## 🚀 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, anvil)
- Git

### 安装

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/UniV2-Foundry-DeepDive.git
cd UniV2-Foundry-DeepDive

# 安装依赖
forge install
```

### 编译

```bash
forge build
```

### 运行测试

```bash
forge test -vvv
```

### 计算 init_code_hash

```bash
forge script script/ComputeInitCodeHash.s.sol
```

### 本地部署

```bash
# 终端1：启动本地节点
anvil

# 终端2：部署合约
forge script script/DeployUniswapV2.s.sol --rpc-url http://localhost:8545 --broadcast
```

## 📖 核心概念

### 恒定乘积公式

Uniswap V2 使用恒定乘积做市商（CPMM）模型：

```
x * y = k
```

其中：
- `x` = token0 储备量
- `y` = token1 储备量
- `k` = 恒定乘积

### 手续费

- 每次交换收取 **0.3%** 手续费
- 0.25% 归流动性提供者（LP）
- 0.05% 归协议（如果 feeTo 已设置）

### init_code_hash

这是 `UniswapV2Pair` 合约创建字节码的 keccak256 哈希。在 `UniswapV2Library.pairFor()` 中使用，用于计算交易对地址。

**重要**：如果你修改了合约或使用不同的编译器版本，需要重新计算这个值！

本项目使用动态计算：

```solidity
keccak256(type(UniswapV2Pair).creationCode)
```

## 🧪 测试覆盖

| 合约 | 测试内容 |
|------|---------|
| Factory | 创建交易对、权限控制、重复检测 |
| Pair | mint、burn、swap、sync、skim、TWAP |
| Router | 添加/移除流动性、各种交换、多跳路由、滑点保护 |

## 📚 学习资源

- [Uniswap V2 白皮书](https://uniswap.org/whitepaper.pdf)
- [Uniswap V2 官方文档](https://docs.uniswap.org/protocol/V2/introduction)
- [本项目详细分析文档](./docs/UNISWAP_V2_ANALYSIS.md)

## ⚠️ 注意事项

1. 本项目仅供学习和研究使用
2. 在生产环境中使用前请进行充分的安全审计
3. init_code_hash 在不同编译器版本下可能不同

## 📄 License

MIT
