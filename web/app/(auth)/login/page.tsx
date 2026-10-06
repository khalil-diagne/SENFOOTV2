"use client";

import { useState } from "react";
import Link from "next/link";
import { Mail, Lock, Eye, EyeOff, ShieldCheck, Zap } from "lucide-react";
import StadiumBackdrop from "@/components/StadiumBackdrop";
import Logo from "@/components/Logo";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
  };

  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden px-4 py-12">
      <StadiumBackdrop />

      <div className="relative z-10 w-full max-w-md">
        <div className="mb-8 flex flex-col items-center text-center">
          <Logo className="h-16 w-16" />
          <h1 className="mt-5 font-display text-3xl font-bold uppercase tracking-[0.2em]">
            EFOOT <span className="text-gradient">MARKET</span> SN
          </h1>
          <p className="mt-2 text-sm text-slate-400">
            Le hub eFootball du Sénégal — marketplace escrow &amp; e-sport
          </p>
        </div>

        <section className="glass rounded-3xl p-8 shadow-2xl shadow-black/50">
          <header className="mb-6">
            <h2 className="font-display text-xl font-semibold uppercase tracking-wider text-white">
              Connexion
            </h2>
            <p className="mt-1 text-sm text-slate-400">Accède à ton espace compétiteur.</p>
          </header>

          <form onSubmit={onSubmit} className="space-y-4">
            <Field icon={<Mail className="h-4 w-4" />} label="Adresse e-mail">
              <input
                type="email"
                autoComplete="email"
                placeholder="vendeur@efoot.sn"
                className="input-neon"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </Field>

            <Field icon={<Lock className="h-4 w-4" />} label="Mot de passe">
              <input
                type={showPassword ? "text" : "password"}
                autoComplete="current-password"
                placeholder="••••••••"
                className="input-neon"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 transition hover:text-neon-cyan"
                aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"}
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </Field>

            <div className="flex items-center justify-between text-sm">
              <label className="inline-flex cursor-pointer items-center gap-2 text-slate-400">
                <input
                  type="checkbox"
                  checked={remember}
                  onChange={(e) => setRemember(e.target.checked)}
                  className="h-4 w-4 rounded border-white/20 bg-white/5 accent-neon-cyan"
                />
                Se souvenir de moi
              </label>
              <Link href="/forgot" className="text-neon-cyan transition hover:text-neon-yellow">
                Mot de passe oublié ?
              </Link>
            </div>

            <button type="submit" className="btn-neon">
              Se connecter
            </button>
          </form>

          <div className="my-6 flex items-center gap-3 text-xs uppercase tracking-widest text-slate-500">
            <span className="h-px flex-1 bg-white/10" />
            ou
            <span className="h-px flex-1 bg-white/10" />
          </div>

          <div className="grid grid-cols-3 gap-3">
            <SocialButton provider="Google" glyph="G" />
            <SocialButton provider="Facebook" glyph="f" />
            <SocialButton provider="Discord" glyph="D" />
          </div>

          <p className="mt-6 text-center text-sm text-slate-400">
            Pas encore de compte ?{" "}
            <Link href="/register" className="font-semibold text-neon-yellow hover:underline">
              Créer un compte
            </Link>
          </p>
        </section>

        <div className="mt-6 flex flex-wrap items-center justify-center gap-2 text-center text-xs text-slate-500">
          <ShieldCheck className="h-4 w-4 text-neon-cyan" />
          Transactions 100% sécurisées
          <span className="text-slate-700">•</span>
          <Zap className="h-4 w-4 text-neon-yellow" />
          Retraits Wave &amp; Orange Money
        </div>
      </div>
    </main>
  );
}

function Field({
  icon,
  label,
  children,
}: {
  icon: React.ReactNode;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-medium uppercase tracking-wider text-slate-400">
        {label}
      </span>
      <span className="relative block">
        <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-500">
          {icon}
        </span>
        {children}
      </span>
    </label>
  );
}

function SocialButton({ provider, glyph }: { provider: string; glyph: string }) {
  return (
    <button
      type="button"
      className="glass-soft flex items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-sm font-medium text-slate-200 transition hover:border-neon-cyan/40 hover:text-white"
    >
      <span className="font-display text-base font-bold text-neon-cyan">{glyph}</span>
      <span className="hidden sm:inline">{provider}</span>
    </button>
  );
}