"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, FileText, Loader2, Copy, Check, Download } from "lucide-react";
import { getToken, generateTemplate } from "@/lib/api";
import { useLang } from "@/lib/i18n";
import LangSwitcher from "@/components/LangSwitcher";

export default function TemplatesPage() {
  const router = useRouter();
  const { t, lang } = useLang();
  const [type, setType] = useState<string>("");
  const [fields, setFields] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState("");
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!getToken()) router.push("/login");
  }, [router]);

  const types = [
    { id: "NDA", label: t("tpl_nda") },
    { id: "ijara shartnomasi", label: t("tpl_rental") },
    { id: "frilans shartnomasi", label: t("tpl_freelance") },
  ];
  const fieldDefs = [
    { key: "party_a", label: t("tpl_partyA") },
    { key: "party_b", label: t("tpl_partyB") },
    { key: "subject", label: t("tpl_subject") },
    { key: "amount", label: t("tpl_amount") },
    { key: "date", label: t("tpl_date") },
  ];

  async function generate() {
    setLoading(true);
    setError("");
    setResult("");
    try {
      const res = await generateTemplate(type, fields, lang);
      setResult(res.document);
    } catch (e) {
      setError((e as Error).message || "Error");
    } finally {
      setLoading(false);
    }
  }

  function copy() {
    navigator.clipboard.writeText(result);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }
  function download() {
    const blob = new Blob([result], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${type || "document"}.txt`;
    a.click();
    URL.revokeObjectURL(url);
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
          <div className="w-11 h-11 rounded-2xl bg-emerald/15 grid place-items-center"><FileText className="w-5 h-5 text-emerald" /></div>
          <h1 className="text-2xl font-black">{t("tpl_title")}</h1>
        </div>
        <p className="text-white/50 text-sm mb-6">{t("tpl_sub")}</p>

        {/* Type */}
        <p className="text-xs font-extrabold uppercase tracking-wider text-white/40 mb-2">{t("tpl_choose")}</p>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 mb-6">
          {types.map((ty) => (
            <button
              key={ty.id}
              onClick={() => setType(ty.id)}
              className={`glass rounded-2xl p-4 text-left text-sm font-bold transition-colors ${type === ty.id ? "border-emerald/70 text-emerald" : "hover:border-emerald/40"}`}
            >
              {ty.label}
            </button>
          ))}
        </div>

        {type && (
          <>
            <div className="space-y-3">
              {fieldDefs.map((f) => (
                <div key={f.key}>
                  <label className="text-xs font-bold text-white/50 mb-1 block">{f.label}</label>
                  <input
                    value={fields[f.key] || ""}
                    onChange={(e) => setFields((s) => ({ ...s, [f.key]: e.target.value }))}
                    className="w-full glass rounded-xl px-4 py-3 text-sm outline-none focus:border-emerald/50"
                  />
                </div>
              ))}
              <div>
                <label className="text-xs font-bold text-white/50 mb-1 block">{t("tpl_extra")}</label>
                <textarea
                  value={fields["extra"] || ""}
                  onChange={(e) => setFields((s) => ({ ...s, extra: e.target.value }))}
                  rows={3}
                  className="w-full glass rounded-xl px-4 py-3 text-sm outline-none focus:border-emerald/50 resize-none"
                />
              </div>
            </div>

            <button
              onClick={generate}
              disabled={loading}
              className="mt-5 w-full bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold py-3.5 rounded-2xl transition-colors flex items-center justify-center gap-2 disabled:opacity-70"
            >
              {loading ? <><Loader2 className="w-4 h-4 animate-spin" /> {t("tpl_generating")}</> : t("tpl_generate")}
            </button>
          </>
        )}

        {error && <p className="text-sm mt-4 text-risk-high font-medium">{error}</p>}

        {result && (
          <div className="mt-6">
            <div className="flex items-center justify-between mb-2">
              <p className="text-xs font-extrabold uppercase tracking-wider text-white/40">{t("tpl_result")}</p>
              <div className="flex gap-2">
                <button onClick={copy} className="flex items-center gap-1.5 text-xs font-bold text-white/60 hover:text-white transition-colors">
                  {copied ? <><Check className="w-3.5 h-3.5 text-emerald" /> {t("copied")}</> : <><Copy className="w-3.5 h-3.5" /> {t("copy")}</>}
                </button>
                <button onClick={download} className="flex items-center gap-1.5 text-xs font-bold text-white/60 hover:text-white transition-colors">
                  <Download className="w-3.5 h-3.5" /> {t("download")}
                </button>
              </div>
            </div>
            <pre className="glass rounded-2xl p-5 text-sm whitespace-pre-wrap font-sans leading-relaxed text-white/90">{result}</pre>
          </div>
        )}
      </main>
    </div>
  );
}
