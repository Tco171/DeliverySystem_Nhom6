# Cập nhật chế độ mock

Tài liệu này thay thế các nhận định “đã bỏ mock/localStorage” trong bản bàn giao trước. Mock được khôi phục cho phát triển, tách src/api.mock.ts khỏi src/api.real.ts. Các endpoint HTTP và register không thay đổi. src/api.ts chọn adapter bằng VITE_USE_MOCK === 'true'; false hoặc không cấu hình chọn real, không fallback khi server lỗi.

Màn hình login/register dùng chung; mock login kiểm tra tài khoản mẫu hoặc shop đã đăng ký, role cố định theo tài khoản. Không có đăng ký admin/staff công khai. Mật khẩu mẫu Express123! cho shop@example.com, staff@example.com, operations@example.com. Mock session và dữ liệu nằm trong localStorage; đăng xuất chỉ xóa session. Đăng ký lưu bản hash SHA-256 cho mật khẩu thử nghiệm, không phải giải pháp lưu mật khẩu thật. Mọi tài khoản mock vẫn chia sẻ dữ liệu một shop demo; không dùng để kiểm thử bảo mật đa tenant.

Backend vẫn phải hash mật khẩu đúng chuẩn, xác thực, phân quyền, CORS/CSRF và kiểm tra nghiệp vụ. Chuyển false không migrate dữ liệu demo. Khởi động lại Vite sau thay đổi env. Không gửi mật khẩu thật vào mock.
