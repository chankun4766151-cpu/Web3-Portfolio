import { useMemo, useState } from "react";
import {
  createPublicClient,
  createWalletClient,
  custom,
  formatUnits,
  http,
  parseUnits,
  type Address,
} from "viem";
import { foundry } from "viem/chains";
import { erc20Abi, tokenBankAbi } from "./abi";

// ✅ 改成你刚刚部署出来的地址
const TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3" as Address;
const BANK_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512" as Address;

// anvil 默认链：http://127.0.0.1:8545
const publicClient = createPublicClient({
  chain: foundry,
  transport: http("http://127.0.0.1:8545"),
});

export default function App() {
  const [account, setAccount] = useState<Address | null>(null);
  const [tokenBal, setTokenBal] = useState<bigint>(0n);
  const [bankBal, setBankBal] = useState<bigint>(0n);
  const [amount, setAmount] = useState<string>("");

  const walletClient = useMemo(() => {
    const eth = (window as any).ethereum;
    if (!eth) return null;
    return createWalletClient({
      chain: foundry,
      transport: custom(eth),
    });
  }, []);

  async function connect() {
    if (!walletClient) {
      alert("请先安装/打开 MetaMask");
      return;
    }
    const [addr] = await walletClient.requestAddresses();
    setAccount(addr);
  }

  async function refresh() {
    if (!account) return;

    const [t, b] = await Promise.all([
      publicClient.readContract({
        address: TOKEN_ADDRESS,
        abi: erc20Abi,
        functionName: "balanceOf",
        args: [account],
      }),
      publicClient.readContract({
        address: BANK_ADDRESS,
        abi: tokenBankAbi,
        functionName: "balances",
        args: [account],
      }),
    ]);

    setTokenBal(t);
    setBankBal(b);
  }

  async function deposit() {
    if (!walletClient || !account) return alert("请先连接钱包");
    if (!amount) return alert("请输入存款数量");

    // 这里假设 Token 是 18 decimals（MyToken 是 18）
    const value = parseUnits(amount, 18);

    // 1) approve
    const approveHash = await walletClient.writeContract({
      address: TOKEN_ADDRESS,
      abi: erc20Abi,
      functionName: "approve",
      args: [BANK_ADDRESS, value],
      account,
    });
    await publicClient.waitForTransactionReceipt({ hash: approveHash });

    // 2) deposit
    const depositHash = await walletClient.writeContract({
      address: BANK_ADDRESS,
      abi: tokenBankAbi,
      functionName: "deposit",
      args: [value],
      account,
    });
    await publicClient.waitForTransactionReceipt({ hash: depositHash });

    await refresh();
    alert("存款成功");
  }

  async function withdraw() {
    if (!walletClient || !account) return alert("请先连接钱包");
    if (!amount) return alert("请输入取款数量");

    const value = parseUnits(amount, 18);

    const withdrawHash = await walletClient.writeContract({
      address: BANK_ADDRESS,
      abi: tokenBankAbi,
      functionName: "withdraw",
      args: [value],
      account,
    });
    await publicClient.waitForTransactionReceipt({ hash: withdrawHash });

    await refresh();
    alert("取款成功");
  }

  return (
    <div style={{ maxWidth: 720, margin: "40px auto", fontFamily: "system-ui" }}>
      <h2>TokenBank (Viem)</h2>

      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <button onClick={connect}>连接钱包</button>
        <button onClick={refresh} disabled={!account}>
          刷新余额
        </button>
        <div style={{ opacity: 0.8 }}>
          {account ? `当前地址：${account}` : "未连接"}
        </div>
      </div>

      <hr style={{ margin: "20px 0" }} />

      <div style={{ lineHeight: 1.8 }}>
        <div>Token 地址：{TOKEN_ADDRESS}</div>
        <div>Bank 地址：{BANK_ADDRESS}</div>
        <div>Token 余额：{formatUnits(tokenBal, 18)} MTK</div>
        <div>Bank 存款：{formatUnits(bankBal, 18)} MTK</div>
      </div>

      <hr style={{ margin: "20px 0" }} />

      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <input
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="输入数量，例如 1.5"
        />
        <button onClick={deposit} disabled={!account}>
          存款
        </button>
        <button onClick={withdraw} disabled={!account}>
          取款
        </button>
      </div>

      <p style={{ marginTop: 16, opacity: 0.75 }}>
        提示：如果你用的是 Anvil，本地链 ID=31337。MetaMask 里需要添加 Foundry/Anvil 网络，
        RPC 填 http://127.0.0.1:8545
      </p>
    </div>
  );
}
