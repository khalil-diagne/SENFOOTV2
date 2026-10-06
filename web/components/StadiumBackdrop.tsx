export default function StadiumBackdrop() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(60%_60%_at_50%_0%,rgba(6,182,212,0.18)_0%,rgba(8,11,17,0)_70%)]" />
      <div className="absolute inset-0 bg-[radial-gradient(50%_50%_at_80%_100%,rgba(250,204,21,0.12)_0%,rgba(8,11,17,0)_70%)]" />
      <div className="absolute left-1/2 top-0 h-[80vh] w-[40vw] -translate-x-1/2 animate-beam bg-gradient-to-b from-white/10 to-transparent blur-3xl" />
      <div className="absolute inset-0 opacity-[0.15] [background-image:linear-gradient(rgba(255,255,255,0.08)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.08)_1px,transparent_1px)] [background-size:48px_48px]" />
      <div className="absolute -bottom-24 left-1/2 h-72 w-[120%] -translate-x-1/2 animate-pulse-glow rounded-[50%] bg-neon-cyan/10 blur-3xl" />
    </div>
  );
}