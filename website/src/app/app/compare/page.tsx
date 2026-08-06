"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, GitCompare, Loader2, Plus, Minus, Pencil } from "lucide-react";
import { getToken, compareDocuments, riskColor, type DiffChange } from "@/lib/api";
import { useLang } from "@/lib/i18n";
import LangSwitcher from "@/components/LangSwitcher";

export default function ComparePage() {
  const router = useRouter();
  const { t, lang } = useLang();
  const [a, setA] = useState("");
  const [b, setB] = useState("");
  const [loading, setLoading] = useState(false);
  const [summary, setSummary] = useState("");
  const [changes, setChanges] = useState<DiffChange[] | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!getToken()) router.push("/login");
  }, [router]);

  async function run() {
    if (!a.trim() || !b.trim()) return;
    setLoading(true);
    setError("");
    setChanges(null);
    setSummary("");
    try {
      const res = await compareDocuments(a, b, lang);
      setSummary(res.summary);
      setChanges(res.changes);
    } catch (e) {
      setError((e as Error).message || "Error");
    } finally {
      setLoading(false);
    }
  }

  const kindIcon = (kind: string) =>
    kind === "added" ? <Plus className="w-4 h-4" /> : kind === "removed" ? <Minus className="w-4 h-4" /> : <Pencil className="w-4 h-4" />;
  const kindLabel = (kind: string) =>
    kind === "added" ? t("cmp_added") : kind === "removed" ? t("cmp_removed") : t("cmp_changed");

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
          <div className="w-11 h-11 rounded-2xl bg-gold/15 grid place-items-center"><GitCompare className="w-5 h-5 text-gold" /></div>
          <h1 className="text-2xl font-black">{t("cmp_title")}</h1>
        </div>
        <p className="text-white/50 text-sm mb-6">{t("cmp_sub")}</p>

        <div className="grid sm:grid-cols-2 gap-3">
          <div>
            <label className="text-xs font-bold text-white/50 mb-1 block">{t("cmp_old")}</label>
            <textarea value={a} onChange={(e) => setA(e.target.value)} placeholder={t("cmp_paste_old")} rows={8}
              className="w-full glass rounded-2xl px-4 py-3 text-sm outline-none focus:border-emerald/50 resize-none" />
          </div>
          <div>
            <label className="text-xs font-bold text-white/50 mb-1 block">{t("cmp_new")}</label>
            <textarea value={b} onChange={(e) => setB(e.target.value)} placeholder={t("cmp_paste_new")} rows={8}
              className="w-full glass rounded-2xl px-4 py-3 text-sm outline-none focus:border-emerald/50 resize-none" />
          </div>
        </div>

        <button onClick={run} disabled={loading || !a.trim() || !b.trim()}
          className="mt-4 w-full bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold py-3.5 rounded-2xl transition-colors flex items-center justify-center gap-2 disabled:opacity-50">
          {loading ? <><Loader2 className="w-4 h-4 animate-spin" /> {t("cmp_running")}</> : t("cmp_run")}
        </button>

        {error && <p className="text-sm mt-4 text-risk-high font-medium">{error}</p>}

        {summary && (
          <div className="mt-6">
            <p className="text-xs font-extrabold uppercase tracking-wider text-white/40 mb-2">{t("cmp_summary")}</p>
            <div className="glass rounded-2xl p-4 text-sm text-white/90 leading-relaxed">{summary}</div>
          </div>
        )}

        {changes && changes.length > 0 && (
          <div className="mt-5">
            <p className="text-xs font-extrabold uppercase tracking-wider text-white/40 mb-2">{t("cmp_changes")}</p>
            <div className="space-y-3">
              {changes.map((c, i) => (
                <div key={i} className="glass rounded-2xl p-4">
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-lg grid place-items-center shrink-0" style={{ backgroundColor: `${riskColor(c.risk_level)}22`, color: riskColor(c.risk_level) }}>
                      {kindIcon(c.kind)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-bold text-sm">{c.title}</p>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-full" style={{ color: riskColor(c.risk_level), backgroundColor: `${riskColor(c.risk_level)}1f` }}>
                          {kindLabel(c.kind)}
                        </span>
                      </div>
                      <p className="text-xs text-white/60 mt-1 leading-relaxed">{c.detail}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
