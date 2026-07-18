"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Crown, Check, Loader2 } from "lucide-react";
import { useLang } from "@/lib/i18n";
import { createCheckout } from "@/lib/api";

export default function PremiumPage() {
  const { t } = useLang();
  const perks = ["prem_1", "prem_2", "prem_3", "prem_4", "prem_5"];
  const [busy, setBusy] = useState<"payme" | "click" | null>(null);
  const [error, setError] = useState("");

  async function pay(provider: "payme" | "click") {
    setBusy(provider);
    setError("");
    try {
      const { url } = await createCheckout(provider);
      window.location.href = url;
    } catch (e) {
      setError((e as Error).message || t("upload_err"));
      setBusy(null);
    }
  }

  return (
    <div className="min-h-screen max-w-lg mx-auto px-5 py-8">
      <Link href="/app" className="inline-flex items-center gap-1.5 text-sm font-semibold text-white/50 hover:text-white mb-6 transition-colors">
        <ArrowLeft className="w-4 h-4" /> {t("back")}
      </Link>

      <div className="rounded-3xl p-8 border-2 border-emerald/40 bg-gradient-to-br from-emerald/10 to-gold/5 text-center">
        <div className="w-16 h-16 rounded-2xl bg-gold/20 grid place-items-center mx-auto mb-5">
          <Crown className="w-8 h-8 text-gold" />
        </div>
        <h1 className="text-2xl font-black">Vakil AI {t("premium")}</h1>
        <div className="mt-2 text-4xl font-black">49 000 <span className="text-lg text-white/50 font-bold">{t("per_month")}</span></div>

        <ul className="mt-7 space-y-3 text-left">
          {perks.map((p) => (
            <li key={p} className="flex items-center gap-2.5 text-white/90"><Check className="w-4 h-4 text-emerald shrink-0" /> {t(p)}</li>
          ))}
        </ul>

        <div className="mt-8 space-y-3">
          <button onClick={() => pay("payme")} disabled={!!busy}
            className="w-full flex items-center justify-center gap-2 bg-[#33cccc] hover:brightness-95 text-navy-darkest font-black py-3.5 rounded-2xl transition-all disabled:opacity-60">
            {busy === "payme" ? <Loader2 className="w-5 h-5 animate-spin" /> : "Payme"}
          </button>
          <button onClick={() => pay("click")} disabled={!!busy}
            className="w-full flex items-center justify-center gap-2 bg-[#00a3ff] hover:brightness-95 text-white font-black py-3.5 rounded-2xl transition-all disabled:opacity-60">
            {busy === "click" ? <Loader2 className="w-5 h-5 animate-spin" /> : "Click"}
          </button>
        </div>
        {error && <p className="text-sm text-risk-high mt-3">{error}</p>}
        <p className="text-xs text-white/40 mt-3">{t("pay_secure")}</p>
      </div>
    </div>
  );
}
