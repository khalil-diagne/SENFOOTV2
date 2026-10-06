import { Trophy, Swords, Coins } from "lucide-react";

interface Match {
  a: string;
  b: string;
  winner: "a" | "b";
}

const BRACKET: { round: string; matches: Match[] }[] = [
  {
    round: "Quarts de finale",
    matches: [
      { a: "DakarWinner", b: "LionPro", winner: "a" },
      { a: "AtlasGG", b: "SaloumGamer", winner: "a" },
      { a: "TerangaFC", b: "SaintLouisPro", winner: "b" },
      { a: "BaolEsport", b: "CasamanceGG", winner: "a" },
    ],
  },
  {
    round: "Demi-finales",
    matches: [
      { a: "DakarWinner", b: "AtlasGG", winner: "a" },
      { a: "SaintLouisPro", b: "BaolEsport", winner: "b" },
    ],
  },
  {
    round: "Finale",
    matches: [{ a: "DakarWinner", b: "BaolEsport", winner: "a" }],
  },
];

const TOURNAMENTS = [
  { name: "Coupe du Sénégal eFootball", fee: "2 000", prize: "250 000", players: 128, status: "Inscriptions ouvertes" },
  { name: "Dakar League — Saison 4", fee: "5 000", prize: "600 000", players: 64, status: "En cours" },
  { name: "Teranga Cup (mobile)", fee: "1 000", prize: "80 000", players: 96, status: "À venir" },
];

export default function TournamentsPage() {
  return (
    <div className="space-y-8">
      <header>
        <p className="text-xs uppercase tracking-[0.3em] text-neon-cyan">Compétition</p>
        <h1 className="mt-1 font-display text-2xl font-bold uppercase tracking-wide text-white md:text-3xl">
          Tournois &amp; Bracket
        </h1>
      </header>

      <section className="space-y-4">
        {TOURNAMENTS.map((t) => (
          <div
            key={t.name}
            className="glass flex flex-wrap items-center justify-between gap-4 rounded-2xl p-5 transition hover:border-neon-cyan/40"
          >
            <div className="flex items-center gap-4">
              <span className="grid h-11 w-11 place-items-center rounded-xl bg-neon-yellow/10 text-neon-yellow">
                <Trophy className="h-5 w-5" />
              </span>
              <div>
                <h2 className="font-display text-base font-semibold uppercase tracking-wide text-white">
                  {t.name}
                </h2>
                <p className="text-xs text-slate-400">{t.players} joueurs inscrits</p>
              </div>
            </div>
            <div className="flex items-center gap-6">
              <Stat label="Entrée" value={`${t.fee} FCFA`} />
              <Stat label="Cagnotte" value={`${t.prize} FCFA`} />
              <span className="chip border-neon-cyan/40 text-neon-cyan">{t.status}</span>
            </div>
          </div>
        ))}
      </section>

      <section className="glass rounded-3xl p-5 md:p-6">
        <h2 className="flex items-center gap-2 font-display text-lg font-bold uppercase tracking-wide text-white">
          <Swords className="h-5 w-5 text-neon-cyan" /> Bracket — Coupe du Sénégal
        </h2>

        <div className="mt-6 flex gap-8 overflow-x-auto pb-4">
          {BRACKET.map((round) => (
            <div key={round.round} className="flex min-w-[220px] flex-col justify-around gap-4">
              <p className="text-center text-xs uppercase tracking-widest text-slate-500">
                {round.round}
              </p>
              {round.matches.map((match, i) => (
                <MatchCard key={`${round.round}-${i}`} match={match} />
              ))}
            </div>
          ))}

          <div className="flex min-w-[200px] flex-col justify-center">
            <p className="text-center text-xs uppercase tracking-widest text-slate-500">Champion</p>
            <div className="glass mt-4 flex flex-col items-center rounded-2xl border-neon-yellow/40 p-5 shadow-glow-yellow">
              <Trophy className="h-8 w-8 text-neon-yellow" />
              <span className="mt-2 font-display text-lg font-bold uppercase tracking-wide text-neon-yellow">
                DakarWinner
              </span>
              <span className="text-xs text-slate-400">250 000 FCFA</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

function MatchCard({ match }: { match: Match }) {
  return (
    <div className="glass-soft overflow-hidden rounded-xl">
      <PlayerRow name={match.a} winner={match.winner === "a"} />
      <div className="h-px bg-white/5" />
      <PlayerRow name={match.b} winner={match.winner === "b"} />
    </div>
  );
}

function PlayerRow({ name, winner }: { name: string; winner: boolean }) {
  return (
    <div className={`flex items-center justify-between px-3 py-2 text-sm ${winner ? "text-white" : "text-slate-500"}`}>
      <span className={winner ? "font-semibold" : ""}>{name}</span>
      {winner && <span className="rounded-full bg-neon-cyan/20 px-2 py-0.5 text-[10px] font-bold uppercase text-neon-cyan">W</span>}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="text-right">
      <p className="flex items-center justify-end gap-1 text-[10px] uppercase tracking-widest text-slate-500">
        <Coins className="h-3 w-3" /> {label}
      </p>
      <p className="font-display text-sm font-bold text-neon-yellow">{value}</p>
    </div>
  );
}