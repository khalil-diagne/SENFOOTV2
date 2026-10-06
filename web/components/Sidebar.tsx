"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Store,
  BrainCircuit,
  Trophy,
  Users,
  BarChart3,
  BadgeDollarSign,
} from "lucide-react";
import Logo from "@/components/Logo";

const NAV = [
  { href: "/", label: "Tableau de bord", icon: LayoutDashboard },
  { href: "/marketplace", label: "Marketplace", icon: Store },
  { href: "/coach", label: "Coach IA (Scan)", icon: BrainCircuit },
  { href: "/tournaments", label: "Tournois", icon: Trophy },
  { href: "/players", label: "Base de Joueurs", icon: Users },
  { href: "/leaderboard", label: "Classement", icon: BarChart3 },
  { href: "/seller", label: "Espace Vendeur", icon: BadgeDollarSign },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-r border-white/10 bg-night-900/70 px-4 py-6 backdrop-blur-xl md:flex">
      <Link href="/" className="flex items-center gap-3 px-2">
        <Logo className="h-10 w-10" />
        <span className="font-display text-sm font-bold uppercase leading-tight tracking-[0.18em] text-white">
          EFOOT <span className="text-gradient">MARKET</span>
          <br />
          <span className="text-[10px] tracking-[0.35em] text-slate-500">SÉNÉGAL</span>
        </span>
      </Link>

      <nav className="mt-8 flex flex-1 flex-col gap-1">
        {NAV.map((item) => {
          const active = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${
                active
                  ? "border border-neon-cyan/40 bg-neon-cyan/10 text-white shadow-glow-cyan"
                  : "border border-transparent text-slate-400 hover:border-white/10 hover:bg-white/5 hover:text-white"
              }`}
            >
              <Icon
                className={`h-5 w-5 transition ${active ? "text-neon-cyan" : "text-slate-500 group-hover:text-neon-cyan"}`}
              />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="glass-soft mt-4 rounded-2xl p-4">
        <p className="font-display text-xs font-bold uppercase tracking-widest text-neon-yellow">
          Passe Pro
        </p>
        <p className="mt-1 text-xs text-slate-400">
          Scan Coach IA illimité & commissions réduites.
        </p>
        <button className="btn-neon mt-3 py-2 text-xs">Découvrir</button>
      </div>
    </aside>
  );
}