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
- `website/` — **Next.js 14 web app** — a full marketing landing + functional web app that talks to
  the same backend. In the project's git repo; **deployed to Vercel** (see Deployment).
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
- **CORS** reads `ALLOWED_ORIGINS` (comma-separated) from env, default `*`. In production on Render
  it is now set to the real web origins (see Deployment). When not `*`, `allow_credentials` stays
  False and auth is Bearer-token (not cookies), so a restricted origin list is safe.
- **DB URL** `app/db/base.py::_normalize_db_url()` accepts any `DATABASE_URL` — rewrites
  `postgres://`/`postgresql://` → `postgresql+asyncpg://`; empty falls back to SQLite. `asyncpg` is in
  requirements. So dropping in a Neon Postgres URL "just works".

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

## On GitHub (2026-07-18)
- **Repo: https://github.com/UMIDABDURAZZOQOV/vakil-ai** (public). ONE repo for the whole project —
  `backend/` + `vakil_ai/` (Flutter) + `website/` all together (the user wanted app + web in one).
  Git was initialised at the project root (`Desktop/Vakil AI/`). `ilm-ai-flutter` and the other Ilm
  AI repos were NOT touched — this is a brand-new repo.
- **`.gitignore`** (project root) excludes all secrets/big dirs: `.env`, `*.db` (incl.
  `backend/vakil_ai.db`), `venv/`, `node_modules/`, `.next/`, Flutter `build/` + `.dart_tool/`, logs.
  Verified nothing sensitive was committed.
- **`README.md`** — in ENGLISH (the user asked). Has 4 screenshots under `website/screenshots/`:
  `landing.png`, `login.png`, `register.png` (web) + `backend-api.png` (FastAPI Swagger `/docs`).
- **Screenshots were captured with Edge headless** (`msedge.exe --headless=new --screenshot=... 
  --virtual-time-budget=7000`). Key lesson: **need `--virtual-time-budget` (~7s)** so React hydrates
  and framer-motion mount animations finish, else the page is blank; and `whileInView` (scroll-
  triggered) sections stay invisible in a headless capture, so shoot at viewport height (hero renders
  via mount `animate`, not scroll). Swagger `/docs` also needs the time budget to render.

## Deployment — LIVE (2026-07-19 / 20)

Both halves are deployed and verified end-to-end (register → login → `/users/me` → CORS all pass).

### Frontend → Vercel
- **Live URL: https://vakil-ai-uz.vercel.app** (full app: `/`, `/login`, `/register`, `/app`,
  `/app/[id]`, `/app/premium`, `/app/settings`).
- Vercel account **pubgmobile200820102009@gmail.com**, project **`vakil-ai`**
  (id `prj_SmSC9puS9UY85KmW07N7zRMjL7KS`), **Root Directory = `website`**, Framework Next.js.
- Env: `NEXT_PUBLIC_API_URL = https://vakil-ai-backend-8yqj.onrender.com` (Production).
- The name **`vakil-ai.vercel.app` is owned by a DIFFERENT account** — cannot be claimed (Vercel
  subdomains are globally unique). So we aliased the deployment to the free **`vakil-ai-uz.vercel.app`**
  (`vercel alias set <deployment> vakil-ai-uz.vercel.app`). Other free names if we ever switch:
  `vakil-app`, `vakiluz`, `vakil-legal-ai`.
- **Deployment Protection was ON** (Vercel Authentication / SSO) → every URL 302-redirected to
  `vercel.com/sso-api`. Disabled with **`vercel project protection disable vakil-ai --sso`**
  (`ssoProtection:false`). Without this the site is not public.
- **Deploy method** (the project's git-based prod URL `vakil-ai-ebon.vercel.app` was dead/404, so we
  deployed from the CLI): `vercel deploy --prod --yes --cwd "<repo root>" --token <TOKEN>`. The CLI
  respects the project's `Root Directory=website`, so deploy **from the repo root**, not from inside
  `website/`.
  - **Gotcha:** deploying from the repo root first uploaded **856 MB** and failed with
    *"File size limit exceeded (100 MB)"* (it swept in `backend/`, `vakil_ai/` Flutter, `.git`).
    Fixed by adding a **`.vercelignore`** at the repo root that excludes `/.git /backend /vakil_ai`
    and all `node_modules/.next/build/.dart_tool` — then the upload is just the `website/` source.

