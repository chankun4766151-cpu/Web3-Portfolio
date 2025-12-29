'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, usePublicClient, useWalletClient } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseEther, formatEther, parseUnits } from 'viem';
import { CONTRACTS, EXPLORER_URL } from '@/constants/addresses';
import MyTokenAbi from '@/constants/MyToken.abi.json';
import TokenBankPermit2Abi from '@/constants/TokenBankPermit2.abi.json';
import { Permit2Abi } from '@/constants/Permit2.abi';

/**
 * TokenBank Permit2 主页面
 * 
 * 功能特性：
 * 1. 显示用户的代币余额和银行存款
 * 2. 传统存款方式（两步：approve + deposit）
 * 3. Permit2 签名存款（一步：签名 + depositWithPermit2）
 * 4. 取款功能
 * 
 * Permit2 工作流程：
 * Step 1: 用户一次性授权 Permit2 合约（approvePermit2）
 * Step 2: 用户对存款操作进行签名（签名是离线的，不花 gas）
 * Step 3: 调用 depositWithPermit2，传入签名数据完成存款
 */

export default function Home() {
    const { address, isConnected } = useAccount();
    const publicClient = usePublicClient();
    const { data: walletClient } = useWalletClient();

    // 状态管理
    const [depositAmount, setDepositAmount] = useState('');
    const [withdrawAmount, setWithdrawAmount] = useState('');
    const [isPermit2Approved, setIsPermit2Approved] = useState(false);

    // ============================
    // 读取合约数据
    // ============================

    // 读取代币余额
    const { data: tokenBalance, refetch: refetchTokenBalance } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
    });

    // 读取银行存款余额
    const { data: bankBalance, refetch: refetchBankBalance } = useReadContract({
        address: CONTRACTS.TokenBankPermit2 as `0x${string}`,
        abi: TokenBankPermit2Abi,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
    });

    // 读取代币符号
    const { data: tokenSymbol } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'symbol',
    });

    // 检查是否已授权 Permit2
    const { data: permit2Allowance, refetch: refetchPermit2Allowance } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'allowance',
        args: address ? [address, CONTRACTS.Permit2 as `0x${string}`] : undefined,
    });

    // 检查是否已授权 TokenBank（传统方式）
    const { data: bankAllowance, refetch: refetchBankAllowance } = useReadContract({
        address: CONTRACTS.MyToken as `0x${string}`,
        abi: MyTokenAbi,
        functionName: 'allowance',
        args: address ? [address, CONTRACTS.TokenBankPermit2 as `0x${string}`] : undefined,
    });

    // 监听 Permit2 授权额度变化
    useEffect(() => {
        if (permit2Allowance) {
            const maxApproval = parseUnits('1000000000', 18); // 10亿代币
            setIsPermit2Approved((permit2Allowance as bigint) >= maxApproval);
        }
    }, [permit2Allowance]);

    // ============================
    // 写入合约函数
    // ============================

    // 授权 Permit2 合约
    const { writeContract: approvePermit2, data: approvePermit2Hash } = useWriteContract();
    const { isLoading: isApprovingPermit2, isSuccess: permit2ApproveSuccess } = useWaitForTransactionReceipt({
        hash: approvePermit2Hash,
    });

    // 授权 TokenBank 合约（传统方式）
    const { writeContract: approveBank, data: approveBankHash } = useWriteContract();
    const { isLoading: isApprovingBank, isSuccess: bankApproveSuccess } = useWaitForTransactionReceipt({
        hash: approveBankHash,
    });

    // 传统存款
    const { writeContract: depositTraditional, data: depositHash } = useWriteContract();
    const { isLoading: isDepositing, isSuccess: depositSuccess } = useWaitForTransactionReceipt({
        hash: depositHash,
    });

    // Permit2 存款
    const { writeContract: depositPermit2, data: permit2DepositHash } = useWriteContract();
    const { isLoading: isDepositingPermit2, isSuccess: permit2DepositSuccess } = useWaitForTransactionReceipt({
        hash: permit2DepositHash,
    });

    // 取款
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

    // ============================
    // 处理函数
    // ============================

    // 授权 Permit2
    const handleApprovePermit2 = async () => {
        try {
            const maxApproval = parseUnits('1000000000', 18); // 授权 10 亿代币
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

    // 授权 TokenBank（传统方式）
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

    // 传统存款
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

    // Permit2 签名存款 ⭐ 核心功能 ⭐
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

            // Step 1: 获取当前 nonce
            const nonce = await getNonce(address);

            // Step 2: 设置签名截止时间（当前时间 + 1小时）
            const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600);

            // Step 3: 构造签名数据
            const permitData = {
                permitted: {
                    token: CONTRACTS.MyToken as `0x${string}`,
                    amount: amount,
                },
                spender: CONTRACTS.TokenBankPermit2 as `0x${string}`,
                nonce: nonce,
                deadline: deadline,
            };

            // Step 4: 获取 Permit2 的 domain separator
            const domainSeparator = await publicClient.readContract({
                address: CONTRACTS.Permit2 as `0x${string}`,
                abi: Permit2Abi,
                functionName: 'DOMAIN_SEPARATOR',
            });

            // Step 5: 构造 EIP-712 类型数据
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

            // Step 6: 用户签名（这里不花 gas！）
            const signature = await walletClient.signTypedData({
                account: address,
                domain,
                types,
                primaryType: 'PermitTransferFrom',
                message: permitData,
            });

            // Step 7: 调用合约的 depositWithPermit2
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

    // 取款
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

    // 获取 Permit2 nonce（用于防止签名重放攻击）
    const getNonce = async (userAddress: `0x${string}`) => {
        if (!publicClient) throw new Error('Public client not available');

        // 生成随机 nonce
        // 在生产环境中，你可以使用更复杂的 nonce 管理策略
        return BigInt(Math.floor(Math.random() * 1000000000));
    };

    // ============================
    // UI 渲染
    // ============================

    if (!isConnected) {
        return (
            <main className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-br from-blue-50 to-indigo-100">
                <div className="text-center">
                    <h1 className="text-4xl font-bold mb-4 text-gray-800">TokenBank (Permit2)</h1>
                    <p className="text-gray-600 mb-8">使用 Permit2 签名进行无 gas 授权的代币存款</p>
                    <ConnectButton />
                </div>
            </main>
        );
    }

    return (
        <main className="min-h-screen p-8 bg-gradient-to-br from-blue-50 to-indigo-100">
            <div className="max-w-4xl mx-auto">
                {/* 头部 */}
                <div className="flex justify-between items-center mb-8">
                    <h1 className="text-4xl font-bold text-gray-800">TokenBank (Permit2)</h1>
                    <ConnectButton />
                </div>

                <p className="text-gray-600 mb-8 text-center">
                    ✨ 使用 Uniswap Permit2 签名实现无 gas 授权的代币存款
                </p>

                {/* 余额卡片 */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                    <div className="bg-white rounded-lg shadow-md p-6">
                        <h3 className="text-sm font-semibold text-gray-500 mb-2">💰 钱包代币余额</h3>
                        <p className="text-3xl font-bold text-gray-800">
                            {tokenBalance ? formatEther(tokenBalance as bigint) : '0'} {tokenSymbol as string || 'MTK'}
                        </p>
                    </div>

                    <div className="bg-white rounded-lg shadow-md p-6">
                        <h3 className="text-sm font-semibold text-gray-500 mb-2">🏦 银行存款余额</h3>
                        <p className="text-3xl font-bold text-gray-800">
                            {bankBalance ? formatEther(bankBalance as bigint) : '0'} {tokenSymbol as string || 'MTK'}
                        </p>
                    </div>
                </div>

                {/* Permit2 设置 */}
                {!isPermit2Approved && (
                    <div className="bg-yellow-50 border-l-4 border-yellow-400 p-6 mb-8 rounded-lg">
                        <h3 className="text-lg font-semibold text-yellow-800 mb-2">⚙️ 初始化设置</h3>
                        <p className="text-yellow-700 mb-4">
                            你需要先授权 Permit2 合约（一次性操作），之后就可以使用签名进行存款了。
                        </p>
                        <button
                            onClick={handleApprovePermit2}
                            disabled={isApprovingPermit2}
                            className="bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-2 px-6 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition"
                        >
                            {isApprovingPermit2 ? '授权中...' : '授权 Permit2 合约'}
                        </button>
                        {approvePermit2Hash && (
                            <a
                                href={`${EXPLORER_URL}${approvePermit2Hash}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="ml-4 text-blue-600 hover:underline"
                            >
                                查看交易 →
                            </a>
                        )}
                    </div>
                )}

                {/* Permit2 签名存款 */}
                <div className="bg-white rounded-lg shadow-md p-6 mb-8">
                    <h2 className="text-2xl font-bold text-gray-800 mb-4">🚀 Permit2 签名存款（推荐）</h2>
                    <p className="text-gray-600 mb-4">
                        一步完成！无需额外 approve 交易，节省 gas 费用
                    </p>

                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                存款金额
                            </label>
                            <input
                                type="number"
                                value={depositAmount}
                                onChange={(e) => setDepositAmount(e.target.value)}
                                placeholder="0.0"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            />
                        </div>

                        <button
                            onClick={handleDepositWithPermit2}
                            disabled={isDepositingPermit2 || !isPermit2Approved}
                            className="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-3 px-6 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition"
                        >
                            {isDepositingPermit2 ? '存款中...' : '签名并存款'}
                        </button>

                        {permit2DepositHash && (
                            <a
                                href={`${EXPLORER_URL}${permit2DepositHash}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="block text-center text-blue-600 hover:underline"
                            >
                                查看交易 →
                            </a>
                        )}
                    </div>
                </div>

                {/* 传统存款方式 */}
                <div className="bg-white rounded-lg shadow-md p-6 mb-8">
                    <h2 className="text-2xl font-bold text-gray-800 mb-4">🔧 传统存款方式（两步）</h2>
                    <p className="text-gray-600 mb-4">
                        需要两次交易：先 approve，再 deposit
                    </p>

                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                存款金额
                            </label>
                            <input
                                type="number"
                                value={depositAmount}
                                onChange={(e) => setDepositAmount(e.target.value)}
                                placeholder="0.0"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            />
                        </div>

                        <div className="flex gap-4">
                            <button
                                onClick={handleApproveBank}
                                disabled={isApprovingBank}
                                className="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-bold py-3 px-6 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition"
                            >
                                {isApprovingBank ? '授权中...' : '1. Approve'}
                            </button>

                            <button
                                onClick={handleDepositTraditional}
                                disabled={isDepositing}
                                className="flex-1 bg-green-500 hover:bg-green-600 text-white font-bold py-3 px-6 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition"
                            >
                                {isDepositing ? '存款中...' : '2. Deposit'}
                            </button>
                        </div>

                        {approveBankHash && (
                            <a
                                href={`${EXPLORER_URL}${approveBankHash}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="block text-center text-blue-600 hover:underline text-sm"
                            >
                                查看 Approve 交易 →
                            </a>
                        )}
                        {depositHash && (
                            <a
                                href={`${EXPLORER_URL}${depositHash}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="block text-center text-blue-600 hover:underline text-sm"
                            >
                                查看 Deposit 交易 →
                            </a>
                        )}
                    </div>
                </div>

                {/* 取款 */}
                <div className="bg-white rounded-lg shadow-md p-6">
                    <h2 className="text-2xl font-bold text-gray-800 mb-4">💸 取款</h2>

                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                取款金额
                            </label>
                            <input
                                type="number"
                                value={withdrawAmount}
                                onChange={(e) => setWithdrawAmount(e.target.value)}
                                placeholder="0.0"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            />
                        </div>

                        <button
                            onClick={handleWithdraw}
                            disabled={isWithdrawing}
                            className="w-full bg-red-500 hover:bg-red-600 text-white font-bold py-3 px-6 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition"
                        >
                            {isWithdrawing ? '取款中...' : '取款'}
                        </button>

                        {withdrawHash && (
                            <a
                                href={`${EXPLORER_URL}${withdrawHash}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="block text-center text-blue-600 hover:underline"
                            >
                                查看交易 →
                            </a>
                        )}
                    </div>
                </div>

                {/* 说明 */}
                <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
                    <h3 className="text-lg font-semibold text-blue-900 mb-2">💡 使用说明</h3>
                    <ul className="list-disc list-inside text-blue-800 space-y-1">
                        <li>首次使用：需要授权 Permit2 合约（一次性操作）</li>
                        <li>Permit2 存款：只需签名即可完成存款，节省 gas</li>
                        <li>传统存款：需要两步操作（approve + deposit），费用较高</li>
                        <li>取款：随时可以取出你在银行的存款</li>
                    </ul>
                </div>
            </div>
        </main>
    );
}
