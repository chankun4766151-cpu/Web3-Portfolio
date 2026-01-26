# Solana Anchor Counter 计数器程序

一个使用 Anchor 框架编写的简单 Solana 计数器程序，用于学习 Solana 智能合约开发。

## 📋 作业要求

使用 Anchor 编写一个简单的计数器程序，包含两个指令：

1. **initialize(ctx)**: 用 seed 派生出账户，初始化 count = 0
2. **increment(ctx)**: 将账户中的 count 加 1

## 🏗️ 项目结构

```
solana-anchor-counter/
├── programs/
│   └── counter/
│       ├── src/
│       │   └── lib.rs          # 主程序代码
│       └── Cargo.toml
├── tests/
│   └── counter.ts              # 测试文件
├── Anchor.toml                 # Anchor 配置
├── Cargo.toml                  # Rust 工作空间配置
└── package.json                # NPM 依赖
```

## 🔑 核心概念

### PDA (Program Derived Address)

PDA 是由程序派生的确定性地址，无需私钥即可由程序控制：

```rust
seeds = [b"counter", user.key().as_ref()],
bump
```

- **seeds**: 用于派生地址的种子，这里使用 "counter" + 用户公钥
- **bump**: 确保地址不在椭圆曲线上，使其成为有效的 PDA

### Initialize 指令

```rust
pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
    let counter = &mut ctx.accounts.counter;
    counter.count = 0;
    Ok(())
}
```

**功能**：
- 创建一个新的 Counter 账户
- 使用 PDA 确保每个用户有唯一的计数器
- 初始化 count = 0

### Increment 指令

```rust
pub fn increment(ctx: Context<Increment>) -> Result<()> {
    let counter = &mut ctx.accounts.counter;
    counter.count = counter.count.checked_add(1)
        .ok_or(ErrorCode::Overflow)?;
    Ok(())
}
```

**功能**：
- 将 count 值加 1
- 使用 `checked_add` 防止溢出
- 验证账户所有权

## 🔧 环境要求

在运行此项目前，需要安装：

1. **Rust**: Solana 程序使用 Rust 编写
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Solana CLI**: 用于部署和管理程序
   ```bash
   sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
   ```

3. **Anchor CLI**: Solana 开发框架
   ```bash
   cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
   avm install latest
   avm use latest
   ```

4. **Node.js**: 运行测试（推荐 v16+）

## 🚀 使用方法

### 1. 安装依赖

```bash
npm install
```

### 2. 构建程序

```bash
anchor build
```

### 3. 运行测试

```bash
anchor test
```

测试会自动：
- 启动本地 Solana 验证器
- 部署程序
- 运行所有测试用例
- 清理环境

### 4. 测试输出示例

```
counter
  ✓ 初始化计数器 (432ms)
  ✓ 递增计数器 (423ms)
  ✓ 多次递增计数器 (2145ms)
  ✓ 验证 PDA 派生的确定性 (1ms)

4 passing (3s)
```

## 📝 详细说明

### 账户结构

```rust
#[account]
pub struct Counter {
    pub count: u64,  // 8 字节
}
```

- 存储空间：8（discriminator）+ 8（count）= 16 字节
- discriminator: Anchor 自动添加的账户类型标识

### 账户验证

**Initialize**:
```rust
#[account(
    init,                                    // 初始化新账户
    payer = user,                            // 支付者
    space = 8 + 8,                           // 分配空间
    seeds = [b"counter", user.key().as_ref()],  // PDA seeds
    bump                                     // PDA bump
)]
```

**Increment**:
```rust
#[account(
    mut,                                     // 可变账户
    seeds = [b"counter", user.key().as_ref()],  // 验证 PDA
    bump                                     // 验证 bump
)]
```

## 🎯 学习要点

1. **PDA 派生**: 理解如何使用 seeds 创建确定性地址
2. **账户验证**: Anchor 如何自动验证账户
3. **安全性**: 使用 `checked_add` 防止溢出
4. **测试驱动**: 完整的测试覆盖所有功能

## 📚 参考资料

- [Anchor 官方文档](https://www.anchor-lang.com/)
- [Solana 开发文档](https://docs.solana.com/)
- [Solana Cookbook](https://solanacookbook.com/)

## 📄 许可证

MIT

## 👨‍💻 作者

ETH Chiangmai 课程作业
