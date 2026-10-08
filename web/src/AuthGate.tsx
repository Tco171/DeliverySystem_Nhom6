import { useEffect, useRef, useState } from "react";
import type { FormEvent, ReactNode } from "react";
import { api } from "./api";
import type { SessionUser } from "./api";
import { AuthContext } from "./auth/context";
import type { AuthMode } from "./auth/context";
import "./App.css";
import "./auth/auth.css";

export default function AuthGate({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [checkingSession, setCheckingSession] = useState(true);
  const [sessionError, setSessionError] = useState("");
  const [authOpen, setAuthOpen] = useState(false);
  const [authMode, setAuthMode] = useState<AuthMode>("login");

  useEffect(() => {
    let active = true;

    api
      .getSession()
      .then((value) => {
        if (active) setUser(value);
      })
      .catch((error) => {
        if (active) {
          setSessionError(
            error instanceof Error
              ? error.message
              : "Không kiểm tra được phiên đăng nhập.",
          );
        }
      })
      .finally(() => {
        if (active) setCheckingSession(false);
      });

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (!sessionError) return;
    const timer = window.setTimeout(() => setSessionError(""), 3500);
    return () => window.clearTimeout(timer);
  }, [sessionError]);

  useEffect(() => {
    const expired = () => {
      setUser(null);
      setSessionError("Phiên đã hết hạn. Vui lòng đăng nhập lại.");
      setAuthMode("login");
      setAuthOpen(true);
    };

    window.addEventListener("express:session-expired", expired);
    return () => window.removeEventListener("express:session-expired", expired);
  }, []);

  useEffect(() => {
    const requested = (event: Event) => {
      const custom = event as CustomEvent<{ mode?: AuthMode }>;
      setAuthMode(custom.detail?.mode ?? "login");
      setAuthOpen(true);
    };

    window.addEventListener("express:auth-request", requested);
    return () => window.removeEventListener("express:auth-request", requested);
  }, []);

  async function logout() {
    await api.logout();
    setUser(null);
    setSessionError("");
  }

  function openAuth(mode: AuthMode = "login") {
    setAuthMode(mode);
    setAuthOpen(true);
  }

  function closeAuth() {
    setAuthOpen(false);
  }

  function updateUser(next: SessionUser) {
    localStorage.setItem("express-user", JSON.stringify(next));
    setUser(next);
  }

  return (
    <AuthContext.Provider
      value={{ user, logout, openAuth, closeAuth, updateUser }}
    >
      {children}

      {checkingSession && (
        <div className="session-check" role="status">
          Đang kiểm tra phiên đăng nhập…
        </div>
      )}

      {sessionError && (
        <div className="session-toast" role="status">
          {sessionError}
        </div>
      )}

      {authOpen && (
        <AuthForm
          initialMode={authMode}
          onClose={closeAuth}
          onLoggedIn={(value) => {
            setSessionError("");
            updateUser(value);
            setAuthOpen(false);
          }}
        />
      )}
    </AuthContext.Provider>
  );
}

function AuthForm({
  initialMode,
  onClose,
  onLoggedIn,
}: {
  initialMode: AuthMode;
  onClose: () => void;
  onLoggedIn: (user: SessionUser) => void;
}) {
  const [mode, setMode] = useState<AuthMode>(initialMode);
  const [fullName, setFullName] = useState("");
  const [shopName, setShopName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const inFlight = useRef(false);

  useEffect(() => {
    setMode(initialMode);
    setError("");
    setSuccess("");
  }, [initialMode]);

  useEffect(() => {
    if (!error) return;
    const timer = window.setTimeout(() => setError(""), 3500);
    return () => window.clearTimeout(timer);
  }, [error]);

  useEffect(() => {
    if (!success) return;
    const timer = window.setTimeout(() => setSuccess(""), 4500);
    return () => window.clearTimeout(timer);
  }, [success]);

  function switchMode(next: AuthMode) {
    setMode(next);
    setError("");
    setSuccess("");
    setPassword("");
    setConfirmation("");
    setShowPassword(false);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (inFlight.current) return;

    setError("");
    setSuccess("");

    const cleanEmail = email.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) {
      setError("Email không hợp lệ.");
      return;
    }

    if (mode === "register") {
      if (!fullName.trim()) {
        setError("Vui lòng nhập họ và tên.");
        return;
      }
      if (!/^0[0-9]{9}$/.test(phone.trim())) {
        setError("Số điện thoại phải gồm 10 số và bắt đầu bằng 0.");
        return;
      }
      if (password.length < 8) {
        setError("Mật khẩu cần ít nhất 8 ký tự.");
        return;
      }
      if (password !== confirmation) {
        setError("Mật khẩu xác nhận chưa khớp.");
        return;
      }
    } else if (!password) {
      setError("Vui lòng nhập mật khẩu.");
      return;
    }

    inFlight.current = true;
    setBusy(true);

    try {
      if (mode === "register") {
        await api.register({ fullName, shopName, phone, email: cleanEmail, password });
        setPassword("");
        setConfirmation("");
        setShowPassword(false);
        setMode("login");
        setSuccess("Đăng ký thành công. Vui lòng đăng nhập bằng tài khoản vừa tạo.");
      } else {
        const nextUser = await api.login({ email: cleanEmail, password });
        setPassword("");
        onLoggedIn(nextUser);
      }
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Không thực hiện được yêu cầu.");
    } finally {
      inFlight.current = false;
      setBusy(false);
    }
  }

  const register = mode === "register";

  return (
    <div className="auth-modal-backdrop" role="presentation" onMouseDown={onClose}>
      <div
        className="auth-modal"
        role="dialog"
        aria-modal="true"
        aria-label={register ? "Đăng ký" : "Đăng nhập"}
        onMouseDown={(event) => event.stopPropagation()}
      >
        <aside className="auth-story auth-story-modal">
          <div className="auth-wordmark"><span>E</span> express.</div>
          <div className="auth-story-body">
            <p className="auth-kicker">GỬI HÀNG AN TÂM</p>
            <h1>Từ cửa hàng bạn,<br />đến mọi hành trình.</h1>
            <p>
              Khách vãng lai có thể xem dịch vụ, chính sách, tra cứu và tạo đơn nhanh.
              Đăng nhập để quản lý đơn hàng, COD và tài khoản.
            </p>
          </div>
        </aside>

        <section className="auth-form-side auth-form-modal">
          <button className="auth-close" type="button" aria-label="Đóng" onClick={onClose}>×</button>
          <div className="auth-form-inner">
            <p className="eyebrow">CHÀO MỪNG ĐẾN EXPRESS</p>
            <h2>{register ? "Đăng ký tài khoản" : "Đăng nhập"}</h2>
            <p className="muted">
              {register
                ? "Tạo tài khoản để quản lý hành trình giao hàng đầy đủ hơn."
                : "Đăng nhập để quản lý đơn hàng, COD và thông tin tài khoản."}
            </p>

            {error && <div className="notice error" role="alert">{error}</div>}
            {success && <div className="notice success" role="status">{success}</div>}

            <form className="auth-fields" onSubmit={submit}>
              {register && (
                <>
                  <label>Họ và tên
                    <input value={fullName} onChange={(event) => setFullName(event.target.value)} maxLength={100} required />
                  </label>
                  <label>Tên cửa hàng (không bắt buộc)
                    <input value={shopName} onChange={(event) => setShopName(event.target.value)} maxLength={150} />
                  </label>
                  <label>Số điện thoại
                    <input value={phone} onChange={(event) => setPhone(event.target.value.replace(/\D/g, "").slice(0, 10))} inputMode="numeric" maxLength={10} required />
                  </label>
                </>
              )}

              <label>Email
                <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" required />
              </label>

              <label>Mật khẩu
                <input type={showPassword ? "text" : "password"} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete={register ? "new-password" : "current-password"} required />
              </label>

              {register && (
                <label>Nhập lại mật khẩu
                  <input type={showPassword ? "text" : "password"} value={confirmation} onChange={(event) => setConfirmation(event.target.value)} autoComplete="new-password" required />
                </label>
              )}

              <label className="auth-show-password checkbox">
                <input type="checkbox" checked={showPassword} onChange={(event) => setShowPassword(event.target.checked)} />
                Hiện mật khẩu
              </label>

              <button className="primary auth-submit" type="submit" disabled={busy}>
                {busy ? "Đang xử lý…" : register ? "Tạo tài khoản" : "Đăng nhập"}
              </button>
            </form>

            <div className="auth-links">
              <button type="button" onClick={() => switchMode(register ? "login" : "register")}>
                {register ? "Đã có tài khoản? Đăng nhập" : "Chưa có tài khoản? Đăng ký"}
              </button>
            </div>

            <button className="auth-guest" type="button" onClick={onClose}>
              Tiếp tục với tư cách khách
            </button>
          </div>
        </section>
      </div>
    </div>
  );
}
