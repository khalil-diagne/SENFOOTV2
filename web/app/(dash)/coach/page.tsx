"use client";

import { useRef, useState } from "react";
import {
  UploadCloud,
  Sparkles,
  Target,
  ShieldAlert,
  Link2,
  TrendingUp,
  Receipt,
} from "lucide-react";

const STRENGTHS = ["Attaque en profondeur", "Pressing haut", "Jeu sur les ailes"];
const WEAKNESSES = [
  "Ligne défensive trop haute face aux contre-attaques rapides",
  "Milieu en infériorité sur les seconds ballons",
];
const SYNERGIES = [
  { label: "Messi + Neymar", value: 92 },
  { label: "Van Dijk + Maldini", value: 88 },
  { label: "Gullit + Pirlo", value: 74 },
];
const LINEUPS = ["4-3-3 Attaque", "4-2-1-3 Contre", "4-3-1-2 Possession"];

export default function CoachPage() {
  const [fileName, setFileName] = useState<string | null>(null);
  const [analyzed, setAnalyzed] = useState(false);
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const onFile = (file?: File) => {
    if (!file) return;
    setFileName(file.name);
    setAnalyzed(false);
  };

  return (
    <div className="space-y-6">
      <header>
        <p className="text-xs uppercase tracking-[0.3em] text-neon-cyan">Coach IA</p>
        <h1 className="mt-1 font-display text-2xl font-bold uppercase tracking-wide text-white md:text-3xl">
          Scan &amp; analyse d&apos;effectif
        </h1>
        <p className="mt-2 max-w-2xl text-sm text-slate-400">
          Dépose une capture de ton effectif : l&apos;IA détecte tes forces, faiblesses et
          synergies, puis propose des compositions.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-2">
        <div
          onDragOver={(e) => {
            e.preventDefault();
            setDragging(true);
          }}
          onDragLeave={() => setDragging(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragging(false);
            onFile(e.dataTransfer.files?.[0]);
          }}
          className={`glass flex flex-col items-center justify-center rounded-3xl border-2 border-dashed p-10 text-center transition ${
            dragging ? "border-neon-cyan/70 bg-neon-cyan/10 shadow-glow-cyan" : "border-white/15"
          }`}
        >
          <span className="grid h-14 w-14 place-items-center rounded-2xl bg-neon-cyan/15 text-neon-cyan">
            <UploadCloud className="h-7 w-7" />
          </span>
          <p className="mt-4 font-display text-lg font-semibold uppercase tracking-wide text-white">
            Glisse ta capture ici
          </p>
          <p className="mt-1 text-xs text-slate-400">PNG / JPG — capture d&apos;écran de ton squad</p>

          <input
            ref={inputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => onFile(e.target.files?.[0])}
          />

          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            className="btn-ghost-neon mt-5"
          >
            Choisir un fichier
          </button>

          {fileName && (
            <p className="mt-4 text-xs text-slate-300">
              Fichier : <span className="text-neon-yellow">{fileName}</span>
            </p>
          )}

          <button
            type="button"
            disabled={!fileName}
            onClick={() => setAnalyzed(true)}
            className="btn-neon mt-4 w-auto disabled:cursor-not-allowed disabled:opacity-40"
          >
            <Sparkles className="mr-2 h-4 w-4" />
            Lancer l&apos;analyse IA
          </button>
        </div>

        <div className="glass rounded-3xl p-6">
          {!analyzed ? (
            <div className="flex h-full min-h-[280px] flex-col items-center justify-center text-center">
              <Sparkles className="h-8 w-8 text-slate-600" />
              <p className="mt-3 text-sm text-slate-500">
                Lance une analyse pour afficher le rapport tactique.
              </p>
            </div>
          ) : (
            <div className="space-y-5">
              <div>
                <h2 className="flex items-center gap-2 font-display text-sm font-bold uppercase tracking-wider text-neon-cyan">
                  <Target className="h-4 w-4" /> Points forts
                </h2>
                <div className="mt-2 flex flex-wrap gap-2">
                  {STRENGTHS.map((s) => (
                    <span key={s} className="chip border-neon-cyan/40 text-neon-cyan">
                      {s}
                    </span>
                  ))}
                </div>
              </div>

              <div>
                <h2 className="flex items-center gap-2 font-display text-sm font-bold uppercase tracking-wider text-amber-300">
                  <ShieldAlert className="h-4 w-4" /> Faiblesses tactiques
                </h2>
                <ul className="mt-2 space-y-1.5 text-sm text-slate-300">
                  {WEAKNESSES.map((w) => (
                    <li key={w} className="flex gap-2">
                      <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-amber-300" />
                      {w}
                    </li>
                  ))}
                </ul>
              </div>

              <div>
                <h2 className="flex items-center gap-2 font-display text-sm font-bold uppercase tracking-wider text-neon-yellow">
                  <Link2 className="h-4 w-4" /> Synergies
                </h2>
                <div className="mt-3 space-y-3">
                  {SYNERGIES.map((s) => (
                    <div key={s.label}>
                      <div className="flex justify-between text-xs text-slate-400">
                        <span>{s.label}</span>
                        <span className="text-slate-200">{s.value}%</span>
                      </div>
                      <div className="mt-1 h-2 overflow-hidden rounded-full bg-white/10">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-neon-yellow to-neon-cyan"
                          style={{ width: `${s.value}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div>
                <h2 className="font-display text-sm font-bold uppercase tracking-wider text-white">
                  Compositions recommandées
                </h2>
                <div className="mt-2 flex flex-wrap gap-2">
                  {LINEUPS.map((l) => (
                    <span key={l} className="chip">
                      {l}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      <PackCalculator />
    </div>
  );
}

function PackCalculator() {
  const [packPrice, setPackPrice] = useState(5000);
  const [expectedValue, setExpectedValue] = useState(7200);

  return (
    <section className="glass rounded-3xl p-6">
      <h2 className="flex items-center gap-2 font-display text-lg font-bold uppercase tracking-wide text-white">
        <Receipt className="h-5 w-5 text-neon-cyan" /> Calculateur de packs
      </h2>
      <p className="mt-1 text-sm text-slate-400">
        Estime la rentabilité d&apos;un pack eFootball avant de l&apos;ouvrir.
      </p>

      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <NumberField
          label="Prix du pack (FCFA)"
          value={packPrice}
          onChange={setPackPrice}
        />
        <NumberField
          label="Valeur estimée des joueurs (FCFA)"
          value={expectedValue}
          onChange={setExpectedValue}
        />
      </div>

      <div className="mt-5 flex flex-wrap items-center gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-4">
        <div className="flex items-center gap-2">
          <TrendingUp className={`h-5 w-5 ${packPrice && expectedValue - packPrice >= 0 ? "text-emerald-300" : "text-red-400"}`} />
          <span className="text-xs uppercase tracking-widest text-slate-400">Rentabilité nette</span>
        </div>
        <span
          className={`font-display text-2xl font-bold ${
            expectedValue - packPrice >= 0 ? "text-emerald-300" : "text-red-400"
          }`}
        >
          {expectedValue - packPrice >= 0 ? "+" : ""}
          {formatXof(expectedValue - packPrice)}
        </span>
        <span className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-slate-300">
          ROI {expectedValue >= packPrice ? "+" : ""}
          {packPrice > 0 ? Math.round(((expectedValue - packPrice) / packPrice) * 100) : 0}%
        </span>
      </div>
    </section>
  );
}

function NumberField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (v: number) => void;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-medium uppercase tracking-wider text-slate-400">
        {label}
      </span>
      <input
        type="number"
        min={0}
        value={value ?? 0}
        onChange={(e) => onChange(Number(e.target.value))}
        className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-slate-100 outline-none transition focus:border-neon-cyan/60 focus:shadow-glow-cyan"
      />
    </label>
  );
}

function formatXof(value: number) {
  return new Intl.NumberFormat("fr-SN", { maximumFractionDigits: 0 }).format(value) + " FCFA";
}