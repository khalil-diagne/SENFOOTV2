"use client";

import { useEffect, useState } from "react";
import { CreditCard, KeyRound, ShieldCheck, X, Check } from "lucide-react";
import { formatFcfa } from "@/lib/format";
import type { Listing } from "@/components/ListingCard";

const STEPS = [
  {
    title: "Paiement sous séquestre",
    text: "Le montant est bloqué dans un compte tiers sécurisé (escrow).",
    icon: CreditCard,
  },
  {
    title: "Transfert du Konami ID",
    text: "Le vendeur transfère l'accès au compte eFootball et le joueur vérifie.",
    icon: KeyRound,
  },
  {
    title: "Validation & libération",
    text: "L'acheteur confirme. Les fonds sont libérés au vendeur.",
    icon: ShieldCheck,
  },
];

export default function EscrowModal({
  listing,
  onClose,
}: {
  listing: Listing | null;
  onClose: () => void;
}) {
  const [step, setStep] = useState(0);

  useEffect(() => {
    setStep(0);
  }, [listing]);

  if (!listing) return null;

  const isLast = step === STEPS.length - 1;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button
        aria-label="Fermer"
        onClick={onClose}
        className="absolute inset-0 bg-black/70 backdrop-blur-sm"
      />
      <div className="glass relative w-full max-w-lg rounded-3xl p-6 shadow-2xl shadow-black/60">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-neon-cyan">Transaction sécurisée</p>
            <h2 className="mt-1 font-display text-xl font-bold uppercase tracking-wide text-white">
              Achat via Escrow
            </h2>
            <p className="mt-1 line-clamp-1 text-sm text-slate-400">{listing.title}</p>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg border border-white/10 bg-white/5 p-1.5 text-slate-400 transition hover:text-white"
            aria-label="Fermer"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="mt-6 space-y-3">
          {STEPS.map((item, index) => {
            const done = index < step;
            const active = index === step;
            const Icon = item.icon;
            return (
              <div
                key={item.title}
                className={`flex items-start gap-3 rounded-2xl border p-3 transition ${
                  active
                    ? "border-neon-cyan/50 bg-neon-cyan/10 shadow-glow-cyan"
                    : "border-white/10 bg-white/5"
                }`}
              >
                <span
                  className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl ${
                    done
                      ? "bg-emerald-400/20 text-emerald-300"
                      : active
                        ? "bg-neon-cyan/20 text-neon-cyan"
                        : "bg-white/5 text-slate-500"
                  }`}
                >
                  {done ? <Check className="h-4 w-4" /> : <Icon className="h-4 w-4" />}
                </span>
                <div>
                  <p className="text-sm font-semibold text-white">
                    {index + 1}. {item.title}
                  </p>
                  <p className="mt-0.5 text-xs text-slate-400">{item.text}</p>
                </div>
              </div>
            );
          })}
        </div>

        <div className="mt-6 flex items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
          <span className="text-xs uppercase tracking-widest text-slate-400">Montant séquestré</span>
          <span className="font-display text-lg font-bold text-neon-yellow">
            {formatFcfa(listing.priceFcfa)}
          </span>
        </div>

        <div className="mt-5 flex gap-3">
          <button onClick={onClose} className="btn-ghost-neon flex-1">
            Annuler
          </button>
          <button
            onClick={() => (isLast ? onClose() : setStep((s) => s + 1))}
            className="btn-neon flex-1"
          >
            {isLast ? "Libérer les fonds" : step === 0 ? "Payer via Wave" : "Étape suivante"}
          </button>
        </div>
      </div>
    </div>
  );
}