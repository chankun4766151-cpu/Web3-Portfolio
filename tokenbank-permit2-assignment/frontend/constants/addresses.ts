/**
 * 合约地址配置
 * 
 * 说明：
 * 部署合约后，需要将合约地址更新到这个文件中
 * - MyToken: 你的 ERC20 代币合约地址
 * - TokenBankPermit2: 你的银行合约地址  
 * - Permit2: Uniswap 官方 Permit2 合约地址（固定的）
 */

export const CONTRACTS = {
    MyToken: '0xe7b200b17a51e3a036eceb1c2f22c57f691d01c5', // ✅ 已部署
    TokenBankPermit2: '0x7e98739ba44ac1bccca11a25aee6ae5b5b40457a', // ✅ 已部署
    Permit2: '0x000000000022D473030F116dDEE9F6B43aC78BA3', // ✅ 官方地址，不需要修改
} as const;

export const EXPLORER_URL = 'https://sepolia.etherscan.io/tx/';
