"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Loader2, ArrowLeft, ShieldAlert, CheckCircle2, CalendarClock, Send, Sparkles, ChevronDown } from "lucide-react";
import {
  getToken,
  clearToken,
  getDocument,
  getChat,
  sendChat,
  riskColor,
  type DocumentDetail,
  type ChatMessage,
} from "@/lib/api";
import { useLang, riskLabelI18n } from "@/lib/i18n";

export default function DocumentPage() {
  const router = useRouter();
  const { t } = useLang();
  const params = useParams<{ id: string }>();
  const id = params.id;

  const [doc, setDoc] = useState<DocumentDetail | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [openFlag, setOpenFlag] = useState<number | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    try {
      const [d, c] = await Promise.all([getDocument(id), getChat(id)]);
      setDoc(d);
      setMessages(c);
    } catch (e) {
      if ((e as { status?: number }).status === 401) {
        clearToken();
        router.push("/login");
      } else {
        router.push("/app");
      }
    } finally {
      setLoading(false);
    }
  }, [id, router]);

  useEffect(() => {
    if (!getToken()) {
      router.push("/login");
      return;
    }
    load();
  }, [load, router]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, sending]);

  async function send() {
    const text = input.trim();
    if (!text || sending) return;
    setInput("");
    setMessages((m) => [...m, { id: `tmp-${Date.now()}`, is_user: true, text, created_at: new Date().toISOString() }]);
    setSending(true);
    try {
      const updated = await sendChat(id, text);
      setMessages(updated);
    } catch {
      setMessages((m) => [...m, { id: `err-${Date.now()}`, is_user: false, text: t("chat_err"), created_at: new Date().toISOString() }]);
    } finally {
      setSending(false);
    }
  }

  if (loading) {
    return <div className="min-h-screen grid place-items-center"><Loader2 className="w-8 h-8 animate-spin text-emerald" /></div>;
  }
  if (!doc) return null;

  const rc = riskColor(doc.risk_level);
  const pct = Math.max(0, Math.min(100, Math.round((doc.risk_score || 0) * (doc.risk_score <= 1 ? 100 : 1))));

  return (
    <div className="min-h-screen max-w-4xl mx-auto px-5 py-6">
      <Link href="/app" className="inline-flex items-center gap-1.5 text-sm font-semibold text-white/50 hover:text-white mb-5 transition-colors">
        <ArrowLeft className="w-4 h-4" /> {t("documents")}
      </Link>

      {/* Header card */}
      <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="glass rounded-3xl p-6 flex items-center gap-5">
        <div className="relative w-[92px] h-[92px] shrink-0">
          <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
            <circle cx="50" cy="50" r="42" fill="none" strokeWidth="9" className="stroke-white/10" />
            <motion.circle
              cx="50" cy="50" r="42" fill="none" strokeWidth="9" strokeLinecap="round" stroke={rc}
              strokeDasharray={2 * Math.PI * 42}
              initial={{ strokeDashoffset: 2 * Math.PI * 42 }}
              animate={{ strokeDashoffset: 2 * Math.PI * 42 * (1 - pct / 100) }}
              transition={{ duration: 1.1, ease: "easeOut" }}
            />
          </svg>
          <div className="absolute inset-0 grid place-items-center text-center">
            <div>
              <div className="text-base font-black leading-none" style={{ color: rc }}>{riskLabelI18n(doc.risk_level, t)}</div>
              <div className="text-[9px] text-white/50 font-bold mt-0.5">{t("risk")}</div>
            </div>
          </div>
        </div>
        <div className="min-w-0">
          <h1 className="text-xl font-black leading-tight break-words">{doc.title}</h1>
          <p className="text-sm text-white/50 mt-1">{new Date(doc.created_at).toLocaleDateString("uz")}</p>
        </div>
      </motion.div>

      {/* Summary */}
      {doc.summary_bullets?.length > 0 && (
        <section className="mt-5 glass rounded-3xl p-6">
          <h2 className="text-sm font-extrabold uppercase tracking-wider text-white/40 mb-3">{t("summary")}</h2>
          <div className="space-y-2.5">
            {doc.summary_bullets.map((b, i) => (
              <div key={i} className="flex items-start gap-2.5 text-[15px] text-white/85">
                <CheckCircle2 className="w-4 h-4 text-emerald mt-1 shrink-0" />
                <span>{b}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Clause flags */}
      {doc.flags?.length > 0 && (
        <section className="mt-5">
          <h2 className="text-sm font-extrabold uppercase tracking-wider text-white/40 mb-3 px-1">{t("clauses")}</h2>
          <div className="space-y-2.5">
            {doc.flags.map((f, i) => (
              <div key={i} className="glass rounded-2xl overflow-hidden">
                <button onClick={() => setOpenFlag(openFlag === i ? null : i)} className="w-full flex items-center gap-3 p-4 text-left">
                  <ShieldAlert className="w-5 h-5 shrink-0" style={{ color: riskColor(f.risk_level) }} />
                  <span className="font-bold flex-1">{f.title}</span>
                  <span className="text-[11px] font-bold px-2 py-0.5 rounded-full shrink-0" style={{ color: riskColor(f.risk_level), backgroundColor: `${riskColor(f.risk_level)}22` }}>
                    {riskLabelI18n(f.risk_level, t)}
                  </span>
                  <ChevronDown className={`w-4 h-4 text-white/40 transition-transform ${openFlag === i ? "rotate-180" : ""}`} />
                </button>
                {openFlag === i && f.explanation && (
                  <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} className="px-4 pb-4 text-sm text-white/70 leading-relaxed">
                    {f.explanation}
                  </motion.div>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Key dates */}
      {doc.key_dates?.length > 0 && (
        <section className="mt-5 glass rounded-3xl p-6">
          <h2 className="text-sm font-extrabold uppercase tracking-wider text-white/40 mb-3 flex items-center gap-2">
            <CalendarClock className="w-4 h-4" /> {t("key_dates")}
          </h2>
          <div className="flex flex-wrap gap-2">
            {doc.key_dates.map((d, i) => (
              <span key={i} className="text-sm px-3 py-1.5 rounded-full bg-gold/15 text-gold-light font-medium">{d}</span>
            ))}
          </div>
        </section>
      )}

      {/* Chat */}
      <section className="mt-5 glass rounded-3xl p-6">
        <h2 className="text-sm font-extrabold uppercase tracking-wider text-white/40 mb-4 flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-gold" /> {t("chat_title")}
        </h2>
        <div className="space-y-3 min-h-[80px] max-h-[420px] overflow-y-auto pr-1">
          {messages.length === 0 && (
            <p className="text-sm text-white/40 text-center py-6">{t("chat_empty")}</p>
          )}
          {messages.map((m) => (
            <div key={m.id} className={`flex ${m.is_user ? "justify-end" : "justify-start"}`}>
              <div className={`max-w-[85%] rounded-2xl px-3.5 py-2.5 text-[14px] leading-relaxed ${
                m.is_user ? "rounded-br-md bg-emerald text-navy-darkest font-medium" : "rounded-bl-md bg-white/[0.06] border border-white/10 text-white/85"
              }`}>
                {m.text}
              </div>
            </div>
          ))}
          {sending && (
            <div className="flex justify-start">
              <div className="rounded-2xl rounded-bl-md bg-white/[0.06] border border-white/10 px-3.5 py-3">
                <span className="inline-flex gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-white/50 animate-bounce" />
                  <span className="w-1.5 h-1.5 rounded-full bg-white/50 animate-bounce [animation-delay:0.15s]" />
                  <span className="w-1.5 h-1.5 rounded-full bg-white/50 animate-bounce [animation-delay:0.3s]" />
                </span>
              </div>
            </div>
          )}
          <div ref={chatEndRef} />
        </div>
        <div className="mt-4 flex items-center gap-2">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && send()}
            placeholder={t("chat_ph")}
            className="flex-1 rounded-full border border-white/10 bg-white/[0.04] px-4 py-3 text-sm outline-none focus:border-emerald transition-colors"
          />
          <button onClick={send} disabled={sending || !input.trim()} className="w-11 h-11 rounded-full bg-emerald hover:bg-emerald-dark grid place-items-center shrink-0 transition-colors disabled:opacity-50">
            <Send className="w-4 h-4 text-navy-darkest" />
          </button>
        </div>
      </section>

      <p className="text-center text-[11px] text-white/25 mt-6 pb-4">{t("disclaimer")}</p>
    </div>
  );
}
