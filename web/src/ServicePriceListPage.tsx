import { useState } from "react";
import { money } from "./api";

type Vehicle = "Xe máy" | "Ô tô";

type PriceRow = {
    vehicle: Vehicle;
    service: string;
    fee: number;
};

type WeightTier = {
    label: string;
    fee: string; // chữ hiển thị trong bảng
};

// ---------------------------------------------------------------
// DỮ LIỆU BẢNG GIÁ (sửa giá ở đây là web cập nhật theo)
// ---------------------------------------------------------------
export const BASE_PRICES: PriceRow[] = [
    { vehicle: "Xe máy", service: "Tiêu chuẩn", fee: 20000 },
    { vehicle: "Xe máy", service: "Nhanh", fee: 30000 },
    { vehicle: "Xe máy", service: "Hỏa tốc", fee: 40000 },
    { vehicle: "Ô tô", service: "Tiêu chuẩn", fee: 50000 },
    { vehicle: "Ô tô", service: "Nhanh", fee: 70000 },
];

// 5-10kg: 10.000đ. Từ kg thứ 11 trở đi, MỖI kg thêm CỘNG THÊM 2.000đ vào mức 10.000đ
// (kg lẻ làm tròn lên). Ví dụ: 11kg = 10.000 + 2.000 = 12.000đ; 12kg = 14.000đ
export const TIER_5_10_FEE = 10000;
export const PER_KG_FEE_OVER_10 = 2000;

export const WEIGHT_TIERS: WeightTier[] = [
    { label: "0 – 5 kg", fee: "Miễn phí" },
    { label: "5 – 10 kg", fee: `+${money(TIER_5_10_FEE)}` },
    { label: "Trên 10 kg", fee: `+${money(TIER_5_10_FEE)}, mỗi kg thêm trên 10 kg cộng ${money(PER_KG_FEE_OVER_10)}` },
];

// 0–5kg: miễn phí | 5–10kg: +10.000đ | >10kg: 10.000đ + 2.000đ cho mỗi kg thêm trên 10kg
export function weightSurcharge(kg: number): number {
    if (!Number.isFinite(kg) || kg <= 5) return 0;
    if (kg <= 10) return TIER_5_10_FEE;
    return TIER_5_10_FEE + Math.ceil(kg - 10) * PER_KG_FEE_OVER_10;
}

const VEHICLES: Vehicle[] = ["Xe máy", "Ô tô"];

function servicesOf(vehicle: Vehicle): string[] {
    return BASE_PRICES.filter((row) => row.vehicle === vehicle).map((row) => row.service);
}

export default function ServicePriceListPage() {
    // Phần tính thử phí
    const [vehicle, setVehicle] = useState<Vehicle>("Xe máy");
    const [service, setService] = useState("Tiêu chuẩn");
    // Giữ ô nhập ở dạng chữ để cho phép xóa trống khi đang gõ; chỉ nhận chữ số 0-9
    const [weightText, setWeightText] = useState("1");
    const weight = weightText === "" ? 0 : Number(weightText);

    const baseFee = BASE_PRICES.find((row) => row.vehicle === vehicle && row.service === service)?.fee ?? 0;
    const surcharge = weightSurcharge(weight);
    const extraKg = weight > 10 ? Math.ceil(weight - 10) : 0; // số kg vượt quá 10kg
    const extraFee = extraKg * PER_KG_FEE_OVER_10; // tiền cộng thêm cho phần vượt
    const total = baseFee + surcharge;

    function changeVehicle(next: Vehicle) {
        setVehicle(next);
        // Ô tô không có "Hỏa tốc" -> nếu dịch vụ đang chọn không tồn tại thì về dịch vụ đầu tiên
        const available = servicesOf(next);
        if (!available.includes(service)) setService(available[0]);
    }

    return (<>
      <section className="panel">
        <div className="panel-heading">
          <h2>Bảng giá dịch vụ Express</h2>
          <p className="muted">Phí cơ bản theo loại xe và dịch vụ giao hàng.</p>
        </div>

        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Loại xe</th>
                <th>Dịch vụ</th>
                <th>Phí cơ bản</th>
              </tr>
            </thead>
            <tbody>
              {BASE_PRICES.map((row) => (<tr key={`${row.vehicle}-${row.service}`}>
                  <td>{row.vehicle}</td>
                  <td>{row.service}</td>
                  <td><strong>{money(row.fee)}</strong></td>
                </tr>))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <h2>Phụ phí khối lượng</h2>
          <p className="muted">Cộng thêm vào phí cơ bản tùy theo khối lượng kiện hàng.</p>
        </div>

        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Khối lượng</th>
                <th>Phụ phí</th>
              </tr>
            </thead>
            <tbody>
              {WEIGHT_TIERS.map((tier) => (<tr key={tier.label}>
                  <td>{tier.label}</td>
                  <td><strong>{tier.fee}</strong></td>
                </tr>))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <h2>Tính thử phí vận chuyển</h2>
          <p className="muted">
            Chỉ mang tính tham khảo. Phí chính thức được hệ thống báo khi bạn tạo đơn.
          </p>
        </div>

        <div className="form-grid">
          <label>
            Loại xe
            <select value={vehicle} onChange={(event) => changeVehicle(event.target.value as Vehicle)}>
              {VEHICLES.map((v) => (<option key={v} value={v}>{v}</option>))}
            </select>
          </label>

          <label>
            Dịch vụ
            <select value={service} onChange={(event) => setService(event.target.value)}>
              {servicesOf(vehicle).map((s) => (<option key={s} value={s}>{s}</option>))}
            </select>
          </label>

          <label>
            Khối lượng (kg)
            <input type="text" inputMode="numeric" pattern="[0-9]*" maxLength={4} placeholder="Nhập số kg" value={weightText} onChange={(event) => setWeightText(event.target.value.replace(/\D/g, ""))}/>
          </label>
        </div>

        <div className="pricing-explanation">
          <p>Phí cơ bản: {money(baseFee)}</p>
          <p>
            Phụ phí khối lượng:{" "}
            {surcharge === 0 ? "Miễn phí" : `+${money(surcharge)}`}
            {weight > 10 && ` = ${money(TIER_5_10_FEE)} + ${money(extraFee)} (thêm ${extraKg} kg, mỗi kg +${money(PER_KG_FEE_OVER_10)})`}
          </p>
          <p><strong>Tổng cộng: {money(total)}</strong></p>
        </div>
      </section>
    </>);
}