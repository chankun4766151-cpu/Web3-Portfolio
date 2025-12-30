/**
 * Permit2 接口 ABI
 * 这是 Permit2 合约的简化接口，只包含我们需要的函数
 */

export const Permit2Abi = [
    {
        inputs: [
            {
                components: [
                    {
                        components: [
                            { internalType: 'address', name: 'token', type: 'address' },
                            { internalType: 'uint256', name: 'amount', type: 'uint256' },
                        ],
                        internalType: 'struct IPermit2.TokenPermissions',
                        name: 'permitted',
                        type: 'tuple',
                    },
                    { internalType: 'uint256', name: 'nonce', type: 'uint256' },
                    { internalType: 'uint256', name: 'deadline', type: 'uint256' },
                ],
                internalType: 'struct IPermit2.PermitTransferFrom',
                name: 'permit',
                type: 'tuple',
            },
            {
                components: [
                    { internalType: 'address', name: 'to', type: 'address' },
                    { internalType: 'uint256', name: 'requestedAmount', type: 'uint256' },
                ],
                internalType: 'struct IPermit2.SignatureTransferDetails',
                name: 'transferDetails',
                type: 'tuple',
            },
            { internalType: 'address', name: 'owner', type: 'address' },
            { internalType: 'bytes', name: 'signature', type: 'bytes' },
        ],
        name: 'permitTransferFrom',
        outputs: [],
        stateMutability: 'nonpayable',
        type: 'function',
    },
    {
        inputs: [
            { internalType: 'address', name: '', type: 'address' },
            { internalType: 'uint256', name: '', type: 'uint256' },
        ],
        name: 'nonceBitmap',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        stateMutability: 'view',
        type: 'function',
    },
    {
        inputs: [],
        name: 'DOMAIN_SEPARATOR',
        outputs: [{ internalType: 'bytes32', name: '', type: 'bytes32' }],
        stateMutability: 'view',
        type: 'function',
    },
] as const;
