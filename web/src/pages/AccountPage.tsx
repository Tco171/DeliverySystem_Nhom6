import { useEffect, useState } from "react";
import { api } from "../api";
import type { AccountInfo, SessionUser } from "../api";
import { useAuth } from "../auth/context";
import "./pages.css";

export default function AccountPage() {
  const { user, updateUser, logout, openAuth } = useAuth();
  const [account, setAccount] = useState<AccountInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [changingPassword, setChangingPassword] = useState(false);
  const [message, setMessage] = useState<{ kind: "success" | "error"; text: string } | null>(null);

  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [shopName, setShopName] = useState("");

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }

    let active = true;
    api.getAccount()
      .then((data) => {
        if (!active) return;
        setAccount(data);
        setFullName(data.fullName || data.name);
        setEmail(data.email ?? "");
        setPhone(data.phone ?? "");
        setShopName(data.shopName ?? "");
      })
      .catch((error: unknown) => {
        if (!active) return;
        setMessage({
          kind: "error",
          text: error instanceof Error ? error.message : "Không tải được thông tin tài khoản.",
        });
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [user]);

  if (!user) {
    return (
      <section className="panel account-page">
        <div className="empty">
          <h3>Bạn chưa đăng nhập</h3>
          <p>Đăng nhập để xem và chỉnh sửa thông tin tài khoản.</p>
          <button className="primary" type="button" onClick={() => openAuth("login")}>Đăng nhập</button>
        </div>
      </section>
    );
  }

  const isBusiness = (account?.accountType ?? user.accountType) === "business";

  async function saveProfile(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);

    const cleanName = fullName.trim();
    const cleanEmail = email.trim();
    const cleanPhone = phone.trim();

    if (!cleanName) {
      setMessage({ kind: "error", text: "Vui lòng nhập họ và tên." });
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) {
      setMessage({ kind: "error", text: "Email không hợp lệ." });
      return;
    }
    if (!/^0[0-9]{9}$/.test(cleanPhone)) {
      setMessage({ kind: "error", text: "Số điện thoại phải gồm 10 số và bắt đầu bằng 0." });
      return;
    }

    setSaving(true);
    try {
      const updated = await api.updateAccount({
        fullName: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
        shopName: isBusiness ? shopName : null,
      });
      setAccount(updated);
      const nextUser: SessionUser = {
        ...user,
        ...updated,
        name: updated.fullName || updated.name,
      };
      updateUser(nextUser);
      setMessage({ kind: "success", text: "Cập nhật thông tin thành công." });
    } catch (error) {
      setMessage({
        kind: "error",
        text: error instanceof Error ? error.message : "Không cập nhật được tài khoản.",
      });
    } finally {
      setSaving(false);
    }
  }

  async function submitPassword(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);

    if (!currentPassword) {
      setMessage({ kind: "error", text: "Vui lòng nhập mật khẩu hiện tại." });
      return;
    }
    if (newPassword.length < 8) {
      setMessage({ kind: "error", text: "Mật khẩu mới phải có ít nhất 8 ký tự." });
      return;
    }
    if (newPassword === currentPassword) {
      setMessage({ kind: "error", text: "Mật khẩu mới phải khác mật khẩu hiện tại." });
      return;
    }
    if (newPassword !== confirmPassword) {
      setMessage({ kind: "error", text: "Mật khẩu nhập lại chưa khớp." });
      return;
    }

    setChangingPassword(true);
    try {
      await api.changePassword({ currentPassword, newPassword });
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      await logout();
      openAuth("login");
    } catch (error) {
      setMessage({
        kind: "error",
        text: error instanceof Error ? error.message : "Không đổi được mật khẩu.",
      });
    } finally {
      setChangingPassword(false);
    }
  }

  return (
    <div className="account-page">
      <section className="account-hero">
        <div className="account-avatar">{(account?.fullName || user.name).trim().charAt(0).toUpperCase() || "E"}</div>
        <div>
          <p className="eyebrow">TÀI KHOẢN EXPRESS</p>
          <h2>{account?.fullName || user.name}</h2>
          <p>{user.role} · {(account?.accountType ?? user.accountType) === "business" ? "Cửa hàng" : "Cá nhân"}</p>
        </div>
      </section>

      {message && <div className={`notice ${message.kind}`} role="status">{message.text}</div>}

      {loading ? (
        <section className="panel"><p role="status">Đang tải thông tin tài khoản…</p></section>
      ) : (
        <div className="account-grid">
          <form className="panel account-form" onSubmit={saveProfile}>
            <div className="panel-heading">
              <div>
                <h2>Thông tin cá nhân</h2>
                <p className="muted">Cập nhật họ tên, email, số điện thoại và thông tin cửa hàng.</p>
              </div>
            </div>

            <div className="form-grid">
              <label>Họ và tên
                <input value={fullName} onChange={(event) => setFullName(event.target.value)} maxLength={100} required />
              </label>
              <label>Email
                <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
              </label>
              <label>Số điện thoại
                <input inputMode="numeric" value={phone} onChange={(event) => setPhone(event.target.value.replace(/\D/g, "").slice(0, 10))} maxLength={10} required />
              </label>
              <label>Loại tài khoản
                <input value={isBusiness ? "Cửa hàng" : "Cá nhân"} disabled />
              </label>
              {isBusiness && (
                <label className="full">Tên cửa hàng
                  <input value={shopName} onChange={(event) => setShopName(event.target.value)} maxLength={150} />
                </label>
              )}
            </div>

            <div className="form-footer">
              <p className="muted">Email và số điện thoại phải là duy nhất trong hệ thống.</p>
              <button className="primary" type="submit" disabled={saving}>{saving ? "Đang lưu…" : "Lưu thay đổi"}</button>
            </div>
          </form>

          <form className="panel account-form" onSubmit={submitPassword}>
            <div className="panel-heading">
              <div>
                <h2>Đổi mật khẩu</h2>
                <p className="muted">Sau khi đổi mật khẩu thành công, bạn sẽ được yêu cầu đăng nhập lại.</p>
              </div>
            </div>

            <div className="account-password-fields">
              <label>Mật khẩu hiện tại
                <input type="password" value={currentPassword} onChange={(event) => setCurrentPassword(event.target.value)} autoComplete="current-password" required />
              </label>
              <label>Mật khẩu mới
                <input type="password" value={newPassword} onChange={(event) => setNewPassword(event.target.value)} autoComplete="new-password" minLength={8} required />
              </label>
              <label>Nhập lại mật khẩu mới
                <input type="password" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} autoComplete="new-password" minLength={8} required />
              </label>
            </div>

            <div className="security-note">
              Không chia sẻ mật khẩu hoặc mã xác nhận với người khác. Mật khẩu mới nên có ít nhất 8 ký tự.
            </div>

            <div className="form-footer">
              <span />
              <button className="primary" type="submit" disabled={changingPassword}>{changingPassword ? "Đang đổi…" : "Đổi mật khẩu"}</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
