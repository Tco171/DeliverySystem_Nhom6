# Kiểm tra bản chuyển đổi

- PASS: `npm run build` (TypeScript + Vite production build).
- PASS: 25 phương thức API; login gửi email/password và cookie credentials; register trim dữ liệu, không gửi role/confirmPassword; lỗi 409, ProblemDetails, session 401, sự kiện hết phiên, logout 204, role không hợp lệ, lỗi mạng. Các response trong kiểm tra này được giả lập riêng trong test, không tồn tại mock ở ứng dụng.
- PASS: mở trang login trong trình duyệt và chuyển sang register; đủ các trường nhập và không còn bộ chọn role.
- Chưa kiểm thử tạo tài khoản/đăng nhập thành công với ASP.NET Core thật vì backend chưa được cung cấp.
- Local dependency cache không cài offline được trong môi trường kiểm tra; build sử dụng bản sao dependencies đã cài của project cũ. Gói ZIP không chứa node_modules. Người nhận dùng npm ci theo package-lock.json.
