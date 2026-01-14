# VoteVault DAO Bank - DAO 治理系统

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)
![Foundry](https://img.shields.io/badge/Foundry-latest-yellow)
![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-v5.4.0-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

一个完整的去中心化自治组织（DAO）治理系统，使用投票代币来民主管理 Bank 合约中的资金。

## 📚 项目概述

这个项目实现了一个基于 OpenZeppelin Governor 框架的完整 DAO 系统，包括：

- **VotingToken** (投票代币): 支持投票功能的 ERC20 代币
- **Bank** (银行合约): 存储和管理资金，只允许管理员提取
- **MyGovernor** (治理合约): DAO 治理核心，通过投票执行提案

### 核心工作流程

```
用户持有代币 → 委托投票权 → 创建提案 → 社区投票 → 执行提案 → 从 Bank 提取资金
```

## 🏗️ 架构设计

```
┌─────────────────┐
│  VotingToken    │  支持投票功能的 ERC20 代币
│  (ERC20Votes)   │  - 每个代币 = 1 票
└────────┬────────┘  - 需要委托才能激活投票权
         │
         │ 投票权来源
         ↓
┌─────────────────┐
│   MyGovernor    │  DAO 治理合约
│   (Governor)    │  - 管理提案生命周期
└────────┬────────┘  - 执行通过的提案
         │
         │ 作为管理员
         ↓
┌─────────────────┐
│      Bank       │  资金管理合约
│                 │  - 存储 ETH
└─────────────────┘  - 只有 Governor 可提取
```

## 📋 智能合约详解

### 1. VotingToken.sol

基于 OpenZeppelin 的 `ERC20Votes` 扩展实现。

**核心功能：**
- ✅ 标准 ERC20 代币功能
- ✅ ERC20Permit: 支持链下签名授权（gasless approval）
- ✅ ERC20Votes: 投票权重跟踪系统

**重要概念：**
```solidity
// 用户必须先委托（delegate）才能激活投票权
token.delegate(自己的地址);  // 委托给自己
token.delegate(他人地址);    // 委托给他人

// 查询投票权
uint256 votes = token.getVotes(账户地址);
```

**为什么需要委托？**
- 防止双重投票：代币可以转账，但投票权在委托时被"快照"记录
- 灵活性：可以委托给专业的投票人
- 检查点机制：记录历史投票权，防止操纵

### 2. Bank.sol

简单但安全的资金管理合约。

**核心功能：**
```solidity
// 任何人都可以存入 ETH
receive() external payable

// 只有管理员（Governor）可以提取
function withdraw(address payable to, uint256 amount) external onlyAdmin
```

**访问控制：**
- `admin` 设置为 Governor 合约地址
- 使用 `onlyAdmin` 修饰器保护敏感函数
- 实现了 DAO 对资金的民主管理

### 3. MyGovernor.sol

基于 OpenZeppelin Governor 系列合约。

**继承链：**
```
MyGovernor
├── Governor (核心治理逻辑)
├── GovernorSettings (可配置参数)
├── GovernorCountingSimple (简单计票：赞成/反对/弃权)
└── GovernorVotes (使用 ERC20Votes 投票)
```

**治理参数：**
| 参数 | 值 | 说明 |
|------|-----|------|
| `votingDelay` | 1 区块 | 提案创建后延迟 1 个区块开始投票 |
| `votingPeriod` | 50400 区块 | 投票期约 7 天（假设 12 秒/区块） |
| `proposalThreshold` | 0 | 任何人都可以创建提案 |
| `quorum` | 4% | 至少需要 4% 的代币参与投票 |

**提案生命周期：**
```
1. Pending (待定)   → 刚创建，等待 votingDelay
2. Active (活跃)    → 正在投票中
3. Succeeded (成功) → 达到法定人数且赞成票多
4. Defeated (失败)  → 未达到法定人数或反对票多
5. Executed (已执行) → 提案已执行
```

## 🧪 测试用例

项目包含 6 个完整的测试用例：

### Test 1: `testInitialSetup`
验证初始部署状态
- ✅ 代币总供应量为 1,000,000
- ✅ Governor 是 Bank 的管理员
- ✅ Bank 初始余额正确

### Test 2: `testDelegation`
测试投票权委托机制
- ✅ 委托前投票权为 0
- ✅ 委托给自己后投票权 = 代币余额
- ✅ 可以委托给他人

### Test 3: `testCannotWithdrawDirectly`
验证访问控制
- ✅ 非管理员无法直接从 Bank 提取资金

### Test 4: `testCreateProposal`
测试提案创建
- ✅ 成功创建提案
- ✅ 提案状态为 Pending

### Test 5: `testCompleteDAOWorkflow` ⭐ 最重要
完整的 DAO 工作流程测试
- ✅ 步骤 1: 委托投票权
- ✅ 步骤 2: 创建提案（提取 2 ETH）
- ✅ 步骤 3: 等待投票期开始
- ✅ 步骤 4: 投票（70% 赞成，20% 反对）
- ✅ 步骤 5: 等待投票期结束
- ✅ 步骤 6: 执行提案，资金成功转移

### Test 6: `testProposalSucceedsWithQuorum`
验证法定人数机制
- ✅ 10% 投票权参与（超过 4% 法定人数）
- ✅ 提案成功通过

## 🚀 快速开始

### 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装

```bash
# 克隆项目
git clone <your-repo-url>
cd VoteVault-DAO-Bank

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
forge test -vvvv

# 运行特定测试
forge test --match-test testCompleteDAOWorkflow -vvvv

# 查看测试覆盖率
forge coverage
```

### 测试输出示例

```
=== Deploying Contracts ===
VotingToken deployed at: 0x5615...
MyGovernor deployed at: 0x2e23...
Bank deployed at: 0x5991...

=== Complete DAO Workflow Test ===
--- Step 1: Delegate Voting Power ---
Owner voting power: 400000 votes
Voter1 voting power: 300000 votes

--- Step 4: Voting ---
Voting Results:
- For: 700000 votes (70%)
- Against: 200000 votes (20%)

--- Step 6: Execute Proposal ---
Bank balance before: 10 ETH
Recipient balance after: 2 ETH
=== DAO Workflow Test Successful! ===
```

## 📖 完整使用教程

### 场景：DAO 决定从 Bank 提取 5 ETH 用于开发

#### 1. 部署合约

```solidity
// 部署投票代币
VotingToken token = new VotingToken();

// 部署治理合约
MyGovernor governor = new MyGovernor(token);

// 部署 Bank，设置 Governor 为管理员
Bank bank = new Bank(address(governor));
```

#### 2. 分发代币

```solidity
// 给社区成员分发代币
token.transfer(member1, 100_000 * 1e18);
token.transfer(member2, 200_000 * 1e18);
// ...
```

#### 3. 成员委托投票权

```solidity
// 每个成员需要委托才能投票
// 方式1: 委托给自己
token.delegate(address(this));

// 方式2: 委托给专业投票人
token.delegate(expertVoter);
```

#### 4. 创建提案

```solidity
// 准备提案参数
address[] memory targets = new address[](1);
targets[0] = address(bank);

uint256[] memory values = new uint256[](1);
values[0] = 0;

bytes[] memory calldatas = new bytes[](1);
calldatas[0] = abi.encodeWithSignature(
    "withdraw(address,uint256)", 
    developerWallet, 
    5 ether
);

string memory description = "Proposal: Fund development with 5 ETH";

// 创建提案
uint256 proposalId = governor.propose(
    targets, 
    values, 
    calldatas, 
    description
);
```

#### 5. 投票

```solidity
// 等待投票期开始（1 个区块后）
// 然后成员可以投票

// 投赞成票
governor.castVote(proposalId, 1);  // 1 = For

// 投反对票
governor.castVote(proposalId, 0);  // 0 = Against

// 弃权
governor.castVote(proposalId, 2);  // 2 = Abstain
```

#### 6. 执行提案

```solidity
// 等待投票期结束（50400 个区块后）
// 如果提案通过，任何人都可以执行

bytes32 descriptionHash = keccak256(bytes(description));
governor.execute(targets, values, calldatas, descriptionHash);

// 资金自动从 Bank 转移到 developerWallet
```

## 🔑 核心概念解释

### 为什么需要投票延迟（Voting Delay）？

- 给社区时间审查提案
- 防止闪电攻击（flash loan 攻击）
- 让代币持有者有时间委托投票权

### 为什么需要法定人数（Quorum）？

- 确保提案有足够的社区参与
- 防止少数人控制 DAO
- 提高决策的合法性

### 检查点机制（Checkpoint）如何工作？

```
区块 100: Alice 有 1000 代币
区块 105: Alice 委托给自己，创建检查点
区块 110: 提案创建（快照区块 = 110）
区块 115: Alice 转账 500 代币给 Bob
区块 120: 投票时，使用区块 110 的快照
         → Alice 仍有 1000 票（防止双重投票）
```

## 🎓 学习要点总结

### 1. DAO 治理原理
- 代币加权投票：1 代币 = 1 票
- 提案生命周期管理
- 法定人数和通过门槛

### 2. OpenZeppelin Governor 框架
- 模块化设计：通过继承组合功能
- GovernorSettings: 灵活的参数配置
- GovernorVotes: 与 ERC20Votes 集成

### 3. ERC20Votes 扩展
- 委托机制的必要性
- 检查点系统防止双重投票
- Gas 优化：批量查询历史投票权

### 4. 访问控制
- Bank 合约的 `onlyAdmin` 修饰器
- Governor 作为 Bank 管理员
- 链上治理实现民主管理

### 5. 测试最佳实践
- 使用 Foundry 的 `vm.prank` 模拟不同用户
- `vm.roll` 推进区块测试时间相关逻辑
- 完整的端到端测试覆盖

## 🛠️ 部署到测试网（可选）

### 1. 配置环境变量

创建 `.env` 文件：
```bash
PRIVATE_KEY=你的私钥
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=你的_Etherscan_API_Key
```

### 2. 部署脚本

创建 `script/Deploy.s.sol`:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/VotingToken.sol";
import "../src/Bank.sol";
import "../src/MyGovernor.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 VotingToken
        VotingToken token = new VotingToken();
        console.log("VotingToken deployed:", address(token));

        // 2. 部署 Governor
        MyGovernor governor = new MyGovernor(token);
        console.log("MyGovernor deployed:", address(governor));

        // 3. 部署 Bank
        Bank bank = new Bank(address(governor));
        console.log("Bank deployed:", address(bank));

        vm.stopBroadcast();
    }
}
```

### 3. 部署命令

```bash
# 加载环境变量
source .env

