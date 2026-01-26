import { ReactNode } from 'react';
import styles from './StatsCard.module.css';

interface StatsCardProps {
    title: string;
    value: string;
    icon?: ReactNode;
    trend?: {
        value: string;
        positive: boolean;
    };
    gradient?: 'primary' | 'secondary' | 'success' | 'accent';
}

export default function StatsCard({ title, value, icon, trend, gradient = 'primary' }: StatsCardProps) {
    return (
        <div className={`${styles.card} ${styles[gradient]}`}>
            <div className={styles.header}>
                <span className={styles.title}>{title}</span>
                {icon && <div className={styles.icon}>{icon}</div>}
            </div>

            <div className={styles.value}>{value}</div>

            {trend && (
                <div className={`${styles.trend} ${trend.positive ? styles.positive : styles.negative}`}>
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                        <path
                            d={trend.positive ? "M8 3L13 8L11.5 9.5L9 7V13H7V7L4.5 9.5L3 8L8 3Z" : "M8 13L13 8L11.5 6.5L9 9V3H7V9L4.5 6.5L3 8L8 13Z"}
                            fill="currentColor"
                        />
                    </svg>
                    <span>{trend.value}</span>
                </div>
            )}
        </div>
    );
}
