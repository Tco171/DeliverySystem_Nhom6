import { request } from "./http";
export interface StaffAssignment {
  assignmentId: number; shipmentId: string; assignmentStatus: string; shipmentStatus: string;
  senderName?: string; senderPhone?: string; pickupAddress?: string;
  recipientName?: string; recipientPhone?: string; deliveryAddress?: string;
  codAmount?: number; service?: string; notes?: string;
}
export type StaffAction = "accept" | "reject" | "start-pickup" | "pickup-success" | "pickup-failed" | "start-delivery" | "delivery-success" | "delivery-failed" | "start-return" | "return-complete";
export const staffApi = {
  list: () => request<StaffAssignment[]>("/staff/shipments"),
  action: (id: number, action: StaffAction, reason?: string) => request<unknown>(`/staff/assignments/${id}/${action}`, {
    method: "PATCH", headers: {"Content-Type":"application/json"}, body: JSON.stringify({ reason: reason ?? "" })
  })
};
export interface VnPayPayment { paymentId: string; shipmentId: string; amount: number; status: string; paymentUrl: string; transactionReference: string; }
export const paymentApi = {
  create: (shipmentId: string) => request<VnPayPayment>("/payments/vnpay", {method:"POST", body:JSON.stringify({shipmentId})}),
  get: (paymentId: string) => request<VnPayPayment>(`/payments/${encodeURIComponent(paymentId)}`)
};
export interface ShipmentPaymentStatus {
  shipmentId: string;
  status: string;
}

export const paymentStatusApi = {
  list: () =>
    request<ShipmentPaymentStatus[]>("/payments/statuses"),
};