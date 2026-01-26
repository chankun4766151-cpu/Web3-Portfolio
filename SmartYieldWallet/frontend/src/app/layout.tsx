import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Web3Provider } from "@/components/Web3Provider";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "SmartYield Wallet | Institutional Yield. For Everyone.",
  description: "A multi-functional DeFi wallet with auto-yield optimization, cross-chain bridge aggregation, and arbitrage detection.",
  keywords: ["DeFi", "Yield", "Cross-chain", "Arbitrage", "Wallet", "Web3"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} font-sans antialiased bg-gray-950 text-white`}>
        <Web3Provider>
          {children}
        </Web3Provider>
      </body>
    </html>
  );
}
