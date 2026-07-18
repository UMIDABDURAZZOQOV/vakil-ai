// Vakil AI web client — talks to the same FastAPI backend as the mobile app.
// All endpoints live under /api/v1; auth is a Bearer JWT.

export const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
const TOKEN_KEY = "vakil_token";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string) {
  localStorage.setItem(TOKEN_KEY, t);
}
export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

export interface ApiError extends Error {
  status?: number;
  detail?: unknown;
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { ...(options.headers as Record<string, string>) };
  if (!(options.body instanceof FormData)) headers["Content-Type"] = "application/json";
  const token = getToken();
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}/api/v1${path}`, { ...options, headers });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = typeof data?.detail === "string" ? data.detail : `Xatolik (${res.status})`;
    const err = new Error(msg) as ApiError;
    err.status = res.status;
    err.detail = data?.detail;
    throw err;
  }
  return data as T;
}

// ─── Types (mirror backend schemas) ───────────────────────────────────────────
export interface User {
  id: string;
  identifier: string;
  name: string;
  role: string;
  telegram_connected: boolean;
  is_premium: boolean;
  documents_used: number;
  documents_quota: number;
}
export interface ClauseFlag {
  title: string;
  risk_level: string; // high | medium | low
  explanation: string;
}
export interface DocumentSummary {
  id: string;
  title: string;
  status: string; // processing | completed | failed
  risk_level: string;
  risk_score: number;
  created_at: string;
}
export interface DocumentDetail extends DocumentSummary {
  original_text: string;
  summary_bullets: string[];
  key_dates: string[];
  compliance_scores: Record<string, number>;
  flags: ClauseFlag[];
}
export interface ChatMessage {
  id: string;
  is_user: boolean;
  text: string;
  created_at: string;
}

// ─── Auth ──────────────────────────────────────────────────────────────────────
export async function register(identifier: string, password: string, name = "") {
  return request<{ access_token: string }>("/auth/register", {
    method: "POST",
    body: JSON.stringify({ identifier, password, name }),
  });
}
export async function login(identifier: string, password: string) {
  return request<{ access_token: string }>("/auth/login", {
    method: "POST",
    body: JSON.stringify({ identifier, password }),
  });
}
export async function me() {
  return request<User>("/users/me");
}

// ─── Documents ───────────────────────────────────────────────────────────────
export async function listDocuments() {
  return request<DocumentSummary[]>("/documents");
}
export async function getDocument(id: string) {
  return request<DocumentDetail>(`/documents/${id}`);
}
export async function uploadDocument(file: File) {
  const fd = new FormData();
  fd.append("file", file);
  return request<DocumentDetail>("/documents/upload", { method: "POST", body: fd });
}

// ─── Chat ────────────────────────────────────────────────────────────────────
export async function getChat(documentId: string) {
  return request<ChatMessage[]>(`/documents/${documentId}/chat`);
}
export async function sendChat(documentId: string, text: string) {
  return request<ChatMessage[]>(`/documents/${documentId}/chat`, {
    method: "POST",
    body: JSON.stringify({ text }),
  });
}

// ─── Payments ────────────────────────────────────────────────────────────────
export async function createCheckout(provider: "payme" | "click") {
  return request<{ url: string }>("/payments/checkout-url", {
    method: "POST",
    body: JSON.stringify({ provider }),
  });
}

export function riskColor(level: string): string {
  return level === "high" ? "#E15554" : level === "medium" ? "#F2A93B" : "#2ECC8F";
}
export function riskLabel(level: string): string {
  return level === "high" ? "Yuqori" : level === "medium" ? "O'rta" : "Past";
}
