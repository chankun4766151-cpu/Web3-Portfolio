# Rebase Shrink Token 通缩代币

一个通缩型 Rebase ERC20 代币，用于理解 rebase 型代币的实现原理。

## 核心特性

- **初始发行量**：1 亿代币 (100,000,000)
- **通缩机制**：每年（每次 rebase）减少 1%
- **Rebase 原理**：通过份额(shares)机制而非直接存储余额

## Rebase 原理

传统 ERC20 直接存储用户余额，而 Rebase Token 存储**份额(shares)**：

```
用户余额 = 用户份额 × (当前总供应量 / 总份额)
```

当调用 `rebase()` 时，总供应量减少 1%，所有用户余额自动等比例减少，无需单独更新每个账户。

## 合约结构

```solidity
// 状态变量
mapping(address => uint256) private _shares;  // 用户份额
uint256 private _totalShares;                  // 总份额
uint256 private _totalSupply;                  // 当前总供应量

// 余额计算
function balanceOf(address account) public view returns (uint256) {
    return _shares[account] * _totalSupply / _totalShares;
}

// 通缩 rebase
function rebase() external onlyOwner {
    _totalSupply = _totalSupply * 99 / 100;  // 减少 1%
}
```

## 快速开始

```bash
# 安装依赖
forge install

# 编译
forge build

# 运行测试
forge test -vvv
```

## 测试用例

| 测试 | 描述 |
|------|------|
| `testInitialState` | 验证初始供应量和余额 |
| `testSingleRebase` | 验证单次 rebase 减少 1% |
| `testMultipleRebases` | 验证多年复利通缩 |
| `testTransferAfterRebase` | 验证 rebase 后转账正确 |
| `testTenYearsDeflation` | 验证 10 年后保留约 90.44% |

## 测试输出示例

```
=== Test: 10 Years Deflation Compound Effect ===
Initial supply: 100000000 tokens
After 10 years supply: 90438207 tokens
Retained percentage (in basis points): 9043
That means approximately 90 % retained
```

## License

MIT
