import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        night: { DEFAULT: "#080B11", 900: "#0A0D14", 800: "#0F172A" },
        neon: { yellow: "#FACC15", cyan: "#06B6D4" },
      },
      fontFamily: {
        display: ["Rajdhani", "ui-sans-serif", "sans-serif"],
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
      },
      boxShadow: {
        "glow-yellow": "0 0 24px rgba(250,204,21,0.35)",
        "glow-cyan": "0 0 28px rgba(6,182,212,0.35)",
      },
      keyframes: {
        "pulse-glow": {
          "0%,100%": { opacity: "0.55" },
          "50%": { opacity: "1" },
        },
        beam: {
          "0%,100%": { transform: "translateX(-6%)" },
          "50%": { transform: "translateX(6%)" },
        },
      },
      animation: {
        "pulse-glow": "pulse-glow 3s ease-in-out infinite",
        beam: "beam 7s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;