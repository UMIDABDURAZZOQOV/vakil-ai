import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { LanguageProvider } from "@/lib/i18n";
import { ThemeProvider } from "@/lib/theme";
import TestModeBanner from "@/components/TestModeBanner";

const jakarta = Plus_Jakarta_Sans({ subsets: ["latin"], variable: "--font-jakarta" });

export const metadata: Metadata = {
  title: "Vakil AI — Sizning professional yuridik yordamchingiz",
  description:
    "Hujjatingizni yuklang — Vakil AI sun'iy intellekt bilan xavflarni aniqlaydi, muhim bandlarni tushuntiradi va savollaringizga javob beradi. O'zbekiston uchun.",
  icons: { icon: "/vakil-logo.png" },
};

// Apply the saved theme before paint so there's no flash.
const THEME_BOOT = `
(function(){try{if(localStorage.getItem("vakil_theme")==="light")document.documentElement.classList.add("light");}catch(e){}})();
`;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz">
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_BOOT }} />
      </head>
      <body className={`${jakarta.variable} font-sans antialiased`}>
        <ThemeProvider>
          <LanguageProvider>
            <TestModeBanner />
            {children}
          </LanguageProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
