import Link from "next/link";
import {
  ShieldCheck,
  TrendingUp,
  Star,
  Trophy,
  BrainCircuit,
  PackageSearch,
  ChevronRight,
} from "lucide-react";
import ListingCard from "@/components/ListingCard";
import { listings } from "@/lib/mock";

const STATS = [
  { label: "Comptes vendus", value: "1 248", icon: ShieldCheck, tone: "text-neon-cyan" },
  { label: "Volume sécurisé", value: "18,4M FCFA", icon: TrendingUp, tone: "text-neon-yellow" },
  { label: "Note vendeur", value: "4.9 / 5", icon: Star, tone: "text-neon-yellow" },
  { label: "Tournois actifs", value: "6", icon: Trophy, tone: "text-neon-cyan" },
];

const TOOLS = [
  {
    href: "/coach",
    title: "Coach IA — Scan d'effectif",
    text: "Dépose une capture et obtiens forces, faiblesses et compositions recommandées.",
    icon: BrainCircuit,
  },
  {
    href: "/coach",
    title: "Analyse de packs",
    text: "Évalue la rentabilité des packs eFootball en un clic.",
    icon: PackageSearch,
  },
  {
    href: "/leaderboard",
    title: "Classement national",
    text: "Compare-toi aux meilleurs joueurs et vendeurs du Sénégal.",
    icon: Trophy,
  },
];

export default function DashboardPage() {
  return (
    <div className="space-y-8">
      <section className="glass relative overflow-hidden rounded-3xl p-6 md:p-8">
        <div className="absolute -right-16 -top-16 h-48 w-48 rounded-full bg-neon-cyan/20 blur-3xl" />
        <div className="relative">
          <p className="text-xs uppercase tracking-[0.3em] text-neon-cyan">Tableau de bord</p>
          <h1 className="mt-2 font-display text-2xl font-bold uppercase tracking-wide text-white md:text-3xl">
            Salut <span className="text-gradient">VendeurSN</span>
          </h1>
          <p className="mt-2 max-w-xl text-sm text-slate-400">
            Ta marketplace escrow et tes outils e-sport, réunis dans un seul hub.
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link href="/marketplace" className="btn-neon w-auto">
              Explorer la marketplace
            </Link>
            <Link href="/coach" className="btn-ghost-neon">
              Scanner mon équipe
            </Link>
          </div>
        </div>
      </section>

      <section className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {STATS.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.label} className="glass rounded-2xl p-4">
              <Icon className={`h-5 w-5 ${stat.tone}`} />
              <p className="mt-3 font-display text-2xl font-bold text-white">{stat.value}</p>
              <p className="text-xs uppercase tracking-wider text-slate-500">{stat.label}</p>
            </div>
          );
        })}
      </section>

      <section className="grid gap-4 lg:grid-cols-3">
        {TOOLS.map((tool) => {
          const Icon = tool.icon;
          return (
            <Link
              key={tool.title}
              href={tool.href}
              className="glass group flex flex-col rounded-2xl p-5 transition hover:border-neon-cyan/40 hover:shadow-glow-cyan"
            >
              <span className="grid h-11 w-11 place-items-center rounded-xl bg-neon-cyan/10 text-neon-cyan">
                <Icon className="h-5 w-5" />
              </span>
              <h2 className="mt-4 font-display text-base font-semibold uppercase tracking-wide text-white">
                {tool.title}
              </h2>
              <p className="mt-1 flex-1 text-sm text-slate-400">{tool.text}</p>
              <span className="mt-3 inline-flex items-center gap-1 text-xs font-semibold text-neon-yellow">
                Ouvrir <ChevronRight className="h-4 w-4 transition group-hover:translate-x-1" />
              </span>
            </Link>
          );
        })}
      </section>

      <section>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="font-display text-lg font-bold uppercase tracking-wide text-white">
            Annonces à la une
          </h2>
          <Link href="/marketplace" className="text-sm text-neon-cyan transition hover:text-neon-yellow">
            Tout voir
          </Link>
        </div>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {listings.slice(0, 3).map((listing) => (
            <ListingCard key={listing.id} listing={listing} />
          ))}
        </div>
      </section>
    </div>
  );
}