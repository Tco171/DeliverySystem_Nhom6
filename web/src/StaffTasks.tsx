import { useState } from "react";
import type { FormEvent } from "react";
import { api, money, STATUS } from "./api";
import type { Shipment, Status } from "./api";
type TaskTab = "pickup" | "delivery" | "return";
interface StaffTasksProps {
    shipments: Shipment[];
    loading: boolean;
    onShipmentUpdated: (shipment: Shipment) => void;
}
const taskStatuses: Record<TaskTab, Status[]> = {
    pickup: ["pending_pickup", "pickup_failed"],
    delivery: ["out_for_delivery", "delivery_failed"],
    return: ["returning"],
};
const tabLabels: Record<TaskTab, string> = {
    pickup: "Lấy hàng",
    delivery: "Giao hàng",
    return: "Hoàn hàng",
};
const actions: Partial<Record<Status, {
    value: Status;
    label: string;
}[]>> = {
    pending_pickup: [
        { value: "picked_up", label: "Đã lấy hàng" },
        { value: "pickup_failed", label: "Không lấy được hàng" },
    ],
    out_for_delivery: [
        { value: "delivered", label: "Giao thành công" },
        { value: "delivery_failed", label: "Giao thất bại" },
    ],
    returning: [
        { value: "returned", label: "Đã giao hàng hoàn cho shop" },
    ],
};
export default function StaffTasks({ shipments, loading, onShipmentUpdated, }: StaffTasksProps) {
    const [tab, setTab] = useState<TaskTab>("pickup");
    const [search, setSearch] = useState("");
    const [selectedId, setSelectedId] = useState<string | null>(null);
    const [message, setMessage] = useState("");
    const tasks = shipments.filter((shipment) => {
        if (!taskStatuses[tab].includes(shipment.status))
            return false;
        const term = search.trim().toLocaleLowerCase("vi");
        return [
            shipment.id,
            shipment.senderName,
            shipment.senderPhone,
            shipment.recipientName,
            shipment.recipientPhone,
            shipment.pickupAddress,
            shipment.deliveryAddress,
        ].some((value) => value.toLocaleLowerCase("vi").includes(term));
    });
    const selected = tasks.find((shipment) => shipment.id === selectedId);
    return (<section className="panel">
      <div className="panel-heading">
        <div>
          <h2>Công việc giao nhận</h2>
          <p className="muted">
            Xem thông tin đơn và ghi nhận kết quả thực hiện.
          </p>
        </div>
        <span className="environment">
          {"Dữ liệu từ API"}
        </span>
      </div>

      {message && (<div className="notice success" role="status">
          {message}
        </div>)}

      <div className="staff-tabs" aria-label="Loại công việc">
        {(Object.keys(tabLabels) as TaskTab[]).map((value) => {
            const count = shipments.filter((shipment) => taskStatuses[value].includes(shipment.status)).length;
            return (<button key={value} type="button" aria-pressed={tab === value} className={tab === value ? "staff-tab selected" : "staff-tab"} onClick={() => {
                    setTab(value);
                    setSelectedId(null);
                    setMessage("");
                }}>
              {tabLabels[value]} <span>{count}</span>
            </button>);
        })}
      </div>

      <label className="staff-search">
        Tìm công việc
        <input placeholder="Mã đơn, tên, số điện thoại hoặc địa chỉ…" value={search} onChange={(event) => setSearch(event.target.value)}/>
      </label>

      {loading ? (<p role="status">Đang tải công việc…</p>) : tasks.length === 0 ? (<div className="empty">
          <h3>Không có công việc phù hợp</h3>
          <p>Thử tìm kiếm khác hoặc chọn loại công việc khác.</p>
        </div>) : (<div className="staff-task-list">
          {tasks.map((shipment) => {
                const isDelivery = tab === "delivery";
                const contact = isDelivery
                    ? shipment.recipientName
                    : shipment.senderName;
                const phone = isDelivery
                    ? shipment.recipientPhone
                    : shipment.senderPhone;
                const address = isDelivery
                    ? shipment.deliveryAddress
                    : shipment.pickupAddress;
                return (<article className="staff-task-card" key={shipment.id}>
                <div className="staff-task-heading">
                  <strong className="tracking-code">{shipment.id}</strong>
                  <span className={`badge ${shipment.status}`}>
                    {STATUS[shipment.status]}
                  </span>
                </div>

                <h3>{contact}</h3>
                <p>{address}</p>
                <a href={`tel:${phone.replace(/[ ()-]/g, "")}`}>
                  {phone}
                </a>

                <div className="staff-task-meta">
                  <span>{shipment.goods}</span>
                  <span>{shipment.weightKg} kg</span>
                  {isDelivery && (<span>COD: {money(shipment.codAmount)}</span>)}
                </div>

                <button type="button" onClick={() => {
                        setSelectedId(shipment.id);
                        setMessage("");
                    }}>
                  Xem và cập nhật
                </button>
              </article>);
            })}
        </div>)}

      {selected && (<TaskResult key={`${selected.id}-${selected.status}`} shipment={selected} onClose={() => setSelectedId(null)} onSaved={(updated) => {
                onShipmentUpdated(updated);
                setSelectedId(null);
                setMessage(`Đã cập nhật: ${STATUS[updated.status]}.`);
            }}/>)}
    </section>);
}
interface TaskResultProps {
    shipment: Shipment;
    onClose: () => void;
    onSaved: (shipment: Shipment) => void;
}
function TaskResult({ shipment, onClose, onSaved, }: TaskResultProps) {
    const availableActions = actions[shipment.status] ?? [];
    const [result, setResult] = useState<Status>(availableActions[0]?.value ?? shipment.status);
    const [note, setNote] = useState("");
    const [codConfirmed, setCodConfirmed] = useState(false);
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState("");
    const failed = result === "pickup_failed" || result === "delivery_failed";
    const requiresCod = result === "delivered" && shipment.codAmount > 0;
    async function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (busy)
            return;
        setError("");
        if (failed && !note.trim()) {
            setError("Vui lòng nhập lý do không hoàn thành.");
            return;
        }
        if (requiresCod && !codConfirmed) {
            setError("Cần xác nhận đã thu đủ tiền COD trước khi hoàn tất.");
            return;
        }
        setBusy(true);
        try {
            const updated = await api.transition(shipment.id, {
                status: result,
                note,
                codCollected: requiresCod ? shipment.codAmount : 0,
            });
            onSaved(updated);
        }
        catch (error) {
            setError(error instanceof Error ? error.message : "Không cập nhật được đơn.");
        }
        finally {
            setBusy(false);
        }
    }
    return (<section className="staff-result">
      <div className="panel-heading">
        <div>
          <h2>Ghi nhận kết quả</h2>
          <p className="muted tracking-code">{shipment.id}</p>
        </div>
        <button type="button" disabled={busy} onClick={onClose}>
          Đóng
        </button>
      </div>

      <div className="route">
        <div>
          <small>LẤY HÀNG / HOÀN HÀNG</small>
          <p>{shipment.pickupAddress}</p>
        </div>
        <span aria-hidden="true">→</span>
        <div>
          <small>GIAO HÀNG</small>
          <p>{shipment.deliveryAddress}</p>
        </div>
      </div>

      <p className="muted">
        Số lần giao: {shipment.attempts}
        {" · "}COD: {money(shipment.codAmount)}
        {" · "}Phí vận chuyển: {money(shipment.fee)}
      </p>

      {shipment.notes && (<div className="staff-note">
          <strong>Lưu ý giao nhận</strong>
          <p>{shipment.notes}</p>
        </div>)}

      {shipment.feePayer === "recipient" && (<p className="hint">
          Người nhận trả phí vận chuyển {money(shipment.fee)} riêng với COD.
          Thao tác này ghi nhận thu COD; việc thanh toán phí được theo dõi riêng.
        </p>)}

      {availableActions.length === 0 ? (<div className="hint">
          Lần thực hiện trước đã thất bại. Đơn đang chờ điều phối
          sắp xếp lấy/giao lại hoặc chuyển hoàn.
          {shipment.events.at(-1)?.note && (<p>Lý do đã ghi nhận: {shipment.events.at(-1)?.note}</p>)}
        </div>) : (<form onSubmit={handleSubmit}>
          {error && (<div className="notice error" role="alert">
              {error}
            </div>)}

          <fieldset disabled={busy}>
            <div className="form-grid">
              <label>
                Kết quả
                <select value={result} onChange={(event) => {
                setResult(event.target.value as Status);
                setCodConfirmed(false);
                setError("");
            }}>
                  {availableActions.map((action) => (<option key={action.value} value={action.value}>
                      {action.label}
                    </option>))}
                </select>
              </label>

              <label className="full">
                {failed ? "Lý do thất bại *" : "Ghi chú"}
                <textarea rows={3} value={note} maxLength={1000} required={failed} onChange={(event) => setNote(event.target.value)} placeholder={failed
                ? "Ví dụ: Không liên hệ được người nhận."
                : "Thông tin bổ sung về lần thực hiện."}/>
              </label>
            </div>

            {requiresCod && (<label className="checkbox">
                <input type="checkbox" checked={codConfirmed} onChange={(event) => setCodConfirmed(event.target.checked)} required/>
                Đã thu đủ tiền COD {money(shipment.codAmount)}
              </label>)}

            {result === "returned" && (<p className="hint">
                Thao tác này ghi nhận nhân viên đã giao hoàn.
                Shop vẫn cần xác nhận đã nhận lại hàng.
              </p>)}

            <div className="actions incident-submit">
              <button type="submit" className="primary">
                {busy ? "Đang lưu…" : "Xác nhận kết quả"}
              </button>
            </div>
          </fieldset>
        </form>)}
    </section>);
}