# 部署到 Sepolia 测试网
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify

# 验证合约
forge verify-contract <合约地址> <合约名> \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

## 📝 常见问题 (FAQ)

### Q1: 为什么我的投票权是 0？
**A:** 你需要先调用 `token.delegate(你的地址)` 来激活投票权。

### Q2: 提案状态一直是 Pending？
**A:** 需要等待 `votingDelay` 区块后才会变成 Active。

### Q3: 为什么提案执行失败？
**A:** 检查：
- 是否达到法定人数（4%）
- 是否赞成票 > 反对票
- 是否已经等待 `votingPeriod` 结束

### Q4: 如何修改治理参数？
**A:** 修改 `MyGovernor.sol` 构造函数中的参数：
```solidity
GovernorSettings(
    1,      // votingDelay
    50400,  // votingPeriod
    0       // proposalThreshold
)
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License

## 🔗 相关资源

- [OpenZeppelin Governor 文档](https://docs.openzeppelin.com/contracts/4.x/governance)
- [ERC20Votes 解释](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Votes)
- [Foundry 教程](https://book.getfoundry.sh/)
- [DAO 最佳实践](https://github.com/scaffold-eth/scaffold-eth-2)

---

**作者**: Your Name  
**日期**: 2026-01-14  
**版本**: 1.0.0

如果这个项目对你有帮助，请给个 ⭐ Star！
