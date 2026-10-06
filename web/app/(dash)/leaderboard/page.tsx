"use client";

import { useState } from "react";
import { BarChart3, Star, TrendingUp } from "lucide-react";

interface PlayerRow {
  name: string;
  region: string;
  points: number;
  winrate: number;
}

interface SellerRow {
  name: string;
  region: string;
  rating: number;
  sales: number;
}

const PLAYERS: PlayerRow[] = [
  { name: "DakarWinner", region: "Dakar", points: 4820, winrate: 78 },
  { name: "AtlasGG", region: "Thiès", points: 4610, winrate: 74 },
  { name: "LionPro", region: "Saint-Louis", points: 4385, winrate: 71 },
  { name: "BaolEsport", region: "Diourbel", points: 4120, winrate: 69 },
  { name: "TerangaFC", region: "Ziguinchor", points: 3990, winrate: 66 },
  { name: "SaloumGamer", region: "Kaolack", points: 3810, winrate: 63 },
];

const SELLERS: SellerRow[] = [
  { name: "AtlasGG", region: "Thiès", rating: 4.9, sales: 240 },
  { name: "DakarWinner", region: "Dakar", rating: 4.8, sales: 132 },
  { name: "TerangaFC", region: "Ziguinchor", rating: 4.7, sales: 76 },
  { name: "SaintLouisPro", region: "Saint-Louis", rating: 4.6, sales: 58 },
  { name: "LionPro", region: "Dakar", rating: 4.4, sales: 21 },
  { name: "SaloumGamer", region: "Kaolack", rating: 4.2, sales: 9 },
];

type Mode = "players" | "sellers";

export default function LeaderboardPage() {
  const [mode, setMode] = useState<Mode>("players");

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-neon-cyan">Sénégal</p>
          <h1 className="mt-1 font-display text-2xl font-bold uppercase tracking-wide text-white md:text-3xl">
            Classement national
          </h1>
        </div>
        <div className="glass flex rounded-xl p-1">
          {(
            [
              { key: "players", label: "Joueurs" },
              { key: "sellers", label: "Vendeurs" },
            ] as const
          ).map((item) => (
            <button
              key={item.key}
              type="button"
              onClick={() => setMode(item.key)}
              className={`rounded-lg px-4 py-2 font-display text-xs font-bold uppercase tracking-wider transition ${
                mode === item.key
                  ? "bg-neon-cyan/15 text-neon-cyan shadow-glow-cyan"
                  : "text-slate-400 hover:text-white"
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      </header>

      <section className="glass overflow-hidden rounded-2xl">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-white/10 text-[11px] uppercase tracking-widest text-slate-500">
            <tr>
              <th className="px-4 py-3">#</th>
              <th className="px-4 py-3">Joueur</th>
              <th className="px-4 py-3">Région</th>
              <th className="px-4 py-3 text-right">
                {mode === "players" ? "Points" : "Note"}
              </th>
              <th className="px-4 py-3 text-right">
                {mode === "players" ? "Winrate" : "Ventes"}
              </th>
            </tr>
          </thead>
          <tbody>
            {mode === "players"
              ? PLAYERS.map((row, i) => (
                  <tr key={row.name} className="border-b border-white/5 last:border-0 hover:bg-white/5">
                    <RankCell rank={i + 1} />
                    <td className="px-4 py-3 font-medium text-white">{row.name}</td>
                    <td className="px-4 py-3 text-slate-400">{row.region}</td>
                    <td className="px-4 py-3 text-right font-display font-bold text-neon-yellow">
                      {row.points}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <span className="inline-flex items-center gap-1 text-emerald-300">
                        <TrendingUp className="h-3.5 w-3.5" />
                        {row.winrate}%
                      </span>
                    </td>
                  </tr>
                ))
              : SELLERS.map((row, i) => (
                  <tr key={row.name} className="border-b border-white/5 last:border-0 hover:bg-white/5">
                    <RankCell rank={i + 1} />
                    <td className="px-4 py-3 font-medium text-white">{row.name}</td>
                    <td className="px-4 py-3 text-slate-400">{row.region}</td>
                    <td className="px-4 py-3 text-right">
                      <span className="inline-flex items-center justify-end gap-1 font-display font-bold text-neon-yellow">
                        <Star className="h-3.5 w-3.5 fill-neon-yellow" />
                        {row.rating.toFixed(1)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right text-slate-300">{row.sales}</td>
                  </tr>
                ))}
          </tbody>
        </table>
      </section>

      <p className="flex items-center gap-2 text-xs text-slate-500">
        <BarChart3 className="h-4 w-4 text-neon-cyan" />
        Classement mis à jour en temps réel selon les matchs &amp; ventes escrow.
      </p>
    </div>
  );
}

function RankCell({ rank }: { rank: number }) {
  return (
    <td className="px-4 py-3">
      <span className={`grid h-7 w-7 place-items-center rounded-lg font-display text-xs font-bold ${rank <= 3 ? cellTone(rank) : "bg-white/5 text-slate-400"}`}>
        {rank}
      </span>
    </td>
  );
}

function cellTone(rank: number) {
  if (rank === 1) return "bg-neon-yellow/20 text-neon-yellow";
  if (rank === 2) return "bg-white/15 text-slate-200";
  return "bg-amber-600/20 text-amber-300";
}