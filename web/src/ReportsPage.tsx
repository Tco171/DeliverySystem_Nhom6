import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api, money, STATUS } from "./api";
import type { ShipmentReport } from "./api";
export default function ReportsPage() {
    const [from, setFrom] = useState("");
    const [to, setTo] = useState("");
    const [query, setQuery] = useState({
        from: "",
        to: "",
        revision: 0,
    });
    const [report, setReport] = useState<ShipmentReport | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [formError, setFormError] = useState("");
    useEffect(() => {
        let active = true;
        setLoading(true);
        setError("");
        setReport(null);
        api.getShipmentReport(query.from, query.to)
            .then((data) => {
            if (active)
                setReport(data);
        })
            .catch((error: unknown) => {
            if (active) {
                setError(error instanceof Error
                    ? error.message
                    : "Không tải được báo cáo.");
            }
        })
            .finally(() => {
            if (active)
                setLoading(false);
        });
        return () => {
            active = false;
        };
    }, [query]);
    function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        setFormError("");
        if (from && to && from > to) {
            setFormError("Ngày bắt đầu không được sau ngày kết thúc.");
            return;
        }
        setQuery((current) => ({
            from,
            to,
            revision: current.revision + 1,
        }));
    }
    function showAll() {
        setFrom("");
        setTo("");
        setFormError("");
        setQuery((current) => ({
            from: "",
            to: "",
            revision: current.revision + 1,
        }));
    }
    const successRate = report && report.total > 0
        ? `${((report.delivered / report.total) * 100).toFixed(1)}%`
        : "—";
    return (<>
      <section className="panel">
        <div className="panel-heading">
          <div>
            <h2>Báo cáo hoạt động</h2>
            <p className="muted">
              Chọn khoảng ngày tạo đơn để xem tình trạng hiện tại
              của các đơn trong khoảng đó.
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <fieldset disabled={loading}>
            <div className="report-filters">
              <label>
                Tạo từ ngày
                <input type="date" value={from} max={to || undefined} onChange={(event) => setFrom(event.target.value)}/>
              </label>

              <label>
                Đến hết ngày
                <input type="date" value={to} min={from || undefined} onChange={(event) => setTo(event.target.value)}/>
              </label>

              <button type="submit" className="primary">
                {loading ? "Đang tải…" : "Xem báo cáo"}
              </button>

              <button type="button" onClick={showAll}>
                Tất cả thời gian
              </button>
            </div>
          </fieldset>
        </form>

        {formError && (<p className="notice error" role="alert">
            {formError}
          </p>)}
      </section>

      {loading ? (<section className="panel">
          <p role="status">Đang tổng hợp dữ liệu…</p>
        </section>) : error ? (<section className="panel">
          <p className="notice error" role="alert">{error}</p>
          <button type="button" onClick={() => setQuery((current) => ({
                ...current,
                revision: current.revision + 1,
            }))}>
            Thử lại
          </button>
        </section>) : report ? (<>
          <div className="report-period">
            <strong>
              Ngày tạo đơn: {report.from || "Từ đầu"} →{" "}
              {report.to || "Không giới hạn"}
            </strong>
            <span>
              Cập nhật:{" "}
              {new Date(report.generatedAt).toLocaleString("vi-VN")}
            </span>
          </div>

          <section className="stats" aria-label="Thống kê vận chuyển">
            {[
                ["Tổng đơn", report.total],
                ["Giao thành công", report.delivered],
                ["Chưa kết thúc", report.active],
                ["Tỷ lệ đã giao / tổng đơn", successRate],
            ].map(([label, value]) => (<article className="stat" key={label}>
                <p>{label}</p>
                <strong>{value}</strong>
              </article>))}
          </section>

          <div className="report-secondary">
            <article className="stat">
              <p>Đang ở trạng thái thất bại</p>
              <strong>{report.failed}</strong>
              <p className="report-explanation">
                Lấy hoặc giao thất bại, chưa chuyển sang bước khác.
              </p>
            </article>

            <article className="stat">
              <p>Đang hoàn hàng</p>
              <strong>{report.returning}</strong>
              <p className="report-explanation">
                Đang trên hành trình trả hàng về shop.
              </p>
            </article>

            <article className="stat">
              <p>Đã giao hoàn</p>
              <strong>{report.returned}</strong>
              <p className="report-explanation">
                Bao gồm hàng chờ shop xác nhận và hàng đã xác nhận.
              </p>
            </article>
          </div>

          <section className="panel">
            <div className="panel-heading">
              <div>
                <h2>Phân bố trạng thái</h2>
                <p className="muted">
                  Mỗi đơn chỉ xuất hiện ở một trạng thái hiện tại.
                </p>
              </div>
            </div>

            {report.total === 0 ? (<div className="empty">
                <h3>Không có đơn trong khoảng ngày này</h3>
                <p>Thử chọn khoảng ngày khác.</p>
              </div>) : (<div className="report-bars">
                {report.byStatus.map((item) => {
                    const percentage = (item.count / report.total) * 100;
                    return (<div className="report-bar-row" key={item.status}>
                      <div className="report-bar-label">
                        <span>{STATUS[item.status]}</span>
                        <strong>
                          {item.count} · {percentage.toFixed(1)}%
                        </strong>
                      </div>

                      <div className="report-bar-track" aria-hidden="true">
                        <div className={`report-bar-fill ${item.status}`} style={{ width: `${percentage}%` }}/>
                      </div>
                    </div>);
                })}
              </div>)}
          </section>

          <section className="panel">
            <div className="panel-heading">
              <h2>Tổng hợp COD và phí</h2>
            </div>

            <div className="report-money">
              <article>
                <p className="muted">COD đã ghi nhận thu</p>
                <strong>{money(report.codCollected)}</strong>
                <p className="muted">
                  Chưa thể hiện số tiền đã đối soát hoặc đã trả cho shop.
                </p>
              </article>

              <article>
                <p className="muted">Phí vận chuyển của đơn giao thành công</p>
                <strong>{money(report.deliveredShippingFees)}</strong>
                <p className="muted">
                  Tổng phí trên đơn, chưa xác nhận phí đã được thanh toán.
                </p>
              </article>
            </div>
          </section>

          <p className="muted">
            Các chỉ số tổng hợp có thể giao nhau. Ví dụ, đơn đang hoàn
            cũng thuộc nhóm chưa kết thúc. Tỷ lệ đã giao được tính trên
            toàn bộ đơn đã chọn, bao gồm các đơn vẫn đang xử lý.
          </p>
        </>) : null}
    </>);
}
