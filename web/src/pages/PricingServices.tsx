import { useMemo, useState } from "react";
import { money } from "../api";
import "./pages.css";

type VehicleKey = "motorbike" | "car";
type ServiceKey = "standard" | "fast" | "express";

type PriceRow = {
  vehicle: VehicleKey;
  vehicleLabel: string;
  service: ServiceKey;
  serviceLabel: string;
  baseFee: number;
  estimate: string;
};

const PRICE_ROWS: PriceRow[] = [
  { vehicle: "motorbike", vehicleLabel: "Xe máy", service: "standard", serviceLabel: "Tiêu chuẩn", baseFee: 20000, estimate: "24 - 48 giờ" },
  { vehicle: "motorbike", vehicleLabel: "Xe máy", service: "fast", serviceLabel: "Nhanh", baseFee: 30000, estimate: "4 - 6 giờ" },
  { vehicle: "motorbike", vehicleLabel: "Xe máy", service: "express", serviceLabel: "Hỏa tốc", baseFee: 40000, estimate: "30 - 60 phút" },
  { vehicle: "car", vehicleLabel: "Ô tô", service: "standard", serviceLabel: "Tiêu chuẩn", baseFee: 50000, estimate: "Trong ngày" },
  { vehicle: "car", vehicleLabel: "Ô tô", service: "fast", serviceLabel: "Nhanh", baseFee: 70000, estimate: "2 - 4 giờ" },
];

interface PricingServicesProps {
  onNavigate?: (path: string) => void;
}

function weightSurcharge(weightKg: number) {
  if (weightKg <= 5) return 0;
  if (weightKg <= 10) return 10000;
  return 10000 + Math.ceil(weightKg - 10) * 2000;
}

export default function PricingServices({ onNavigate }: PricingServicesProps) {
  const [vehicle, setVehicle] = useState<VehicleKey>("motorbike");
  const [service, setService] = useState<ServiceKey>("standard");
  const [weightKg, setWeightKg] = useState(2);

  const availableServices = useMemo(
    () => PRICE_ROWS.filter((row) => row.vehicle === vehicle),
    [vehicle],
  );

  const activeRate =
    PRICE_ROWS.find((row) => row.vehicle === vehicle && row.service === service) ??
    availableServices[0];

  const surcharge = weightSurcharge(Math.max(0, weightKg));
  const estimatedTotal = activeRate.baseFee + surcharge;

  function changeVehicle(next: VehicleKey) {
    setVehicle(next);
    if (next === "car" && service === "express") setService("fast");
  }

  function createOrder(targetService: ServiceKey) {
    sessionStorage.setItem("express_selected_service", targetService);
    if (onNavigate) onNavigate("/orders/create");
    else window.location.href = "/orders/create";
  }

  return (
    <div className="ps-container">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">BẢNG GIÁ EXPRESS</p>
            <h2>Dịch vụ vận chuyển</h2>
            <p className="muted">
              Bảng giá này dùng cùng quy tắc với backend và ứng dụng mobile.
              Phí cuối cùng được hệ thống xác nhận khi bạn bấm Tính phí.
            </p>
          </div>
        </div>

        <div className="ps-services-grid">
          {PRICE_ROWS.filter((row) => row.vehicle === "motorbike").map((row) => (
            <article className={`ps-service-card ${row.service === "fast" ? "highlight" : ""}`} key={`${row.vehicle}-${row.service}`}>
              <div className="ps-card-header">
                <h3>Giao {row.serviceLabel}</h3>
                <p className="ps-card-desc">Xe máy · {row.estimate}</p>
              </div>
              <div className="ps-card-price-box">
                <div className="ps-card-price-label">Cước cơ bản</div>
                <div className="ps-card-price-val">{money(row.baseFee)}</div>
              </div>
              <ul className="ps-card-features">
                <li><span className="ps-feature-check">✓</span> 0 - 5 kg: không phụ phí khối lượng</li>
                <li><span className="ps-feature-check">✓</span> Trên 5 - 10 kg: +10.000 đ</li>
                <li><span className="ps-feature-check">✓</span> Trên 10 kg: +10.000 đ và +2.000 đ/kg vượt</li>
              </ul>
              <div className="ps-card-action">
                <button type="button" className="ps-btn-create" onClick={() => createOrder(row.service)}>
                  + Tạo đơn {row.serviceLabel}
                </button>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Bảng cước cơ bản</h2>
            <p className="muted">Ô tô hiện hỗ trợ Tiêu chuẩn và Nhanh; chưa hỗ trợ Hỏa tốc.</p>
          </div>
        </div>
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Phương tiện</th>
                <th>Dịch vụ</th>
                <th>Cước cơ bản</th>
                <th>Thời gian tham khảo</th>
              </tr>
            </thead>
            <tbody>
              {PRICE_ROWS.map((row) => (
                <tr key={`${row.vehicle}-${row.service}`}>
                  <td>{row.vehicleLabel}</td>
                  <td>{row.serviceLabel}</td>
                  <td>{money(row.baseFee)}</td>
                  <td>{row.estimate}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Tính thử phí</h2>
            <p className="muted">Tính theo đúng bảng phí hiện tại của backend.</p>
          </div>
        </div>

        <div className="form-grid">
          <label>
            Phương tiện
            <select value={vehicle} onChange={(event) => changeVehicle(event.target.value as VehicleKey)}>
              <option value="motorbike">Xe máy</option>
              <option value="car">Ô tô</option>
            </select>
          </label>

          <label>
            Dịch vụ
            <select value={service} onChange={(event) => setService(event.target.value as ServiceKey)}>
              {availableServices.map((row) => (
                <option key={row.service} value={row.service}>{row.serviceLabel}</option>
              ))}
            </select>
          </label>

          <label>
            Khối lượng (kg)
            <input type="number" min="0.01" step="0.01" value={weightKg} onChange={(event) => setWeightKg(Math.max(0.01, event.target.valueAsNumber || 0.01))} />
          </label>
        </div>

        <div className="hint">
          Cước cơ bản: <strong>{money(activeRate.baseFee)}</strong> · Phụ phí khối lượng: <strong>{money(surcharge)}</strong> · Dự kiến: <strong>{money(estimatedTotal)}</strong>
        </div>
      </section>
    </div>
  );
}
