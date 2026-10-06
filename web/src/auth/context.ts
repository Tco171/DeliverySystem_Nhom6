import { createContext, useContext } from "react";
import type { SessionUser } from "../api";
export const AuthContext = createContext<{ user: SessionUser; logout: () => Promise<void> } | null>(null);
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("Không có phiên đăng nhập.");
  return context;
}
