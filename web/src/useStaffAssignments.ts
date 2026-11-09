import { useCallback, useEffect, useState } from "react";
import { getStaffAssignments } from "./staffApi";
import type { StaffActionResult, StaffAssignment } from "./staffApi";

export function useStaffAssignments() {
  const [assignments, setAssignments] = useState<StaffAssignment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const refresh = useCallback(async () => {
    try {
      setAssignments(await getStaffAssignments());
      setError("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Không tải được danh sách đơn.");
    } finally {
      setLoading(false);
    }
  }, []);

  // Tải lần đầu
  useEffect(() => {
    let cancelled = false;
    getStaffAssignments()
      .then((data) => { if (!cancelled) { setAssignments(data); setError(""); } })
      .catch((err: unknown) => {
        if (!cancelled)
          setError(err instanceof Error ? err.message : "Không tải được danh sách đơn.");
      })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, []);

  // Chạy action; thành công thì refresh, thất bại thì ném lỗi cho UI
  const run = useCallback(async (action: () => Promise<StaffActionResult>) => {
    const result = await action();
    await refresh();
    return result;
  }, [refresh]);

  return { assignments, loading, error, refresh, run };
}