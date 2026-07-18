# Vakil AI — project memory (CLAUDE.md)

Vakil AI ("vakil" = lawyer) is an **AI legal-document assistant for Uzbekistan**. A user uploads a
contract or document (PDF / text / image); the AI extracts the text, flags **risky clauses**
(high/medium/low), writes a plain-language **summary**, pulls out **key dates/deadlines**, and lets
the user **chat about the document** (answers are grounded ONLY in that document — no hallucination).
Free tier = 2 documents/month; Premium = 49 000 UZS/month via **Payme / Click**. In Uzbek/Russian/
English. Telegram bot integration.

The code is the source of truth; this file is the narrative so context isn't lost across
machines/sessions.

## Repo layout (`C:\Users\Page\Desktop\Vakil AI\`)
- `backend/` — **FastAPI** API (async SQLAlchemy + SQLite, Gemini AI, Payme/Click, Telegram bot).
  Serves both the mobile app and the web app. Runs with its own `venv`.
- `vakil_ai/` — **Flutter** mobile app (also has a `web/` folder). The original product.
- `website/` — **Next.js 14 web app** (BUILT THIS SESSION 2026-07-18) — a full marketing landing +
  functional web app that talks to the same backend. Not a git repo yet.
- `vakil_ai_bot_logo.png` — the brand logo (copied into `website/public/vakil-logo.png`).

## Brand (from `vakil_ai/lib/core/theme/app_colors.dart`)
Navy (`#0A1730`→`#1E3157`), Emerald `#22C58B`, Gold `#CBA35C`; risk colors high `#E15554`, medium
`#F2A93B`, low `#2ECC8F`. Tagline: "Sizning professional yuridik yordamchingiz". Dark-first design.

## Backend (`backend/`)
FastAPI, prefix **`/api/v1`**, Bearer-JWT auth (`app/api/deps.py::get_current_user`).
- **Endpoints:** `POST /auth/register` `{identifier,password,name}` → `{access_token}`;
  `POST /auth/login`; `GET /users/me` → UserOut; `GET /documents`; `GET /documents/{id}`;
  `POST /documents/upload` (multipart `file`, 402 when free limit hit); `GET|POST /documents/{id}/chat`;
  `POST /payments/checkout-url` `{provider: "payme"|"click"}` → `{url}`; Payme/Click webhooks.
- **Models** (`app/db/models.py`): `User` (identifier=phone/email, is_premium, premium_until,
  documents_used_this_period, telegram_connected), `Document` (title, original_text, risk_level,
  risk_score, summary_bullets JSON, key_dates JSON, compliance_scores JSON, status), `ClauseFlag`
  (title, risk_level, explanation), `ChatMessage`, `Deadline`, `Payment`.
- **AI** (`app/services/ai_provider.py`): abstract `AIProvider` with a Gemini impl (`gemini-2.5-flash`)
  and an offline fallback (works with no key). `analyze_document()` + `chat_reply()` (chat is
  strictly document-grounded). Needs `GEMINI_API_KEY` in `backend/.env` for real output.
- **Config** (`app/core/config.py`): `free_tier_document_limit=2`, `premium_price_uzs=49000`,
  Payme/Click keys, `telegram_bot_token`. **Run:** `backend/venv/Scripts/python.exe -m uvicorn
  app.main:app --port 8000`.
- **CORS** currently `allow_origins=["*"]` — tighten to the real web origin before production.

## Flutter app (`vakil_ai/`) — reviewed, clean
Screens: splash, onboarding, auth (welcome/login/register), dashboard, scanner (camera),
analysis detail, chat, history, settings, shell. `flutter analyze` = **3 trivial info lints only**
(no errors/warnings). i18n uz/ru/en in `lib/core/localization/app_strings.dart`. Well-architected,
near production-ready.

## Website (`website/`) — BUILT THIS SESSION (Next.js 14, TS, Tailwind, framer-motion)
A full, professional, animated web app in the Ilm-AI style — **not just a landing page**: it has the
app's real features wired to the backend. Dark-first, glass cards, aurora blobs, animated demos.

- **Config:** `package.json`, `tailwind.config.js` (brand colors), `tsconfig.json`, `next.config.mjs`,
  `postcss.config.js`, `src/app/globals.css` (CSS-variable theming + light-mode overrides + `.glass`).
- **API client** `src/lib/api.ts` — base `NEXT_PUBLIC_API_URL` (default `http://localhost:8000`),
  token in localStorage, typed fns for every endpoint (auth, me, documents, upload, chat, checkout).
- **i18n** `src/lib/i18n.tsx` — `LanguageProvider` + `useLang()` + `t()`, full uz/ru/en dict,
  localStorage-persisted; `LangSwitcher.tsx` (UZ/RU/EN). Everything is translated, including the demo.
- **Theme** `src/lib/theme.tsx` + `ThemeToggle.tsx` — dark/light toggle. globals.css defines
  `:root` (dark) and `:root.light` vars, plus light-mode `!important` overrides for the dark utility
  classes actually used (`text-white/XX`, `bg-white/[...]`, `border-white/XX`, `bg-navy-*`). Boot
  script in `layout.tsx` applies the saved theme before paint (no flash).
- **Pages:**
  - `/` (`app/page.tsx`) — landing: nav (theme+lang+login+start), animated hero + `DemoShowcase`,
    stats (count-up), 6 feature cards (tilt/hover), how-it-works, pricing (Free/Premium), download CTA,
    footer. All CTAs go to `/register`.
  - `DemoShowcase.tsx` — two self-playing demos: an animated document risk-analysis card (risk gauge
    sweeps, bullets + clause flags appear) and an AI chat card (typing → grounded answer). Original
    example content, fully i18n.
  - `/login`, `/register` — auth, save token, redirect to `/app`.
  - `/app` — dashboard: upload (file→analyze→redirect), document list (risk badges), quota, header
    with theme/lang/settings/premium/logout.
  - `/app/[id]` — document detail: risk ring, summary, expandable clause flags, key dates, + live
    per-document **AI chat**.
  - `/app/settings` — profile, plan/quota, language, theme, logout.
  - `/app/premium` — real **Payme/Click** checkout (calls `/payments/checkout-url`, redirects to url).
- **Test-mode notice** `TestModeBanner.tsx` — slim gold dismissible bar at top of every page
  (uz/ru/en), rendered in `layout.tsx`. Remove when leaving test mode.
- **Verified:** `npm run build` clean (9 routes); backend smoke test passed (register→token→me,
  document upload path, checkout endpoint). Run: `cd website && npm run dev`.

### Gotcha (Windows/Next dev)
Running `npm run build` (production) while `next dev` is running corrupts `.next` → "Cannot find
module './xxx.js'". Fix: stop dev, `rm -rf .next`, restart. Don't build while dev is running.

## Status (2026-07-18)
- Backend: works locally (17 routes), needs `GEMINI_API_KEY` for real AI; CORS still `*`.
- Flutter app: reviewed, clean.
- Website: full feature parity with the app (auth, upload, analysis, chat, settings, premium),
  3 languages, dark/light, animated. Built & building cleanly; not deployed yet.

## Planned next (not done yet)
- Deploy: push `website/` to GitHub → Vercel; backend → Render (like Ilm AI). Set `NEXT_PUBLIC_API_URL`
  to the prod backend, tighten backend CORS to the web origin, add real Payme/Click + Gemini keys.
- Optional: a dedicated web camera-scan UX (upload already accepts images), history search,
  Telegram-link flow on web.
