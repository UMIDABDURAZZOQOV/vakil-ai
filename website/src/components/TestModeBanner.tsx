"use client";

import { useEffect, useState } from "react";
import { X, AlertTriangle } from "lucide-react";
import { useLang } from "@/lib/i18n";

export default function TestModeBanner() {
  const { t } = useLang();
  const [hidden, setHidden] = useState(true);

  useEffect(() => {
    setHidden(sessionStorage.getItem("vakil_testmode_dismissed") === "1");
  }, []);

  if (hidden) return null;

  return (
    <div className="relative z-[60] flex items-center justify-center gap-2 bg-gold text-navy-darkest text-[13px] font-bold px-9 py-1.5 text-center">
      <AlertTriangle className="w-4 h-4 shrink-0" />
      <span>{t("testmode")}</span>
      <button
        onClick={() => {
          sessionStorage.setItem("vakil_testmode_dismissed", "1");
          setHidden(true);
        }}
        aria-label="Close"
        className="absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded hover:bg-navy-darkest/10"
      >
        <X className="w-3.5 h-3.5" />
      </button>
    </div>
  );
}
