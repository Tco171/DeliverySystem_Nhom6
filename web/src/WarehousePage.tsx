import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api, STATUS } from "./api";
import type { Hub, HubAction, Shipment } from "./api";
interface WarehousePageProps {
    shipments: Shipment[];
    loading: boolean;
    onShipmentUpdated: (shipment: Shipment) => void;
}
export default function WarehousePage({ shipments, loading, onShipmentUpdated, }: WarehousePageProps) {
    const [hubs, setHubs] = useState<Hub[]>([]);
    const [hubId, setHubId] = useState("");
    const [action, setAction] = useState<HubAction>("receive");
    const [shipmentId, setShipmentId] = useState("");
    const [note, setNote] = useState("");
    const [search, setSearch] = useState("");
    const [hubsLoading, setHubsLoading] = useState(true);
    const [hubError, setHubError] = useState("");
    const [reload, setReload] = useState(0);
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    useEffect(() => {
        let active = true;
        setHubsLoading(true);
        setHubError("");
        api.listHubs()
            .then((data) => {
            if (!active)
                return;
            setHubs(data);
            setHubId((current) => data.some((hub) => hub.id === current)
                ? current
                : (data[0]?.id ?? ""));
        })
            .catch((error: unknown) => {
            if (active) {
                setHubError(error instanceof Error
                    ? error.message
                    : "Không tải được danh sách kho.");
            }
        })
            .finally(() => {
            if (active)
                setHubsLoading(false);
        });
        return () => {
            active = false;
        };
    }, [reload]);
    const eligibleShipments = shipments.filter((shipment) => {
        if (action === "dispatch") {
            return (shipment.status === "at_hub" &&
                shipment.currentHubId === hubId);
        }
        return (shipment.status === "picked_up" ||
            shipment.status === "in_transit" ||
            (shipment.status === "at_hub" && !shipment.currentHubId));
    });
    const selected = eligibleShipments.find((shipment) => shipment.id === shipmentId);
    const inventory = shipments.filter((shipment) => shipment.status === "at_hub" &&
        shipment.currentHubId === hubId);
    const visibleInventory = inventory.filter((shipment) => {
        const term = search.trim().toLocaleLowerCase("vi");
        return [
            shipment.id,
            shipment.recipientName,
            shipment.deliveryAddress,
        ].some((value) => value.toLocaleLowerCase("vi").includes(term));
    });
    const hub = hubs.find((item) => item.id === hubId);
    function resetSelection() {
        setShipmentId("");
        setNote("");
        setError("");
        setSuccess("");
    }
    async function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (busy)
            return;
        if (!selected || !hubId) {
            setError("Vui lòng chọn kho và đơn hàng hợp lệ.");
            return;
        }
        setBusy(true);
        setError("");
        setSuccess("");
        try {
            const updated = await api.recordHubAction(selected.id, {
                hubId,
                action,
                note,
            });
            onShipmentUpdated(updated);
            setShipmentId("");
            setNote("");
            setSuccess(action === "receive"
                ? `Đã nhập đơn ${updated.id} vào ${hub?.name}.`
                : `Đã xuất đơn ${updated.id} khỏi ${hub?.name}.`);
        }
        catch (error) {
            setError(error instanceof Error ? error.message : "Không lưu được thao tác.");
        }
        finally {
            setBusy(false);
        }
    }
    if (loading || hubsLoading) {
        return (<section className="panel">
        <p role="status">Đang tải dữ liệu kho…</p>
      </section>);
    }
    if (hubError) {
        return (<section className="panel">
        <p className="notice error" role="alert">{hubError}</p>
        <button type="button" onClick={() => setReload((current) => current + 1)}>
          Thử lại
        </button>
      </section>);
    }
    if (hubs.length === 0) {
        return (<section className="panel">
        <p>Chưa có kho được cấu hình.</p>
      </section>);
    }
    return (<>
      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Nhập và xuất kho</h2>
            <p className="muted">
              Ghi nhận khi kiện hàng thực tế đến hoặc rời kho.
            </p>
          </div>
          <span className="environment">
            {inventory.length} kiện đang tại kho
          </span>
        </div>

        {error && (<div className="notice error" role="alert">{error}</div>)}

        {success && (<div className="notice success" role="status">{success}</div>)}

        <form onSubmit={handleSubmit}>
          <fieldset disabled={busy}>
            <div className="form-grid">
              <label>
                Kho đang thao tác
                <select value={hubId} onChange={(event) => {
            setHubId(event.target.value);
            resetSelection();
        }}>
                  {hubs.map((item) => (<option key={item.id} value={item.id}>
                      {item.name}
                    </option>))}
                </select>
              </label>

              <label>
                Thao tác
                <select value={action} onChange={(event) => {
            setAction(event.target.value as HubAction);
            resetSelection();
        }}>
                  <option value="receive">Nhận hàng vào kho</option>
                  <option value="dispatch">Xuất hàng khỏi kho</option>
                </select>
              </label>

              <label className="full">
                Đơn hàng
                <select value={selected?.id ?? ""} onChange={(event) => {
            setShipmentId(event.target.value);
            setError("");
            setSuccess("");
        }} required>
                  <option value="">
                    {eligibleShipments.length === 0
            ? "Không có đơn phù hợp với thao tác này"
            : "Chọn đơn hàng"}
                  </option>

                  {eligibleShipments.map((shipment) => (<option key={shipment.id} value={shipment.id}>
                      {shipment.id} — {shipment.recipientName}
                    </option>))}
                </select>
              </label>

              <label className="full">
                Ghi chú
                <textarea rows={3} maxLength={1000} value={note} onChange={(event) => setNote(event.target.value)} placeholder="Thông tin bàn giao hoặc tình trạng kiện hàng…"/>
              </label>
            </div>

            {selected && (<div className="warehouse-summary">
                <strong>{selected.goods}</strong>
                <p>
                  {selected.weightKg} kg · {STATUS[selected.status]}
                </p>
                <p>Địa chỉ giao: {selected.deliveryAddress}</p>
              </div>)}

            <div className="actions warehouse-actions">
              <button type="submit" className="primary" disabled={!selected}>
                {busy
            ? "Đang lưu…"
            : action === "receive"
                ? "Xác nhận nhập kho"
                : "Xác nhận xuất kho"}
              </button>
            </div>
          </fieldset>
        </form>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Hàng đang lưu tại kho</h2>
            <p className="muted">{hub?.name}</p>
          </div>
        </div>

        <label className="warehouse-search">
          Tìm kiện hàng trong kho
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Mã đơn, người nhận hoặc địa chỉ giao…"/>
        </label>

        {visibleInventory.length === 0 ? (<div className="empty">
            <p>Không có kiện hàng phù hợp.</p>
          </div>) : (<div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Mã vận đơn</th>
                  <th>Người nhận</th>
                  <th>Hàng hóa</th>
                  <th>Khối lượng</th>
                </tr>
              </thead>
              <tbody>
                {visibleInventory.map((shipment) => (<tr key={shipment.id}>
                    <td>
                      <strong className="tracking-code">
                        {shipment.id}
                      </strong>
                    </td>
                    <td>{shipment.recipientName}</td>
                    <td>{shipment.goods}</td>
                    <td>{shipment.weightKg} kg</td>
                  </tr>))}
              </tbody>
            </table>
          </div>)}
      </section>
      
    </>);
}
