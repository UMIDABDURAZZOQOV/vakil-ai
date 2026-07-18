"use client";

/**
 * Animated product demos for the Vakil AI landing — a self-playing document
 * risk analysis card and an AI chat card. All illustrations are drawn from
 * scratch with SVG/CSS + framer-motion; content is original marketing copy.
 */

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { FileText, ShieldAlert, Sparkles, CheckCircle2, Send } from "lucide-react";
import { useLang } from "@/lib/i18n";

function useTick(steps: number, ms: number) {
  const [t, setT] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setT((x) => (x + 1) % steps), ms);
    return () => clearInterval(id);
  }, [steps, ms]);
  return t;
}

const glass =
  "rounded-3xl border border-white/10 bg-navy-card/60 backdrop-blur-xl shadow-[0_30px_80px_-30px_rgba(0,0,0,0.6)]";

// ── Document risk-analysis demo ────────────────────────────────────────────────
function AnalysisDemo() {
  const { t } = useLang();
  const tick = useTick(5, 1100);
  const bullets = [t("demo_b1"), t("demo_b2"), t("demo_b3")];
  const flags = [
    { txt: t("demo_f1"), r: "medium", c: "#F2A93B" },
    { txt: t("demo_f2"), r: "high", c: "#E15554" },
  ];
  // Risk gauge sweeps to "medium"
  const riskPct = tick >= 1 ? 62 : 0;

  return (
    <div className={`${glass} p-5 sm:p-6`}>
      <div className="flex items-center gap-3 mb-4">
        <div className="w-10 h-10 rounded-xl bg-emerald/15 grid place-items-center">
          <FileText className="w-5 h-5 text-emerald" />
        </div>
        <div className="min-w-0">
          <p className="font-bold text-white truncate">{t("demo_file")}</p>
          <p className="text-xs text-white/50">{t("demo_analyzed")}</p>
        </div>
        <span className="ml-auto text-[11px] font-bold px-2.5 py-1 rounded-full bg-emerald/15 text-emerald">
          {t("ready")}
        </span>
      </div>

      {/* Risk gauge */}
      <div className="flex items-center gap-4 mb-5">
        <div className="relative w-[92px] h-[92px] shrink-0">
          <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
            <circle cx="50" cy="50" r="42" fill="none" strokeWidth="9" className="stroke-white/10" />
            <motion.circle
              cx="50" cy="50" r="42" fill="none" strokeWidth="9" strokeLinecap="round"
              stroke="#F2A93B"
              strokeDasharray={2 * Math.PI * 42}
              animate={{ strokeDashoffset: 2 * Math.PI * 42 * (1 - riskPct / 100) }}
              transition={{ duration: 1.1, ease: "easeOut" }}
            />
          </svg>
          <div className="absolute inset-0 grid place-items-center text-center">
            <div>
              <div className="text-lg font-black text-white leading-none">{t("risk_medium")}</div>
              <div className="text-[9px] text-white/50 font-bold mt-0.5">{t("risk")}</div>
            </div>
          </div>
        </div>
        <div className="flex-1">
          <p className="text-xs font-bold text-white/50 uppercase tracking-wider mb-2">{t("summary")}</p>
          <div className="space-y-1.5">
            {bullets.map((b, i) => (
              <motion.div
                key={b}
                initial={{ opacity: 0, x: -8 }}
                animate={{ opacity: tick > i ? 1 : 0.25, x: 0 }}
                transition={{ duration: 0.3 }}
                className="flex items-start gap-1.5 text-[13px] text-white/80"
              >
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald mt-0.5 shrink-0" />
                <span>{b}</span>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Clause flags */}
      <p className="text-xs font-bold text-white/50 uppercase tracking-wider mb-2">{t("clauses")}</p>
      <div className="space-y-2">
        {flags.map((f, i) => (
          <motion.div
            key={f.txt}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: tick > i + 1 ? 1 : 0, y: tick > i + 1 ? 0 : 8 }}
            transition={{ duration: 0.35 }}
            className="flex items-center gap-2.5 rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2"
          >
            <ShieldAlert className="w-4 h-4 shrink-0" style={{ color: f.c }} />
            <span className="text-[13px] text-white/85 flex-1">{f.txt}</span>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full" style={{ color: f.c, backgroundColor: `${f.c}22` }}>
              {f.r === "high" ? t("risk_high") : t("risk_medium")}
            </span>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

// ── AI chat demo ────────────────────────────────────────────────────────────────
function ChatDemo() {
  const { t } = useLang();
  const tick = useTick(4, 1600);
  return (
    <div className={`${glass} p-5 sm:p-6 flex flex-col`}>
      <div className="flex items-center gap-2 mb-4">
        <div className="w-8 h-8 rounded-lg bg-gold/20 grid place-items-center">
          <Sparkles className="w-4 h-4 text-gold" />
        </div>
        <span className="font-bold text-white text-sm">{t("demo_chat_title")}</span>
        <span className="ml-auto text-[10px] text-white/40">{t("only_doc")}</span>
      </div>

      <div className="flex-1 space-y-3 min-h-[220px]">
        <AnimatePresence>
          {tick >= 1 && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="flex justify-end">
              <div className="max-w-[80%] rounded-2xl rounded-br-md bg-emerald text-navy-darkest px-3.5 py-2.5 text-[13px] font-medium">
                {t("demo_q")}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
        <AnimatePresence>
          {tick >= 2 && (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="flex justify-start">
              <div className="max-w-[85%] rounded-2xl rounded-bl-md bg-white/[0.06] border border-white/10 text-white/85 px-3.5 py-2.5 text-[13px] leading-relaxed">
                {tick >= 3 ? (
                  t("demo_a")
                ) : (
                  <span className="inline-flex gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-white/50 animate-bounce" />
                    <span className="w-1.5 h-1.5 rounded-full bg-white/50 animate-bounce [animation-delay:0.15s]" />
                    <span className="w-1.5 h-1.5 rounded-full bg-white/50 animate-bounce [animation-delay:0.3s]" />
                  </span>
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="mt-4 flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-4 py-2.5">
        <span className="text-[13px] text-white/40 flex-1">Savolingizni yozing…</span>
        <div className="w-8 h-8 rounded-full bg-emerald grid place-items-center">
          <Send className="w-4 h-4 text-navy-darkest" />
        </div>
      </div>
    </div>
  );
}

export default function DemoShowcase() {
  return (
    <div className="grid md:grid-cols-2 gap-5">
      <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.6 }}>
        <AnalysisDemo />
      </motion.div>
      <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.6, delay: 0.12 }}>
        <ChatDemo />
      </motion.div>
    </div>
  );
}
