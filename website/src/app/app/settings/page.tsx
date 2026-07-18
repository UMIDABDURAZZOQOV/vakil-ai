"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, User as UserIcon, Crown, LogOut, Loader2 } from "lucide-react";
import { getToken, clearToken, me, type User } from "@/lib/api";
import { useLang } from "@/lib/i18n";
import LangSwitcher from "@/components/LangSwitcher";
import ThemeToggle from "@/components/ThemeToggle";

export default function SettingsPage() {
  const router = useRouter();
  const { t } = useLang();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!getToken()) {
      router.push("/login");
      return;
    }
    me().then(setUser).catch(() => { clearToken(); router.push("/login"); }).finally(() => setLoading(false));
  }, [router]);

  function logout() {
    clearToken();
    router.push("/");
  }

  if (loading) return <div className="min-h-screen grid place-items-center"><Loader2 className="w-8 h-8 animate-spin text-emerald" /></div>;

  return (
    <div className="min-h-screen max-w-lg mx-auto px-5 py-8">
      <Link href="/app" className="inline-flex items-center gap-1.5 text-sm font-semibold text-white/50 hover:text-white mb-6 transition-colors">
        <ArrowLeft className="w-4 h-4" /> {t("back")}
      </Link>

      <h1 className="text-2xl font-black mb-6">{t("settings")}</h1>

      {/* Account */}
      <section className="glass rounded-3xl p-6 mb-4">
        <p className="text-xs font-extrabold uppercase tracking-wider text-white/40 mb-4">{t("account")}</p>
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-emerald/15 grid place-items-center shrink-0">
            <UserIcon className="w-7 h-7 text-emerald" />
          </div>
          <div className="min-w-0">
            <p className="font-bold text-lg truncate">{user?.name || "—"}</p>
            <p className="text-sm text-white/50 truncate">{user?.identifier}</p>
          </div>
        </div>
        <div className="mt-5 flex items-center gap-3">
          {user?.is_premium ? (
            <span className="flex items-center gap-1.5 text-sm font-bold px-3 py-1.5 rounded-full bg-gold/15 text-gold">
              <Crown className="w-4 h-4" /> {t("plan_premium")}
            </span>
          ) : (
            <>
              <span className="text-sm text-white/60">{t("plan_free")} · {user?.documents_used}/{user?.documents_quota}</span>
              <Link href="/app/premium" className="ml-auto text-sm font-bold text-emerald">{t("get_premium")} →</Link>
            </>
          )}
        </div>
      </section>

      {/* Preferences */}
      <section className="glass rounded-3xl p-6 mb-4 space-y-4">
        <div className="flex items-center justify-between">
          <span className="font-semibold">{t("language_label")}</span>
          <LangSwitcher />
        </div>
        <div className="flex items-center justify-between">
          <span className="font-semibold">{t("settings")}</span>
          <ThemeToggle />
        </div>
      </section>

      <button onClick={logout} className="w-full glass rounded-3xl p-4 flex items-center justify-center gap-2 text-risk-high font-bold hover:bg-white/[0.03] transition-colors">
        <LogOut className="w-5 h-5" /> {t("logout")}
      </button>
    </div>
  );
}
