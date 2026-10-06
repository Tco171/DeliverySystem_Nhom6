import { useEffect, useRef, useState } from "react";
import type { FormEvent, ReactNode } from "react";
import { api, MOCK_MODE } from "./api";
import type { SessionUser } from "./api";
import { AuthContext } from "./auth/context";
import "./App.css";
import "./auth/auth.css";

export default function AuthGate({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [sessionError, setSessionError] = useState("");

  // Tự ẩn lỗi session sau 3 giây
  useEffect(() => {
    if (!sessionError) return;

    const timer = setTimeout(() => {
      setSessionError("");
    }, 3000);

    return () => clearTimeout(timer);
  }, [sessionError]);

  useEffect(() => {
    let active = true;

    api
      .getSession()
      .then((value) => {
        if (active) {
          setUser(value);
        }
      })
      .catch((error) => {
        if (active) {
          setSessionError(
            error instanceof Error
              ? error.message
              : "Không kiểm tra được phiên đăng nhập."
          );
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    const expired = () => {
      setUser(null);
      setSessionError("Phiên đã hết hạn. Vui lòng đăng nhập lại.");
    };

    window.addEventListener("express:session-expired", expired);

    return () => {
      window.removeEventListener("express:session-expired", expired);
    };
  }, []);

  async function logout() {
    await api.logout();
    setUser(null);
    setSessionError("");
  }

  if (user) {
    return (
      <AuthContext.Provider
        key={user.id}
        value={{ user, logout }}
      >
        {children}
      </AuthContext.Provider>
    );
  }

  return (
    <AuthForm
      checkingSession={loading}
      sessionError={sessionError}
      onLoggedIn={(value) => {
        setSessionError("");
        setUser(value);
      }}
    />
  );
}

function AuthForm({
  checkingSession,
  sessionError,
  onLoggedIn,
}: {
  checkingSession: boolean;
  sessionError: string;
  onLoggedIn: (user: SessionUser) => void;
}) {
  const [mode, setMode] = useState<"login" | "register">("login");

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

  // Tự ẩn thông báo lỗi sau 3 giây
  useEffect(() => {
    if (!error) return;

    const timer = setTimeout(() => {
      setError("");
    }, 3000);

    return () => clearTimeout(timer);
  }, [error]);

  // Tự ẩn thông báo thành công sau 3 giây
  useEffect(() => {
    if (!success) return;

    const timer = setTimeout(() => {
      setSuccess("");
    }, 3000);

    return () => clearTimeout(timer);
  }, [success]);

  const inFlight = useRef(false);

  const register = mode === "register";

  function switchMode() {
    setMode(register ? "login" : "register");

    setError("");
    setSuccess("");

    setPassword("");
    setConfirmation("");
    setShowPassword(false);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (inFlight.current || checkingSession) return;

    setError("");
    setSuccess("");

    if (register) {
      if (!fullName.trim()) {
        setError("Vui lòng nhập họ tên.");
        return;
      }

      if (!/^\+?[0-9 ()-]{8,20}$/.test(phone.trim())) {
        setError("Số điện thoại không hợp lệ.");
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
    }

    inFlight.current = true;
    setBusy(true);

    try {
      if (register) {
        await api.register({
          fullName,
          shopName,
          phone,
          email,
          password,
        });

        setPassword("");
        setConfirmation("");
        setShowPassword(false);

        setMode("login");

        setSuccess(
          "Đăng ký thành công. Vui lòng đăng nhập bằng tài khoản vừa tạo."
        );
      } else {
        const user = await api.login({
          email,
          password,
        });

        setPassword("");

        onLoggedIn(user);
      }
    } catch (error) {
      setError(
        error instanceof Error
          ? error.message
          : "Không thực hiện được yêu cầu."
      );
    } finally {
      inFlight.current = false;
      setBusy(false);
    }
  }

  return (
    <main className="auth-layout">
      <aside className="auth-story">
        <div className="auth-wordmark">
          <span>E</span> express.
        </div>

        <div className="auth-story-body">
          <p className="auth-kicker">GỬI HÀNG AN TÂM</p>

          <h1>
            Từ cửa hàng bạn,
            <br />
            đến mọi hành trình.
          </h1>

          <p>
            Quản lý đơn hàng, theo dõi vận chuyển và đối soát thu hộ trong một
            không gian.
          </p>

          <div
            className="auth-route"
            aria-hidden="true"
          >
            <span>
              01
              <br />
              <b>Tạo đơn</b>
            </span>

            <i />

            <span>
              02
              <br />
              <b>Giao hàng</b>
            </span>

            <i />

            <span>
              03
              <br />
              <b>Đối soát</b>
            </span>
          </div>
        </div>

        <p className="auth-story-footer">
          EXPRESS · HỆ THỐNG QUẢN LÝ GIAO HÀNG
        </p>
      </aside>

      <section className="auth-form-side">
        <div className="auth-form-inner">
          <p className="eyebrow">
            CHÀO MỪNG ĐẾN EXPRESS
          </p>

          <h2>
            {register
              ? "Đăng ký tài khoản"
              : "Đăng nhập"}
          </h2>

          <p className="muted">
            {register
              ? "Tạo tài khoản để bắt đầu sử dụng dịch vụ giao hàng."
              : "Nhập thông tin tài khoản để tiếp tục công việc của bạn."}
          </p>

          {checkingSession && (
            <p
              role="status"
              className="muted"
            >
              Đang kiểm tra phiên đăng nhập…
            </p>
          )}

          {!checkingSession && sessionError && (
            <p
              className="notice error"
              role="status"
            >
              {sessionError}
            </p>
          )}

          {error && (
            <p
              className="notice error"
              role="alert"
            >
              {error}
            </p>
          )}

          {success && (
            <p
              className="notice success"
              role="status"
            >
              {success}
            </p>
          )}

          {MOCK_MODE && (
            <div className="auth-demo-note">
              <strong>Chế độ thử nghiệm</strong>

              <p>
                Dùng thông tin giả, không nhập mật khẩu thật. Các tài khoản shop
                dùng chung dữ liệu mẫu.
              </p>

              <p>
                shop@example.com · staff@example.com · operations@example.com
                <br />
                Mật khẩu chung: <strong>Express123!</strong>
              </p>
            </div>
          )}

          <form onSubmit={submit}>
            <fieldset
              disabled={busy || checkingSession}
              className="auth-fields"
            >
              {register && (
                <>
                  <label>
                    Họ và tên
                    <input
                      required
                      name="fullName"
                      autoComplete="name"
                      maxLength={100}
                      value={fullName}
                      onChange={(e) =>
                        setFullName(e.target.value)
                      }
                    />
                  </label>

                  <label>
                      Tên cửa hàng (nếu có)
                      <input
                        name="shopName"
                        autoComplete="organization"
                        maxLength={150}
                        value={shopName}
                        onChange={(e) =>
                          setShopName(e.target.value)
                        }
                        placeholder="Bỏ trống nếu bạn là người dùng cá nhân"
                      />
                    </label>

                  <label>
                    Số điện thoại
                    <input
                      required
                      name="phone"
                      type="tel"
                      autoComplete="tel"
                      maxLength={20}
                      value={phone}
                      onChange={(e) =>
                        setPhone(e.target.value)
                      }
                    />
                  </label>
                </>
              )}

              <label>
                Email
                <input
                  required
                  name="email"
                  type="email"
                  autoComplete="username"
                  maxLength={254}
                  value={email}
                  onChange={(e) =>
                    setEmail(e.target.value)
                  }
                />
              </label>

              <label>
                Mật khẩu
                <input
                  required
                  name="password"
                  type={
                    showPassword
                      ? "text"
                      : "password"
                  }
                  autoComplete={
                    register
                      ? "new-password"
                      : "current-password"
                  }
                  minLength={
                    register ? 8 : undefined
                  }
                  maxLength={128}
                  value={password}
                  onChange={(e) =>
                    setPassword(e.target.value)
                  }
                />
              </label>

              {register && (
                <>
                  <span className="muted">
                    Sử dụng ít nhất 8 ký tự cho mật khẩu.
                  </span>

                  <label>
                    Xác nhận mật khẩu
                    <input
                      required
                      name="confirmPassword"
                      type={
                        showPassword
                          ? "text"
                          : "password"
                      }
                      autoComplete="new-password"
                      maxLength={128}
                      value={confirmation}
                      onChange={(e) =>
                        setConfirmation(
                          e.target.value
                        )
                      }
                    />
                  </label>
                </>
              )}

              <label className="checkbox auth-show-password">
                <input
                  type="checkbox"
                  checked={showPassword}
                  onChange={(e) =>
                    setShowPassword(
                      e.target.checked
                    )
                  }
                />

                Hiển thị mật khẩu
              </label>

              <button
                type="submit"
                className="primary auth-submit"
              >
                {busy
                  ? "Đang xử lý…"
                  : register
                    ? "Tạo tài khoản"
                    : "Đăng nhập"}
              </button>
            </fieldset>
          </form>

          <p className="auth-switch">
            {register
              ? "Đã có tài khoản?"
              : "Bạn chưa có tài khoản?"}{" "}

            <button
              type="button"
              disabled={busy}
              onClick={switchMode}
            >
              {register
                ? "Đăng nhập"
                : "Đăng ký tài khoản"}
            </button>
          </p>

          <p className="auth-small-print">
            Nhân viên giao nhận và điều hành sử dụng tài khoản do đơn vị cấp.
          </p>
        </div>
      </section>
    </main>
  );
}