### Backend → Render
- **Live URL: https://vakil-ai-backend-8yqj.onrender.com** (`/api/v1/health` → 200, `/docs` works).
- Render service **`vakil-ai-backend`** (id `srv-d9e41djrjlhs73bm7rlg`), blueprint `render.yaml`.
- **`ALLOWED_ORIGINS`** set (via Render API) to
  `https://vakil-ai-uz.vercel.app,https://vakil-ai.com,https://www.vakil-ai.com` — CORS now echoes the
  specific origin, no longer `*`. Setting an env var via API does **not** auto-deploy; had to trigger
  a deploy (`POST /v1/services/<id>/deploys`) for it to take effect.
- **Python pinned to 3.12.7** (`backend/.python-version` + `PYTHON_VERSION` env) — Render's default
  3.14 has no pydantic-core wheel and the Rust build fails.
- **render.yaml has NO `databases:` block** — Render's free plan allows only ONE free Postgres per
  account (would clash with Ilm AI's). So the backend runs on **built-in SQLite**.

### AI — REAL Gemini live (verified 2026-07-20)
`GEMINI_API_KEY` is now set on Render → the AI is **no longer the mock fallback**. Verified
end-to-end by uploading a real service contract: it returned `risk_level: high`, **7 clause flags**
(HIGH/MED/LOW) each with genuine Uzbek legal reasoning, **5 extracted key dates**, and a grounded,
clause-numbered chat answer. (Mock mode is detectable by the literal word "mock" in the output — it
was gone.) Two minor quirks noticed: `risk_score` scale looks off (returned `1.0` for a HIGH doc —
UI shows the level word, so cosmetic), and `compliance_scores` came back 0/0/0 for a contract with
no data-protection clauses (arguably correct, but looks empty in the UI). Payme checkout returns a
real **test** URL (`checkout.test.paycom.uz`, `PAYME_TEST_MODE=true`).

### ⚠️ Known limitation — ephemeral data
Render free tier = **SQLite in ephemeral storage → all users/documents are WIPED on every
redeploy/restart.** Fine for a test/demo; for real users add a free **Neon Postgres**
(https://neon.tech) and set its `postgresql://…` URL as **`DATABASE_URL`** on Render (the backend
auto-converts to async — see `_normalize_db_url`). Not done yet.

### Custom domain `vakil-ai.com` — owned but DNS broken (not done)
The user owns **vakil-ai.com** (registrar joker.com); the Vercel deployment is already aliased to
`www.vakil-ai.com`. But its nameservers are `DIRECTI1/2.IRANDNS.COM`, which **don't answer** ("No
Reachable Authority") → the domain doesn't resolve anywhere. To use it: at the registrar, switch
nameservers to Vercel's (`ns1.vercel-dns.com`, `ns2.vercel-dns.com`) **or** add `A @ 76.76.21.21`
+ `CNAME www cname.vercel-dns.com` (use the exact values Vercel's Domains tab shows). Once fixed,
`vakil-ai.com` is more professional than any `.vercel.app`.

### Secrets used this session (rotate/revoke when done)
Deploys were driven with a **Vercel token** (`vcp_…`) and a **Render API key** (`rnd_…`) the user
pasted. These are account-scoped — the user should revoke them when they no longer want CLI/API
access.

## Still optional (not done)
- Real Payme/Click **production** keys on Render (Payme is in test mode now — `PAYME_TEST_MODE=true`).
- Neon Postgres for persistent data (see limitation above).
- (done) `GEMINI_API_KEY` is set — AI is live/real.
- Fix `vakil-ai.com` DNS; then add it (and drop `-uz`) as the primary origin.
- A dedicated web camera-scan UX, history search, Telegram-link flow on web.
- Remove `TestModeBanner` when leaving test mode.
