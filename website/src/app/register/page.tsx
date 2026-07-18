"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Loader2, ShieldCheck } from "lucide-react";
import { register, setToken } from "@/lib/api";
import { useLang } from "@/lib/i18n";
import LangSwitcher from "@/components/LangSwitcher";

export default function RegisterPage() {
  const router = useRouter();
  const { t } = useLang();
  const [name, setName] = useState("");
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (password.length < 6) {
      setError(t("err_pass6"));
      return;
    }
    setLoading(true);
    try {
      const r = await register(identifier.trim(), password, name.trim());
      setToken(r.access_token);
      router.push("/app");
    } catch (err) {
      setError((err as Error).message || t("err_reg"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen grid place-items-center px-5 py-10">
      <div className="blob w-[380px] h-[380px] top-0 -right-20 bg-gold/20" />
      <div className="absolute top-5 right-5"><LangSwitcher /></div>
      <div className="w-full max-w-sm relative">
        <Link href="/" className="flex items-center justify-center gap-2.5 mb-8">
          <Image src="/vakil-logo.png" alt="Vakil AI" width={40} height={40} className="rounded-xl" />
          <span className="font-extrabold text-xl">Vakil <span className="text-emerald">AI</span></span>
        </Link>
        <div className="glass rounded-3xl p-7">
          <h1 className="text-2xl font-black mb-1">{t("reg_title")}</h1>
          <p className="text-sm text-white/50 mb-6">{t("reg_sub")}</p>
          <form onSubmit={submit} className="space-y-3">
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder={t("ph_name")}
              className="w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm outline-none focus:border-emerald transition-colors" />
            <input value={identifier} onChange={(e) => setIdentifier(e.target.value)} placeholder={t("ph_id")}
              className="w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm outline-none focus:border-emerald transition-colors" />
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder={t("ph_pass6")}
              className="w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm outline-none focus:border-emerald transition-colors" />
            {error && <p className="text-sm text-risk-high font-medium">{error}</p>}
            <button disabled={loading} className="w-full flex items-center justify-center gap-2 rounded-2xl bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold py-3 transition-colors disabled:opacity-60">
              {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : t("register")}
            </button>
          </form>
          <p className="text-sm text-white/50 text-center mt-5">
            {t("have_account")} <Link href="/login" className="text-emerald font-bold">{t("log_in")}</Link>
          </p>
        </div>
        <p className="flex items-center justify-center gap-1.5 text-xs text-white/40 mt-5">
          <ShieldCheck className="w-3.5 h-3.5" /> {t("secured2")}
        </p>
      </div>
    </div>
  );
}
