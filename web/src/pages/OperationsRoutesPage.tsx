import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { FormEvent } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { request } from "../lib/http";
import "./OperationsRoutesPage.css";

type RouteStatus = "draft" | "active" | "completed" | "cancelled";
type RouteStop = { id: number; shipmentId: string; stopOrder: number; stopType: "pickup" | "delivery"; addressSnapshot: string; latitude: number | null; longitude: number | null; status: string; notes?: string | null };
type RouteSummary = { id: number; routeCode: string; name: string; staffId: number; area: string; status: RouteStatus; plannedDate: string; stopCount: number; pendingStopCount: number; completedStopCount: number; createdAt: string };
type RouteDetail = RouteSummary & { notes?: string | null; staff?: { id: number; employeeCode: string; area: string; status: string; isAvailable: boolean } | null; stops: RouteStop[] };
type ListResponse = { total: number; data: RouteSummary[] };
const statusLabel: Record<RouteStatus, string> = { draft: "Bản nháp", active: "Đang thực hiện", completed: "Hoàn tất", cancelled: "Đã hủy" };
const dateOnly = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

export default function OperationsRoutesPage() {
  const [routes, setRoutes] = useState<RouteSummary[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [detail, setDetail] = useState<RouteDetail | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [createForm, setCreateForm] = useState({ name: "", staffId: "", area: "", plannedDate: dateOnly(new Date()), notes: "" });
  const [stopForm, setStopForm] = useState({ shipmentId: "", stopType: "delivery" as "pickup" | "delivery" });

  const fetchRoutes = useCallback(async () => {
    const params = new URLSearchParams();
    if (statusFilter) params.set("status", statusFilter);
    if (search.trim()) params.set("search", search.trim());
    const query = params.toString();
    const result = await request<ListResponse>(`/operations/routes${query ? `?${query}` : ""}`);
    return result.data ?? [];
  }, [search, statusFilter]);

  const loadRoutes = useCallback(async () => {
    setRoutes(await fetchRoutes());
  }, [fetchRoutes]);

  const loadDetail = useCallback(async (id: number) => {
    const result = await request<RouteDetail>(`/operations/routes/${id}`);
    setDetail({ ...result, stops: [...(result.stops ?? [])].sort((a, b) => a.stopOrder - b.stopOrder) });
    setSelectedId(id);
  }, []);

  const refresh = useCallback(async () => {
    setError("");
    try {
      await loadRoutes();
      if (selectedId !== null) await loadDetail(selectedId);
    } catch (e) { setError(e instanceof Error ? e.message : "Không tải được dữ liệu tuyến."); }
  }, [loadRoutes, loadDetail, selectedId]);

  useEffect(() => {
    let active = true;
    fetchRoutes()
      .then(data => {
        if (active) setRoutes(data);
      })
      .catch((e: unknown) => {
        if (active) setError(e instanceof Error ? e.message : "Không tải được danh sách tuyến.");
      });
    return () => { active = false; };
  }, [fetchRoutes]);

  const mutate = async (action: () => Promise<unknown>, successMessage: string, reload = true) => {
    setBusy(true); setError(""); setNotice("");
    try {
      await action();
      setNotice(successMessage);
      if (reload) {
        await loadRoutes();
        if (selectedId !== null) await loadDetail(selectedId);
      }
    } catch (e) { setError(e instanceof Error ? e.message : "Thao tác không thành công."); }
    finally { setBusy(false); }
  };

  const createRoute = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const staffId = Number(createForm.staffId);
    if (!Number.isInteger(staffId) || staffId < 1) { setError("Staff ID phải là số nguyên dương theo ID nhân viên trong database."); return; }
    await mutate(async () => {
      const created = await request<RouteDetail>("/operations/routes", { method: "POST", body: JSON.stringify({ ...createForm, staffId, plannedDate: new Date(`${createForm.plannedDate}T00:00:00`).toISOString() }) });
      setShowCreate(false);
      await loadRoutes();
      if (created?.id) await loadDetail(created.id);
    }, "Đã tạo tuyến giao hàng.", false);
  };

  const addStop = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!detail) return;
    const nextOrder = detail.stops.reduce((max, stop) => Math.max(max, stop.stopOrder), 0) + 1;
    await mutate(() => request(`/operations/routes/${detail.id}/stops`, { method: "POST", body: JSON.stringify({ shipmentId: stopForm.shipmentId.trim(), stopOrder: nextOrder, stopType: stopForm.stopType }) }), "Đã thêm điểm dừng.");
    setStopForm({ shipmentId: "", stopType: "delivery" });
  };

  const reorder = async (index: number, delta: -1 | 1) => {
    if (!detail) return;
    const next = [...detail.stops];
    const target = index + delta;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    const payload = next.map((stop, i) => ({ stopId: stop.id, stopOrder: i + 1 }));
    await mutate(() => request(`/operations/routes/${detail.id}/stops/reorder`, { method: "PATCH", body: JSON.stringify({ stops: payload }) }), "Đã cập nhật thứ tự điểm dừng.");
  };

  const stopActionsAllowed = detail?.status === "draft";
  const mapPoints = useMemo(() => (detail?.stops ?? []).filter(s => s.latitude != null && s.longitude != null), [detail]);

  return <main className="routes-page">
    <header className="routes-page__header"><div><p className="routes-page__eyebrow">OPERATIONS · DELIVERY</p><h1>Quản lý tuyến giao hàng</h1><p>Theo dõi tuyến, sắp xếp điểm dừng và cập nhật trạng thái.</p></div><button className="routes-btn routes-btn--primary" onClick={() => setShowCreate(v => !v)}>{showCreate ? "Đóng form" : "+ Tạo tuyến"}</button></header>
    {error && <div className="routes-alert routes-alert--error">{error}</div>}{notice && <div className="routes-alert routes-alert--success">{notice}</div>}
    {showCreate && <form className="routes-card routes-create" onSubmit={createRoute}><h2>Tạo tuyến mới</h2><div className="routes-form-grid">
      <label>Tên tuyến<input required maxLength={200} value={createForm.name} onChange={e => setCreateForm({ ...createForm, name: e.target.value })} /></label>
      <label>Staff ID<input required type="number" min="1" step="1" value={createForm.staffId} onChange={e => setCreateForm({ ...createForm, staffId: e.target.value })} /><small>Nhập ID số của nhân viên trong database.</small></label>
      <label>Khu vực<input maxLength={200} value={createForm.area} onChange={e => setCreateForm({ ...createForm, area: e.target.value })} /></label>
      <label>Ngày dự kiến<input required type="date" value={createForm.plannedDate} onChange={e => setCreateForm({ ...createForm, plannedDate: e.target.value })} /></label>
      <label className="routes-form-grid__wide">Ghi chú<textarea rows={2} maxLength={1000} value={createForm.notes} onChange={e => setCreateForm({ ...createForm, notes: e.target.value })} /></label>
    </div><button className="routes-btn routes-btn--primary" disabled={busy}>Lưu tuyến</button></form>}
    <section className="routes-layout"><div className="routes-card routes-list"><div className="routes-list__filters"><input placeholder="Tìm mã tuyến, tên hoặc khu vực…" value={search} onChange={e => setSearch(e.target.value)} /><select value={statusFilter} onChange={e => setStatusFilter(e.target.value)}><option value="">Tất cả trạng thái</option><option value="draft">Bản nháp</option><option value="active">Đang thực hiện</option><option value="completed">Hoàn tất</option><option value="cancelled">Đã hủy</option></select><button className="routes-btn" onClick={() => void refresh()} disabled={busy}>Làm mới</button></div>
      {routes.length === 0 ? <p className="routes-empty">Chưa có tuyến phù hợp.</p> : routes.map(route => <button key={route.id} className={`routes-list__item ${selectedId === route.id ? "is-selected" : ""}`} onClick={() => void loadDetail(route.id).catch((e: unknown) => setError(e instanceof Error ? e.message : "Không tải được chi tiết tuyến."))}><span className="routes-list__item-top"><strong>{route.routeCode}</strong><span className={`routes-status routes-status--${route.status}`}>{statusLabel[route.status]}</span></span><span>{route.name}</span><small>{route.area || "Chưa có khu vực"} · {route.stopCount} điểm dừng</small></button>)}</div>
    <div className="routes-detail">{!detail ? <div className="routes-card routes-empty routes-detail__placeholder">Chọn một tuyến để xem chi tiết.</div> : <>
      <section className="routes-card"><div className="routes-detail__title"><div><p className="routes-page__eyebrow">{detail.routeCode}</p><h2>{detail.name}</h2></div><span className={`routes-status routes-status--${detail.status}`}>{statusLabel[detail.status]}</span></div>
      <div className="routes-metadata"><div><small>Nhân viên ID</small><strong>{detail.staff?.id ?? detail.staffId ?? "—"}</strong></div><div><small>Khu vực</small><strong>{detail.area || "—"}</strong></div><div><small>Ngày dự kiến</small><strong>{new Date(detail.plannedDate).toLocaleDateString("vi-VN")}</strong></div><div><small>Điểm dừng</small><strong>{detail.stops.length}</strong></div></div>
      <div className="routes-actions">{detail.status === "draft" && <button className="routes-btn routes-btn--primary" disabled={busy || detail.stops.length === 0} onClick={() => void mutate(() => request(`/operations/routes/${detail.id}/activate`, { method: "PATCH" }), "Đã kích hoạt tuyến.")}>Kích hoạt tuyến</button>}{detail.status === "active" && <button className="routes-btn routes-btn--primary" disabled={busy} onClick={() => { if (window.confirm("Xác nhận hoàn tất tuyến này?")) void mutate(() => request(`/operations/routes/${detail.id}/complete`, { method: "PATCH" }), "Đã hoàn tất tuyến."); }}>Hoàn tất</button>}{detail.status === "draft" && <button className="routes-btn routes-btn--danger" disabled={busy} onClick={() => { if (window.confirm("Xác nhận hủy tuyến này?")) void mutate(() => request(`/operations/routes/${detail.id}/cancel`, { method: "PATCH" }), "Đã hủy tuyến."); }}>Hủy tuyến</button>}</div>
      {detail.notes && <p className="routes-note">{detail.notes}</p>}</section>
      <section className="routes-card"><div className="routes-section-heading"><div><h3>Điểm dừng</h3><p>Thứ tự được lưu về backend.</p></div></div>
        {stopActionsAllowed && <form className="routes-add-stop" onSubmit={addStop}><label>Mã đơn hàng / Shipment ID<input required value={stopForm.shipmentId} onChange={e => setStopForm({ ...stopForm, shipmentId: e.target.value })} placeholder="Ví dụ: EXP-…" /></label><label>Loại điểm<select value={stopForm.stopType} onChange={e => setStopForm({ ...stopForm, stopType: e.target.value as "pickup" | "delivery" })}><option value="pickup">Lấy hàng</option><option value="delivery">Giao hàng</option></select></label><button className="routes-btn routes-btn--primary" disabled={busy}>Thêm điểm</button></form>}
        {detail.stops.length === 0 ? <p className="routes-empty">Tuyến chưa có điểm dừng.</p> : <ol className="routes-stops">{detail.stops.map((stop, index) => <li key={stop.id}><div className="routes-stop__number">{index + 1}</div><div className="routes-stop__body"><strong>{stop.stopType === "pickup" ? "Lấy hàng" : "Giao hàng"} · {stop.shipmentId}</strong><span>{stop.addressSnapshot || "Chưa có địa chỉ"}</span><small>{stop.latitude != null && stop.longitude != null ? `${stop.latitude.toFixed(5)}, ${stop.longitude.toFixed(5)}` : "Chưa có tọa độ"} · {stop.status}</small></div>{stopActionsAllowed && <div className="routes-stop__actions"><button title="Lên" disabled={busy || index === 0} onClick={() => void reorder(index, -1)}>↑</button><button title="Xuống" disabled={busy || index === detail.stops.length - 1} onClick={() => void reorder(index, 1)}>↓</button><button title="Xóa điểm dừng" disabled={busy} onClick={() => { if (window.confirm("Xóa điểm dừng này?")) void mutate(() => request(`/operations/routes/${detail.id}/stops/${stop.id}`, { method: "DELETE" }), "Đã xóa điểm dừng."); }}>×</button></div>}</li>)}</ol>}
      </section>
      <section className="routes-card"><h3>Bản đồ tuyến</h3>{mapPoints.length === 0 ? <p className="routes-empty">Chưa có tọa độ để hiển thị bản đồ. Hãy chọn tọa độ khi tạo đơn hàng.</p> : <RouteStopsMap stops={mapPoints} />}</section>
    </>}</div></section>
  </main>;
}

