import { useState } from 'react';
import StatsCard from '../StatsCard/StatsCard';
import { mockPortfolioStats, mockYieldStrategies, formatCurrency, formatPercentage, calculateOptimalAPY } from '../../utils/mockData';
import styles from './Dashboard.module.css';

export default function Dashboard() {
    const [userBalance] = useState(10000);
    const optimalAPY = calculateOptimalAPY(mockYieldStrategies);
    const monthlyEarnings = (userBalance * optimalAPY / 100 / 12);

    return (
        <section id="dashboard" className={styles.dashboard}>
            <div className={styles.container}>
                <div className={styles.hero}>
                    <h1 className={styles.title}>
                        Smart Banking.<br />
                        Institutional Yield.<br />
                        <span className={styles.highlight}>For Everyone.</span>
                    </h1>
                    <p className={styles.subtitle}>
                        Maximize your crypto earnings with AI-powered yield optimization,
                        low-cost cross-chain bridges, and real-time arbitrage opportunities.
                    </p>
                </div>

                <div className={styles.statsGrid}>
                    <StatsCard
                        title="Total Value Locked"
                        value={mockPortfolioStats.totalValueLocked}
                        gradient="primary"
                        trend={{ value: "+12.5% this month", positive: true }}
                        icon={
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                                <path d="M12 2L2 7L12 12L22 7L12 2Z" fill="currentColor" opacity="0.3" />
                                <path d="M2 17L12 22L22 17V12L12 17L2 12V17Z" fill="currentColor" />
                            </svg>
                        }
                    />
                    <StatsCard
                        title="Average APY"
                        value={formatPercentage(mockPortfolioStats.averageAPY)}
                        gradient="success"
                        trend={{ value: "+0.8% from last week", positive: true }}
                        icon={
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                                <path d="M16 6L18 8L22 4L20 2L16 6Z" fill="currentColor" />
                                <path d="M4 14L2 16L6 20L8 18L4 14Z" fill="currentColor" />
                                <path d="M14 4L4 14L10 20L20 10L14 4Z" fill="currentColor" opacity="0.3" />
                            </svg>
                        }
                    />
                    <StatsCard
                        title="Total Profit"
                        value={mockPortfolioStats.totalProfit}
                        gradient="secondary"
                        trend={{ value: "+$45.2K this month", positive: true }}
                        icon={
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                                <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM13 17H11V15H13V17ZM13 13H11V7H13V13Z" fill="currentColor" opacity="0.3" />
                                <path d="M11 7H13V13H11V7ZM11 15H13V17H11V15Z" fill="currentColor" />
                            </svg>
                        }
                    />
                    <StatsCard
                        title="Active Users"
                        value={mockPortfolioStats.activeUsers.toLocaleString()}
                        gradient="accent"
                        trend={{ value: "+156 new this week", positive: true }}
                        icon={
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                                <path d="M16 11C17.66 11 18.99 9.66 18.99 8C18.99 6.34 17.66 5 16 5C14.34 5 13 6.34 13 8C13 9.66 14.34 11 16 11Z" fill="currentColor" opacity="0.3" />
                                <path d="M8 11C9.66 11 10.99 9.66 10.99 8C10.99 6.34 9.66 5 8 5C6.34 5 5 6.34 5 8C5 9.66 6.34 11 8 11Z" fill="currentColor" />
                                <path d="M8 13C5.67 13 1 14.17 1 16.5V19H15V16.5C15 14.17 10.33 13 8 13Z" fill="currentColor" />
                                <path d="M16 13C15.71 13 15.38 13.02 15.03 13.05C16.19 13.89 17 15.02 17 16.5V19H23V16.5C23 14.17 18.33 13 16 13Z" fill="currentColor" opacity="0.3" />
                            </svg>
                        }
                    />
                </div>

                <div className={styles.portfolio}>
                    <h2 className={styles.sectionTitle}>Your Portfolio</h2>
                    <div className={styles.portfolioCard}>
                        <div className={styles.portfolioHeader}>
                            <div>
                                <div className={styles.balanceLabel}>Total Balance</div>
                                <div className={styles.balanceValue}>{formatCurrency(userBalance)}</div>
                            </div>
                            <div>
                                <div className={styles.apyLabel}>Current APY</div>
                                <div className={styles.apyValue}>{formatPercentage(optimalAPY)}</div>
                            </div>
                            <div>
                                <div className={styles.earningsLabel}>Monthly Earnings</div>
                                <div className={styles.earningsValue}>{formatCurrency(monthlyEarnings)}</div>
                            </div>
                        </div>

                        <div className={styles.strategyList}>
                            <h3 className={styles.strategyTitle}>Active Strategies</h3>
                            {mockYieldStrategies.map((strategy) => (
                                <div key={strategy.protocol} className={styles.strategyItem}>
                                    <div className={styles.strategyInfo}>
                                        <div className={styles.strategyName}>{strategy.protocol}</div>
                                        <div className={styles.strategyMeta}>
                                            TVL: {strategy.tvl} • APY: {formatPercentage(strategy.apy)}
                                        </div>
                                    </div>
                                    <div className={styles.strategyAllocation}>
                                        <div className={styles.allocationBar}>
                                            <div
                                                className={styles.allocationFill}
                                                style={{ width: `${strategy.allocation}%` }}
                                            />
                                        </div>
                                        <div className={styles.allocationText}>{strategy.allocation}%</div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <div className={styles.quickActions}>
                    <button className={styles.actionButton}>
                        <div className={styles.actionIcon}>💰</div>
                        <div className={styles.actionText}>Deposit & Earn</div>
                    </button>
                    <button className={styles.actionButton}>
                        <div className={styles.actionIcon}>🌉</div>
                        <div className={styles.actionText}>Cross-Chain Bridge</div>
                    </button>
                    <button className={styles.actionButton}>
                        <div className={styles.actionIcon}>📈</div>
                        <div className={styles.actionText}>Find Arbitrage</div>
                    </button>
                </div>
            </div>
        </section>
    );
}
