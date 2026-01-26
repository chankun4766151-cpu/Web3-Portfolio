import { mockArbitrageOpportunities, getRiskColor } from '../../utils/mockData';
import styles from './ArbitragePage.module.css';

export default function ArbitragePage() {
    return (
        <section id="arbitrage" className={styles.arbitragePage}>
            <div className={styles.container}>
                <h2 className={styles.title}>Arbitrage Opportunities</h2>
                <p className={styles.subtitle}>
                    Real-time arbitrage opportunities across DEXs and CEXs
                </p>

                <div className={styles.statsBar}>
                    <div className={styles.statItem}>
                        <span className={styles.statLabel}>Active Opportunities</span>
                        <span className={styles.statValue}>{mockArbitrageOpportunities.length}</span>
                    </div>
                    <div className={styles.statItem}>
                        <span className={styles.statLabel}>Total Volume</span>
                        <span className={styles.statValue}>$6.12K</span>
                    </div>
                    <div className={styles.statItem}>
                        <span className={styles.statLabel}>Avg. Profit</span>
                        <span className={styles.statValue}>2.0%</span>
                    </div>
                </div>

                <div className={styles.opportunitiesList}>
                    {mockArbitrageOpportunities.map((opportunity) => (
                        <div key={opportunity.id} className={styles.opportunityCard}>
                            <div className={styles.cardHeader}>
                                <div className={styles.pairInfo}>
                                    <div className={styles.pairName}>{opportunity.pair}</div>
                                    <div className={styles.pairRoute}>
                                        <span className={styles.exchange}>{opportunity.buyOn}</span>
                                        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                                            <path d="M5 8H11M11 8L8 5M11 8L8 11" stroke="currentColor" strokeWidth="2" />
                                        </svg>
                                        <span className={styles.exchange}>{opportunity.sellOn}</span>
                                    </div>
                                </div>

                                <div className={styles.profitBadge}>
                                    <div className={styles.profitAmount}>{opportunity.profit}</div>
                                    <div className={styles.profitPercent}>+{opportunity.profitPercentage}%</div>
                                </div>
                            </div>

                            <div className={styles.cardDetails}>
                                <div className={styles.detailRow}>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Risk Level:</span>
                                        <span
                                            className={styles.riskBadge}
                                            style={{ color: getRiskColor(opportunity.risk) }}
                                        >
                                            {opportunity.risk}
                                        </span>
                                    </div>

                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Est. Gas:</span>
                                        <span className={styles.detailValue}>{opportunity.estimatedGas}</span>
                                    </div>

                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Volume:</span>
                                        <span className={styles.detailValue}>{opportunity.volume}</span>
                                    </div>
                                </div>
                            </div>

                            <div className={styles.cardActions}>
                                <button className={styles.detailsButton}>
                                    View Details
                                </button>
                                <button className={styles.executeButton}>
                                    Execute Arbitrage
                                </button>
                            </div>

                            {opportunity.risk === 'Low' && (
                                <div className={styles.recommendedBadge}>⭐ Recommended</div>
                            )}
                        </div>
                    ))}
                </div>

                <div className={styles.howItWorks}>
                    <h3 className={styles.howTitle}>How It Works</h3>

                    <div className={styles.stepsGrid}>
                        <div className={styles.stepCard}>
                            <div className={styles.stepNumber}>1</div>
                            <h4 className={styles.stepTitle}>Scan Markets</h4>
                            <p className={styles.stepDesc}>
                                Our AI continuously monitors prices across 50+ exchanges
                            </p>
                        </div>

                        <div className={styles.stepCard}>
                            <div className={styles.stepNumber}>2</div>
                            <h4 className={styles.stepTitle}>Detect Opportunity</h4>
                            <p className={styles.stepDesc}>
                                When a price difference is found, we calculate potential profit
                            </p>
                        </div>

                        <div className={styles.stepCard}>
                            <div className={styles.stepNumber}>3</div>
                            <h4 className={styles.stepTitle}>Execute Trade</h4>
                            <p className={styles.stepDesc}>
                                One-click execution with optimal routing and gas optimization
                            </p>
                        </div>

                        <div className={styles.stepCard}>
                            <div className={styles.stepNumber}>4</div>
                            <h4 className={styles.stepTitle}>Earn Profit</h4>
                            <p className={styles.stepDesc}>
                                Profit is automatically sent to your wallet
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
}
