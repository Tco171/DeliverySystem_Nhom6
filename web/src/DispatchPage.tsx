import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api, employeeLoad, STATUS } from "./api";
import type { AssignmentKind, DeliveryEmployee, Shipment, Shift, Status } from "./api";
interface DispatchPageProps {
    shipments: Shipment[];
    loading: boolean;
    onShipmentUpdated: (shipment: Shipment) => void;
}
const eligibleStatuses: Record<AssignmentKind, Status[]> = {
    pickup: ["pending_pickup", "pickup_failed"],
    delivery: [
        "picked_up",
        "in_transit",
        "at_hub",
        "out_for_delivery",
        "delivery_failed",
    ],
    return: ["delivery_failed", "returning"],
};
export default function DispatchPage({ shipments, loading, onShipmentUpdated, }: DispatchPageProps) {
    const [employees, setEmployees] = useState<DeliveryEmployee[]>([]);
    const [employeesLoading, setEmployeesLoading] = useState(true);
    const [loadError, setLoadError] = useState("");
    const [reload, setReload] = useState(0);
    const [kind, setKind] = useState<AssignmentKind>("pickup");
    const [shipmentId, setShipmentId] = useState("");
    const [area, setArea] = useState("");
    const [shift, setShift] = useState<Shift>("morning");
    const [staffId, setStaffId] = useState("");
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    useEffect(() => {
        let active = true;
        setEmployeesLoading(true);
        setLoadError("");
        api.listEmployees()
            .then((data) => {
            if (!active)
                return;
            setEmployees(data);
            setArea(data[0]?.area ?? "");
        })
            .catch((error: unknown) => {
            if (active) {
                setLoadError(error instanceof Error
                    ? error.message
                    : "Không tải được nhân viên.");
            }
        })
            .finally(() => {
            if (active)
                setEmployeesLoading(false);
        });
        return () => {
            active = false;
        };
    }, [reload]);
    const areas = [...new Set(employees.map((employee) => employee.area))];
    const eligibleOrders = shipments.filter((shipment) => eligibleStatuses[kind].includes(shipment.status));
    const selected = eligibleOrders.find((shipment) => shipment.id === shipmentId);
    const availableEmployees = employees.filter((employee) => employee.area === area && employee.shift === shift);
    const selectedEmployee = availableEmployees.find((employee) => employee.id === staffId);
    async function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (busy)
            return;
        if (!selected || !selectedEmployee) {
            setError("Vui lòng chọn đơn hàng và nhân viên.");
            return;
        }
        setBusy(true);
        setError("");
        setSuccess("");
        try {
            const updated = await api.assignShipment(selected.id, {
                staffId,
                kind,
                area,
                shift,
            });
            onShipmentUpdated(updated);
            setShipmentId("");
            setStaffId("");
            setSuccess(`Đã phân công cho ${selectedEmployee.name}.`);
        }
        catch (error) {
            setError(error instanceof Error ? error.message : "Không phân công được.");
        }
        finally {
            setBusy(false);
        }
    }
    if (loading || employeesLoading) {
        return (<section className="panel">
        <p role="status">Đang tải dữ liệu điều phối…</p>
      </section>);
    }
    if (loadError) {
        return (<section className="panel">
        <p className="notice error" role="alert">{loadError}</p>
        <button onClick={() => setReload((value) => value + 1)}>
          Thử lại
        </button>
      </section>);
    }
    return (<section className="panel">
      <div className="panel-heading">
        <div>
          <h2>Điều phối công việc hôm nay</h2>
          <p className="muted">
            Chọn khu vực theo địa chỉ thực tế của công việc.
            Chọn khu vực phù hợp với địa chỉ nhận hoặc giao hàng.
          </p>
        </div>
      </div>

      {error && (<div className="notice error" role="alert">{error}</div>)}

      {success && (<div className="notice success" role="status">{success}</div>)}

      <form onSubmit={handleSubmit}>
        <fieldset disabled={busy}>
          <div className="form-grid">
            <label>
              Công việc
              <select value={kind} onChange={(event) => {
            setKind(event.target.value as AssignmentKind);
            setShipmentId("");
            setStaffId("");
            setSuccess("");
            setError("");
        }}>
                <option value="pickup">Lấy hàng / lấy lại</option>
                <option value="delivery">Giao hàng / giao lại</option>
                <option value="return">Hoàn hàng</option>
              </select>
            </label>

            <label>
              Đơn hàng
              <select required value={selected?.id ?? ""} onChange={(event) => {
            setShipmentId(event.target.value);
            setStaffId("");
            setSuccess("");
            setError("");
        }}>
                <option value="">Chọn đơn hàng</option>
                {eligibleOrders.map((shipment) => (<option key={shipment.id} value={shipment.id}>
                    {shipment.id} — {STATUS[shipment.status]}
                  </option>))}
              </select>
            </label>

            <label>
              Khu vực
              <select required value={area} onChange={(event) => {
            setArea(event.target.value);
            setStaffId("");
        }}>
                <option value="" disabled>Chọn khu vực</option>
                {areas.map((value) => (<option key={value} value={value}>{value}</option>))}
              </select>
            </label>

            <label>
              Ca làm việc
              <select value={shift} onChange={(event) => {
            setShift(event.target.value as Shift);
            setStaffId("");
        }}>
                <option value="morning">Ca sáng</option>
                <option value="afternoon">Ca chiều</option>
              </select>
            </label>

            <label className="full">
              Nhân viên
              <select required value={staffId} onChange={(event) => setStaffId(event.target.value)}>
                <option value="">Chọn nhân viên</option>

                {availableEmployees.map((employee) => {
            const load = employeeLoad(shipments, employee.id, shift, selected?.id);
            return (<option key={employee.id} value={employee.id} disabled={load >= employee.capacity}>
                      {employee.name} — {load}/{employee.capacity} việc khác
                    </option>);
        })}
              </select>
            </label>
          </div>

          {availableEmployees.length === 0 && (<p className="hint">
              Không có nhân viên cho khu vực và ca đã chọn.
            </p>)}

          {selected && (<div className="warehouse-summary">
              <strong>
                {kind === "delivery"
                ? selected.recipientName
                : selected.senderName}
              </strong>
              <p>
                {kind === "delivery"
                ? selected.deliveryAddress
                : selected.pickupAddress}
              </p>
              <p>Số lần giao đã bắt đầu: {selected.attempts}</p>
            </div>)}

          <p className="hint">
            Phân công giao hàng sẽ bắt đầu lần giao ngay.
            Đơn đang giao được đổi nhân viên mà không tăng số lần giao.
          </p>

          <div className="actions">
            <button type="submit" className="primary" disabled={!selected || !selectedEmployee}>
              {busy ? "Đang lưu…" : "Xác nhận phân công"}
            </button>
          </div>
        </fieldset>
      </form>
    </section>);
}
