// STAFF API SERVICE (Ân phụ trách - Thuật dùng cho giao diện Staff)
// Quy tắc: mọi thao tác Staff dùng assignmentId, KHÔNG dùng shipmentId.
import { request } from "./lib/http";

export type AssignmentStatus =
  | "assigned" | "accepted" | "in_progress"
  | "completed" | "rejected" | "cancelled";

export type StaffShipmentStatus =
  | "pending_pickup" | "picking_up" | "picked_up" | "pickup_failed"
  | "delivering" | "delivery_failed" | "delivered"
  | "return_pending" | "returning" | "returned";

export interface StaffAssignment {
  assignmentId: number;            // dùng cho MỌI action
  assignmentStatus: AssignmentStatus;
  assignedAt: string;
  acceptedAt: string | null;
  shipmentId: string;              // chỉ để hiển thị
  shipmentStatus: StaffShipmentStatus;
  senderName: string;
  senderPhone: string;
  pickupAddress: string;
  recipientName: string;
  recipientPhone: string;
  deliveryAddress: string;
  goods: string;
  weightKg: number;
  codAmount: number;
  service: string;
  notes: string;
}

export interface StaffActionResult {
  message: string;
  assignment?: {
    id: number; shipmentId?: string; status: AssignmentStatus;
    isActive?: boolean; acceptedAt?: string | null;
    endedAt?: string | null; rejectionReason?: string | null;
  };
  shipment?: {
    id: string; status: StaffShipmentStatus; assignmentStatus?: AssignmentStatus;
    attempts?: number; deliveryAttempts?: number; remainingAttempts?: number;
    maxDeliveryAttempts?: number; codAmount?: number; codCollected?: number;
    reason?: string;
  };
}

export const ASSIGNMENT_STATUS_LABEL: Record<AssignmentStatus, string> = {
  assigned: "Chờ nhận đơn", accepted: "Đã nhận đơn", in_progress: "Đang thực hiện",
  completed: "Hoàn tất", rejected: "Đã từ chối", cancelled: "Đã huỷ",
};

export const STAFF_SHIPMENT_STATUS_LABEL: Record<StaffShipmentStatus, string> = {
  pending_pickup: "Chờ lấy hàng", picking_up: "Đang đi lấy hàng",
  picked_up: "Đã lấy hàng", pickup_failed: "Lấy hàng thất bại",
  delivering: "Đang giao hàng", delivery_failed: "Giao hàng thất bại",
  delivered: "Giao thành công", return_pending: "Chờ hoàn hàng",
  returning: "Đang hoàn hàng", returned: "Đã hoàn hàng",
};

const MIN_REASON = 3; // khớp DTO backend
const MAX_REASON = 300;

function cleanReason(reason: string, what: string): string {
  const value = (reason ?? "").trim();
  if (value.length < MIN_REASON || value.length > MAX_REASON) {
    throw new Error(`Lý do ${what} phải từ ${MIN_REASON} đến ${MAX_REASON} ký tự.`);
  }
  return value;
}

async function patch(id: number, action: string, body?: { reason: string }) {
  if (!Number.isInteger(id) || id <= 0) throw new Error("assignmentId không hợp lệ.");
  return request<StaffActionResult>(`/staff/assignments/${id}/${action}`, {
    method: "PATCH",
    body: body ? JSON.stringify(body) : undefined,
  });
}

// ---- 11 hàm theo mục 8.3 ----
export function getStaffAssignments(): Promise<StaffAssignment[]> {
  return request<StaffAssignment[]>("/staff/shipments");
}
export function acceptAssignment(id: number) { return patch(id, "accept"); }
export async function rejectAssignment(id: number, reason: string) {
  return patch(id, "reject", { reason: cleanReason(reason, "từ chối") });
}
export function startPickup(id: number) { return patch(id, "start-pickup"); }
export function pickupSuccess(id: number) { return patch(id, "pickup-success"); }
export async function pickupFailed(id: number, reason: string) {
  return patch(id, "pickup-failed", { reason: cleanReason(reason, "lấy hàng thất bại") });
}
export function startDelivery(id: number) { return patch(id, "start-delivery"); }
export function deliverySuccess(id: number) { return patch(id, "delivery-success"); }
export async function deliveryFailed(id: number, reason: string) {
  return patch(id, "delivery-failed", { reason: cleanReason(reason, "giao thất bại") });
}
export function startReturn(id: number) { return patch(id, "start-return"); }
export function returnComplete(id: number) { return patch(id, "return-complete"); }

// ---- Helper cho UI: assignment này đang được phép làm gì? ----
export type StaffActionName =
  | "accept" | "reject" | "startPickup" | "pickupSuccess" | "pickupFailed"
  | "startDelivery" | "deliverySuccess" | "deliveryFailed"
  | "startReturn" | "returnComplete";

// Các action cần Modal nhập lý do
export const ACTIONS_NEED_REASON: readonly StaffActionName[] =
  ["reject", "pickupFailed", "deliveryFailed"];

export function getAvailableActions(
  a: Pick<StaffAssignment, "assignmentStatus" | "shipmentStatus">,
): StaffActionName[] {
  const shipment = (a.shipmentStatus ?? "").trim().toLowerCase();
  const assignment = (a.assignmentStatus ?? "").trim().toLowerCase();
  // Shipment is authoritative after work begins. Assignment is used only
  // for initial accepting and when Backend allows reattempting pickup.
  if (shipment === "pending_pickup") {
    if (assignment === "assigned") return ["accept", "reject"];
    if (assignment === "accepted") return ["startPickup"];
    return [];
  }
  if (shipment === "pickup_failed") {
    // Backend StartPickup requires assignment.Status == accepted.
    return assignment === "accepted" ? ["startPickup"] : [];
  }
  switch (shipment) {
    case "picking_up": return ["pickupSuccess", "pickupFailed"];
    case "picked_up":
    case "delivery_failed": return ["startDelivery"];
    case "delivering": return ["deliverySuccess", "deliveryFailed"];
    case "return_pending": return ["startReturn"];
    case "returning": return ["returnComplete"];
    default: return [];
  }
}
