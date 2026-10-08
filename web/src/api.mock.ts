
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
    return_confirmed: "Shop đã nhận hàng hoàn"
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
    vehicleType: "motorbike" | "car";
    service: "standard" | "fast" | "express";
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
const STORAGE = "express-demo-shipments-v1";
const quotes = new Map<string, {
    input: string;
    fee: number;
    expiresAt: string;
}>();
export const money = (value: number) => new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND"
}).format(value);
export const nextStatuses: Record<Status, Status[]> = {
    pending_pickup: ["picked_up", "pickup_failed"],
    pickup_failed: ["pending_pickup"],
    picked_up: ["in_transit"],
    in_transit: ["at_hub", "out_for_delivery"],
    at_hub: ["in_transit", "out_for_delivery"],
    out_for_delivery: ["delivered", "delivery_failed"],
    delivery_failed: ["out_for_delivery", "returning"],
    delivered: [],
    returning: ["returned"],
    returned: ["return_confirmed"],
    return_confirmed: []
};
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
    if ([input.codAmount, input.declaredValue].some((n) => !Number.isSafeInteger(n) || n < 0)) {
        throw new Error("Giá trị hàng và COD phải là số nguyên không âm.");
    }
    if (!["motorbike", "car"].includes(input.vehicleType)) {
        throw new Error("Loại phương tiện không hợp lệ.");
    }
    if (!["standard", "fast", "express"].includes(input.service)) {
        throw new Error("Dịch vụ không hợp lệ.");
    }
    if (input.vehicleType === "car" && input.service === "express") {
        throw new Error("Ô tô hiện chưa hỗ trợ dịch vụ Hỏa tốc.");
    }
}
function seed(): Shipment[] {
    const now = new Date().toISOString();
    return [
        {
            id: "EXP-DEMO-001",
            senderName: "Mây Studio",
            senderPhone: "0901234567",
            pickupAddress: "12 Nguyễn Trãi, TP. Hồ Chí Minh",
            recipientName: "Nguyễn An",
            recipientPhone: "0912345678",
            deliveryAddress: "28 Lê Lợi, TP. Hồ Chí Minh",
            goods: "Áo thun",
            weightKg: 1,
            lengthCm: 25,
            widthCm: 20,
            heightCm: 10,
            declaredValue: 350000,
            codAmount: 350000,
            vehicleType: "motorbike",
            service: "standard",
            feePayer: "deduct_cod",
            notes: "Gọi trước khi giao",
            fee: 25000,
            status: "pending_pickup",
            attempts: 0,
            codCollected: 0,
            createdAt: now,
            events: [
                {
                    status: "pending_pickup",
                    at: now,
                    note: "Đơn hàng mẫu được tạo.",
                },
            ]
        },
    ];
}
function read(): Shipment[] {
    const saved = localStorage.getItem(STORAGE);
    if (saved)
        return JSON.parse(saved) as Shipment[];
    const initial = seed();
    localStorage.setItem(STORAGE, JSON.stringify(initial));
    return initial;
}
function save(shipments: Shipment[]) {
    localStorage.setItem(STORAGE, JSON.stringify(shipments));
}
export interface PickupLocation {
    id: string;
    name: string;
    contactName: string;
    contactPhone: string;
    address: string;
}
const PICKUP_STORAGE = "express-demo-pickup-locations-v1";
function readPickupLocations(): PickupLocation[] {
    const saved = localStorage.getItem(PICKUP_STORAGE);
    return saved ? (JSON.parse(saved) as PickupLocation[]) : [];
}
export const INCIDENT_TYPES = {
    damaged: "Hàng hóa hư hỏng",
    lost: "Thất lạc hàng hóa",
    incorrect_information: "Sai thông tin giao nhận",
    complaint: "Khiếu nại",
    other: "Vấn đề khác"
} as const;
export const INCIDENT_STATUSES = {
    open: "Đã tiếp nhận",
    investigating: "Đang xử lý",
    resolved: "Đã giải quyết"
} as const;
export type IncidentType = keyof typeof INCIDENT_TYPES;
export type IncidentStatus = keyof typeof INCIDENT_STATUSES;
export interface IncidentInput {
    type: IncidentType;
    description: string;
}
export interface Incident extends IncidentInput {
    id: string;
    shipmentId: string;
    status: IncidentStatus;
    createdAt: string;
    resolution: string | null;
}
const INCIDENT_STORAGE = "express-demo-incidents-v1";
function readIncidents(): Incident[] {
    const saved = localStorage.getItem(INCIDENT_STORAGE);
    return saved ? (JSON.parse(saved) as Incident[]) : [];
}
export interface Hub {
    id: string;
    name: string;
    address: string;
}
export type HubAction = "receive" | "dispatch";
const DEMO_HUBS: Hub[] = [
    {
        id: "hub-hcm",
        name: "Kho TP. Hồ Chí Minh",
        address: "TP. Hồ Chí Minh"
    },
    {
        id: "hub-danang",
        name: "Trung tâm trung chuyển Đà Nẵng",
        address: "Đà Nẵng"
    },
    {
        id: "hub-hanoi",
        name: "Kho Hà Nội",
        address: "Hà Nội"
    },
];
const legacyMockApi = {
    async listPickupLocations(): Promise<PickupLocation[]> {
        return readPickupLocations();
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
        const locations = readPickupLocations();
        if (locations.some((location) => location.name.toLocaleLowerCase("vi") ===
            clean.name.toLocaleLowerCase("vi"))) {
            throw new Error("Tên điểm lấy hàng đã tồn tại.");
        }
        const location: PickupLocation = {
            id: crypto.randomUUID(),
            ...clean,
        };
        localStorage.setItem(PICKUP_STORAGE, JSON.stringify([...locations, location]));
        return location;
    },
    async getShipment(id: string): Promise<Shipment> {
        const trackingCode = id.trim();
        if (!trackingCode) {
            throw new Error("Vui lòng nhập mã vận đơn.");
        }
        const shipment = read().find((item) => item.id.toUpperCase() === trackingCode.toUpperCase());
        if (!shipment) {
            throw new Error("Không tìm thấy vận đơn. Vui lòng kiểm tra lại mã.");
        }
        return shipment;
    },
    async list(): Promise<Shipment[]> {
        return read();
    },
    async quote(input: ShipmentInput): Promise<Quote> {
        validate(input);
        const baseFee = input.vehicleType === "motorbike"
            ? input.service === "standard" ? 20000 : input.service === "fast" ? 30000 : 40000
            : input.service === "standard" ? 50000 : 70000;
        const weightSurcharge = input.weightKg <= 5
            ? 0
            : input.weightKg <= 10
                ? 10000
                : 10000 + Math.ceil(input.weightKg - 10) * 2000;
        const fee = baseFee + weightSurcharge;
        if (input.feePayer === "deduct_cod" && input.codAmount < fee) {
            throw new Error("COD không đủ để khấu trừ phí vận chuyển.");
        }
        const quote = {
            id: crypto.randomUUID(),
            fee,
            expiresAt: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
        };
        quotes.set(quote.id, {
            input: JSON.stringify(input),
            fee,
            expiresAt: quote.expiresAt,
        });
        return quote;
    },
    async create(input: ShipmentInput, quoteId: string): Promise<Shipment> {
        validate(input);
        const quote = quotes.get(quoteId);
        if (!quote ||
            quote.input !== JSON.stringify(input) ||
            Date.parse(quote.expiresAt) <= Date.now()) {
            throw new Error("Báo giá hết hạn hoặc thông tin đã đổi. Hãy tính lại phí.");
        }
        const now = new Date().toISOString();
        const shipment: Shipment = {
            ...input,
            id: `EXP-${crypto.randomUUID().toUpperCase()}`,
            fee: quote.fee,
            status: "pending_pickup",
            attempts: 0,
            codCollected: 0,
            createdAt: now,
            events: [
                {
                    status: "pending_pickup",
                    at: now,
                    note: "Đã xác nhận yêu cầu giao hàng.",
                },
            ],
        };
        save([shipment, ...read()]);
        quotes.delete(quoteId);
        return shipment;
    },
    async transition(id: string, input: TransitionInput): Promise<Shipment> {
        const shipments = read();
        const shipment = shipments.find((item) => item.id === id);
        if (!shipment)
            throw new Error("Không tìm thấy đơn hàng.");
        if (!nextStatuses[shipment.status].includes(input.status)) {
            throw new Error("Chuyển trạng thái không hợp lệ.");
        }
        if (["pickup_failed", "delivery_failed", "returning"].includes(input.status) &&
            !input.note.trim()) {
            throw new Error("Vui lòng nhập lý do.");
        }
        if (input.status === "out_for_delivery" && shipment.attempts >= 3) {
            throw new Error("Demo giới hạn 3 lần giao. Vui lòng chuyển hoàn.");
        }
        if (input.status === "delivered" &&
            shipment.codAmount > 0 &&
            input.codCollected !== shipment.codAmount) {
            throw new Error("Cần xác nhận đã thu đủ tiền COD.");
        }
        shipment.status = input.status;
        if (input.status !== "at_hub") {
            shipment.currentHubId = null;
        }
        if (input.status === "out_for_delivery")
            shipment.attempts += 1;
        if (input.status === "delivered") {
            shipment.codCollected = shipment.codAmount;
        }
        shipment.events.push({
            status: input.status,
            at: new Date().toISOString(),
            note: input.note.trim(),
        });
        save(shipments);
        return shipment;
    },
    async listIncidents(shipmentId: string): Promise<Incident[]> {
        const shipmentExists = read().some((shipment) => shipment.id === shipmentId);
        if (!shipmentExists) {
            throw new Error("Không tìm thấy đơn hàng.");
        }
        return readIncidents().filter((incident) => incident.shipmentId === shipmentId);
    },
    async createIncident(shipmentId: string, input: IncidentInput): Promise<Incident> {
        const description = input.description.trim();
        if (!Object.prototype.hasOwnProperty.call(INCIDENT_TYPES, input.type)) {
            throw new Error("Loại sự cố không hợp lệ.");
        }
        // Proposed input limits; confirm these with the backend team.
        if (description.length < 10 || description.length > 2000) {
            throw new Error("Nội dung sự cố phải từ 10 đến 2.000 ký tự.");
        }
        const shipmentExists = read().some((shipment) => shipment.id === shipmentId);
        if (!shipmentExists) {
            throw new Error("Không tìm thấy đơn hàng.");
        }
        const incident: Incident = {
            id: crypto.randomUUID(),
            shipmentId,
            type: input.type,
            description,
            status: "open",
            createdAt: new Date().toISOString(),
            resolution: null,
        };
        localStorage.setItem(INCIDENT_STORAGE, JSON.stringify([incident, ...readIncidents()]));
        return incident;
    },
    async listHubs(): Promise<Hub[]> {
        return DEMO_HUBS.map((hub) => ({ ...hub }));
    },
    async recordHubAction(shipmentId: string, input: {
        hubId: string;
        action: HubAction;
        note: string;
    }): Promise<Shipment> {
        if (!["receive", "dispatch"].includes(input.action)) {
            throw new Error("Thao tác kho không hợp lệ.");
        }
        const hub = DEMO_HUBS.find((item) => item.id === input.hubId);
        if (!hub) {
            throw new Error("Không tìm thấy kho.");
        }
        const shipments = read();
        const shipment = shipments.find((item) => item.id === shipmentId);
        if (!shipment) {
            throw new Error("Không tìm thấy đơn hàng.");
        }
        if (input.action === "receive") {
            // Support older demo orders marked at_hub without a warehouse.
            const legacyHubRecord = shipment.status === "at_hub" && !shipment.currentHubId;
            if (!["picked_up", "in_transit"].includes(shipment.status) &&
                !legacyHubRecord) {
                throw new Error("Trạng thái hiện tại không cho phép nhập kho.");
            }
            shipment.status = "at_hub";
            shipment.currentHubId = hub.id;
        }
        else {
            if (shipment.status !== "at_hub" ||
                shipment.currentHubId !== hub.id) {
                throw new Error("Đơn hàng không có trong kho đã chọn.");
            }
            shipment.status = "in_transit";
            shipment.currentHubId = null;
        }
        const description = input.action === "receive"
            ? `Đã nhập kho: ${hub.name}.`
            : `Đã xuất kho: ${hub.name}.`;
        shipment.events.push({
            status: shipment.status,
            at: new Date().toISOString(),
            note: [description, input.note.trim()].filter(Boolean).join(" "),
        });
        save(shipments);
        return shipment;
    },
    async listAllIncidents(): Promise<Incident[]> {
        return readIncidents().sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
    },
    async updateIncident(incidentId: string, input: {
        status: "investigating" | "resolved";
        resolution: string;
    }): Promise<Incident> {
        const resolution = input.resolution.trim();
        if (input.status !== "investigating" &&
            input.status !== "resolved") {
            throw new Error("Trạng thái xử lý không hợp lệ.");
        }
        if (input.status === "resolved" && !resolution) {
            throw new Error("Vui lòng nhập kết quả giải quyết.");
        }
        if (resolution.length > 2000) {
            throw new Error("Kết quả giải quyết không được vượt quá 2.000 ký tự.");
        }
        const incidents = readIncidents();
        const incident = incidents.find((item) => item.id === incidentId);
        if (!incident) {
            throw new Error("Không tìm thấy báo cáo sự cố.");
        }
        const validTransition = (incident.status === "open" && input.status === "investigating") ||
            (incident.status === "investigating" && input.status === "resolved");
        if (!validTransition) {
            throw new Error("Trạng thái đã thay đổi hoặc thao tác không hợp lệ. Hãy tải lại danh sách.");
        }
        incident.status = input.status;
        incident.resolution =
            input.status === "resolved" ? resolution : null;
        localStorage.setItem(INCIDENT_STORAGE, JSON.stringify(incidents));
        return incident;
    },
    async getShipmentReport(from: string, to: string): Promise<ShipmentReport> {
        if (from && to && from > to) {
            throw new Error("Ngày bắt đầu không được sau ngày kết thúc.");
        }
        // Demo uses the browser's local time zone.
        // The real backend should use an agreed reporting time zone.
        const start = from ? new Date(`${from}T00:00:00`) : null;
        const endExclusive = to ? new Date(`${to}T00:00:00`) : null;
        if ((start && Number.isNaN(start.getTime())) ||
            (endExclusive && Number.isNaN(endExclusive.getTime()))) {
            throw new Error("Khoảng ngày không hợp lệ.");
        }
        if (endExclusive) {
            endExclusive.setDate(endExclusive.getDate() + 1);
        }
        const shipments = read().filter((shipment) => {
            const createdAt = Date.parse(shipment.createdAt);
            return ((!start || createdAt >= start.getTime()) &&
                (!endExclusive || createdAt < endExclusive.getTime()));
        });
        const countStatus = (...statuses: Status[]) => shipments.filter((shipment) => statuses.includes(shipment.status)).length;
        return {
            from,
            to,
            generatedAt: new Date().toISOString(),
            total: shipments.length,
            delivered: countStatus("delivered"),
            failed: countStatus("pickup_failed", "delivery_failed"),
            returning: countStatus("returning"),
            returned: countStatus("returned", "return_confirmed"),
            active: shipments.filter((shipment) => !["delivered", "return_confirmed"].includes(shipment.status)).length,
            codCollected: shipments.reduce((sum, shipment) => sum + shipment.codCollected, 0),
            deliveredShippingFees: shipments
                .filter((shipment) => shipment.status === "delivered")
                .reduce((sum, shipment) => sum + shipment.fee, 0),
            byStatus: (Object.keys(STATUS) as Status[]).map((status) => ({
                status,
                count: countStatus(status),
            })),
        };
    },
    async getPricing(): Promise<PricingConfig> {
        return readPricing();
    },
    async savePricing(config: PricingConfig): Promise<PricingConfig> {
        validatePricing(config);
        localStorage.setItem(PRICING_STORAGE, JSON.stringify(config));
        return readPricing();
    },
    async listEmployees(): Promise<DeliveryEmployee[]> {
        return DEMO_EMPLOYEES.map((employee) => ({ ...employee }));
    },
    async assignShipment(shipmentId: string, input: AssignmentInput): Promise<Shipment> {
        const shipments = read();
        const shipment = shipments.find((item) => item.id === shipmentId);
        const employee = DEMO_EMPLOYEES.find((item) => item.id === input.staffId);
        if (!shipment || !employee) {
            throw new Error("Không tìm thấy đơn hàng hoặc nhân viên.");
        }
        if (employee.area !== input.area ||
            employee.shift !== input.shift) {
            throw new Error("Nhân viên không phụ trách khu vực/ca đã chọn.");
        }
        const allowed: Record<AssignmentKind, Status[]> = {
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
        if (!Object.prototype.hasOwnProperty.call(allowed, input.kind) ||
            !allowed[input.kind].includes(shipment.status)) {
            throw new Error("Đơn hàng không phù hợp với công việc đã chọn.");
        }
        const startingDelivery = input.kind === "delivery" &&
            shipment.status !== "out_for_delivery";
        if (startingDelivery && shipment.attempts >= 3) {
            throw new Error("Đơn đã đạt giới hạn demo 3 lần giao. Hãy xử lý hoàn.");
        }
        const load = employeeLoad(shipments, employee.id, input.shift, shipment.id);
        if (load >= employee.capacity) {
            throw new Error("Nhân viên đã đủ tải trong ca này. Hãy chọn người khác.");
        }
        const nextStatus: Record<AssignmentKind, Status> = {
            pickup: "pending_pickup",
            delivery: "out_for_delivery",
            return: "returning",
        };
        shipment.status = nextStatus[input.kind];
        shipment.assignedStaffId = employee.id;
        shipment.assignmentKind = input.kind;
        shipment.assignmentArea = input.area;
        shipment.assignmentDate = localDateKey();
        shipment.assignmentShift = input.shift;
        if (startingDelivery)
            shipment.attempts += 1;
        shipment.currentHubId = null;
        const taskLabel = {
            pickup: "lấy hàng",
            delivery: "giao hàng",
            return: "hoàn hàng",
        }[input.kind];
        shipment.events.push({
            status: shipment.status,
            at: new Date().toISOString(),
            note: `Phân công ${employee.name} thực hiện ${taskLabel}. ` +
                `Khu vực: ${input.area}. ` +
                `Ca: ${input.shift === "morning" ? "sáng" : "chiều"}.`,
        });
        save(shipments);
        return shipment;
    },
    async getSettlementData(): Promise<SettlementData> {
        const settlements = readSettlements();
        return {
            eligibleShipments: eligibleForSettlement(read(), settlements),
            settlements,
        };
    },
    async createSettlement(input: CreateSettlementInput): Promise<Settlement> {
        requireDemoOperations();
        if (input.shipmentIds.length === 0 ||
            new Set(input.shipmentIds).size !== input.shipmentIds.length) {
            throw new Error("Danh sách đơn phải có ít nhất một đơn và không trùng.");
        }
        if (!Number.isSafeInteger(input.adjustment)) {
            throw new Error("Khoản điều chỉnh phải là số nguyên.");
        }
        const reason = input.adjustmentReason.trim();
        if (input.adjustment !== 0 && !reason) {
            throw new Error("Vui lòng nhập lý do điều chỉnh.");
        }
        if (reason.length > 1000) {
            throw new Error("Lý do điều chỉnh tối đa 1.000 ký tự.");
        }
        const settlements = readSettlements();
        const eligible = eligibleForSettlement(read(), settlements);
        const lines: SettlementLine[] = input.shipmentIds.map((id) => {
            const shipment = eligible.find((item) => item.id === id);
            if (!shipment) {
                throw new Error("Có đơn không còn đủ điều kiện hoặc đã thuộc kỳ khác. Hãy tải lại.");
            }
            return {
                shipmentId: shipment.id,
                codCollected: shipment.codCollected,
                shippingDeduction: shipment.feePayer === "deduct_cod" ? shipment.fee : 0,
            };
        });
        const totalCod = lines.reduce((sum, line) => sum + line.codCollected, 0);
        const shippingDeduction = lines.reduce((sum, line) => sum + line.shippingDeduction, 0);
        const netAmount = totalCod - shippingDeduction + input.adjustment;
        if (![totalCod, shippingDeduction, netAmount].every(Number.isSafeInteger) ||
            netAmount < 0) {
            throw new Error("Số tiền không hợp lệ. Bản demo chưa hỗ trợ kỳ có số dư âm.");
        }
        const settlement: Settlement = {
            id: `SET-${crypto.randomUUID().toUpperCase()}`,
            createdAt: new Date().toISOString(),
            lines,
            totalCod,
            shippingDeduction,
            adjustment: input.adjustment,
            adjustmentReason: reason,
            netAmount,
            status: "pending",
            completedAt: null,
            paymentReference: null,
        };
        localStorage.setItem(SETTLEMENT_STORAGE, JSON.stringify([settlement, ...settlements]));
        return settlement;
    },
    async completeSettlement(settlementId: string, paymentReference: string): Promise<Settlement> {
        requireDemoOperations();
        const settlements = readSettlements();
        const settlement = settlements.find((item) => item.id === settlementId);
        if (!settlement || settlement.status !== "pending") {
            throw new Error("Kỳ không tồn tại hoặc đã hoàn tất.");
        }
        const reference = paymentReference.trim();
        if (settlement.netAmount > 0 && !reference) {
            throw new Error("Vui lòng nhập mã tham chiếu thanh toán.");
        }
        if (reference.length > 200) {
            throw new Error("Mã tham chiếu tối đa 200 ký tự.");
        }
        settlement.status = "completed";
        settlement.completedAt = new Date().toISOString();
        settlement.paymentReference =
            settlement.netAmount > 0 ? reference : null;
        localStorage.setItem(SETTLEMENT_STORAGE, JSON.stringify(settlements));
        return settlement;
    }
};
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
const PRICING_STORAGE = "express-demo-pricing-v1";
const DEFAULT_PRICING: PricingConfig = {
    includedWeightKg: 1,
    volumetricDivisor: 5000,
    standard: {
        baseFee: 25000,
        extraKgFee: 5000,
    },
    express: {
        baseFee: 40000,
        extraKgFee: 5000,
    }
};
function readPricing(): PricingConfig {
    const saved = localStorage.getItem(PRICING_STORAGE);
    return saved
        ? (JSON.parse(saved) as PricingConfig)
        : {
            ...DEFAULT_PRICING,
            standard: { ...DEFAULT_PRICING.standard },
            express: { ...DEFAULT_PRICING.express }
        };
}
function validatePricing(config: PricingConfig) {
    if (!Number.isFinite(config.includedWeightKg) ||
        config.includedWeightKg <= 0 ||
        !Number.isFinite(config.volumetricDivisor) ||
        config.volumetricDivisor <= 0) {
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
export interface SessionUser {
    id: string;
    name: string;
    role: UserRole;
}
const DEMO_SESSION_STORAGE = "express-demo-session-v1";

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
const DEMO_EMPLOYEES: DeliveryEmployee[] = [
    {
        id: "demo-staff",
        name: "Nhân viên giao nhận demo",
        area: "TP. Hồ Chí Minh",
        shift: "morning",
        capacity: 5
    },
    {
        id: "demo-staff-2",
        name: "Trần Bình",
        area: "TP. Hồ Chí Minh",
        shift: "afternoon",
        capacity: 5
    },
    {
        id: "demo-staff-3",
        name: "Lê An",
        area: "Hà Nội",
        shift: "morning",
        capacity: 5
    },
];
export function localDateKey(): string {
    const date = new Date();
    return [
        date.getFullYear(),
        String(date.getMonth() + 1).padStart(2, "0"),
        String(date.getDate()).padStart(2, "0"),
    ].join("-");
}
export function hasActiveAssignment(shipment: Shipment): boolean {
    return ((shipment.assignmentKind === "pickup" &&
        shipment.status === "pending_pickup") ||
        (shipment.assignmentKind === "delivery" &&
            shipment.status === "out_for_delivery") ||
        (shipment.assignmentKind === "return" &&
            shipment.status === "returning"));
}
export function employeeLoad(shipments: Shipment[], staffId: string, shift: Shift, excludeShipmentId?: string): number {
    return shipments.filter((shipment) => shipment.id !== excludeShipmentId &&
        shipment.assignedStaffId === staffId &&
        shipment.assignmentDate === localDateKey() &&
        shipment.assignmentShift === shift &&
        hasActiveAssignment(shipment)).length;
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
const SETTLEMENT_STORAGE = "express-demo-settlements-v1";
function readSettlements(): Settlement[] {
    const saved = localStorage.getItem(SETTLEMENT_STORAGE);
    return saved ? (JSON.parse(saved) as Settlement[]) : [];
}
function requireDemoOperations() {
    if (localStorage.getItem(DEMO_SESSION_STORAGE) !== "operations") {
        throw new Error("Thao tác này dành cho nhân viên điều hành.");
    }
}
function eligibleForSettlement(shipments: Shipment[], settlements: Settlement[]): Shipment[] {
    // Pending batches also reserve their orders, preventing reuse.
    const includedIds = new Set(settlements.flatMap((settlement) => settlement.lines.map((line) => line.shipmentId)));
    return shipments.filter((shipment) => shipment.status === "delivered" &&
        shipment.codAmount > 0 &&
        shipment.codCollected === shipment.codAmount &&
        !includedIds.has(shipment.id));
}

import type { RegisterInput, RegisterResult } from './api.real';

interface MockAccount extends SessionUser { email: string; passwordHash: string; }
const ACCOUNT_KEY = 'express-test-accounts-v1';
const SESSION_KEY = 'express-test-user-v1';

async function demoHash(password: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(password));
  return Array.from(new Uint8Array(digest), n => n.toString(16).padStart(2, '0')).join('');
}
async function accounts(): Promise<MockAccount[]> {
  const passwordHash = await demoHash('Express123!');
  const seeded: MockAccount[] = [
    { id: 'demo-customer', name: 'Khách hàng thử nghiệm', role: 'customer', email: 'customer@example.com', passwordHash },
    { id: 'demo-staff', name: 'Nhân viên giao nhận demo', role: 'staff', email: 'staff@example.com', passwordHash },
    { id: 'demo-operations', name: 'Điều hành thử nghiệm', role: 'operations', email: 'operations@example.com', passwordHash },
  ];
  return [...seeded, ...JSON.parse(localStorage.getItem(ACCOUNT_KEY) ?? '[]') as MockAccount[]];
}

export const mockApi = {
  ...legacyMockApi,
  async getSession(): Promise<SessionUser | null> {
    const id = localStorage.getItem(SESSION_KEY);
    const account = (await accounts()).find(a => a.id === id);
    if (!account) return null;
    localStorage.setItem(DEMO_SESSION_STORAGE, account.role);
    return { id: account.id, name: account.name, role: account.role };
  },
  async login(input: { email: string; password: string }): Promise<SessionUser> {
    const account = (await accounts()).find(a => a.email === input.email.trim().toLowerCase());
    if (!account || account.passwordHash !== await demoHash(input.password)) throw new Error('Email hoặc mật khẩu không đúng.');
    localStorage.setItem(SESSION_KEY, account.id);
    localStorage.setItem(DEMO_SESSION_STORAGE, account.role);
    return { id: account.id, name: account.name, role: account.role };
  },
  async register(input: RegisterInput): Promise<RegisterResult> {
    if (!input.fullName.trim() || !input.shopName.trim() || !/^\+?[0-9 ()-]{8,20}$/.test(input.phone.trim()) || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email.trim()) || input.password.length < 8 || input.password.length > 128) throw new Error('Thông tin đăng ký không hợp lệ.');
    const email = input.email.trim().toLowerCase();
    if ((await accounts()).some(a => a.email === email)) throw new Error('Email đã được đăng ký.');
    const account: MockAccount = { id: crypto.randomUUID(), name: input.fullName.trim(), role: 'customer', email, passwordHash: await demoHash(input.password) };
    const saved = JSON.parse(localStorage.getItem(ACCOUNT_KEY) ?? '[]') as MockAccount[];
    localStorage.setItem(ACCOUNT_KEY, JSON.stringify([...saved, account]));
    return { message: 'Đăng ký thử nghiệm thành công.' };
  },
  async logout(): Promise<void> {
    localStorage.removeItem(SESSION_KEY);
    localStorage.removeItem(DEMO_SESSION_STORAGE);
  },
};
