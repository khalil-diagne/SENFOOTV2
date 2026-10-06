"use client";

import { Bell, Search, Moon, Plus, Wallet } from "lucide-react";
import Link from "next/link";

export default function Topbar() {
  return (
    <header className="sticky top-0 z-40 flex h-16 items-center gap-4 border-b border-white/10 bg-night-900/70 px-4 backdrop-blur-xl md:px-8">
      <div className="relative hidden flex-1 sm:block">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
        <input
          placeholder="Rechercher un compte, un joueur, un vendeur..."
          className="w-full max-w-md rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-slate-100 placeholder:text-slate-500 outline-none transition focus:border-neon-cyan/60 focus:shadow-glow-cyan"
        />
      </div>

      <div className="ml-auto flex items-center gap-2 md:gap-3">
        <Link href="/marketplace" className="btn-neon hidden w-auto px-4 py-2 text-xs sm:inline-flex">
          <Plus className="mr-1 h-4 w-4" />
          Vendre un compte
        </Link>

        <div className="hidden items-center gap-2 rounded-xl border border-neon-yellow/30 bg-neon-yellow/10 px-3 py-2 sm:flex">
          <Wallet className="h-4 w-4 text-neon-yellow" />
          <span className="font-display text-sm font-bold text-neon-yellow">45 000 FCFA</span>
        </div>

        <button className="relative rounded-xl border border-white/10 bg-white/5 p-2.5 text-slate-300 transition hover:text-white">
          <Bell className="h-4 w-4" />
          <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-neon-cyan shadow-glow-cyan" />
        </button>

        <button className="rounded-xl border border-white/10 bg-white/5 p-2.5 text-slate-300 transition hover:text-white">
          <Moon className="h-4 w-4" />
        </button>

        <button className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 p-1 pr-3 transition hover:border-neon-cyan/40">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-gradient-to-br from-neon-cyan/40 to-neon-yellow/40 font-display text-sm font-bold text-night-900">
            V
          </span>
          <span className="hidden text-left leading-tight sm:block">
            <span className="block text-xs font-semibold text-white">VendeurSN</span>
            <span className="block text-[10px] text-slate-500">Vendeur vérifié</span>
          </span>
        </button>
      </div>
    </header>
  );
}