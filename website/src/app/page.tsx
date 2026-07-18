"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import { motion, useInView, type Variants } from "framer-motion";
import {
  ShieldCheck, ScanLine, MessagesSquare, CalendarClock, FileSearch, Languages,
  Lock, Check, ArrowRight, Menu, X, Sparkles,
} from "lucide-react";
import DemoShowcase from "@/components/DemoShowcase";
import LangSwitcher from "@/components/LangSwitcher";
import ThemeToggle from "@/components/ThemeToggle";
import { useLang } from "@/lib/i18n";

const fadeUp: Variants = {
  hidden: { opacity: 0, y: 28 },
  show: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.16, 1, 0.3, 1] } },
};
const stagger: Variants = { hidden: {}, show: { transition: { staggerChildren: 0.1 } } };

function Counter({ to, suffix = "" }: { to: number; suffix?: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "-60px" });
  const [n, setN] = useState(0);
  useEffect(() => {
    if (!inView) return;
    const start = performance.now();
    let raf = 0;
    const loop = (t: number) => {
      const p = Math.min(1, (t - start) / 1200);
      setN(Math.round(to * (1 - Math.pow(1 - p, 3))));
      if (p < 1) raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [inView, to]);
  return <span ref={ref}>{n.toLocaleString()}{suffix}</span>;
}

export default function Page() {
  const { t } = useLang();
  const [menu, setMenu] = useState(false);

  const features = [
    { icon: ShieldCheck, color: "#22C58B", t: "f1t", d: "f1d" },
    { icon: FileSearch, color: "#CBA35C", t: "f2t", d: "f2d" },
    { icon: MessagesSquare, color: "#1CB0F6", t: "f3t", d: "f3d" },
    { icon: CalendarClock, color: "#F2A93B", t: "f4t", d: "f4d" },
    { icon: ScanLine, color: "#7048E8", t: "f5t", d: "f5d" },
    { icon: Languages, color: "#E15554", t: "f6t", d: "f6d" },
  ];
  const steps = [
    { n: "1", t: "s1t", d: "s1d" },
    { n: "2", t: "s2t", d: "s2d" },
    { n: "3", t: "s3t", d: "s3d" },
  ];

  return (
    <div className="relative min-h-screen text-white">
      {/* Nav */}
      <header className="sticky top-0 z-50 border-b border-white/5 bg-navy-darkest/70 backdrop-blur-xl">
        <div className="max-w-6xl mx-auto px-5 h-16 flex items-center justify-between">
          <a href="#" className="flex items-center gap-2.5">
            <Image src="/vakil-logo.png" alt="Vakil AI" width={36} height={36} className="rounded-xl" />
            <span className="font-extrabold text-lg tracking-tight">Vakil <span className="text-emerald">AI</span></span>
          </a>
          <nav className="hidden md:flex items-center gap-8 text-sm font-semibold text-white/70">
            <a href="#features" className="hover:text-white transition-colors">{t("nav_features")}</a>
            <a href="#how" className="hover:text-white transition-colors">{t("nav_how")}</a>
            <a href="#pricing" className="hover:text-white transition-colors">{t("nav_pricing")}</a>
          </nav>
          <div className="hidden md:flex items-center gap-3">
            <ThemeToggle />
            <LangSwitcher />
            <a href="/login" className="text-sm font-bold text-white/70 hover:text-white transition-colors">{t("nav_login")}</a>
            <a href="/register" className="bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold text-sm px-5 py-2.5 rounded-xl transition-colors">{t("nav_start")}</a>
          </div>
          <button className="md:hidden p-2" onClick={() => setMenu(!menu)} aria-label="Menu">
            {menu ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
        {menu && (
          <div className="md:hidden border-t border-white/5 px-5 py-4 flex flex-col gap-4 text-sm font-semibold bg-navy-darkest">
            <a href="#features" onClick={() => setMenu(false)}>{t("nav_features")}</a>
            <a href="#how" onClick={() => setMenu(false)}>{t("nav_how")}</a>
            <a href="#pricing" onClick={() => setMenu(false)}>{t("nav_pricing")}</a>
            <LangSwitcher className="self-start" />
            <a href="/login" onClick={() => setMenu(false)} className="font-bold py-1">{t("nav_login")}</a>
            <a href="/register" onClick={() => setMenu(false)} className="bg-emerald text-navy-darkest font-bold px-5 py-2.5 rounded-xl text-center">{t("nav_start")}</a>
          </div>
        )}
      </header>

      {/* Hero */}
      <section className="relative overflow-hidden pt-16 pb-20 md:pt-24 md:pb-28">
        <div className="blob w-[440px] h-[440px] -top-24 -left-24 bg-emerald/30" />
        <div className="blob w-[380px] h-[380px] top-10 -right-20 bg-gold/20" style={{ animationDelay: "-7s" }} />
        <div className="absolute inset-0 grid-bg" />
        <div className="relative max-w-6xl mx-auto px-5 grid lg:grid-cols-2 gap-12 items-center">
          <motion.div initial="hidden" animate="show" variants={stagger}>
            <motion.div variants={fadeUp} className="inline-flex items-center gap-2 rounded-full border border-emerald/30 bg-emerald/10 px-3 py-1.5 text-xs font-bold text-emerald mb-6">
              <Sparkles className="w-3.5 h-3.5" /> {t("hero_badge")}
            </motion.div>
            <motion.h1 variants={fadeUp} className="text-4xl sm:text-5xl md:text-[3.4rem] font-black leading-[1.05] tracking-tight">
              {t("hero_h1_a")} <span className="text-emerald">{t("hero_h1_b")}</span>,<br />{t("hero_h1_c")} <span className="text-gold">{t("hero_h1_d")}</span>.
            </motion.h1>
            <motion.p variants={fadeUp} className="mt-5 text-lg text-white/70 max-w-md leading-relaxed">{t("hero_p")}</motion.p>
            <motion.div variants={fadeUp} className="mt-8 flex flex-wrap gap-3">
              <a href="/register" className="inline-flex items-center gap-2 bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold px-6 py-3.5 rounded-2xl transition-colors">
                {t("hero_cta1")} <ArrowRight className="w-4 h-4" />
              </a>
              <a href="#how" className="inline-flex items-center gap-2 border border-white/15 hover:bg-white/5 font-bold px-6 py-3.5 rounded-2xl transition-colors">{t("hero_cta2")}</a>
            </motion.div>
            <motion.div variants={fadeUp} className="mt-8 flex items-center gap-6 text-sm text-white/50">
              <span className="flex items-center gap-1.5"><Lock className="w-4 h-4 text-emerald" /> {t("trust_encrypted")}</span>
              <span className="flex items-center gap-1.5"><Check className="w-4 h-4 text-emerald" /> {t("trust_free")}</span>
            </motion.div>
          </motion.div>
          <motion.div initial={{ opacity: 0, scale: 0.95, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.15 }}>
            <DemoShowcase />
          </motion.div>
        </div>
      </section>

      {/* Stats */}
      <section className="max-w-5xl mx-auto px-5 pb-16">
        <div className="glass rounded-3xl grid grid-cols-3 divide-x divide-white/10 py-7">
          {[
            { v: 3, s: t("sec"), l: t("stat1") },
            { v: 100, s: "%", l: t("stat2") },
            { v: 24, s: "/7", l: t("stat3") },
          ].map((x) => (
            <div key={x.l} className="text-center px-3">
              <div className="text-3xl sm:text-4xl font-black text-emerald"><Counter to={x.v} suffix={x.s} /></div>
              <div className="text-xs sm:text-sm text-white/60 mt-1">{x.l}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section id="features" className="max-w-6xl mx-auto px-5 py-16 md:py-24">
        <motion.div initial="hidden" whileInView="show" viewport={{ once: true }} variants={fadeUp} className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black tracking-tight">{t("feat_title")}</h2>
          <p className="mt-3 text-white/60 max-w-xl mx-auto">{t("feat_sub")}</p>
        </motion.div>
        <motion.div initial="hidden" whileInView="show" viewport={{ once: true, margin: "-60px" }} variants={stagger} className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {features.map((f) => (
            <motion.div key={f.t} variants={fadeUp} whileHover={{ y: -6 }} className="glass rounded-3xl p-6 transition-shadow hover:shadow-[0_30px_70px_-30px_rgba(34,197,139,0.35)] group">
              <div className="w-12 h-12 rounded-2xl grid place-items-center mb-5 transition-transform group-hover:scale-110 group-hover:-rotate-6" style={{ backgroundColor: `${f.color}1f` }}>
                <f.icon className="w-6 h-6" style={{ color: f.color }} />
              </div>
              <h3 className="font-bold text-lg mb-2">{t(f.t)}</h3>
              <p className="text-sm text-white/60 leading-relaxed">{t(f.d)}</p>
            </motion.div>
          ))}
        </motion.div>
      </section>

      {/* How it works */}
      <section id="how" className="max-w-5xl mx-auto px-5 py-16 md:py-24">
        <motion.h2 initial="hidden" whileInView="show" viewport={{ once: true }} variants={fadeUp} className="text-3xl md:text-4xl font-black text-center tracking-tight mb-14">
          {t("how_title")}
        </motion.h2>
        <div className="grid md:grid-cols-3 gap-6">
          {steps.map((s, i) => (
            <motion.div key={s.n} initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.5, delay: i * 0.12 }} className="glass rounded-3xl p-7 text-center">
              <div className="w-14 h-14 rounded-2xl bg-emerald text-navy-darkest text-2xl font-black grid place-items-center mx-auto mb-5">{s.n}</div>
              <h3 className="font-bold text-lg mb-2">{t(s.t)}</h3>
              <p className="text-sm text-white/60">{t(s.d)}</p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="max-w-4xl mx-auto px-5 py-16 md:py-24">
        <motion.div initial="hidden" whileInView="show" viewport={{ once: true }} variants={fadeUp} className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black tracking-tight">{t("price_title")}</h2>
          <p className="mt-3 text-white/60">{t("price_sub")}</p>
        </motion.div>
        <div className="grid sm:grid-cols-2 gap-5">
          <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="glass rounded-3xl p-7">
            <p className="text-sm font-bold text-white/60 uppercase tracking-wider">{t("free")}</p>
            <div className="mt-2 text-4xl font-black">0 <span className="text-lg text-white/50 font-bold">{t("som")}</span></div>
            <ul className="mt-6 space-y-3 text-sm">
              {["free_1", "free_2", "free_3", "free_4"].map((k) => (
                <li key={k} className="flex items-center gap-2.5 text-white/80"><Check className="w-4 h-4 text-emerald shrink-0" /> {t(k)}</li>
              ))}
            </ul>
            <a href="/register" className="mt-7 block text-center border border-white/15 hover:bg-white/5 font-bold py-3 rounded-2xl transition-colors">{t("nav_start")}</a>
          </motion.div>
          <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.1 }} className="rounded-3xl p-7 relative overflow-hidden border-2 border-emerald/40 bg-gradient-to-br from-emerald/10 to-gold/5">
            <span className="absolute top-5 right-5 text-[11px] font-bold px-2.5 py-1 rounded-full bg-gold text-navy-darkest">{t("popular")}</span>
            <p className="text-sm font-bold text-emerald uppercase tracking-wider">{t("premium")}</p>
            <div className="mt-2 text-4xl font-black">49 000 <span className="text-lg text-white/50 font-bold">{t("per_month")}</span></div>
            <ul className="mt-6 space-y-3 text-sm">
              {["prem_1", "prem_2", "prem_3", "prem_4", "prem_5"].map((k) => (
                <li key={k} className="flex items-center gap-2.5 text-white/90"><Check className="w-4 h-4 text-emerald shrink-0" /> {t(k)}</li>
              ))}
            </ul>
            <a href="/register" className="mt-7 block text-center bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold py-3 rounded-2xl transition-colors">{t("get_premium")}</a>
          </motion.div>
        </div>
        <p className="text-center text-xs text-white/40 mt-5">{t("pay_note")}</p>
      </section>

      {/* Download CTA */}
      <section id="download" className="max-w-5xl mx-auto px-5 py-16 md:py-24">
        <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="relative overflow-hidden rounded-[2rem] border border-white/10 bg-gradient-to-br from-navy-light to-navy-card p-9 md:p-14 text-center">
          <div className="blob w-[320px] h-[320px] -top-20 left-1/2 -translate-x-1/2 bg-emerald/25" />
          <div className="relative">
            <Image src="/vakil-logo.png" alt="Vakil AI" width={64} height={64} className="rounded-2xl mx-auto mb-6" />
            <h2 className="text-3xl md:text-4xl font-black tracking-tight">{t("dl_title")}</h2>
            <p className="mt-3 text-white/60 max-w-lg mx-auto">{t("dl_sub")}</p>
            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <a href="/register" className="inline-flex items-center gap-2 bg-emerald hover:bg-emerald-dark text-navy-darkest font-bold px-6 py-3.5 rounded-2xl transition-colors">
                <ScanLine className="w-4 h-4" /> {t("dl_web")}
              </a>
              <a href="/login" className="inline-flex items-center gap-2 border border-white/15 hover:bg-white/5 font-bold px-6 py-3.5 rounded-2xl transition-colors">{t("dl_login")}</a>
            </div>
          </div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/5">
        <div className="max-w-6xl mx-auto px-5 py-10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2.5">
            <Image src="/vakil-logo.png" alt="Vakil AI" width={28} height={28} className="rounded-lg" />
            <span className="font-extrabold">Vakil <span className="text-emerald">AI</span></span>
          </div>
          <p className="text-sm text-white/40">© 2026 Vakil AI. {t("footer_tagline")}</p>
          <div className="flex gap-5 text-sm text-white/50">
            <a href="#" className="hover:text-white">{t("footer_terms")}</a>
            <a href="#" className="hover:text-white">{t("footer_privacy")}</a>
          </div>
        </div>
        <p className="text-center text-[11px] text-white/25 pb-6 px-5">{t("disclaimer")}</p>
      </footer>
    </div>
  );
}
