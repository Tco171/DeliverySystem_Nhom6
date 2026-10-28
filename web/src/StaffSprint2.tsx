import { useCallback, useEffect, useRef, useState } from "react";
import { staffApi } from "./lib/sprint2";
import type { StaffAction, StaffAssignment } from "./lib/sprint2";
import "./StaffSprint2.css";

type StaffButton = { action: StaffAction; label: string; reason?: boolean };
const actions: Record<string, StaffButton[]> = {
  assigned: [{ action: "accept", label: "Nhận đơn" }, { action: "reject", label: "Từ chối", reason: true }],
  accepted: [{ action: "start-pickup", label: "Bắt đầu lấy hàng" }],
  picking_up: [{ action: "pickup-success", label: "Lấy hàng thành công" }, { action: "pickup-failed", label: "Lấy hàng thất bại", reason: true }],
  picked_up: [{ action: "start-delivery", label: "Bắt đầu giao" }],
  delivering: [{ action: "delivery-success", label: "Giao thành công" }, { action: "delivery-failed", label: "Giao thất bại", reason: true }],
  return_pending: [{ action: "start-return", label: "Bắt đầu hoàn hàng" }],
  returning: [{ action: "return-complete", label: "Hoàn hàng thành công" }],
};
const statusNames: Record<string, string> = {
  assigned: "Đã phân công", accepted: "Đã nhận đơn", picking_up: "Đang lấy hàng",
  picked_up: "Đã lấy hàng", delivering: "Đang giao hàng", delivered: "Đã giao hàng",
  return_pending: "Chờ hoàn hàng", returning: "Đang hoàn hàng", returned: "Đã hoàn hàng", rejected: "Đã từ chối",
  pickup_failed: "Lấy hàng thất bại", delivery_failed: "Giao hàng thất bại",
};
const displayStatus = (value?: string) => statusNames[(value ?? "").toLowerCase()] ?? value ?? "Chưa cập nhật";
const money = (value?: number) => `${Number(value ?? 0).toLocaleString("vi-VN")} đ`;

