# Auth và tích hợp — 02/10/2026

## Thay đổi

Tất cả api.ts gọi HTTP; bỏ seed/localStorage và chọn role. Giữ 24 thao tác cũ, thêm register (25 thao tác). HTTP helper ở src/lib/http.ts xử lý lỗi mạng, JSON message/ProblemDetails, 204, 401 phiên hết hạn. Login email/password; đăng ký fullName, shopName, phone, email, password và xác nhận mật khẩu ở UI. Đăng ký thành công quay về login giữ email, không tự tạo session. Backend xác định role shop/staff/operations; public register chỉ tạo shop, không nhận role. Staff/operations dùng tài khoản được cấp.

Menu shop đã có đối soát; chỉ shop tải điểm lấy hàng. Màn hình nghiệp vụ giữ lại, nút mô phỏng trạng thái bị bỏ.

## API mới: POST /api/v1/auth/register

```json
{
  "fullName": "Nguyễn An",
  "shopName": "Cửa hàng An",
  "phone": "0900000001",
  "email": "an@example.com",
  "password": "mat-khau-vi-du"
}
```

Response 201 (hoặc 200): `{ "message": "Đăng ký thành công" }`. Không đăng nhập tự động. 400 dữ liệu sai; 409 email trùng. Error có message hoặc ProblemDetails/errors. UI giới hạn họ tên 100, shop 150, email 254, phone 20, password 8–128 ký tự. Chính sách mật khẩu cần nhóm thống nhất. Server validation, hash password, chuẩn hóa email/phone, tạo user+shop trong transaction, không cho client tự nâng role. confirmPassword không gửi server.

## Auth hiện có

- GET /api/v1/auth/session: SessionUser hoặc null; client cũng hiểu 401 là signed out.
- POST /api/v1/auth/login: `{email,password}` → `{id,name,role}` và cookie phiên.
- POST /api/v1/auth/logout: hủy session; JSON hoặc 204.

credentials:include được giữ, chưa có bearer token. Cookie, CORS origin chính xác, HTTPS và CSRF phải thống nhất với backend trước triển khai. Client chưa gửi CSRF token; bổ sung bước cấp token/header khi backend chốt, không tắt bảo vệ. Tên cookie trong OpenAPI là đề xuất.

VITE_API_BASE_URL ví dụ https://localhost:7001; thay đúng server và restart Vite. Bỏ trống gọi /api/v1 cùng origin, cần reverse proxy. Không dùng VITE_USE_MOCK nữa, không đặt secret trong VITE_*.

## Giới hạn

Chưa có backend thật để kiểm thử tích hợp. Còn shop xác nhận hoàn, CRUD danh mục, đối soát đa shop, phân trang, tự phân công theo vùng, thanh toán thật và mobile. Bản này không tuyên bố hoàn thành toàn bộ đề tài. Khi đổi phân quyền hoặc CSRF, cả hai nhóm phải cập nhật đồng bộ.
