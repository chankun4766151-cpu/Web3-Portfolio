# ETH 看涨期权 Token (ECALL)

## 项目说明

这是一个基于 ERC20 的 ETH 看涨期权 Token 合约，实现了期权的发行、行权和过期销毁功能。

### 核心功能

1. **发行期权（项目方）**：项目方存入 ETH，按 1:1 铸造期权 Token
2. **行权（用户）**：在行权日当天，用户支付行权价格（USDT），获取 ETH
3. **过期销毁（项目方）**：行权日之后，项目方赎回剩余 ETH 和收到的 USDT

### 合约参数

- **行权价格**：2000 USDT per ETH
- **行权日期**：部署时指定（测试中设置为 7 天后）
- **支付代币**：USDT（测试中使用 MockUSDT）

## 快速开始

### 1. 安装依赖

```bash
# 初始化 Git（如果还没有）
git init

# 安装 OpenZeppelin 合约
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# 安装 forge-std
forge install foundry-rs/forge-std --no-commit
```

### 2. 编译合约

```bash
forge build
```

### 3. 运行测试

```bash
# 运行所有测试并显示详细日志
forge test -vvvv

# 运行单个测试
forge test --match-test test_IssueAndExercise -vvvv
```

## 测试用例说明

### 测试 1：发行期权
- 项目方存入 10 ETH
- 验证铸造了 10 个期权 Token

### 测试 2：完整发行和行权流程
1. 项目方发行 10 ETH 期权
2. 用户购买 5 个期权 Token
3. 时间快进到行权日
4. 用户行权，支付 10,000 USDT 获取 5 ETH

### 测试 3：过期销毁
1. 项目方发行期权
2. 部分用户行权
3. 行权日结束后，项目方赎回剩余 ETH 和收到的 USDT

### 测试 4-6：边界条件
- 非行权日不能行权
- 非项目方不能发行/销毁
- 过期后不能行权

### 测试 7：多用户行权
- 多个用户在行权日分别行权

## 合约架构

### EthCallOption.sol - 核心期权合约

**状态变量：**
- `owner`: 项目方地址
- `strikePrice`: 行权价格（USDT/ETH）
- `expiryDate`: 行权日期
- `paymentToken`: 支付代币（USDT）
- `isExpired`: 是否已过期

**核心函数：**
- `issue()`: 发行期权（项目方）
- `exercise(amount)`: 行权（用户）
- `expireAndRedeem()`: 过期销毁（项目方）

### MockUSDT.sol - 模拟 USDT

用于测试的简单 ERC20 Token。

## 提交作业

### 1. 生成测试日志

```bash
# 运行测试并保存输出
forge test -vvvv > test_logs.txt
```

### 2. 截图测试输出

截取包含以下内容的日志：
- 发行事件和状态变化
- 行权事件和状态变化
- 过期销毁事件和状态变化

### 3. 推送到 GitHub

```bash
git add .
git commit -m "完成 ETH 看涨期权 Token 合约"
git remote add origin <你的仓库地址>
git push -u origin main
```

## 代码说明

### 发行期权流程

```solidity
// 项目方调用 issue() 并发送 ETH
function issue() external payable onlyOwner {
    // 铸造等量的期权 Token
    _mint(msg.sender, msg.value);
}
```

### 行权流程

```solidity
// 用户在行权日调用 exercise()
function exercise(uint256 amount) external onlyOnExpiryDate {
    // 1. 计算需要支付的 USDT
    uint256 usdtAmount = (amount * strikePrice) / 1e18;
    
    // 2. 转入 USDT
    paymentToken.transferFrom(msg.sender, address(this), usdtAmount);
    
    // 3. 销毁期权 Token
    _burn(msg.sender, amount);
    
    // 4. 转移 ETH
    msg.sender.call{value: amount}("");
}
```

### 过期销毁流程

```solidity
// 项目方在行权日之后调用
function expireAndRedeem() external onlyOwner {
    isExpired = true;
    
    // 返还所有 ETH 和 USDT
    owner.call{value: address(this).balance}("");
    paymentToken.transfer(owner, paymentToken.balanceOf(address(this)));
}
```

## 许可证

MIT
