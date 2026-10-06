import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EFOOT MARKET SN — Hub eFootball",
  description:
    "Marketplace eFootball sécurisée (escrow) et hub e-sport du Sénégal : coach IA, tournois, classement.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}