"use client";

import { ShieldCheck, Star, Users } from "lucide-react";
import { formatFcfa } from "@/lib/format";

export type Platform = "iOS" | "Android" | "PlayStation" | "Xbox" | "PC";

export interface Listing {
  id: string;
  title: string;
  power: number;
  platform: Platform;
  priceFcfa: number;
  stars: string[];
  seller: { name: string; verified: boolean; rating: number; sales: number };
  imageUrl?: string;
}

const PLATFORM_STYLE: Record<Platform, string> = {
  iOS: "border-neon-cyan/30 bg-neon-cyan/10 text-neon-cyan",
  Android: "border-emerald-400/30 bg-emerald-400/10 text-emerald-300",
  PlayStation: "border-sky-400/30 bg-sky-400/10 text-sky-300",
  Xbox: "border-green-400/30 bg-green-400/10 text-green-300",
  PC: "border-violet-400/30 bg-violet-400/10 text-violet-300",
};

export default function ListingCard({
  listing,
  onBuy,
}: {
  listing: Listing;
  onBuy?: (id: string) => void;
}) {
  const { seller } = listing;

  return (
    <article className="group relative overflow-hidden rounded-2xl border border-white/10 glass transition duration-300 hover:-translate-y-1 hover:border-neon-cyan/40 hover:shadow-glow-cyan">
      <div className="relative h-40 overflow-hidden">
        {listing.imageUrl ? (
          <img
            src={listing.imageUrl}
            alt={listing.title}
            className="h-full w-full object-cover opacity-80 transition duration-500 group-hover:scale-105 group-hover:opacity-100"
          />
        ) : (
          <div className="h-full w-full bg-gradient-to-br from-night-800 via-night-900 to-black" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-night via-night/40 to-transparent" />

        <div className="absolute left-3 top-3 flex flex-col items-center rounded-xl border border-neon-yellow/30 bg-black/50 px-3 py-2 backdrop-blur-md">
          <span className="font-display text-2xl font-bold leading-none text-neon-yellow">
            {listing.power}
          </span>
          <span className="mt-1 text-[10px] uppercase tracking-widest text-slate-400">
            Puissance
          </span>
        </div>

        <span
          className={`absolute right-3 top-3 rounded-full border px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wider backdrop-blur-md ${PLATFORM_STYLE[listing.platform]}`}
        >
          {listing.platform}
        </span>
      </div>

      <div className="space-y-4 p-4">
        <h3 className="line-clamp-1 font-display text-base font-semibold uppercase tracking-wide text-white">
          {listing.title}
        </h3>

        <div className="flex flex-wrap gap-1.5">
          {listing.stars.slice(0, 4).map((player) => (
            <span
              key={player}
              className="rounded-md border border-white/10 bg-white/5 px-2 py-0.5 text-[11px] font-medium text-slate-300"
            >
              {player}
            </span>
          ))}
          {listing.stars.length > 4 && (
            <span className="rounded-md border border-white/10 bg-white/5 px-2 py-0.5 text-[11px] text-slate-400">
              +{listing.stars.length - 4}
            </span>
          )}
        </div>

        <div className="flex items-center justify-between border-t border-white/5 pt-3">
          <div className="flex items-center gap-2">
            <span className="grid h-8 w-8 place-items-center rounded-full bg-gradient-to-br from-neon-cyan/30 to-neon-yellow/30 text-xs font-bold text-white">
              {seller.name.charAt(0).toUpperCase()}
            </span>
            <div className="leading-tight">
              <div className="flex items-center gap-1 text-xs font-medium text-slate-200">
                {seller.name}
                {seller.verified && <ShieldCheck className="h-3.5 w-3.5 text-neon-cyan" />}
              </div>
              <div className="flex items-center gap-2 text-[11px] text-slate-500">
                <span className="inline-flex items-center gap-0.5 text-neon-yellow">
                  <Star className="h-3 w-3 fill-neon-yellow" />
                  {seller.rating.toFixed(1)}
                </span>
                <span className="inline-flex items-center gap-0.5">
                  <Users className="h-3 w-3" />
                  {seller.sales} ventes
                </span>
              </div>
            </div>
          </div>
          <span className="font-display text-lg font-bold text-neon-yellow">
            {formatFcfa(listing.priceFcfa)}
          </span>
        </div>

        <button
          type="button"
          onClick={() => onBuy?.(listing.id)}
          className="w-full rounded-xl bg-gradient-to-r from-neon-yellow to-amber-400 py-2.5 font-display text-sm font-bold uppercase tracking-widest text-night-900 transition hover:brightness-110 active:scale-[0.98]"
        >
          Acheter via Escrow
        </button>
      </div>
    </article>
  );
}