'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, usePublicClient, useWalletClient } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseEther, formatEther, parseUnits, encodeFunctionData, createWalletClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { signAuthorization } from 'viem/experimental';
import { sepolia } from 'viem/chains';
import { CONTRACTS, EXPLORER_URL } from '@/constants/addresses';
import MyTokenAbi from '@/constants/MyToken.abi.json';
import TokenBankPermit2Abi from '@/constants/TokenBankPermit2.abi.json';
import { Permit2Abi } from '@/constants/Permit2.abi';
import { DelegatorAbi } from '@/constants/Delegator.abi';

// ... (existing code comments)

export default function Home() {
    const { address, isConnected } = useAccount();
    const publicClient = usePublicClient();
    const { data: walletClient } = useWalletClient();

    // 状态管理
    const [depositAmount, setDepositAmount] = useState('');
    const [withdrawAmount, setWithdrawAmount] = useState('');
    const [isPermit2Approved, setIsPermit2Approved] = useState(false);
    const [isEip7702Loading, setIsEip7702Loading] = useState(false); // EIP-7702 Loading State
    const [privateKey, setPrivateKey] = useState(''); // 私钥输入
    const [showPrivateKeyInput, setShowPrivateKeyInput] = useState(false); // 显示私钥输入框

    // ... (existing read contracts)
    const { data: tokenBalance, refetch: refetchTokenBalance } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
    });

    const { data: bankBalance, refetch: refetchBankBalance } = useReadContract({
        address: CONTRACTS.TokenBankPermit2 as `0x${string}`,
        abi: TokenBankPermit2Abi,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
    });

    const { data: tokenSymbol } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'symbol',
    });

    const { data: permit2Allowance, refetch: refetchPermit2Allowance } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'allowance',
        args: address ? [address, CONTRACTS.Permit2 as `0x${string}`] : undefined,
    });

    const { data: bankAllowance, refetch: refetchBankAllowance } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'allowance',
        args: address ? [address, CONTRACTS.TokenBankPermit2 as `0x${string}`] : undefined,
    });

    // ... (existing effects)
    useEffect(() => {
        if (permit2Allowance) {
            const maxApproval = parseUnits('1000000000', 18);
            setIsPermit2Approved((permit2Allowance as bigint) >= maxApproval);
        }
    }, [permit2Allowance]);

    // ... (existing write hooks)
    const { writeContract: approvePermit2, data: approvePermit2Hash } = useWriteContract();
    const { isLoading: isApprovingPermit2, isSuccess: permit2ApproveSuccess } = useWaitForTransactionReceipt({
        hash: approvePermit2Hash,
    });

    const { writeContract: approveBank, data: approveBankHash } = useWriteContract();
    const { isLoading: isApprovingBank, isSuccess: bankApproveSuccess } = useWaitForTransactionReceipt({
        hash: approveBankHash,
    });

    const { writeContract: depositTraditional, data: depositHash } = useWriteContract();
    const { isLoading: isDepositing, isSuccess: depositSuccess } = useWaitForTransactionReceipt({
        hash: depositHash,
    });

    const { writeContract: depositPermit2, data: permit2DepositHash } = useWriteContract();
    const { isLoading: isDepositingPermit2, isSuccess: permit2DepositSuccess } = useWaitForTransactionReceipt({
        hash: permit2DepositHash,
    });

    const { writeContract: withdraw, data: withdrawHash } = useWriteContract();
    const { isLoading: isWithdrawing, isSuccess: withdrawSuccess } = useWaitForTransactionReceipt({
        hash: withdrawHash,
    });

    // 交易成功后刷新余额
    useEffect(() => {
        if (permit2ApproveSuccess || bankApproveSuccess || depositSuccess || permit2DepositSuccess || withdrawSuccess) {
            refetchTokenBalance();
            refetchBankBalance();
            refetchPermit2Allowance();
            refetchBankAllowance();
        }
    }, [permit2ApproveSuccess, bankApproveSuccess, depositSuccess, permit2DepositSuccess, withdrawSuccess]);


    // ... (existing handlers)
    const handleApprovePermit2 = async () => {
        try {
            const maxApproval = parseUnits('1000000000', 18);
            approvePermit2({
                address: CONTRACTS.MyToken as `0x${string}`,
                abi: MyTokenAbi,
                functionName: 'approve',
                args: [CONTRACTS.Permit2, maxApproval],
            });
        } catch (error) {
            console.error('授权 Permit2 失败:', error);
            alert('授权失败: ' + (error as Error).message);
        }
    };

    const handleApproveBank = async () => {
        try {
            if (!depositAmount || parseFloat(depositAmount) <= 0) {
                alert('请输入有效的存款金额');
                return;
            }
            const amount = parseEther(depositAmount);
            approveBank({
                address: CONTRACTS.MyToken as `0x${string}`,
                abi: MyTokenAbi,
                functionName: 'approve',
                args: [CONTRACTS.TokenBankPermit2, amount],
            });
        } catch (error) {
            console.error('授权 TokenBank 失败:', error);
            alert('授权失败: ' + (error as Error).message);
        }
    };

    const handleDepositTraditional = async () => {
        try {
            if (!depositAmount || parseFloat(depositAmount) <= 0) {
                alert('请输入有效的存款金额');
                return;
            }
            if ((bankAllowance as bigint) < parseEther(depositAmount)) {
                alert('请先授权足够的代币额度给 TokenBank');
                return;
            }
            const amount = parseEther(depositAmount);
            depositTraditional({
                address: CONTRACTS.TokenBankPermit2 as `0x${string}`,
                abi: TokenBankPermit2Abi,
                functionName: 'deposit',
                args: [amount],
            });
        } catch (error) {
            console.error('存款失败:', error);
            alert('存款失败: ' + (error as Error).message);
        }
    };

    const handleDepositWithPermit2 = async () => {
        try {
            if (!address || !walletClient || !publicClient) {
                alert('请先连接钱包');
                return;
            }

            if (!depositAmount || parseFloat(depositAmount) <= 0) {
                alert('请输入有效的存款金额');
                return;
            }

            if (!isPermit2Approved) {
                alert('请先授权 Permit2 合约');
                return;
            }

            const amount = parseEther(depositAmount);
            const nonce = await getNonce(address);
            const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600);

            const permitData = {
                permitted: {
                    token: CONTRACTS.MyToken as `0x${string}`,
                    amount: amount,
                },
                spender: CONTRACTS.TokenBankPermit2 as `0x${string}`,
                nonce: nonce,
                deadline: deadline,
            };

            const domain = {
                name: 'Permit2',
                chainId: await walletClient.getChainId(),
                verifyingContract: CONTRACTS.Permit2 as `0x${string}`,
            };

            const types = {
                PermitTransferFrom: [
                    { name: 'permitted', type: 'TokenPermissions' },
                    { name: 'spender', type: 'address' },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'deadline', type: 'uint256' },
                ],
                TokenPermissions: [
                    { name: 'token', type: 'address' },
                    { name: 'amount', type: 'uint256' },
                ],
            };

            const signature = await walletClient.signTypedData({
                account: address,
                domain,
                types,
                primaryType: 'PermitTransferFrom',
                message: permitData,
            });

            depositPermit2({
                address: CONTRACTS.TokenBankPermit2 as `0x${string}`,
                abi: TokenBankPermit2Abi,
                functionName: 'depositWithPermit2',
                args: [
                    {
                        permitted: {
                            token: CONTRACTS.MyToken as `0x${string}`,
                            amount: amount,
                        },
                        nonce: nonce,
                        deadline: deadline,
                    },
                    address,
                    signature,
                ],
            });
        } catch (error) {
            console.error('Permit2 存款失败:', error);
            alert('Permit2 存款失败: ' + (error as Error).message);
        }
    };

    // EIP-7702 授权并存款 ⭐ 新功能 ⭐
    const handleDepositWithEIP7702 = async () => {
        try {
            if (!publicClient) {
                alert('请先连接钱包');
                return;
            }

            if (!depositAmount || parseFloat(depositAmount) <= 0) {
                alert('请输入有效的存款金额');
                return;
            }

            // 检查是否提供了私钥
            if (!privateKey || !privateKey.startsWith('0x') || privateKey.length !== 66) {
                alert('请输入有效的私钥（0x 开头，64位十六进制）');
                setShowPrivateKeyInput(true);
                return;
            }

            setIsEip7702Loading(true);
            const amount = parseEther(depositAmount);

            // 1. 使用私钥创建账户
            const account = privateKeyToAccount(privateKey as `0x${string}`);
            const pkAddress = account.address;

            console.log('使用私钥账户:', pkAddress);

            // 2. 创建专用的 wallet client
            const pkWalletClient = createWalletClient({
                account,
                chain: sepolia,
                transport: http(),
            });

            // 3. 构造 Execution 调用数据
            // Call 1: approve(TokenBank, amount)
            const approveData = encodeFunctionData({
                abi: MyTokenAbi,
                functionName: 'approve',
                args: [CONTRACTS.TokenBankPermit2, amount],
            });

            // Call 2: deposit(amount)
            const depositData = encodeFunctionData({
                abi: TokenBankPermit2Abi,
                functionName: 'deposit',
                args: [amount],
            });

            const executions = [
                {
                    target: CONTRACTS.MyToken as `0x${string}`,
                    value: 0n,
                    callData: approveData,
                },
                {
                    target: CONTRACTS.TokenBankPermit2 as `0x${string}`,
                    value: 0n,
                    callData: depositData,
                },
            ];

            // 4. 签署 Authorization (EIP-7702)
            // 将当前 EOA 委托给 Delegator 合约
            console.log('正在签署 EIP-7702 Authorization...');
            const authorization = await signAuthorization(pkWalletClient, {
                contractAddress: CONTRACTS.Delegator as `0x${string}`,
            });

            console.log('Authorization 签署成功!', authorization);

            // 5. 构造 Delegator.execute 调用
            const executeData = encodeFunctionData({
                abi: DelegatorAbi,
                functionName: 'execute',
                args: [executions],
            });

            // 6. 发送交易 (Self-call with Authorization)
            console.log('正在发送 EIP-7702 交易...');
            const hash = await pkWalletClient.sendTransaction({
                to: pkAddress, // 发送给自己
                data: executeData,
                authorizationList: [authorization],
            });

            console.log('EIP-7702 交易哈希:', hash);
            alert(`✅ 交易已发送!\n\n交易哈希: ${hash}\n\n请去区块浏览器查看详情：\n${EXPLORER_URL}${hash}`);

            setIsEip7702Loading(false);

            // 触发一次刷新
            setTimeout(() => {
                refetchTokenBalance();
                refetchBankBalance();
            }, 5000);

        } catch (error) {
            console.error('EIP-7702 操作失败:', error);
            alert('❌ EIP-7702 操作失败:\n\n' + (error as Error).message);
            setIsEip7702Loading(false);
        }
    };

    const handleWithdraw = async () => {
        try {
            if (!withdrawAmount || parseFloat(withdrawAmount) <= 0) {
                alert('请输入有效的取款金额');
                return;
            }
            const amount = parseEther(withdrawAmount);
            withdraw({
                address: CONTRACTS.TokenBankPermit2 as `0x${string}`,
                abi: TokenBankPermit2Abi,
                functionName: 'withdraw',
                args: [amount],
            });
        } catch (error) {
            console.error('取款失败:', error);
            alert('取款失败: ' + (error as Error).message);
        }
    };

    const getNonce = async (userAddress: `0x${string}`) => {
        if (!publicClient) throw new Error('Public client not available');
        return BigInt(Math.floor(Math.random() * 1000000000));
    };

    if (!isConnected) {
        return (
            <main className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-br from-purple-50 to-pink-100">
                <div className="text-center">
                    <h1 className="text-4xl font-bold mb-4 text-gray-800">TokenBank (EIP-7702)</h1>
                    <p className="text-gray-600 mb-8">体验下一代账户抽象：EIP-7702</p>
                    <ConnectButton />
                </div>
            </main>
        );
    }

    return (
        <main className="min-h-screen p-8 bg-gradient-to-br from-purple-50 to-pink-100">
            <div className="max-w-4xl mx-auto">
                {/* 头部 */}
                <div className="flex justify-between items-center mb-8">
                    <h1 className="text-4xl font-bold text-gray-800">TokenBank (EIP-7702)</h1>
                    <ConnectButton />
                </div>

                <p className="text-gray-600 mb-8 text-center">
                    🚀 体验 EIP-7702：让你的 EOA 账户瞬间拥有智能合约的批量处理能力
                </p>

                {/* 余额卡片 */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                    <div className="bg-white rounded-lg shadow-md p-6 border-t-4 border-purple-500">
                        <h3 className="text-sm font-semibold text-gray-500 mb-2">💰 钱包代币余额</h3>
                        <p className="text-3xl font-bold text-gray-800">
                            {tokenBalance ? formatEther(tokenBalance as bigint) : '0'} {tokenSymbol as string || 'MTK'}
                        </p>
                    </div>

                    <div className="bg-white rounded-lg shadow-md p-6 border-t-4 border-pink-500">
                        <h3 className="text-sm font-semibold text-gray-500 mb-2">🏦 银行存款余额</h3>
                        <p className="text-3xl font-bold text-gray-800">
                            {bankBalance ? formatEther(bankBalance as bigint) : '0'} {tokenSymbol as string || 'MTK'}
                        </p>
                    </div>
                </div>

                {/* EIP-7702 核心区域 */}
                <div className="bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg shadow-lg p-6 mb-8 text-white">
                    <h2 className="text-2xl font-bold mb-2">⚡ EIP-7702 极速存款</h2>
                    <p className="opacity-90 mb-6">
                        无需预先 Approve，无需 Gas 授权交易！在一个原子交易中完成授权委托 + 批量执行。
                    </p>

                    <div className="bg-white/10 p-6 rounded-lg backdrop-blur-sm">
                        {/* 私钥输入区域 */}
                        <div className="mb-4">
                            <div className="flex items-center justify-between mb-2">
                                <label className="block text-sm font-medium opacity-90">
                                    🔑 私钥（Private Key）
                                </label>
                                <button
                                    onClick={() => setShowPrivateKeyInput(!showPrivateKeyInput)}
                                    className="text-xs text-white/70 hover:text-white underline"
                                >
                                    {showPrivateKeyInput ? '隐藏' : '显示'}
                                </button>
                            </div>
                            {showPrivateKeyInput && (
                                <div className="space-y-2">
                                    <input
                                        type="password"
                                        value={privateKey}
                                        onChange={(e) => setPrivateKey(e.target.value)}
                                        placeholder="0x..."
                                        className="w-full px-4 py-2 bg-white/20 border border-white/30 rounded-lg focus:outline-none focus:ring-2 focus:ring-white/50 placeholder-white/50 text-white text-sm font-mono"
                                    />
                                    <p className="text-xs opacity-60">
                                        ⚠️ 输入你的私钥（0x 开头，64位十六进制）。请确保在安全环境下使用！
                                    </p>
                                </div>
                            )}
                        </div>

                        <label className="block text-sm font-medium mb-2 opacity-90">
                            存款金额
                        </label>
                        <div className="flex gap-4">
                            <input
                                type="number"
                                value={depositAmount}
                                onChange={(e) => setDepositAmount(e.target.value)}
                                placeholder="0.0"
                                className="flex-1 px-4 py-3 bg-white/20 border border-white/30 rounded-lg focus:outline-none focus:ring-2 focus:ring-white/50 placeholder-white/50 text-white"
                            />
                            <button
                                onClick={handleDepositWithEIP7702}
                                disabled={isEip7702Loading}
                                className="bg-white text-purple-600 font-bold py-3 px-8 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition shadow-lg"
                            >
                                {isEip7702Loading ? '处理中...' : '授权并存款 🚀'}
                            </button>
                        </div>
                        <p className="text-xs mt-4 opacity-70">
                            * 使用 EIP-7702 在一个交易中完成授权委托 + 批量执行（Approve + Deposit）。
                        </p>
                    </div>
                </div>

                {/* 旧版功能折叠或保留在下方 */}
                <div className="opacity-60 hover:opacity-100 transition duration-300">
                    <h3 className="text-xl font-bold text-gray-700 mb-4 px-2">Legacy Methods (Old)</h3>

                    {/* Permit2 签名存款 */}
                    <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
                        <h2 className="text-lg font-bold text-gray-800 mb-2">Permit2 签名存款</h2>
                        <div className="flex gap-4 items-center">
                            {!isPermit2Approved && (
                                <button
                                    onClick={handleApprovePermit2}
                                    disabled={isApprovingPermit2}
                                    className="bg-yellow-500 text-white px-4 py-2 rounded text-sm"
                                >
                                    Approve Permit2
                                </button>
                            )}
                            <button
                                onClick={handleDepositWithPermit2}
                                disabled={isDepositingPermit2 || !isPermit2Approved}
                                className="bg-blue-500 text-white px-4 py-2 rounded text-sm"
                            >
                                Permit2 存款
                            </button>
                        </div>
                    </div>

                    {/* 传统存款 */}
                    <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
                        <h2 className="text-lg font-bold text-gray-800 mb-2">传统存款 (Approve + Deposit)</h2>
                        <div className="flex gap-4">
                            <button
                                onClick={handleApproveBank}
                                disabled={isApprovingBank}
                                className="bg-gray-500 text-white px-4 py-2 rounded text-sm"
                            >
                                Approve
                            </button>
                            <button
                                onClick={handleDepositTraditional}
                                disabled={isDepositing}
                                className="bg-green-500 text-white px-4 py-2 rounded text-sm"
                            >
                                Deposit
                            </button>
                        </div>
                    </div>
                </div>

                {/* 取款 */}
                <div className="bg-white rounded-lg shadow-md p-6 mt-8">
                    <h2 className="text-2xl font-bold text-gray-800 mb-4">💸 取款</h2>
                    <div className="flex gap-4">
                        <input
                            type="number"
                            value={withdrawAmount}
                            onChange={(e) => setWithdrawAmount(e.target.value)}
                            placeholder="0.0"
                            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg"
                        />
                        <button
                            onClick={handleWithdraw}
                            disabled={isWithdrawing}
                            className="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-8 rounded-lg"
                        >
                            取款
                        </button>
                    </div>
                </div>
            </div>
        </main>
    );
}
