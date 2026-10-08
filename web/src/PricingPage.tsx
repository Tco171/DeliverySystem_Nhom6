import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api, money } from "./api";
import type { PricingConfig, ServiceRate } from "./api";
export default function PricingPage() {
    const [config, setConfig] = useState<PricingConfig | null>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [loadError, setLoadError] = useState("");
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const [reload, setReload] = useState(0);
    useEffect(() => {
        let active = true;
        setLoading(true);
        setLoadError("");
        api.getPricing()
            .then((data) => {
            if (active)
                setConfig(data);
        })
            .catch((error: unknown) => {
            if (active) {
                setLoadError(error instanceof Error
                    ? error.message
                    : "Không tải được bảng giá.");
            }
        })
            .finally(() => {
            if (active)
                setLoading(false);
        });
        return () => {
            active = false;
        };
    }, [reload]);
    function clearMessages() {
        setError("");
        setSuccess("");
    }
    function updateGeneral(key: "includedWeightKg" | "volumetricDivisor", value: number) {
        setConfig((current) => current ? { ...current, [key]: value } : current);
        clearMessages();
    }
    function updateRate(service: "standard" | "express", key: keyof ServiceRate, value: number) {
        setConfig((current) => current
            ? {
                ...current,
                [service]: {
                    ...current[service],
                    [key]: value,
                },
            }
            : current);
        clearMessages();
    }
    async function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (!config || saving)
            return;
        setSaving(true);
        clearMessages();
        try {
            const saved = await api.savePricing(config);
            setConfig(saved);
            setSuccess("Đã lưu bảng giá. Báo giá mới sẽ sử dụng mức phí này.");
        }
        catch (error) {
            setError(error instanceof Error ? error.message : "Không lưu được bảng giá.");
        }
        finally {
            setSaving(false);
        }
    }
    if (loading) {
        return (<section className="panel">
        <p role="status">Đang tải bảng giá…</p>
      </section>);
    }
    if (loadError || !config) {
        return (<section className="panel">
        <p className="notice error" role="alert">
          {loadError || "Không có dữ liệu bảng giá."}
        </p>
        <button type="button" onClick={() => setReload((current) => current + 1)}>
          Thử lại
        </button>
      </section>);
    }
    return (<section className="panel">
      <div className="panel-heading">
        <div>
          <h2>Cấu hình phí vận chuyển</h2>
          <p className="muted">
            Áp dụng cho báo giá mới. Không thay đổi phí của đơn đã tạo.
          </p>
        </div>
      </div>

      {error && (<div className="notice error" role="alert">{error}</div>)}

      {success && (<div className="notice success" role="status">{success}</div>)}

      <form onSubmit={handleSubmit}>
        <fieldset disabled={saving}>
          <div className="form-grid">
            <label>
              Khối lượng trong phí cơ bản (kg)
              <input type="number" required min="0.01" step="0.01" value={Number.isFinite(config.includedWeightKg)
            ? config.includedWeightKg
            : ""} onChange={(event) => updateGeneral("includedWeightKg", event.target.valueAsNumber)}/>
            </label>

            <label>
              Hệ số quy đổi thể tích (cm³/kg)
              <input type="number" required min="1" step="1" value={Number.isFinite(config.volumetricDivisor)
            ? config.volumetricDivisor
            : ""} onChange={(event) => updateGeneral("volumetricDivisor", event.target.valueAsNumber)}/>
            </label>
          </div>

          <div className="pricing-services">
            {(["standard", "express"] as const).map((service) => (<section className="pricing-service" key={service}>
                <h3>
                  {service === "standard" ? "Tiêu chuẩn" : "Hỏa tốc"}
                </h3>

                <label>
                  Phí cơ bản (đ)
                  <input type="number" min="0" step="1" required value={Number.isFinite(config[service].baseFee)
                ? config[service].baseFee
                : ""} onChange={(event) => updateRate(service, "baseFee", event.target.valueAsNumber)}/>
                </label>

                <label>
                  Phí mỗi kg vượt mức, làm tròn lên (đ)
                  <input type="number" min="0" step="1" required value={Number.isFinite(config[service].extraKgFee)
                ? config[service].extraKgFee
                : ""} onChange={(event) => updateRate(service, "extraKgFee", event.target.valueAsNumber)}/>
                </label>

                <p className="muted">
                  Phí cơ bản đang nhập:{" "}
                  {Number.isFinite(config[service].baseFee)
                ? money(config[service].baseFee)
                : "—"}
                </p>
              </section>))}
          </div>

          <div className="pricing-explanation">
            <strong>Cách tính phí </strong>
            <p>
              Khối lượng quy đổi = dài × rộng × cao / hệ số quy đổi.
            </p>
            <p>
              Khối lượng tính phí là giá trị lớn hơn giữa khối lượng
              thực tế và khối lượng quy đổi.
            </p>
            <p>
              Phí = phí cơ bản + số kg vượt mức được làm tròn lên ×
              phí mỗi kg vượt mức.
            </p>
          </div>

          <div className="actions">
            <button type="submit" className="primary">
              {saving ? "Đang lưu…" : "Lưu bảng giá"}
            </button>
          </div>
        </fieldset>
      </form>
    </section>);
}
