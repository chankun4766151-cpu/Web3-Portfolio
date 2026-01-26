import { useState } from 'react';
import { mockBridgeRoutes, mockChains, Chain } from '../../utils/mockData';
import styles from './BridgePage.module.css';

export default function BridgePage() {
    const [fromChain, setFromChain] = useState<Chain>(mockChains[0]);
    const [toChain, setToChain] = useState<Chain>(mockChains[1]);
    const [amount, setAmount] = useState('');
    const [selectedRoute, setSelectedRoute] = useState(mockBridgeRoutes[0]);

    const handleSwapChains = () => {
        const temp = fromChain;
        setFromChain(toChain);
        setToChain(temp);
    };

    return (
        <section id="bridge" className={styles.bridgePage}>
            <div className={styles.container}>
                <h2 className={styles.title}>Cross-Chain Bridge Aggregator</h2>
                <p className={styles.subtitle}>
                    Find the cheapest and fastest route to bridge your assets across chains
                </p>

                <div className={styles.mainCard}>
                    <div className={styles.bridgeForm}>
                        <div className={styles.chainSelector}>
                            <label className={styles.label}>From</label>
                            <div className={styles.chainSelect}>
                                <select
                                    className={styles.select}
                                    value={fromChain.id}
                                    onChange={(e) => setFromChain(mockChains.find(c => c.id === Number(e.target.value))!)}
                                >
                                    {mockChains.map((chain) => (
                                        <option key={chain.id} value={chain.id}>
                                            {chain.name}
                                        </option>
                                    ))}
                                </select>
                            </div>

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

                        <button className={styles.swapButton} onClick={handleSwapChains}>
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                                <path
                                    d="M7 10L12 15L17 10H7Z"
                                    fill="currentColor"
                                />
                                <path
                                    d="M17 14L12 9L7 14H17Z"
                                    fill="currentColor"
                                    opacity="0.5"
                                />
                            </svg>
                        </button>

                        <div className={styles.chainSelector}>
                            <label className={styles.label}>To</label>
                            <div className={styles.chainSelect}>
                                <select
                                    className={styles.select}
                                    value={toChain.id}
                                    onChange={(e) => setToChain(mockChains.find(c => c.id === Number(e.target.value))!)}
                                >
                                    {mockChains.map((chain) => (
                                        <option key={chain.id} value={chain.id}>
                                            {chain.name}
                                        </option>
                                    ))}
                                </select>
                            </div>
                        </div>
                    </div>

                    <div className={styles.routesList}>
                        <h3 className={styles.routesTitle}>Available Routes</h3>

                        {mockBridgeRoutes.map((route, index) => (
                            <div
                                key={route.name}
                                className={`${styles.routeCard} ${selectedRoute.name === route.name ? styles.selected : ''}`}
                                onClick={() => setSelectedRoute(route)}
                            >
                                <div className={styles.routeHeader}>
                                    <div className={styles.routeName}>
                                        {index === 0 && <span className={styles.bestBadge}>Best Price</span>}
                                        {route.name}
                                    </div>
                                    <div className={styles.routeTime}>{route.estimatedTime}</div>
                                </div>

                                <div className={styles.routeDetails}>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Fee:</span>
                                        <span className={styles.detailValue}>{route.fee}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>You'll receive:</span>
                                        <span className={styles.receiveAmount}>
                                            {amount ? (parseFloat(amount) - 0.008).toFixed(4) : '0.0'} ETH
                                        </span>
                                    </div>
                                </div>

                                {selectedRoute.name === route.name && (
                                    <div className={styles.selectedBadge}>✓ Selected</div>
                                )}
                            </div>
                        ))}
                    </div>

                    <button className={styles.bridgeButton}>
                        Execute Bridge
                    </button>
                </div>

                <div className={styles.infoGrid}>
                    <div className={styles.infoCard}>
                        <div className={styles.infoIcon}>⚡</div>
                        <h4 className={styles.infoTitle}>Fast Transfers</h4>
                        <p className={styles.infoDesc}>
                            Bridge your assets in minutes, not hours
                        </p>
                    </div>
                    <div className={styles.infoCard}>
                        <div className={styles.infoIcon}>💎</div>
                        <h4 className={styles.infoTitle}>Best Rates</h4>
                        <p className={styles.infoDesc}>
                            Always get the most cost-effective route
                        </p>
                    </div>
                    <div className={styles.infoCard}>
                        <div className={styles.infoIcon}>🔒</div>
                        <h4 className={styles.infoTitle}>Secure</h4>
                        <p className={styles.infoDesc}>
                            Trusted by thousands of users worldwide
                        </p>
                    </div>
                </div>

                <div className={styles.supportedChains}>
                    <h3 className={styles.supportedTitle}>Supported Chains</h3>
                    <div className={styles.chainsBadges}>
                        {mockChains.map((chain) => (
                            <div key={chain.id} className={styles.chainBadge}>
                                {chain.name}
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
}
