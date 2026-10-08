# EXPRESS - Form + Order API

## 1. Luong du lieu

Web React / Flutter Mobile
-> POST /api/v1/shipping-quotes
-> nhan quoteId + fee
-> POST /api/v1/shipments
-> SQL Server luu Shipment + ShipmentEvent
-> Web va Mobile GET /api/v1/shipments dung chung du lieu.

## 2. API

### POST /api/v1/shipping-quotes
Request:
```json
{
  "senderName": "Nguyen Van A",
  "senderPhone": "0901234567",
  "pickupAddress": "Quan 1, TP.HCM",
  "recipientName": "Nguyen Van B",
  "recipientPhone": "0912345678",
  "deliveryAddress": "Thu Duc, TP.HCM",
  "goods": "Ao quan",
  "weightKg": 1,
  "lengthCm": 20,
  "widthCm": 15,
  "heightCm": 10,
  "declaredValue": 300000,
  "codAmount": 300000,
  "service": "standard",
  "feePayer": "deduct_cod",
  "notes": "Goi truoc khi giao"
}
```

Response:
```json
{
  "id": "Q-...",
  "fee": 25000,
  "expiresAt": "2026-10-05T03:00:00Z",
  "chargeableWeightKg": 1
}
```

### POST /api/v1/shipments
Gui lai cac truong cua form va them:
```json
{ "quoteId": "Q-..." }
```

Response la Shipment:
- id
- recipientName
- deliveryAddress
- fee
- status
- codAmount
- events
- ...

### GET /api/v1/shipments
Tra danh sach don cua tai khoan dang dang nhap.

### GET /api/v1/shipments/{shipmentId}
Tra chi tiet don.

### POST /api/v1/shipments/{shipmentId}/events
Doi trang thai don:
```json
{
  "status": "picked_up",
  "note": "Da lay hang"
}
```

### GET/POST /api/v1/pickup-locations
Quan ly diem lay hang da luu.

## 3. Gia cuoc hien tai

- Tieu chuan: 25.000d / kg dau tien
- Hoa toc: 40.000d / kg dau tien
- Vuot 1kg: +5.000d cho moi kg lam tron len
- Khoi luong quy doi = dai x rong x cao / 5000
- Khoi luong tinh phi = max(khoi luong thuc, khoi luong quy doi)

Day la muc gia dang dong bo voi PricingPage/demo hien tai; sau nay co the tach thanh bang Pricing trong database.

## 4. Database

Sau khi mo project backend:
```powershell
dotnet ef migrations add AddOrderSystem
dotnet ef database update
```

Neu database DeliverySystemDB da ton tai thi chi can chay hai lenh tren trong thu muc:
`backend/Back_DeliverySystem/Back_DeliverySystem`

## 5. Chay API cho Mobile

May tinh va dien thoai/emulator phai truy cap duoc IP LAN cua may tinh.

Vi du:
```powershell
dotnet run --urls "http://0.0.0.0:5174"
```

Flutter dang dung:
`http://192.168.10.2:5174`

Neu IP may tinh thay doi, sua `baseUrl` trong:
`mobile/lib/services/api_service.dart`

## 6. Lu y

Phien ban nay dung `X-User-Id` de dong bo don theo tai khoan voi he thong auth hien tai. Khi lam production nen thay bang JWT/cookie session that, khong cho client tu do gia mao User ID.