export default function StaffSprint2() {
  const [orders, setOrders] = useState<StaffAssignment[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<number | null>(null);
  const [toast, setToast] = useState<{ text: string; error: boolean } | null>(null);
  const [selected, setSelected] = useState<number | null>(null);
  const [reasonAction, setReasonAction] = useState<{ id: number; action: StaffAction; label: string } | null>(null);
  const [reason, setReason] = useState("");
  const [search, setSearch] = useState("");
  const alive = useRef(true);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const notify = useCallback((text: string, error = false) => {
    if (toastTimer.current) clearTimeout(toastTimer.current);
    setToast({ text, error });
    toastTimer.current = setTimeout(() => setToast(null), 4500);
  }, []);
  const load = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const data = await staffApi.list();
      if (alive.current) setOrders(data);
    } catch (error) {
      if (alive.current) notify(error instanceof Error ? error.message : "Không tải được đơn được phân công", true);
    } finally {
      if (alive.current && !silent) setLoading(false);
    }
  }, [notify]);

  useEffect(() => {
    alive.current = true;
    void load();
    const onFocus = () => void load(true);
    window.addEventListener("focus", onFocus);
    return () => {
      alive.current = false;
      window.removeEventListener("focus", onFocus);
      if (toastTimer.current) clearTimeout(toastTimer.current);
    };
  }, [load]);

  async function run(id: number, action: StaffAction, reasonText?: string) {
    setBusyId(id);
    try {
      await staffApi.action(id, action, reasonText);
      setReasonAction(null);
      setReason("");
      await load(true);
      notify("Cập nhật trạng thái đơn hàng thành công.");
    } catch (error) {
      notify(error instanceof Error ? error.message : "Thao tác thất bại", true);
    } finally {
      if (alive.current) setBusyId(null);
    }
  }

  const filtered = orders.filter(o => [o.shipmentId, o.senderName, o.recipientName, o.recipientPhone, o.pickupAddress, o.deliveryAddress]
    .some(value => (value ?? "").toLocaleLowerCase("vi").includes(search.trim().toLocaleLowerCase("vi"))));

  return <section className="panel staff-s2">
    <div className="panel-heading staff-s2-header">
      <div><h2>Staff Home · Đơn được phân công</h2><p className="muted">Nhận đơn, lấy hàng và giao hàng theo đúng trạng thái hiện tại.</p></div>
      <button type="button" onClick={() => void load()} disabled={loading || busyId !== null}>Làm mới</button>
    </div>
    <label className="staff-s2-search">Tìm đơn hàng
      <input type="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Mã vận đơn, tên, địa chỉ, số điện thoại…" />
    </label>
    {loading && <p role="status" className="staff-s2-loading">Đang tải danh sách đơn được phân công…</p>}
    {!loading && filtered.length === 0 && <div className="empty"><h3>Không có đơn hàng phù hợp</h3><p>{search ? "Hãy thử từ khóa khác." : "Hiện bạn chưa được phân công đơn hàng nào."}</p></div>}
    <div className="staff-task-list">
      {!loading && filtered.map(o => {
        // Shipment is authoritative once it reaches a recognized shipment state.
        // At pending_pickup, use assignment status for accept/start-pickup.
        const shipmentStatus = (o.shipmentStatus ?? "").trim().toLowerCase();
        const assignmentStatus = (o.assignmentStatus ?? "").trim().toLowerCase();
        const status = shipmentStatus && (shipmentStatus in actions || shipmentStatus in statusNames)
          ? shipmentStatus : assignmentStatus;
        const available = actions[status] ?? [];
        const expanded = selected === o.assignmentId;
        return <article className="staff-task-card staff-s2-card" key={o.assignmentId}>
          <div className="staff-task-heading"><strong className="tracking-code">{o.shipmentId}</strong><span className={`staff-s2-badge staff-s2-${status.replace(/[^a-z_-]/g, "")}`}>{displayStatus(status)}</span></div>
          <div className="staff-s2-addresses"><p><strong>Điểm lấy:</strong> {o.pickupAddress || "Chưa có địa chỉ"}</p><p><strong>Điểm giao:</strong> {o.deliveryAddress || "Chưa có địa chỉ"}</p></div>
          <p><strong>COD:</strong> {money(o.codAmount)}</p>
          <button type="button" className="staff-s2-detail" aria-expanded={expanded} onClick={() => setSelected(expanded ? null : o.assignmentId)}>{expanded ? "Ẩn chi tiết" : "Xem chi tiết"}</button>
          {expanded && <div className="staff-s2-expanded"><p><strong>Người gửi:</strong> {o.senderName || "—"} · {o.senderPhone || "—"}</p><p><strong>Người nhận:</strong> {o.recipientName || "—"} · {o.recipientPhone || "—"}</p><p><strong>Dịch vụ:</strong> {o.service || "—"}</p><p><strong>Ghi chú:</strong> {o.notes || "Không có"}</p><p><strong>Trạng thái đơn:</strong> {displayStatus(o.shipmentStatus)}</p></div>}
          <div className="staff-s2-actions">{available.map(a => <button key={a.action} type="button" disabled={busyId !== null} onClick={() => a.reason ? (setReason(""), setReasonAction({ id: o.assignmentId, action: a.action, label: a.label })) : void run(o.assignmentId, a.action)}>{busyId === o.assignmentId ? "Đang xử lý…" : a.label}</button>)}</div>
        </article>;
      })}
    </div>
    {toast && <div className={`staff-s2-toast ${toast.error ? "error" : "success"}`} role={toast.error ? "alert" : "status"}>{toast.text}<button type="button" onClick={() => setToast(null)} aria-label="Đóng thông báo">×</button></div>}
    {reasonAction && <div className="staff-s2-overlay" role="presentation" onMouseDown={e => { if (e.target === e.currentTarget && busyId === null) setReasonAction(null); }}>
      <div className="staff-s2-modal" role="dialog" aria-modal="true" aria-labelledby="staff-reason-title">
        <h3 id="staff-reason-title">{reasonAction.label}</h3><p>Vui lòng nhập lý do để cập nhật trạng thái đơn hàng.</p>
        <label htmlFor="staff-reason">Lý do <span aria-hidden="true">*</span></label>
        <textarea id="staff-reason" autoFocus rows={4} maxLength={300} value={reason} onChange={e => setReason(e.target.value)} placeholder="Nhập lý do (ít nhất 3 ký tự)…" />
        <small>{reason.trim().length}/300 ký tự</small>
        <div className="staff-s2-modal-actions"><button type="button" disabled={busyId !== null} onClick={() => setReasonAction(null)}>Hủy</button><button type="button" disabled={busyId !== null || reason.trim().length < 3} onClick={() => void run(reasonAction.id, reasonAction.action, reason.trim())}>Xác nhận</button></div>
      </div>
    </div>}
  </section>;
}
