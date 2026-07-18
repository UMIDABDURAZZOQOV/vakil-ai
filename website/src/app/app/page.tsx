"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Loader2, Upload, FileText, LogOut, Crown, ShieldAlert, ArrowRight, Settings } from "lucide-react";
import {
  getToken,
  clearToken,
  me,
  listDocuments,
  uploadDocument,
  riskColor,
  type User,
  type DocumentSummary,
} from "@/lib/api";
import { useLang, riskLabelI18n } from "@/lib/i18n";
import LangSwitcher from "@/components/LangSwitcher";
import ThemeToggle from "@/components/ThemeToggle";

export default function DashboardPage() {
  const router = useRouter();
  const { t } = useLang();
  const [user, setUser] = useState<User | null>(null);
  const [docs, setDocs] = useState<DocumentSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    try {
      const [u, d] = await Promise.all([me(), listDocuments()]);
      setUser(u);
      setDocs(d);
    } catch (e) {
      if ((e as { status?: number }).status === 401) {
        clearToken();
        router.push("/login");
      }
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    if (!getToken()) {
      router.push("/login");
      return;
    }
    load();
  }, [load, router]);

  async function onFile(file: File) {
    setUploading(true);
    setMsg(null);
    try {
      const doc = await uploadDocument(file);
      await load();
      router.push(`/app/${doc.id}`);
    } catch (e) {
      const err = e as { status?: number; message: string };
      setMsg({ ok: false, text: err.status === 402 ? t("limit_reached") : err.message || t("upload_err") });
    } finally {
      setUploading(false);
    }
  }

  function logout() {
    clearToken();
    router.push("/");
  }

  if (loading) {
    return <div className="min-h-screen grid place-items-center"><Loader2 className="w-8 h-8 animate-spin text-emerald" /></div>;
  }

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="sticky top-0 z-40 border-b border-white/5 bg-navy-darkest/70 backdrop-blur-xl">
        <div className="max-w-4xl mx-auto px-5 h-16 flex items-center justify-between">
          <Link href="/app" className="flex items-center gap-2.5">
            <Image src="/vakil-logo.png" alt="Vakil AI" width={32} height={32} className="rounded-lg" />
            <span className="font-extrabold">Vakil <span className="text-emerald">AI</span></span>
          </Link>
          <div className="flex items-center gap-2 sm:gap-3">
            <ThemeToggle />
            <LangSwitcher />
            <Link href="/app/settings" className="p-2 text-white/50 hover:text-white transition-colors" aria-label={t("settings")}>
              <Settings className="w-5 h-5" />
            </Link>
            {user?.is_premium ? (
              <span className="hidden sm:flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full bg-gold/15 text-gold">
                <Crown className="w-3.5 h-3.5" /> {t("premium")}
              </span>
            ) : (
              <Link href="/app/premium" className="hidden sm:flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full bg-emerald/15 text-emerald hover:bg-emerald/25 transition-colors">
                <Crown className="w-3.5 h-3.5" /> {t("get_premium")}
              </Link>
            )}
            <button onClick={logout} className="p-2 text-white/50 hover:text-white transition-colors" aria-label={t("logout")}>
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-5 py-8">
        <div className="mb-6">
          <h1 className="text-2xl font-black">{t("hi")}{user?.name ? `, ${user.name}` : ""} 👋</h1>
          <p className="text-white/50 text-sm mt-1">
            {user && !user.is_premium
              ? t("quota_used").replace("{u}", String(user.documents_used)).replace("{q}", String(user.documents_quota))
              : t("unlimited")}
          </p>
        </div>

        {/* Upload */}
        <input
          ref={fileRef}
          type="file"
          accept=".pdf,.txt,image/*"
          className="hidden"
          onChange={(e) => e.target.files?.[0] && onFile(e.target.files[0])}
        />
        <button
          onClick={() => fileRef.current?.click()}
          disabled={uploading}
          className="w-full glass rounded-3xl border-2 border-dashed border-emerald/30 hover:border-emerald/60 p-8 flex flex-col items-center gap-3 transition-colors disabled:opacity-70"
        >
          {uploading ? (
            <>
              <Loader2 className="w-8 h-8 text-emerald animate-spin" />
              <p className="font-bold">{t("analyzing")}</p>
              <p className="text-xs text-white/50">{t("analyzing_sub")}</p>
            </>
          ) : (
            <>
              <div className="w-14 h-14 rounded-2xl bg-emerald/15 grid place-items-center">
                <Upload className="w-6 h-6 text-emerald" />
              </div>
              <p className="font-bold">{t("upload")}</p>
              <p className="text-xs text-white/50">{t("upload_sub")}</p>
            </>
          )}
        </button>
        {msg && <p className={`text-sm mt-3 font-medium ${msg.ok ? "text-emerald" : "text-risk-high"}`}>{msg.text}</p>}

        {/* Documents */}
        <div className="mt-8">
          <p className="text-xs font-extrabold uppercase tracking-wider text-white/40 mb-3">{t("recent")}</p>
          {docs.length === 0 ? (
            <div className="glass rounded-3xl p-10 text-center text-white/50">
              <FileText className="w-10 h-10 mx-auto mb-3 opacity-40" />
              {t("no_docs")}
            </div>
          ) : (
            <div className="space-y-3">
              {docs.map((d, i) => (
                <motion.div key={d.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                  <Link href={`/app/${d.id}`} className="glass rounded-2xl p-4 flex items-center gap-4 hover:border-emerald/40 transition-colors group">
                    <div className="w-11 h-11 rounded-xl grid place-items-center shrink-0" style={{ backgroundColor: `${riskColor(d.risk_level)}22` }}>
                      <ShieldAlert className="w-5 h-5" style={{ color: riskColor(d.risk_level) }} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-bold truncate">{d.title}</p>
                      <p className="text-xs text-white/40">{new Date(d.created_at).toLocaleDateString()} · {d.status === "completed" ? t("ready") : d.status}</p>
                    </div>
                    <span className="text-[11px] font-bold px-2.5 py-1 rounded-full shrink-0" style={{ color: riskColor(d.risk_level), backgroundColor: `${riskColor(d.risk_level)}1f` }}>
                      {riskLabelI18n(d.risk_level, t)}
                    </span>
                    <ArrowRight className="w-4 h-4 text-white/30 group-hover:text-emerald group-hover:translate-x-0.5 transition-all shrink-0" />
                  </Link>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
