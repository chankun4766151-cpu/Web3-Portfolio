import { useState } from 'react';
import { mockYieldStrategies, formatCurrency, formatPercentage, calculateEarnings } from '../../utils/mockData';
import styles from './YieldPage.module.css';

export default function YieldPage() {
    const [amount, setAmount] = useState('');
    const [selectedStrategy, setSelectedStrategy] = useState(mockYieldStrategies[2]); // Yearn by default (highest APY)

    const estimatedDaily = amount ? calculateEarnings(parseFloat(amount), selectedStrategy.apy, 1) : 0;
    const estimatedMonthly = amount ? calculateEarnings(parseFloat(amount), selectedStrategy.apy, 30) : 0;
    const estimatedYearly = amount ? calculateEarnings(parseFloat(amount), selectedStrategy.apy, 365) : 0;

    return (
        <section id="yield" className={styles.yieldPage}>
            <div className={styles.container}>
                <h2 className={styles.title}>Auto-Yield Optimizer</h2>
                <p className={styles.subtitle}>
                    Deposit your assets and let our AI-powered routing find the best yields across DeFi protocols
                </p>

                <div className={styles.mainGrid}>
                    <div className={styles.depositCard}>
                        <h3 className={styles.cardTitle}>Deposit Assets</h3>

                        <div className={styles.inputGroup}>
                            <label className={styles.label}>Amount</label>
                            <div className={styles.inputWrapper}>
                                <input
                                    type="number"
                                    className={styles.input}
                                    placeholder="0.0"
                                    value={amount}
                                    onChange={(e) => setAmount(e.target.value)}
                                />
                                <span className={styles.currency}>ETH</span>
                            </div>
                        </div>

                        <div className={styles.balanceRow}>
                            <span className={styles.balanceLabel}>Available Balance:</span>
                            <span className={styles.balanceValue}>5.234 ETH</span>
                        </div>

                        <div className={styles.estimations}>
                            <div className={styles.estimationRow}>
                                <span>Daily Earnings</span>
                                <span className={styles.estimationValue}>{formatCurrency(estimatedDaily)}</span>
                            </div>
                            <div className={styles.estimationRow}>
                                <span>Monthly Earnings</span>
                                <span className={styles.estimationValue}>{formatCurrency(estimatedMonthly)}</span>
                            </div>
                            <div className={styles.estimationRow}>
                                <span>Yearly Earnings</span>
                                <span className={styles.estimationValue}>{formatCurrency(estimatedYearly)}</span>
                            </div>
                        </div>

                        <div className={styles.buttonGroup}>
                            <button className={styles.depositButton}>
                                Deposit & Earn
                            </button>
                            <button className={styles.withdrawButton}>
                                Withdraw
                            </button>
                        </div>
                    </div>

                    <div className={styles.strategiesCard}>
                        <h3 className={styles.cardTitle}>Available Strategies</h3>

                        <div className={styles.strategyList}>
                            {mockYieldStrategies.map((strategy) => (
                                <div
                                    key={strategy.protocol}
                                    className={`${styles.strategyItem} ${selectedStrategy.protocol === strategy.protocol ? styles.selected : ''}`}
                                    onClick={() => setSelectedStrategy(strategy)}
                                >
                                    <div className={styles.strategyHeader}>
                                        <div className={styles.protocolName}>{strategy.protocol}</div>
                                        <div className={styles.apyBadge}>{formatPercentage(strategy.apy)}</div>
                                    </div>

                                    <div className={styles.strategyMeta}>
                                        <div className={styles.metaItem}>
                                            <span className={styles.metaLabel}>TVL:</span>
                                            <span className={styles.metaValue}>{strategy.tvl}</span>
                                        </div>
                                        <div className={styles.metaItem}>
                                            <span className={styles.metaLabel}>Risk:</span>
                                            <span className={`${styles.riskBadge} ${styles[strategy.risk.toLowerCase()]}`}>
                                                {strategy.risk}
                                            </span>
                                        </div>
                                    </div>

                                    <div className={styles.allocationInfo}>
                                        <span className={styles.allocationLabel}>Current Allocation:</span>
                                        <div className={styles.allocationBar}>
                                            <div
                                                className={styles.allocationFill}
                                                style={{ width: `${strategy.allocation}%` }}
                                            />
                                        </div>
                                        <span className={styles.allocationPercent}>{strategy.allocation}%</span>
                                    </div>

                                    {selectedStrategy.protocol === strategy.protocol && (
                                        <div className={styles.selectedIndicator}>✓ Selected</div>
                                    )}
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <div className={styles.featuresGrid}>
                    <div className={styles.featureCard}>
                        <div className={styles.featureIcon}>🔄</div>
                        <h4 className={styles.featureTitle}>Auto-Rebalancing</h4>
                        <p className={styles.featureDesc}>
                            Automatically rebalances your portfolio to maintain optimal yield
                        </p>
                    </div>
                    <div className={styles.featureCard}>
                        <div className={styles.featureIcon}>🛡️</div>
                        <h4 className={styles.featureTitle}>Risk Management</h4>
                        <p className={styles.featureDesc}>
                            Smart contracts audited by top security firms
                        </p>
                    </div>
                    <div className={styles.featureCard}>
                        <div className={styles.featureIcon}>⚡</div>
                        <h4 className={styles.featureTitle}>Instant Withdrawals</h4>
                        <p className={styles.featureDesc}>
                            Withdraw your funds anytime without lock-up periods
                        </p>
                    </div>
                </div>
            </div>
        </section>
    );
}
