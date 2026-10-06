import { useEffect, useState } from "react";
import type { FormEvent } from "react";

import {
  api,
  INCIDENT_STATUSES,
  INCIDENT_TYPES,
} from "./api";

import type {
  Incident,
  IncidentStatus,
} from "./api";


export default function IncidentManagement() {
  const [incidents, setIncidents] = useState<Incident[]>([]);

  const [filter, setFilter] =
    useState<IncidentStatus | "">("");

  const [search, setSearch] = useState("");

  const [selectedId, setSelectedId] =
    useState<number | null>(null);

  const [loading, setLoading] = useState(true);

  const [loadError, setLoadError] = useState("");

  const [success, setSuccess] = useState("");

  const [reload, setReload] = useState(0);

  // =====================================================
  // LOAD DANH SÁCH KHIẾU NẠI
  // =====================================================

  useEffect(() => {
    let active = true;

    setLoading(true);
    setLoadError("");

    api
      .listAllIncidents()
      .then((data) => {
        if (active) {
          setIncidents(data);
        }
      })
      .catch((error: unknown) => {
        if (active) {
          setLoadError(
            error instanceof Error
              ? error.message
              : "Không tải được danh sách sự cố."
          );
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, [reload]);


  // =====================================================
  // TÌM KIẾM + LỌC
  // =====================================================

  const visible = incidents.filter(
    (incident) => {
      const matchesStatus =
        !filter ||
        incident.status === filter;

      const term = search
        .trim()
        .toLocaleLowerCase("vi");

      const values = [
        incident.shipmentId,
        incident.content,
        INCIDENT_TYPES[incident.type] ?? "",
      ];

      const matchesSearch =
        !term ||
        values.some((value) =>
          value
            .toLocaleLowerCase("vi")
            .includes(term)
        );

      return (
        matchesStatus &&
        matchesSearch
      );
    }
  );


  // =====================================================
  // BÁO CÁO ĐANG ĐƯỢC CHỌN
  // =====================================================

  const selected = incidents.find(
    (item) => item.id === selectedId
  );


  // =====================================================
  // GIAO DIỆN
  // =====================================================

  return (
    <>
      <section className="panel">

        <div className="panel-heading">
          <div>
            <h2>
              Tiếp nhận và xử lý sự cố
            </h2>

            <p className="muted">
              Theo dõi báo cáo và ghi nhận
              kết quả giải quyết.
            </p>
          </div>

          <button
            type="button"
            disabled={
              loading ||
              Boolean(selected)
            }
            onClick={() => {
              setSuccess("");

              setReload(
                (current) =>
                  current + 1
              );
            }}
          >
            Tải lại
          </button>
        </div>


        {/* THÔNG BÁO THÀNH CÔNG */}

        {success && (
          <div
            className="notice success"
            role="status"
          >
            {success}
          </div>
        )}


        {/* BỘ LỌC */}

        <div className="filters">

          <input
            aria-label="Tìm báo cáo sự cố"
            placeholder="Mã vận đơn, nội dung hoặc loại sự cố…"
            value={search}
            onChange={(event) =>
              setSearch(
                event.target.value
              )
            }
          />


          <select
            aria-label="Lọc trạng thái xử lý"
            value={filter}
            onChange={(event) =>
              setFilter(
                event.target.value as
                  | IncidentStatus
                  | ""
              )
            }
          >
            <option value="">
              Tất cả trạng thái
            </option>

            {Object.entries(
              INCIDENT_STATUSES
            ).map(
              ([value, label]) => (
                <option
                  key={value}
                  value={value}
                >
                  {label}
                </option>
              )
            )}
          </select>

        </div>


        {/* DANH SÁCH */}

        {loading ? (

          <p role="status">
            Đang tải báo cáo…
          </p>

        ) : loadError ? (

          <div
            className="notice error"
            role="alert"
          >
            {loadError}
          </div>

        ) : visible.length === 0 ? (

          <div className="empty">

            <h3>
              Không có báo cáo phù hợp
            </h3>

            <p>
              Báo cáo được tạo từ phần
              Sự cố và khiếu nại trong
              chi tiết vận đơn.
            </p>

          </div>

        ) : (

          <div className="table-scroll">

            <table>

              <thead>
                <tr>
                  <th>Vận đơn</th>

                  <th>
                    Loại sự cố
                  </th>

                  <th>
                    Ngày báo cáo
                  </th>

                  <th>
                    Trạng thái
                  </th>

                  <th>
                    Thao tác
                  </th>
                </tr>
              </thead>


              <tbody>

                {visible.map(
                  (incident) => (

                    <tr key={incident.id}>

                      <td>
                        <strong className="tracking-code">
                          {
                            incident.shipmentId
                          }
                        </strong>
                      </td>


                      <td>
                        {
                          INCIDENT_TYPES[
                            incident.type
                          ]
                        }
                      </td>


                      <td>
                        {new Date(
                          incident.createdAt
                        ).toLocaleString(
                          "vi-VN"
                        )}
                      </td>


                      <td>

                        <span
                          className={
                            `badge incident-${incident.status}`
                          }
                        >
                          {
                            INCIDENT_STATUSES[
                              incident.status
                            ]
                          }
                        </span>

                      </td>


                      <td>

                        <button
                          type="button"
                          disabled={
                            Boolean(
                              selected
                            )
                          }
                          onClick={() => {
                            setSelectedId(
                              incident.id
                            );

                            setSuccess("");
                          }}
                        >
                          Xem báo cáo
                        </button>

                      </td>

                    </tr>

                  )
                )}

              </tbody>

            </table>

          </div>

        )}

      </section>


      {/* ===============================================
          TRÌNH XỬ LÝ KHIẾU NẠI
         =============================================== */}

      {selected && (

        <IncidentEditor

          key={
            `${selected.id}-${selected.status}`
          }

          incident={selected}

          onClose={() =>
            setSelectedId(null)
          }

          onSaved={(updated) => {

            setIncidents(
              (current) =>
                current.map(
                  (item) =>
                    item.id ===
                    updated.id
                      ? updated
                      : item
                )
            );

            setSelectedId(null);

            setSuccess(
              `Đã cập nhật báo cáo: ${
                INCIDENT_STATUSES[
                  updated.status
                ]
              }.`
            );
          }}
        />

      )}

    </>
  );
}



// =======================================================
// PROPS EDITOR
// =======================================================

interface IncidentEditorProps {
  incident: Incident;

  onClose: () => void;

  onSaved: (
    incident: Incident
  ) => void;
}



// =======================================================
// INCIDENT EDITOR
// =======================================================

function IncidentEditor({
  incident,
  onClose,
  onSaved,
}: IncidentEditorProps) {

  const [response, setResponse] =
    useState("");

  const [busy, setBusy] =
    useState(false);

  const [error, setError] =
    useState("");


  // =====================================================
  // CẬP NHẬT TRẠNG THÁI
  // =====================================================

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>
  ) {

    event.preventDefault();


    if (
      busy ||
      incident.status === "resolved"
    ) {
      return;
    }


    setBusy(true);
    setError("");


    try {

      // pending
      //      ↓
      // processing
      //      ↓
      // resolved

      const nextStatus:
        | "processing"
        | "resolved" =
        incident.status === "pending"
          ? "processing"
          : "resolved";


      const updated =
        await api.updateIncident(
          incident.id,
          {
            status: nextStatus,

            response:
              nextStatus ===
              "resolved"
                ? response
                : "",
          }
        );


      onSaved(updated);

    } catch (error) {

      setError(
        error instanceof Error
          ? error.message
          : "Không cập nhật được báo cáo."
      );

    } finally {

      setBusy(false);

    }
  }


  // =====================================================
  // GIAO DIỆN EDITOR
  // =====================================================

  return (

    <section className="panel">

      <div className="panel-heading">

        <div>

          <h2>
            {
              INCIDENT_TYPES[
                incident.type
              ]
            }
          </h2>


          <p className="muted tracking-code">
            Vận đơn:{" "}
            {incident.shipmentId}
          </p>

        </div>


        <button
          type="button"
          disabled={busy}
          onClick={onClose}
        >
          Đóng
        </button>

      </div>


      {/* NỘI DUNG BÁO CÁO */}

      <div className="incident-card">

        <span
          className={
            `badge incident-${incident.status}`
          }
        >
          {
            INCIDENT_STATUSES[
              incident.status
            ]
          }
        </span>


        <p className="incident-description">
          {incident.content}
        </p>


        <time
          className="muted"
          dateTime={
            incident.createdAt
          }
        >
          Gửi lúc:{" "}
          {new Date(
            incident.createdAt
          ).toLocaleString(
            "vi-VN"
          )}
        </time>

      </div>


      {/* ===============================================
          ĐÃ GIẢI QUYẾT
         =============================================== */}

      {incident.status ===
      "resolved" ? (

        <div className="incident-resolution incident-editor-space">

          <strong>
            Kết quả giải quyết
          </strong>

          <p>
            {incident.response ||
              "Không có nội dung phản hồi."}
          </p>


          {incident.resolvedAt && (

            <time
              className="muted"
              dateTime={
                incident.resolvedAt
              }
            >
              Giải quyết lúc:{" "}
              {new Date(
                incident.resolvedAt
              ).toLocaleString(
                "vi-VN"
              )}
            </time>

          )}

        </div>

      ) : (

        // ===============================================
        // CHƯA GIẢI QUYẾT
        // ===============================================

        <form
          onSubmit={handleSubmit}
          className="incident-editor-space"
        >

          {error && (

            <div
              className="notice error"
              role="alert"
            >
              {error}
            </div>

          )}


          <fieldset disabled={busy}>


            {/* PENDING */}

            {incident.status ===
            "pending" ? (

              <p className="muted">

                Bắt đầu xử lý để chuyển
                báo cáo sang trạng thái{" "}

                <strong>
                  Đang xử lý
                </strong>.

              </p>

            ) : (

              // PROCESSING

              <label>

                Kết quả giải quyết

                <textarea
                  rows={4}
                  value={response}
                  maxLength={2000}
                  required
                  onChange={(event) =>
                    setResponse(
                      event.target.value
                    )
                  }
                  placeholder="Mô tả nguyên nhân, biện pháp và kết quả xử lý…"
                />

                <span className="muted">
                  {response.length}
                  /2.000 ký tự
                </span>

              </label>

            )}


            <div className="actions incident-submit">

              <button
                type="submit"
                className="primary"

                disabled={
                  incident.status ===
                    "processing" &&
                  !response.trim()
                }
              >

                {busy
                  ? "Đang lưu…"

                  : incident.status ===
                    "pending"

                  ? "Bắt đầu xử lý"

                  : "Hoàn tất giải quyết"}

              </button>

            </div>

          </fieldset>

        </form>

      )}

    </section>

  );
}