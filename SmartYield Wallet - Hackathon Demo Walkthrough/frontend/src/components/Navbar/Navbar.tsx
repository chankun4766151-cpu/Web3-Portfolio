import styles from './Navbar.module.css';
import { shortenAddress } from '../../utils/mockData';

interface NavbarProps {
    walletAddress?: string;
    onConnect: () => void;
}

export default function Navbar({ walletAddress, onConnect }: NavbarProps) {
    return (
        <nav className={styles.navbar}>
            <div className={styles.container}>
                <div className={styles.logo}>
                    <div className={styles.logoIcon}>
                        <span className={styles.iconText}>SY</span>
                    </div>
                    <span className={styles.logoText}>SmartYield</span>
                </div>

                <div className={styles.navLinks}>
                    <a href="#dashboard" className={styles.navLink}>
                        Dashboard
                    </a>
                    <a href="#yield" className={styles.navLink}>
                        Yield
                    </a>
                    <a href="#bridge" className={styles.navLink}>
                        Bridge
                    </a>
                    <a href="#arbitrage" className={styles.navLink}>
                        Arbitrage
                    </a>
                </div>

                <button className={styles.connectButton} onClick={onConnect}>
                    {walletAddress ? (
                        <>
                            <span className={styles.statusDot}></span>
                            {shortenAddress(walletAddress)}
                        </>
                    ) : (
                        <>
                            <svg
                                width="20"
                                height="20"
                                viewBox="0 0 20 20"
                                fill="none"
                                xmlns="http://www.w3.org/2000/svg"
                            >
                                <path
                                    d="M17 7H14V5C14 3.9 13.1 3 12 3H5C3.9 3 3 3.9 3 5V15C3 16.1 3.9 17 5 17H17C18.1 17 19 16.1 19 15V9C19 7.9 18.1 7 17 7ZM5 5H12V7H5V5ZM17 15H5V9H17V15Z"
                                    fill="currentColor"
                                />
                                <circle cx="14" cy="12" r="1.5" fill="currentColor" />
                            </svg>
                            Connect Wallet
                        </>
                    )}
                </button>
            </div>
        </nav>
    );
}
