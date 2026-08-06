"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, Scale, Loader2, Sparkles } from "lucide-react";
import { getToken, askLegal } from "@/lib/api";
import { useLang } from "@/lib/i18n";
import LangSwitcher from "@/components/LangSwitcher";

export default function LegalAskPage() {
  const router = useRouter();
  const { t, lang } = useLang();
  const [question, setQuestion] = useState("");
  const [asked, setAsked] = useState("");
  const [answer, setAnswer] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!getToken()) router.push("/login");
  }, [router]);

  const examples = [t("legal_ex1"), t("legal_ex2"), t("legal_ex3")];

  async function ask(q?: string) {
    const query = (q ?? question).trim();
    if (!query) return;
    setAsked(query);
    setLoading(true);
    setError("");
    setAnswer("");
    try {
      const res = await askLegal(query, lang);
      setAnswer(res.answer);
    } catch (e) {
      setError((e as Error).message || "Error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen">
      <header className="sticky top-0 z-40 border-b border-white/5 bg-navy-darkest/70 backdrop-blur-xl">
        <div className="max-w-3xl mx-auto px-5 h-16 flex items-center justify-between">
          <Link href="/app" className="flex items-center gap-2 text-sm font-bold text-white/60 hover:text-white transition-colors">
            <ArrowLeft className="w-4 h-4" /> {t("back")}
          </Link>
          <LangSwitcher />
        </div>
      </header>

      <main className="max-w-3xl mx-auto px-5 py-8">
        <div className="flex items-center gap-3 mb-1">
          <div className="w-11 h-11 rounded-2xl grid place-items-center" style={{ backgroundColor: "#1CB0F61f" }}><Scale className="w-5 h-5" style={{ color: "#1CB0F6" }} /></div>
          <h1 className="text-2xl font-black">{t("legal_title")}</h1>
        </div>
        <p className="text-white/50 text-sm mb-6">{t("legal_sub")}</p>

        <textarea
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          placeholder={t("legal_ph")}
          rows={3}
          className="w-full glass rounded-2xl px-4 py-3.5 text-sm outline-none focus:border-emerald/50 resize-none"
        />
        <button
          onClick={() => ask()}
          disabled={loading || !question.trim()}
          className="mt-3 w-full bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold py-3.5 rounded-2xl transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {loading ? <><Loader2 className="w-4 h-4 animate-spin" /> {t("legal_asking")}</> : <><Sparkles className="w-4 h-4" /> {t("legal_ask")}</>}
        </button>

        {!answer && !loading && (
          <div className="mt-6">
            <p className="text-xs font-extrabold uppercase tracking-wider text-white/40 mb-2">{t("legal_examples")}</p>
            <div className="flex flex-col gap-2">
              {examples.map((ex, i) => (
                <button key={i} onClick={() => { setQuestion(ex); ask(ex); }} className="glass rounded-xl px-4 py-3 text-sm text-left text-white/70 hover:text-white hover:border-emerald/40 transition-colors">
                  {ex}
                </button>
              ))}
            </div>
          </div>
        )}

        {error && <p className="text-sm mt-4 text-risk-high font-medium">{error}</p>}

        {(answer || loading) && (
          <div className="mt-6">
            {asked && <p className="text-sm font-bold text-white/80 mb-3">{asked}</p>}
            {loading ? (
              <div className="glass rounded-2xl p-5 flex items-center gap-3 text-white/50 text-sm"><Loader2 className="w-4 h-4 animate-spin text-emerald" /> {t("legal_asking")}</div>
            ) : (
              <div className="glass rounded-2xl p-5 text-sm whitespace-pre-wrap leading-relaxed text-white/90">{answer}</div>
            )}
          </div>
        )}

        <p className="text-[11px] text-white/30 mt-6 text-center">{t("legal_disclaimer")}</p>
      </main>
    </div>
  );
}
