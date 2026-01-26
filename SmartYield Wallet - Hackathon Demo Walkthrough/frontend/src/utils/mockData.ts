import { YieldStrategy, BridgeRoute, ArbitrageOpportunity, PortfolioStats, Chain } from '../types';

// Mock Yield Strategies
export const mockYieldStrategies: YieldStrategy[] = [
    {
        protocol: 'Aave',
        apy: 3.5,
        allocation: 40,
        tvl: '$1.2B',
        risk: 'Low',
    },
    {
        protocol: 'Compound',
        apy: 4.2,
        allocation: 30,
        tvl: '$850M',
        risk: 'Low',
    },
    {
        protocol: 'Yearn Finance',
        apy: 5.8,
        allocation: 20,
        tvl: '$320M',
        risk: 'Medium',
    },
    {
        protocol: 'Lido',
        apy: 3.2,
        allocation: 10,
        tvl: '$2.1B',
        risk: 'Low',
    },
];

// Mock Bridge Routes
export const mockBridgeRoutes: BridgeRoute[] = [
    {
        name: 'Stargate Finance',
        fee: '0.008 ETH',
        estimatedTime: '8 min',
    },
    {
        name: 'LayerZero',
        fee: '0.010 ETH',
        estimatedTime: '5 min',
    },
    {
        name: 'Hop Protocol',
        fee: '0.015 ETH',
        estimatedTime: '10 min',
    },
    {
        name: 'Synapse',
        fee: '0.012 ETH',
        estimatedTime: '7 min',
    },
];

// Mock Arbitrage Opportunities
export const mockArbitrageOpportunities: ArbitrageOpportunity[] = [
    {
        id: '1',
        pair: 'ETH/USDC',
        buyOn: 'Uniswap V3',
        sellOn: 'Binance',
        profit: '$45.30',
        profitPercentage: 2.3,
        risk: 'Low',
        estimatedGas: '0.002 ETH',
        volume: '$2,000',
    },
    {
        id: '2',
        pair: 'WBTC/ETH',
        buyOn: 'Sushiswap',
        sellOn: 'Coinbase',
        profit: '$32.15',
        profitPercentage: 1.8,
        risk: 'Medium',
        estimatedGas: '0.003 ETH',
        volume: '$1,800',
    },
    {
        id: '3',
        pair: 'USDT/DAI',
        buyOn: 'Curve',
        sellOn: 'Kraken',
        profit: '$12.80',
        profitPercentage: 0.9,
        risk: 'Low',
        estimatedGas: '0.001 ETH',
        volume: '$1,400',
    },
    {
        id: '4',
        pair: 'LINK/ETH',
        buyOn: 'Uniswap V2',
        sellOn: 'OKX',
        profit: '$28.50',
        profitPercentage: 3.1,
        risk: 'High',
        estimatedGas: '0.004 ETH',
        volume: '$920',
    },
];

// Mock Portfolio Stats
export const mockPortfolioStats: PortfolioStats = {
    totalValueLocked: '$23.5M',
    averageAPY: 4.2,
    totalProfit: '$1.2M',
    activeUsers: 1243,
};

// Mock Chains
export const mockChains: Chain[] = [
    { id: 1, name: 'Ethereum' },
    { id: 42161, name: 'Arbitrum' },
    { id: 10, name: 'Optimism' },
    { id: 137, name: 'Polygon' },
    { id: 8453, name: 'Base' },
    { id: 56, name: 'BSC' },
];

// Calculate optimal APY based on strategies
export const calculateOptimalAPY = (strategies: YieldStrategy[]): number => {
    return strategies.reduce((acc, strategy) => {
        return acc + (strategy.apy * strategy.allocation) / 100;
    }, 0);
};

// Format currency
export const formatCurrency = (value: number | string): string => {
    const num = typeof value === 'string' ? parseFloat(value) : value;
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
    }).format(num);
};

// Format percentage
export const formatPercentage = (value: number): string => {
    return `${value.toFixed(2)}%`;
};

// Simulate deposit and calculate earnings
export const calculateEarnings = (
    depositAmount: number,
    apy: number,
    days: number
): number => {
    const dailyRate = apy / 365 / 100;
    return depositAmount * dailyRate * days;
};

// Get risk color
export const getRiskColor = (risk: 'Low' | 'Medium' | 'High'): string => {
    switch (risk) {
        case 'Low':
            return 'var(--success)';
        case 'Medium':
            return 'var(--warning)';
        case 'High':
            return 'var(--danger)';
    }
};

// Shorten address
export const shortenAddress = (address: string): string => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
};
