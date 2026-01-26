export interface YieldStats {
  totalDeposited: string;
  currentAPY: number;
  monthlyEarnings: string;
  totalEarnings: string;
}

export interface YieldStrategy {
  protocol: string;
  apy: number;
  allocation: number;
  tvl: string;
  risk: 'Low' | 'Medium' | 'High';
}

export interface BridgeRoute {
  name: string;
  fee: string;
  estimatedTime: string;
  icon?: string;
}

export interface BridgeQuote {
  fromChain: Chain;
  toChain: Chain;
  amount: string;
  routes: BridgeRoute[];
}

export interface Chain {
  id: number;
  name: string;
  icon?: string;
}

export interface ArbitrageOpportunity {
  id: string;
  pair: string;
  buyOn: string;
  sellOn: string;
  profit: string;
  profitPercentage: number;
  risk: 'Low' | 'Medium' | 'High';
  estimatedGas: string;
  volume: string;
}

export interface PortfolioStats {
  totalValueLocked: string;
  averageAPY: number;
  totalProfit: string;
  activeUsers: number;
}

export interface Transaction {
  hash: string;
  type: 'deposit' | 'withdraw' | 'bridge' | 'arbitrage';
  amount: string;
  timestamp: number;
  status: 'pending' | 'completed' | 'failed';
}

export interface WalletState {
  address: string | null;
  balance: string;
  connected: boolean;
  chainId: number | null;
}
