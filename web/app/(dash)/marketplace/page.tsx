"use client";

import { useState } from "react";
import { SlidersHorizontal, Search } from "lucide-react";
import ListingCard, { type Listing } from "@/components/ListingCard";
import EscrowModal from "@/components/EscrowModal";
import { listings } from "@/lib/mock";

const POWER_FILTERS = ["Toutes", "3000+", "3200+", "3300+"];
const PLATFORM_FILTERS = ["Toutes", "iOS", "Android", "PlayStation", "Xbox", "PC"];

export default function MarketplacePage() {
  const [power, setPower] = useState("Toutes");
  const [platform, setPlatform] = useState("Toutes");
  const [selected, setSelected] = useState<Listing | null>(null);

  const filtered = listings.filter((l) => {
    const powerOk =
      power === "Toutes" || l.power >= Number.parseInt(power.replace("+", ""), 10);
    const platformOk = platform === "Toutes" || l.platform === platform;
    return powerOk && platformOk;
  });

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-neon-cyan">Marketplace</p>
          <h1 className="mt-1 font-display text-2xl font-bold uppercase tracking-wide text-white md:text-3xl">
            Comptes eFootball
          </h1>
        </div>
        <div className="relative w-full max-w-xs">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
          <input
            placeholder="Puissance, joueur, vendeur..."
            className="w-full rounded-xl border border-white/10 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-slate-100 placeholder:text-slate-500 outline-none transition focus:border-neon-cyan/60 focus:shadow-glow-cyan"
          />
        </div>
      </header>

      <div className="glass space-y-4 rounded-2xl p-4">
        <div className="flex items-center gap-2 text-xs uppercase tracking-widest text-slate-500">
          <SlidersHorizontal className="h-4 w-4 text-neon-cyan" />
          Filtres
        </div>
        <FilterRow label="Puissance" options={POWER_FILTERS} value={power} onChange={setPower} />
        <FilterRow
          label="Plateforme"
          options={PLATFORM_FILTERS}
          value={platform}
          onChange={setPlatform}
        />
      </div>

      <p className="text-xs uppercase tracking-widest text-slate-500">
        {filtered.length} annonce{filtered.length > 1 ? "s" : ""}
      </p>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {filtered.map((listing) => (
          <ListingCard key={listing.id} listing={listing} onBuy={() => setSelected(listing)} />
        ))}
      </div>

      <EscrowModal listing={selected} onClose={() => setSelected(null)} />
    </div>
  );
}

function FilterRow({
  label,
  options,
  value,
  onChange,
}: {
  label: string;
  options: string[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="w-24 shrink-0 text-xs font-medium text-slate-400">{label}</span>
      {options.map((option) => (
        <button
          key={option}
          type="button"
          onClick={() => onChange(option)}
          className={`chip ${value === option ? "border-neon-cyan/60 bg-neon-cyan/15 text-white shadow-glow-cyan" : ""}`}
        >
          {option}
        </button>
      ))}
    </div>
  );
}