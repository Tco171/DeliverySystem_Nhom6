import { request } from "./lib/http";
export const STATUS = {
  pending_pickup: "Chờ lấy hàng",
  pickup_failed: "Lấy hàng thất bại",
  picked_up: "Đã lấy hàng",
  in_transit: "Đang vận chuyển",
  at_hub: "Đã đến kho",
  out_for_delivery: "Đang giao hàng",
  delivery_failed: "Giao hàng thất bại",
  delivered: "Giao thành công",
  returning: "Đang hoàn hàng",
  returned: "Đã giao hoàn",
  return_confirmed: "Shop đã nhận hàng hoàn",
} as const;

export type Status = keyof typeof STATUS;

export type FeePayer = "shop_prepaid" | "recipient" | "deduct_cod";

export interface ShipmentInput {
  senderName: string;
  senderPhone: string;
  pickupAddress: string;
  recipientName: string;
  recipientPhone: string;
  deliveryAddress: string;
  goods: string;
  weightKg: number;
  lengthCm: number;
  widthCm: number;
  heightCm: number;
  declaredValue: number;
  codAmount: number;
  service: "standard" | "express";
  feePayer: FeePayer;
  notes: string;
}

export interface Quote {
  id: string;
  fee: number;
  expiresAt: string;
}

export interface TrackingEvent {
  status: Status;
  at: string;
  note: string;
}

export interface Shipment extends ShipmentInput {
  currentHubId?: string | null;
  id: string;
  status: Status;
  fee: number;
  attempts: number;
  codCollected: number;
  createdAt: string;
  events: TrackingEvent[];
  assignedStaffId?: string;
  assignmentKind?: "pickup" | "delivery" | "return";
  assignmentArea?: string;
  assignmentDate?: string;
  assignmentShift?: "morning" | "afternoon";
}

export interface TransitionInput {
  status: Status;
  note: string;
  codCollected?: number;
}

export const money = (value: number) =>
  new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
  }).format(value);

function validate(input: ShipmentInput) {
  const required = [
    input.senderName,
    input.pickupAddress,
    input.recipientName,
    input.deliveryAddress,
    input.goods,
  ];

  if (required.some((value) => !value.trim())) {
    throw new Error("Vui lòng điền đầy đủ thông tin bắt buộc.");
  }

  const phone = /^\+?[0-9 ()-]{8,20}$/;
  if (!phone.test(input.senderPhone.trim())) {
  throw new Error("Số điện thoại người gửi không hợp lệ.");
}   

if (!phone.test(input.recipientPhone.trim())) {
  throw new Error("Số điện thoại người nhận không hợp lệ.");
}

  const dimensions = [
    input.weightKg,
    input.lengthCm,
    input.widthCm,
    input.heightCm,
  ];

  if (dimensions.some((n) => !Number.isFinite(n) || n <= 0)) {
    throw new Error("Khối lượng và kích thước phải lớn hơn 0.");
  }

  if (
    [input.codAmount, input.declaredValue].some(
      (n) => !Number.isSafeInteger(n) || n < 0,
    )
  ) {
    throw new Error("Giá trị hàng và COD phải là số nguyên không âm.");
  }
}

export interface PickupLocation {
  id: string;
  name: string;
  contactName: string;
  contactPhone: string;
  address: string;
}

export const INCIDENT_TYPES = {
  damaged: "Hàng hóa hư hỏng",
  delayed: "Giao hàng chậm",
  lost: "Thất lạc hàng hóa",
  wrong_item: "Sai hàng",
  other: "Vấn đề khác",
} as const;

export const INCIDENT_STATUSES = {
  pending: "Chờ xử lý",
  processing: "Đang xử lý",
  resolved: "Đã giải quyết",
} as const;

export type IncidentType = keyof typeof INCIDENT_TYPES;

export type IncidentStatus = keyof typeof INCIDENT_STATUSES;

export interface IncidentInput {
  type: IncidentType;
  content: string;
}

export interface Incident extends IncidentInput {
  id: number;
  shipmentId: string;
  status: IncidentStatus;
  createdAt: string;
  response: string | null;
  resolvedAt: string | null;
}

export interface Hub {
  id: string;
  name: string;
  address: string;
}

export type HubAction = "receive" | "dispatch";

export interface ShipmentReport {
  from: string;
  to: string;
  generatedAt: string;
  total: number;
  delivered: number;
  failed: number;
  returning: number;
  returned: number;
  active: number;
  codCollected: number;
  deliveredShippingFees: number;
  byStatus: {
    status: Status;
    count: number;
  }[];
}

export interface ServiceRate {
  baseFee: number;
  extraKgFee: number;
}

export interface PricingConfig {
  includedWeightKg: number;
  volumetricDivisor: number;
  standard: ServiceRate;
  express: ServiceRate;
}

