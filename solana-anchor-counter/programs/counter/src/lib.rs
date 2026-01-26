use anchor_lang::prelude::*;

// 这是你的程序ID，部署时会自动生成
// 暂时使用占位符，实际使用时会被替换
declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod counter {
    use super::*;

    /// Initialize 指令 - 初始化计数器账户
    /// 
    /// 这个指令会：
    /// 1. 使用 PDA (Program Derived Address) 创建一个确定性的账户
    /// 2. 将 count 初始化为 0
    /// 
    /// 参数:
    /// - ctx: 包含所有需要的账户信息
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        counter.count = 0;
        msg!("计数器已初始化，count = 0");
        Ok(())
    }

    /// Increment 指令 - 将计数器加1
    /// 
    /// 这个指令会：
    /// 1. 检查账户的有效性
    /// 2. 将 count 值加 1
    /// 3. 使用 checked_add 防止溢出
    /// 
    /// 参数:
    /// - ctx: 包含所有需要的账户信息
    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        // 使用 checked_add 防止溢出，如果溢出会返回错误
        counter.count = counter
            .count
            .checked_add(1)
            .ok_or(ErrorCode::Overflow)?;
        msg!("计数器递增，当前 count = {}", counter.count);
        Ok(())
    }
}

// ===== 账户验证结构 =====

/// Initialize 指令需要的账户
#[derive(Accounts)]
pub struct Initialize<'info> {
    /// Counter 账户 - 使用 PDA 派生
    /// 
    /// 关键参数说明：
    /// - init: 表示这是一个需要初始化的新账户
    /// - payer = user: 指定由 user 账户支付创建账户的租金
    /// - space: 分配的存储空间 = 8字节（discriminator）+ 8字节（u64）
    /// - seeds: 用于派生 PDA 的种子，这里使用 "counter" + user的公钥
    /// - bump: PDA 的 bump seed，Anchor 会自动找到有效的 bump
    #[account(
        init,
        payer = user,
        space = 8 + 8,
        seeds = [b"counter", user.key().as_ref()],
        bump
    )]
    pub counter: Account<'info, Counter>,
    
    /// 用户账户 - 需要签名并支付租金
    #[account(mut)]
    pub user: Signer<'info>,
    
    /// 系统程序 - 用于创建账户
    pub system_program: Program<'info, System>,
}

/// Increment 指令需要的账户
#[derive(Accounts)]
pub struct Increment<'info> {
    /// Counter 账户 - 必须是可变的
    /// 
    /// 关键参数说明：
    /// - mut: 表示这个账户数据会被修改
    /// - seeds: 用于验证这是正确的 PDA
    /// - bump: 验证 PDA 的有效性
    #[account(
        mut,
        seeds = [b"counter", user.key().as_ref()],
        bump
    )]
    pub counter: Account<'info, Counter>,
    
    /// 用户账户 - 需要签名
    pub user: Signer<'info>,
}

// ===== 数据结构 =====

/// Counter 账户的数据结构
/// 
/// 这个结构定义了存储在区块链上的数据格式
#[account]
pub struct Counter {
    /// 计数器的值
    /// 使用 u64 类型，范围 0 到 18,446,744,073,709,551,615
    pub count: u64,
}

// ===== 错误定义 =====

/// 自定义错误代码
#[error_code]
pub enum ErrorCode {
    #[msg("计数器溢出")]
    Overflow,
}
