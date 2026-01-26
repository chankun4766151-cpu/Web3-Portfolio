import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Counter } from "../target/types/counter";
import { expect } from "chai";

/**
 * 测试文件说明：
 * 这个文件包含了计数器程序的完整测试用例
 * 测试内容包括：
 * 1. 初始化计数器
 * 2. 递增计数器
 * 3. 多次递增验证
 */

describe("counter", () => {
  // 配置 Anchor 客户端
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Counter as Program<Counter>;
  
  // 获取用户钱包（默认是本地测试钱包）
  const user = provider.wallet;
  
  // 用于存储 PDA 地址
  let counterPda: anchor.web3.PublicKey;
  let bump: number;

  /**
   * 在所有测试之前：派生 PDA 地址
   * 
   * PDA (Program Derived Address) 派生过程：
   * 1. 使用 seeds: ["counter", user.publicKey]
   * 2. 使用程序 ID
   * 3. findProgramAddressSync 会找到有效的地址和 bump
   */
  before(async () => {
    [counterPda, bump] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("counter"),
        user.publicKey.toBuffer(),
      ],
      program.programId
    );
    
    console.log("PDA 地址:", counterPda.toBase58());
    console.log("Bump:", bump);
  });

  /**
   * 测试 1: 初始化计数器
   * 
   * 验证：
   * - 账户创建成功
   * - count 初始值为 0
   */
  it("初始化计数器", async () => {
    console.log("\n=== 测试: 初始化计数器 ===");
    
    // 调用 initialize 指令
    const tx = await program.methods
      .initialize()
      .accounts({
        counter: counterPda,
        user: user.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    console.log("初始化交易签名:", tx);

    // 获取账户数据
    const counterAccount = await program.account.counter.fetch(counterPda);
    
    console.log("当前 count 值:", counterAccount.count.toString());
    
    // 验证 count 为 0
    expect(counterAccount.count.toNumber()).to.equal(0);
  });

  /**
   * 测试 2: 递增计数器
   * 
   * 验证：
   * - increment 指令执行成功
   * - count 值从 0 变为 1
   */
  it("递增计数器", async () => {
    console.log("\n=== 测试: 递增计数器 ===");
    
    // 调用 increment 指令
    const tx = await program.methods
      .increment()
      .accounts({
        counter: counterPda,
        user: user.publicKey,
      })
      .rpc();

    console.log("递增交易签名:", tx);

    // 获取更新后的账户数据
    const counterAccount = await program.account.counter.fetch(counterPda);
    
    console.log("当前 count 值:", counterAccount.count.toString());
    
    // 验证 count 为 1
    expect(counterAccount.count.toNumber()).to.equal(1);
  });

  /**
   * 测试 3: 多次递增
   * 
   * 验证：
   * - 可以连续调用 increment
   * - count 值正确累加
   */
  it("多次递增计数器", async () => {
    console.log("\n=== 测试: 多次递增计数器 ===");
    
    // 递增 5 次
    for (let i = 0; i < 5; i++) {
      const tx = await program.methods
        .increment()
        .accounts({
          counter: counterPda,
          user: user.publicKey,
        })
        .rpc();
      
      console.log(`递增 #${i + 1} 交易签名:`, tx);
    }

    // 验证最终的 count 值
    const counterAccount = await program.account.counter.fetch(counterPda);
    
    console.log("最终 count 值:", counterAccount.count.toString());
    
    // 应该是 1（第一次测试） + 5 = 6
    expect(counterAccount.count.toNumber()).to.equal(6);
  });

  /**
   * 测试 4: 验证 PDA 派生的确定性
   * 
   * 验证：
   * - 使用相同的 seeds 总是得到相同的地址
   */
  it("验证 PDA 派生的确定性", async () => {
    console.log("\n=== 测试: PDA 派生确定性 ===");
    
    // 再次派生 PDA
    const [derivedPda, derivedBump] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("counter"),
        user.publicKey.toBuffer(),
      ],
      program.programId
    );
    
    console.log("原始 PDA:", counterPda.toBase58());
    console.log("重新派生的 PDA:", derivedPda.toBase58());
    
    // 验证地址相同
    expect(derivedPda.toBase58()).to.equal(counterPda.toBase58());
    expect(derivedBump).to.equal(bump);
  });
});