function RouteStopsMap({ stops }: { stops: RouteStop[] }) {
  const elementRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<L.Map | null>(null);
  const stopsRef = useRef(stops);

  useEffect(() => {
    stopsRef.current = stops;
  }, [stops]);

  useEffect(() => {
    if (!elementRef.current || mapRef.current) return;
    const first = stopsRef.current[0];
    const map = L.map(elementRef.current).setView([first.latitude!, first.longitude!], 13);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);
    const points = stopsRef.current.map((stop, index) => {
      const point: L.LatLngExpression = [stop.latitude!, stop.longitude!];
      const marker = L.marker(point).addTo(map);
      marker.bindPopup(`<strong>${index + 1}. ${stop.stopType === "pickup" ? "Lấy hàng" : "Giao hàng"}</strong><br>${escapeHtml(stop.shipmentId)}<br>${escapeHtml(stop.addressSnapshot || "Chưa có địa chỉ")}`);
      return point;
    });
    if (points.length > 1) {
      const line = L.polyline(points, { color: "#123f31", weight: 4, opacity: 0.75 }).addTo(map);
      map.fitBounds(line.getBounds().pad(0.15));
    } else {
      map.setView(points[0], 15);
    }
    mapRef.current = map;
    window.setTimeout(() => map.invalidateSize(), 0);
    return () => { map.remove(); mapRef.current = null; };
  }, []);

  return <div className="routes-map-wrap"><div className="routes-map-points">{stops.map((stop, index) => <div key={stop.id}><b>{index + 1}. {stop.stopType === "pickup" ? "Lấy" : "Giao"}</b><span>{stop.shipmentId}</span><small>{stop.latitude?.toFixed(5)}, {stop.longitude?.toFixed(5)}</small></div>)}</div><div className="routes-map-canvas" ref={elementRef} /></div>;
}

function escapeHtml(value: string) {
  return value.replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[character] ?? character));
}
