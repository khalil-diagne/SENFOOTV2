export default function Logo({ className = "h-9 w-9" }: { className?: string }) {
  return (
    <span
      className={`inline-grid place-items-center rounded-xl border border-neon-cyan/30 bg-gradient-to-br from-neon-cyan/20 to-neon-yellow/20 shadow-glow-cyan ${className}`}
    >
      <svg viewBox="0 0 24 24" className="h-2/3 w-2/3" fill="none" stroke="currentColor" strokeWidth="1.6">
        <circle cx="12" cy="12" r="9" />
        <path d="M12 3.5 9 7l1.4 3.2h3.2L15 7l-3-3.5zM5 9l2.4 2 .5 3-2 1.8M19 9l-2.4 2-.5 3 2 1.8M12 20.5l-2-2.5h4l-2 2.5" />
      </svg>
    </span>
  );
}