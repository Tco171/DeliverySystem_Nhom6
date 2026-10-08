# Web Public / Guest + Account update

Các thay đổi chính:

- Web mở được ở chế độ khách vãng lai, không còn bắt buộc đăng nhập trước khi vào App.
- Guest có thể xem Trang chủ, Bảng giá & Dịch vụ, Chính sách & FAQ, tra cứu vận đơn và mở form Tạo đơn nhanh.
- Login / Register được mở dạng modal từ bất kỳ trang public nào.
- Có giao diện Quên mật khẩu (backend OTP/forgot-password chưa có trong project backend hiện tại nên đang hiển thị trạng thái chờ endpoint).
- Customer/Staff/Operations vẫn giữ các trang và quyền cũ.
- Customer có trang Tài khoản: xem/sửa thông tin và đổi mật khẩu.
- Account API dùng:
  - GET `/api/v1/account/me`
  - PUT `/api/v1/account/me`
  - PUT `/api/v1/account/change-password`
- Guest không thấy điểm lấy hàng đã lưu; phần này chỉ hiện cho customer đăng nhập.
- Sau đổi mật khẩu thành công, web logout và yêu cầu đăng nhập lại.

## Backend cần có

Để các chức năng tài khoản chạy thật, backend cần các endpoint Account nêu trên và đọc `X-User-Id`.

Để guest tạo đơn thật không cần đăng nhập, backend `/shipping-quotes` và `/shipments` phải cho phép request không có `X-User-Id` (shipment guest có thể không gắn UserId). Nếu backend vẫn bắt user ID thì web sẽ báo lỗi từ API, dù giao diện guest đã sẵn sàng.

## Chạy

```powershell
cd D:\Express\DeliverySystem\web
npm install
npm run build
npm run dev
```

Backend hiện web đang trỏ tới port `5274` theo `.env`.