function validatePricing(config: PricingConfig) {
  if (
    !Number.isFinite(config.includedWeightKg) ||
    config.includedWeightKg <= 0 ||
    !Number.isFinite(config.volumetricDivisor) ||
    config.volumetricDivisor <= 0
  ) {
    throw new Error("Khối lượng cơ bản và hệ số quy đổi phải lớn hơn 0.");
  }

  const fees = [
    config.standard.baseFee,
    config.standard.extraKgFee,
    config.express.baseFee,
    config.express.extraKgFee,
  ];

  if (fees.some((fee) => !Number.isSafeInteger(fee) || fee < 0)) {
    throw new Error("Các mức phí phải là số nguyên không âm.");
  }
}

export type UserRole = "customer" | "staff" | "operations";

export type AccountType =
  | "personal"
  | "business";

export interface SessionUser {
  id: string;
  name: string;
  role: UserRole;
  accountType?: AccountType;
}

export type AssignmentKind = "pickup" | "delivery" | "return";

export type Shift = "morning" | "afternoon";

export interface DeliveryEmployee {
  id: string;
  name: string;
  area: string;
  shift: Shift;
  capacity: number;
}

export interface AssignmentInput {
  staffId: string;
  kind: AssignmentKind;
  area: string;
  shift: Shift;
}

