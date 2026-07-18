"use client";

import { useLang, type Lang } from "@/lib/i18n";

const LANGS: { id: Lang; label: string }[] = [
  { id: "uz", label: "UZ" },
  { id: "ru", label: "RU" },
  { id: "en", label: "EN" },
];

export default function LangSwitcher({ className = "" }: { className?: string }) {
  const { lang, setLang } = useLang();
  return (
    <div className={`inline-flex items-center gap-0.5 rounded-full border border-white/10 bg-white/[0.04] p-0.5 ${className}`}>
      {LANGS.map((l) => (
        <button
          key={l.id}
          onClick={() => setLang(l.id)}
          className={`px-2.5 py-1 rounded-full text-xs font-bold transition-colors ${
            lang === l.id ? "bg-emerald text-navy-darkest" : "text-white/60 hover:text-white"
          }`}
        >
          {l.label}
        </button>
      ))}
    </div>
  );
}
