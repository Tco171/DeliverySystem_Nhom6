# DeliverySystem — bản có mock và API thật

Giữ cấu trúc web/ (React), backend/ (đặt chỗ ASP.NET Core), mobile/ (đặt chỗ Flutter), docs/.

## Chạy

Trong web/: `npm ci`, copy `.env.example` thành `.env`, chạy `npm run dev`.

```dotenv
VITE_USE_MOCK=true
VITE_API_BASE_URL=https://localhost:7001
```

VITE_USE_MOCK=true: dùng dữ liệu thử nghiệm localStorage, không cần backend. Login/register vẫn nhập thông tin, không chọn role. Tài khoản mẫu:

| Email | Mật khẩu | Vai trò |
|---|---|---|
| shop@example.com | Express123! | Shop |
| staff@example.com | Express123! | Giao nhận |
| operations@example.com | Express123! | Điều hành |

Đăng ký tạo thêm shop thử nghiệm. Chỉ nhập dữ liệu và mật khẩu giả. Các shop mock dùng chung bộ đơn mẫu, chưa cách ly tenant. Hash mật khẩu demo chỉ giúp tránh lưu rõ, không phải bảo mật production. Không có thanh toán thật.

Khi backend sẵn sàng: đổi VITE_USE_MOCK=false, chỉnh URL đúng, khởi động lại Vite. Lỗi API thật không fallback sang mock. Bỏ biến mock cũng dùng API thật. Dữ liệu localStorage không tự chuyển vào DB.

src/api.ts chọn adapter; src/api.real.ts gọi HTTP và giữ 25 endpoint; src/api.mock.ts chứa mô phỏng riêng. Giao diện và kiểu dữ liệu được giữ. Backend/mobile vẫn cần nhóm cung cấp code. Đọc docs/MOCK_MODE.md và docs/AUTH_VA_TICH_HOP.md (các phần HTTP/auth).