export function localDateKey(): string {
  const date = new Date();

  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

export function hasActiveAssignment(shipment: Shipment): boolean {
  return (
    (shipment.assignmentKind === "pickup" &&
      shipment.status === "pending_pickup") ||
    (shipment.assignmentKind === "delivery" &&
      shipment.status === "out_for_delivery") ||
    (shipment.assignmentKind === "return" &&
      shipment.status === "returning")
  );
}

export function employeeLoad(
  shipments: Shipment[],
  staffId: string,
  shift: Shift,
  excludeShipmentId?: string,
): number {
  return shipments.filter(
    (shipment) =>
      shipment.id !== excludeShipmentId &&
      shipment.assignedStaffId === staffId &&
      shipment.assignmentDate === localDateKey() &&
      shipment.assignmentShift === shift &&
      hasActiveAssignment(shipment),
  ).length;
}

export interface SettlementLine {
  shipmentId: string;
  codCollected: number;
  shippingDeduction: number;
}

export interface Settlement {
  id: string;
  createdAt: string;
  lines: SettlementLine[];
  totalCod: number;
  shippingDeduction: number;
  adjustment: number;
  adjustmentReason: string;
  netAmount: number;
  status: "pending" | "completed";
  completedAt: string | null;
  paymentReference: string | null;
}

export interface SettlementData {
  eligibleShipments: Shipment[];
  settlements: Settlement[];
}

export interface CreateSettlementInput {
  shipmentIds: string[];
  adjustment: number;
  adjustmentReason: string;
}

export interface RegisterInput { fullName: string; shopName: string; phone: string; email: string; password: string; }
export interface RegisterResult { message: string; }
function checkedSession(value: SessionUser): SessionUser {
  if (
    !value ||
    typeof value.id !== 'string' ||
    typeof value.name !== 'string' ||
    !['customer', 'staff', 'operations'].includes(value.role)
  ) {
    throw new Error(
      'Phản hồi tài khoản không hợp lệ. Vui lòng liên hệ bộ phận hỗ trợ.'
    );
  }

  return value;
}

export const api = {
async listPickupLocations(): Promise<PickupLocation[]> {
    return request<PickupLocation[]>("/pickup-locations");
},
async createPickupLocation(input: Omit<PickupLocation, "id">): Promise<PickupLocation> {
    const clean = {
        name: input.name.trim(),
        contactName: input.contactName.trim(),
        contactPhone: input.contactPhone.trim(),
        address: input.address.trim(),
    };
    if (Object.values(clean).some((value) => !value)) {
        throw new Error("Vui lòng nhập tên điểm lấy hàng, người gửi, số điện thoại và địa chỉ.");
    }
    if (!/^\+?[0-9 ()-]{8,20}$/.test(clean.contactPhone)) {
        throw new Error("Số điện thoại tại điểm lấy hàng không hợp lệ.");
    }
    return request<PickupLocation>("/pickup-locations", {
        method: "POST",
        body: JSON.stringify(clean),
    });
},
async getShipment(id: string): Promise<Shipment> {
    const trackingCode = id.trim();
    if (!trackingCode) {
        throw new Error("Vui lòng nhập mã vận đơn.");
    }
    return request<Shipment>(`/shipments/${encodeURIComponent(trackingCode)}`);
},
async list(): Promise<Shipment[]> {
    return request<Shipment[]>("/shipments");
},
async quote(input: ShipmentInput): Promise<Quote> {
    validate(input);
    return request<Quote>("/shipping-quotes", {
        method: "POST",
        body: JSON.stringify(input),
    });
},
async create(input: ShipmentInput, quoteId: string): Promise<Shipment> {
    validate(input);
    return request<Shipment>("/shipments", {
        method: "POST",
        body: JSON.stringify({ ...input, quoteId }),
    });
},
async transition(id: string, input: TransitionInput): Promise<Shipment> {
    return request<Shipment>(`/shipments/${encodeURIComponent(id)}/events`, {
        method: "POST",
        body: JSON.stringify(input),
    });
},
async listIncidents(shipmentId: string): Promise<Incident[]> {
    return request<Incident[]>(
        `/shipments/${encodeURIComponent(shipmentId)}/complaints`
    );
},
async createIncident(shipmentId: string, input: IncidentInput): Promise<Incident> {
    const content = input.content.trim();
    if (!Object.prototype.hasOwnProperty.call(INCIDENT_TYPES, input.type)) {
        throw new Error("Loại sự cố không hợp lệ.");
    }
    if (content.length < 10 || content.length > 2000) {
        throw new Error("Nội dung sự cố phải từ 10 đến 2.000 ký tự.");
    }
    return request<Incident>(
        `/shipments/${encodeURIComponent(shipmentId)}/complaints`,
        {
            method: "POST",
            body: JSON.stringify({
                type: input.type,
                content,
            }),
        }
    );
},
async listHubs(): Promise<Hub[]> {
    return request<Hub[]>("/hubs");
},
async recordHubAction(shipmentId: string, input: {
    hubId: string;
    action: HubAction;
    note: string;
}): Promise<Shipment> {
    if (!["receive", "dispatch"].includes(input.action)) {
        throw new Error("Thao tác kho không hợp lệ.");
    }
    return request<Shipment>(`/shipments/${encodeURIComponent(shipmentId)}/hub-events`, {
        method: "POST",
        body: JSON.stringify(input),
    });
},
async listAllIncidents(): Promise<Incident[]> {
  return request<Incident[]>("/complaints");
},

async updateIncident(
  incidentId: number,
  input: {
    status: "processing" | "resolved";
    response: string;
  }
): Promise<Incident> {

  const response = input.response.trim();

  if (
    input.status !== "processing" &&
    input.status !== "resolved"
  ) {
    throw new Error(
      "Trạng thái xử lý không hợp lệ."
    );
  }

  if (
    input.status === "resolved" &&
    !response
  ) {
    throw new Error(
      "Vui lòng nhập kết quả giải quyết."
    );
  }

  if (response.length > 2000) {
    throw new Error(
      "Kết quả giải quyết không được vượt quá 2.000 ký tự."
    );
  }

  return request<Incident>(
    `/complaints/${incidentId}`,
    {
      method: "PATCH",

      body: JSON.stringify({
        status: input.status,
        response,
      }),
    }
  );
},
async getShipmentReport(from: string, to: string): Promise<ShipmentReport> {
    if (from && to && from > to) {
        throw new Error("Ngày bắt đầu không được sau ngày kết thúc.");
    }
    const params = new URLSearchParams();
    if (from)
        params.set("from", from);
    if (to)
        params.set("to", to);
    const query = params.toString();
    return request<ShipmentReport>(`/reports/shipments${query ? `?${query}` : ""}`);
},
async getPricing(): Promise<PricingConfig> {
    return request<PricingConfig>("/pricing");
},
async savePricing(config: PricingConfig): Promise<PricingConfig> {
    validatePricing(config);
    return request<PricingConfig>("/pricing", {
        method: "PUT",
        body: JSON.stringify(config),
    });
},
async listEmployees(): Promise<DeliveryEmployee[]> {
    return request<DeliveryEmployee[]>("/employees/dispatch");
},
async assignShipment(shipmentId: string, input: AssignmentInput): Promise<Shipment> {
    return request<Shipment>(`/shipments/${encodeURIComponent(shipmentId)}/assignment`, {
        method: "PUT",
        body: JSON.stringify(input),
    });
},
async getSettlementData(): Promise<SettlementData> {
    return request<SettlementData>("/settlements");
},
async createSettlement(input: CreateSettlementInput): Promise<Settlement> {
    return request<Settlement>("/settlements", {
        method: "POST",
        body: JSON.stringify(input),
    });
},
async completeSettlement(settlementId: string, paymentReference: string): Promise<Settlement> {
    return request<Settlement>(`/settlements/${encodeURIComponent(settlementId)}/complete`, {
        method: "POST",
        body: JSON.stringify({ paymentReference }),
    });
},

async getSession(): Promise<SessionUser | null> {
  const saved = localStorage.getItem("express-user");
  if (!saved) return null;

  try {
    return checkedSession(JSON.parse(saved) as SessionUser);
  } catch {
    localStorage.removeItem("express-user");
    return null;
  }
},
async login(input: {email:string;password:string}): Promise<SessionUser> {
  const user = checkedSession(await request<SessionUser>('/auth/login',{
    method:'POST',
    body:JSON.stringify({...input,email:input.email.trim()})
  }));
  localStorage.setItem("express-user", JSON.stringify(user));
  return user;
},
async register(input: RegisterInput): Promise<RegisterResult> {
 return request<RegisterResult>('/auth/register',{method:'POST',body:JSON.stringify({fullName:input.fullName.trim(),shopName:input.shopName.trim(),phone:input.phone.trim(),email:input.email.trim(),password:input.password})});
},
async logout(): Promise<void> {
  try { await request<unknown>('/auth/logout',{method:'POST'}); }
  finally { localStorage.removeItem("express-user"); }
}

};
