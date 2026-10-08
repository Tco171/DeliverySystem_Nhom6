export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) { super(message); this.status = status; }
}
const BASE = (import.meta.env.VITE_API_BASE_URL ?? "").replace(/\/$/, "");
export async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const headers = new Headers(init?.headers);
  headers.set("Accept", "application/json");
  const savedUser = localStorage.getItem("express-user");
  if (savedUser) {
    try {
      const user = JSON.parse(savedUser) as { id?: string };
      if (user.id) headers.set("X-User-Id", user.id);
    } catch {
      // Ignore invalid local session data.
    }
  }
  if (init?.body) headers.set("Content-Type", "application/json");
  let response: Response;
  try { response = await fetch(`${BASE}/api/v1${path}`, { ...init, headers, credentials: "include", signal: init?.signal ?? AbortSignal.timeout(15000) }); }
  catch { throw new ApiError(0, "Không kết nối được máy chủ. Vui lòng thử lại sau."); }
  const raw = await response.text();
  let body: unknown = null;
  try { body = raw ? JSON.parse(raw) : null; } catch { /* Validated below. */ }
  if (!response.ok) {
    if (response.status === 401 && !path.startsWith("/auth/")) window.dispatchEvent(new Event("express:session-expired"));
    const problem = body as { message?: string; title?: string; errors?: Record<string, string[]> } | null;
    const fields = problem?.errors && Object.values(problem.errors).flat().filter(v => typeof v === "string");
    throw new ApiError(response.status, problem?.message || (fields?.length ? fields.join(" ") : problem?.title) || `Yêu cầu không thành công (${response.status}).`);
  }
  if (response.status === 204) return undefined as T;
  if (!raw || body === null && raw.trim() !== "null") throw new ApiError(response.status, "Máy chủ trả về dữ liệu không hợp lệ.");
  return body as T;
}
