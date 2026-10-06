"use client";

import { useState } from "react";
import Link from "next/link";
import { Mail, Lock, User, Eye, EyeOff, ShieldCheck, Zap } from "lucide-react";
import Logo from "@/components/Logo";
import StadiumBackdrop from "@/components/StadiumBackdrop";

export default function RegisterPage() {
  const [role, setRole] = useState<"buyer" | "seller">("buyer");
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const mismatch = confirm.length > 0 && confirm !== password;

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
  };

  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden px-4 py-12">
      <StadiumBackdrop />

      <div className="relative z-10 w-full max-w-md">
        <div className="mb-6 flex flex-col items-center text-center">
          <Logo className="h-10 w-10" />
          <h1 className="mt-4 font-display text-2xl font-bold uppercase tracking-[0.2em]">
            Créer un compte
          </h1>
          <p className="mt-1 text-sm text-slate-400">Rejoins le hub eFootball du Sénégal.</p>
        </div>

        <section className="glass rounded-3xl p-8 shadow-2xl shadow-black/50">
          <div className="mb-6 grid grid-cols-2 gap-2">
            {(["buyer", "seller"] as const).map((item) => (
              <button
                key={item}
                type="button"
                onClick={() => setRole(item)}
                className={`rounded-xl border px-3 py-2 text-sm font-medium transition ${
                  role === item
                    ? "border-neon-cyan/50 bg-neon-cyan/10 text-white shadow-glow-cyan"
                    : "border-white/10 bg-white/5 text-slate-400 hover:text-white"
                }`}
              >
                {item === "buyer" ? "Acheteur" : "Vendeur"}
              </button>
            ))}
          </div>

          <form onSubmit={onSubmit} className="space-y-4">
            <Field icon={<User className="h-4 w-4" />} label="Nom complet">
              <input
                type="text"
                placeholder="Moussa Ndiaye"
                className="input-neon"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                required
              />
            </Field>

            <Field icon={<Mail className="h-4 w-4" />} label="Adresse e-mail">
              <input
                type="email"
                autoComplete="email"
                placeholder="joueur@efoot.sn"
                className="input-neon"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </Field>

            <Field icon={<Lock className="h-4 w-4" />} label="Mot de passe">
              <input
                type={showPassword ? "text" : "password"}
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
                aria-label="Afficher le mot de passe"
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </Field>

            <Field icon={<Lock className="h-4 w-4" />} label="Confirmer le mot de passe">
              <input
                type={showPassword ? "text" : "password"}
                placeholder="••••••••"
                className={`input-neon ${mismatch ? "border-red-500/60" : ""}`}
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                required
              />
            </Field>

            {mismatch && (
              <p className="text-xs text-red-400">Les mots de passe ne correspondent pas.</p>
            )}

            <button type="submit" className="btn-neon" disabled={mismatch}>
              Créer mon compte
            </button>
          </form>

          <div className="mt-6 flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-xs text-slate-500">
            <span className="inline-flex items-center gap-1">
              <ShieldCheck className="h-3.5 w-3.5 text-neon-cyan" /> Transactions sécurisées
            </span>
            <span className="inline-flex items-center gap-1">
              <Zap className="h-3.5 w-3.5 text-neon-yellow" /> Wave &amp; Orange Money
            </span>
          </div>
        </section>

        <p className="mt-6 text-center text-sm text-slate-400">
          Déjà inscrit ?{" "}
          <Link href="/login" className="text-neon-cyan transition hover:text-white">
            Se connecter
          </Link>
        </p>
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
    <div>
      <label className="mb-1 block text-xs font-medium uppercase tracking-wider text-slate-400">
        {label}
      </label>
      <div className="relative">
        <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-500">
          {icon}
        </span>
        {children}
      </div>
    </div>
  );
}