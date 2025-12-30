import type { Metadata } from "next";
import { Providers } from "@/lib/wagmi";
import "./globals.css";

export const metadata: Metadata = {
    title: "TokenBank Permit2",
    description: "使用 Permit2 签名进行代币存款的去中心化银行",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="zh-CN">
            <body>
                <Providers>{children}</Providers>
            </body>
        </html>
    );
}
