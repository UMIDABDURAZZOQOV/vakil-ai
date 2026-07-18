"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";

export type Lang = "uz" | "ru" | "en";
const KEY = "vakil_lang";

type Dict = Record<string, string>;

const T: Record<Lang, Dict> = {
  uz: {
    // nav
    nav_features: "Xususiyatlar", nav_how: "Qanday ishlaydi", nav_pricing: "Narxlar",
    nav_login: "Kirish", nav_start: "Boshlash", get_app: "Ilovani olish",
    // hero
    hero_badge: "Sun'iy intellekt asosidagi yuridik yordamchi",
    hero_h1_a: "Hujjatlaringizni", hero_h1_b: "tushuning", hero_h1_c: "xavflarni", hero_h1_d: "oldindan biling",
    hero_p: "Shartnoma yoki hujjatni yuklang — Vakil AI xavfli bandlarni topadi, oddiy tilda tushuntiradi va savollaringizga javob beradi. O'zbekiston uchun.",
    hero_cta1: "Bepul boshlash", hero_cta2: "Qanday ishlaydi",
    trust_encrypted: "Shifrlangan", trust_free: "Bepul tarif",
    // stats
    stat1: "O'rtacha tahlil vaqti", stat2: "Hujjatga asoslangan javob", stat3: "Har doim yoningizda",
    sec: " soniya",
    // features
    feat_title: "Bir ilovada butun yuridik yordam",
    feat_sub: "Hujjatni yuklashdan tortib xavfsiz qaror qabul qilgunga qadar — hammasi shu yerda.",
    f1t: "Xavflarni oldindan aniqlang", f1d: "AI hujjatdagi xavfli bandlarni topib, yuqori/o'rta/past darajada belgilaydi.",
    f2t: "Oddiy tilda tushuntirish", f2d: "Murakkab yuridik matn oddiy, tushunarli qisqacha xulosaga aylanadi.",
    f3t: "Hujjat bo'yicha suhbat", f3d: "Savol bering — javob faqat sizning hujjatingiz asosida beriladi, to'qib chiqarmaydi.",
    f4t: "Muhim sanalar va muddatlar", f4d: "To'lov, uzaytirish va bekor qilish muddatlarini avtomatik ajratadi va eslatadi.",
    f5t: "Skaner va PDF", f5d: "Hujjatni suratga oling yoki PDF yuklang — matn avtomatik o'qiladi.",
    f6t: "O'zbek tilida", f6d: "O'zbekiston qonunchiligi va foydalanuvchilari uchun moslashtirilgan.",
    // how
    how_title: "Uch qadamda tayyor",
    s1t: "Hujjatni yuklang", s1d: "PDF yuklang yoki kamera bilan skanerlang.",
    s2t: "AI tahlil qiladi", s2d: "Bir necha soniyada xavf, xulosa va bandlar tayyor.",
    s3t: "Tushunib, harakat qiling", s3d: "Savol bering, muddatlarni ko'ring, xavfsiz qaror qabul qiling.",
    // pricing
    price_title: "Sodda narxlar", price_sub: "Bepul boshlang, kerak bo'lsa Premium'ga o'ting.",
    free: "Bepul", som: "so'm", popular: "Ommabop", premium: "Premium", per_month: "so'm/oy",
    free_1: "Oyiga 2 ta hujjat tahlili", free_2: "Xavf va xulosa", free_3: "Hujjat bo'yicha suhbat", free_4: "O'zbek tilida",
    prem_1: "Cheksiz hujjat tahlili", prem_2: "Muhim sanalar va eslatmalar", prem_3: "Ustuvor AI javoblari", prem_4: "Telegram integratsiyasi", prem_5: "Barcha bepul imkoniyatlar",
    get_premium: "Premium olish", pay_note: "To'lov: Payme va Click orqali",
    // download
    dl_title: "Bugun birinchi hujjatingizni tahlil qiling",
    dl_sub: "Vakil AI'ni web'da boshlang yoki ilovani yuklab oling — bepul.",
    dl_web: "Web'da boshlash", dl_login: "Hisobga kirish",
    // footer
    footer_tagline: "Sizning professional yuridik yordamchingiz.",
    footer_terms: "Shartlar", footer_privacy: "Maxfiylik",
    disclaimer: "Vakil AI umumiy ma'lumot beradi va professional yuridik maslahat o'rnini bosmaydi.",
    // auth
    login_title: "Xush kelibsiz", login_sub: "Hisobingizga kiring",
    reg_title: "Hisobingizni yarating", reg_sub: "Xavfsiz, AI asosidagi yuridik tahlil",
    ph_name: "Ismingiz", ph_id: "Telefon raqam yoki Email", ph_pass: "Parol", ph_pass6: "Parol (kamida 6 belgi)",
    no_account: "Hisobingiz yo'qmi?", have_account: "Hisobingiz bormi?", register: "Ro'yxatdan o'tish", log_in: "Kirish",
    secured: "Vakil AI shifrlash bilan himoyalangan", secured2: "Ma'lumotlaringiz xavfsiz saqlanadi",
    err_pass6: "Parol kamida 6 ta belgidan iborat bo'lsin", err_login: "Kirishda xatolik", err_reg: "Ro'yxatdan o'tishda xatolik",
    // dashboard
    hi: "Salom", quota_used: "Bu oy: {u}/{q} hujjat ishlatildi", unlimited: "Cheksiz hujjat tahlili",
    upload: "Hujjat yuklang", upload_sub: "PDF, matn yoki rasm · xavf va xulosa bir zumda",
    analyzing: "AI hujjatni tahlil qilyapti…", analyzing_sub: "Bir necha soniya",
    recent: "So'nggi hujjatlar", no_docs: "Hali hujjat yo'q. Birinchisini yuklang!",
    limit_reached: "Bepul limit tugadi — Premium tarifga o'ting.", upload_err: "Yuklashda xatolik",
    logout: "Chiqish", ready: "Tayyor",
    // risk
    risk_high: "Yuqori", risk_medium: "O'rta", risk_low: "Past", risk: "XAVF",
    // document
    documents: "Hujjatlar", summary: "Qisqacha", clauses: "Xavfli bandlar", key_dates: "Muhim sanalar",
    chat_title: "Hujjat bo'yicha suhbat", chat_empty: "Hujjat haqida savol bering — javob faqat shu hujjat asosida beriladi.",
    chat_ph: "Savolingizni yozing…", chat_err: "Kechirasiz, javob berishda xatolik. Qayta urinib ko'ring.",
    only_doc: "faqat hujjatingiz asosida",
    // premium page
    back: "Orqaga", pay_btn: "Payme yoki Click orqali to'lash",
    pay_secure: "To'lov Payme va Click orqali xavfsiz amalga oshiriladi.",
    settings: "Sozlamalar", account: "Hisob", language_label: "Til",
    plan_free: "Bepul tarif", plan_premium: "Premium tarif",
    testmode: "Sayt test rejimida ishlamoqda — xatoliklar bo'lishi mumkin.",
    demo_file: "Ijara shartnomasi.pdf", demo_analyzed: "AI tahlil qilindi · 3 soniya",
    demo_b1: "Shartnoma 12 oylik, avtomatik uzaytiriladi",
    demo_b2: "Ijara har yili 15% ga oshirilishi mumkin",
    demo_b3: "Bir tomonlama bekor qilish sharti mavjud",
    demo_f1: "Avtomatik uzaytirish bandi", demo_f2: "Jarima: oylik to'lovning 200%",
    demo_chat_title: "Vakil AI bilan suhbat",
    demo_q: "Shartnomani muddatidan oldin bekor qilsam nima bo'ladi?",
    demo_a: "Hujjatga ko'ra, muddatidan oldin bekor qilsangiz oylik to'lovning 200% miqdorida jarima to'laysiz (7-band). Bundan tashqari, kamida 30 kun oldin yozma ogohlantirish yuborishingiz shart.",
  },
  ru: {
    nav_features: "Возможности", nav_how: "Как это работает", nav_pricing: "Цены",
    nav_login: "Войти", nav_start: "Начать", get_app: "Скачать приложение",
    hero_badge: "Юридический помощник на базе ИИ",
    hero_h1_a: "Понимайте", hero_h1_b: "документы", hero_h1_c: "знайте риски", hero_h1_d: "заранее",
    hero_p: "Загрузите договор или документ — Vakil AI найдёт рискованные пункты, объяснит простым языком и ответит на вопросы. Для Узбекистана.",
    hero_cta1: "Начать бесплатно", hero_cta2: "Как это работает",
    trust_encrypted: "Шифрование", trust_free: "Бесплатный тариф",
    stat1: "Среднее время анализа", stat2: "Ответы на основе документа", stat3: "Всегда рядом",
    sec: " секунды",
    feat_title: "Вся юридическая помощь в одном приложении",
    feat_sub: "От загрузки документа до безопасного решения — всё здесь.",
    f1t: "Выявляйте риски заранее", f1d: "ИИ находит рискованные пункты и отмечает их как высокий/средний/низкий.",
    f2t: "Объяснение простым языком", f2d: "Сложный юридический текст превращается в понятное краткое резюме.",
    f3t: "Чат по документу", f3d: "Задайте вопрос — ответ только на основе вашего документа, без выдумок.",
    f4t: "Важные даты и сроки", f4d: "Автоматически находит сроки оплаты, продления и расторжения и напоминает.",
    f5t: "Сканер и PDF", f5d: "Сфотографируйте документ или загрузите PDF — текст распознаётся автоматически.",
    f6t: "На узбекском языке", f6d: "Адаптировано под законодательство и пользователей Узбекистана.",
    how_title: "Готово в три шага",
    s1t: "Загрузите документ", s1d: "Загрузите PDF или отсканируйте камерой.",
    s2t: "ИИ анализирует", s2d: "Риск, резюме и пункты готовы за секунды.",
    s3t: "Поймите и действуйте", s3d: "Задавайте вопросы, смотрите сроки, принимайте безопасные решения.",
    price_title: "Простые цены", price_sub: "Начните бесплатно, при необходимости — Premium.",
    free: "Бесплатно", som: "сум", popular: "Популярно", premium: "Premium", per_month: "сум/мес",
    free_1: "2 анализа документов в месяц", free_2: "Риск и резюме", free_3: "Чат по документу", free_4: "На узбекском",
    prem_1: "Безлимитный анализ документов", prem_2: "Важные даты и напоминания", prem_3: "Приоритетные ответы ИИ", prem_4: "Интеграция с Telegram", prem_5: "Все бесплатные возможности",
    get_premium: "Купить Premium", pay_note: "Оплата: через Payme и Click",
    dl_title: "Проанализируйте свой первый документ сегодня",
    dl_sub: "Начните в вебе или скачайте приложение Vakil AI — бесплатно.",
    dl_web: "Начать в вебе", dl_login: "Войти в аккаунт",
    footer_tagline: "Ваш профессиональный юридический помощник.",
    footer_terms: "Условия", footer_privacy: "Конфиденциальность",
    disclaimer: "Vakil AI даёт общую информацию и не заменяет профессиональную юридическую консультацию.",
    login_title: "Добро пожаловать", login_sub: "Войдите в свой аккаунт",
    reg_title: "Создайте аккаунт", reg_sub: "Безопасный юридический анализ на базе ИИ",
    ph_name: "Ваше имя", ph_id: "Телефон или Email", ph_pass: "Пароль", ph_pass6: "Пароль (минимум 6 символов)",
    no_account: "Нет аккаунта?", have_account: "Есть аккаунт?", register: "Регистрация", log_in: "Войти",
    secured: "Защищено шифрованием Vakil AI", secured2: "Ваши данные хранятся безопасно",
    err_pass6: "Пароль должен быть не менее 6 символов", err_login: "Ошибка входа", err_reg: "Ошибка регистрации",
    hi: "Привет", quota_used: "В этом месяце: {u}/{q} документов", unlimited: "Безлимитный анализ",
    upload: "Загрузите документ", upload_sub: "PDF, текст или фото · риск и резюме мгновенно",
    analyzing: "ИИ анализирует документ…", analyzing_sub: "Несколько секунд",
    recent: "Недавние документы", no_docs: "Документов пока нет. Загрузите первый!",
    limit_reached: "Бесплатный лимит исчерпан — перейдите на Premium.", upload_err: "Ошибка загрузки",
    logout: "Выйти", ready: "Готово",
    risk_high: "Высокий", risk_medium: "Средний", risk_low: "Низкий", risk: "РИСК",
    documents: "Документы", summary: "Кратко", clauses: "Рискованные пункты", key_dates: "Важные даты",
    chat_title: "Чат по документу", chat_empty: "Задайте вопрос — ответ только на основе этого документа.",
    chat_ph: "Напишите вопрос…", chat_err: "Извините, ошибка ответа. Попробуйте снова.",
    only_doc: "только на основе вашего документа",
    back: "Назад", pay_btn: "Оплатить через Payme или Click",
    pay_secure: "Оплата безопасно через Payme и Click.",
    settings: "Настройки", account: "Аккаунт", language_label: "Язык",
    plan_free: "Бесплатный тариф", plan_premium: "Premium тариф",
    testmode: "Сайт работает в тестовом режиме — возможны ошибки.",
    demo_file: "Договор аренды.pdf", demo_analyzed: "Проанализировано ИИ · 3 секунды",
    demo_b1: "Договор на 12 месяцев, продлевается автоматически",
    demo_b2: "Аренда может повышаться на 15% ежегодно",
    demo_b3: "Есть условие одностороннего расторжения",
    demo_f1: "Пункт об автопродлении", demo_f2: "Штраф: 200% ежемесячной платы",
    demo_chat_title: "Чат с Vakil AI",
    demo_q: "Что будет, если расторгнуть договор досрочно?",
    demo_a: "Согласно документу, при досрочном расторжении вы платите штраф в размере 200% ежемесячной платы (пункт 7). Кроме того, необходимо письменно уведомить минимум за 30 дней.",
  },
  en: {
    nav_features: "Features", nav_how: "How it works", nav_pricing: "Pricing",
    nav_login: "Log in", nav_start: "Get started", get_app: "Get the app",
    hero_badge: "AI-powered legal assistant",
    hero_h1_a: "Understand your", hero_h1_b: "documents", hero_h1_c: "know the risks", hero_h1_d: "in advance",
    hero_p: "Upload a contract or document — Vakil AI finds risky clauses, explains them in plain language and answers your questions. Built for Uzbekistan.",
    hero_cta1: "Start free", hero_cta2: "How it works",
    trust_encrypted: "Encrypted", trust_free: "Free tier",
    stat1: "Average analysis time", stat2: "Document-grounded answers", stat3: "Always with you",
    sec: " seconds",
    feat_title: "All your legal help in one app",
    feat_sub: "From uploading a document to a confident decision — it's all here.",
    f1t: "Spot risks in advance", f1d: "AI finds risky clauses and marks them high/medium/low.",
    f2t: "Plain-language explanations", f2d: "Complex legal text becomes a clear, simple summary.",
    f3t: "Chat about your document", f3d: "Ask anything — answers come only from your document, never made up.",
    f4t: "Key dates & deadlines", f4d: "Automatically extracts payment, renewal and cancellation dates and reminds you.",
    f5t: "Scan & PDF", f5d: "Snap a photo or upload a PDF — text is read automatically.",
    f6t: "In Uzbek", f6d: "Tailored to Uzbekistan's laws and users.",
    how_title: "Ready in three steps",
    s1t: "Upload a document", s1d: "Upload a PDF or scan with your camera.",
    s2t: "AI analyzes it", s2d: "Risk, summary and clauses ready in seconds.",
    s3t: "Understand and act", s3d: "Ask questions, see deadlines, make safe decisions.",
    price_title: "Simple pricing", price_sub: "Start free, upgrade to Premium when you need it.",
    free: "Free", som: "UZS", popular: "Popular", premium: "Premium", per_month: "UZS/mo",
    free_1: "2 document analyses per month", free_2: "Risk & summary", free_3: "Chat about your document", free_4: "In Uzbek",
    prem_1: "Unlimited document analysis", prem_2: "Key dates & reminders", prem_3: "Priority AI answers", prem_4: "Telegram integration", prem_5: "Everything in Free",
    get_premium: "Get Premium", pay_note: "Payment: via Payme and Click",
    dl_title: "Analyze your first document today",
    dl_sub: "Start on the web or download the Vakil AI app — free.",
    dl_web: "Start on web", dl_login: "Log in",
    footer_tagline: "Your professional legal assistant.",
    footer_terms: "Terms", footer_privacy: "Privacy",
    disclaimer: "Vakil AI provides general information and is not a substitute for professional legal advice.",
    login_title: "Welcome back", login_sub: "Log in to your account",
    reg_title: "Create your account", reg_sub: "Secure, AI-powered legal analysis",
    ph_name: "Your name", ph_id: "Phone or Email", ph_pass: "Password", ph_pass6: "Password (min 6 chars)",
    no_account: "No account?", have_account: "Have an account?", register: "Sign up", log_in: "Log in",
    secured: "Protected by Vakil AI encryption", secured2: "Your data is stored securely",
    err_pass6: "Password must be at least 6 characters", err_login: "Login failed", err_reg: "Registration failed",
    hi: "Hi", quota_used: "This month: {u}/{q} documents used", unlimited: "Unlimited analysis",
    upload: "Upload a document", upload_sub: "PDF, text or photo · risk & summary instantly",
    analyzing: "AI is analyzing the document…", analyzing_sub: "A few seconds",
    recent: "Recent documents", no_docs: "No documents yet. Upload your first!",
    limit_reached: "Free limit reached — upgrade to Premium.", upload_err: "Upload failed",
    logout: "Log out", ready: "Ready",
    risk_high: "High", risk_medium: "Medium", risk_low: "Low", risk: "RISK",
    documents: "Documents", summary: "Summary", clauses: "Risky clauses", key_dates: "Key dates",
    chat_title: "Chat about the document", chat_empty: "Ask a question — answers come only from this document.",
    chat_ph: "Type your question…", chat_err: "Sorry, something went wrong. Please try again.",
    only_doc: "grounded in your document",
    back: "Back", pay_btn: "Pay via Payme or Click",
    pay_secure: "Payment is processed securely via Payme and Click.",
    settings: "Settings", account: "Account", language_label: "Language",
    plan_free: "Free plan", plan_premium: "Premium plan",
    testmode: "The site is in test mode — errors may occur.",
    demo_file: "Rental agreement.pdf", demo_analyzed: "Analyzed by AI · 3 seconds",
    demo_b1: "12-month term, renews automatically",
    demo_b2: "Rent may increase by 15% each year",
    demo_b3: "Includes a one-sided termination clause",
    demo_f1: "Auto-renewal clause", demo_f2: "Penalty: 200% of monthly rent",
    demo_chat_title: "Chat with Vakil AI",
    demo_q: "What happens if I terminate the contract early?",
    demo_a: "According to the document, early termination incurs a penalty of 200% of the monthly rent (clause 7). You must also give written notice at least 30 days in advance.",
  },
};

interface Ctx {
  lang: Lang;
  setLang: (l: Lang) => void;
  t: (key: string) => string;
}
const LangContext = createContext<Ctx | undefined>(undefined);

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>("uz");
  useEffect(() => {
    const s = localStorage.getItem(KEY) as Lang | null;
    if (s === "uz" || s === "ru" || s === "en") setLangState(s);
  }, []);
  function setLang(l: Lang) {
    setLangState(l);
    localStorage.setItem(KEY, l);
  }
  const t = (key: string) => T[lang][key] ?? T.uz[key] ?? key;
  return <LangContext.Provider value={{ lang, setLang, t }}>{children}</LangContext.Provider>;
}

export function useLang(): Ctx {
  const c = useContext(LangContext);
  if (!c) throw new Error("useLang must be used within LanguageProvider");
  return c;
}

/** Risk label helper that respects the current language. */
export function riskLabelI18n(level: string, t: (k: string) => string): string {
  return level === "high" ? t("risk_high") : level === "medium" ? t("risk_medium") : t("risk_low");
}
