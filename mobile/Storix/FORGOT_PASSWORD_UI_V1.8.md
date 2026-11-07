# STORIX v1.8 — Lấy lại mật khẩu (UI-only)

**Phạm vi:** bổ sung màn hình khôi phục mật khẩu và điều hướng từ thẻ đăng nhập API. Không thay đổi các chức năng nghiệp vụ và API.

## Cách sử dụng
1. Mở ứng dụng, ở màn hình đăng nhập API nhấn **Quên mật khẩu? Liên hệ quản trị viên**.
2. Nhập tên đăng nhập hoặc email để chuẩn bị thông tin cần hỗ trợ.
3. Nhấn **Xem hướng dẫn khôi phục** để biết các bước liên hệ quản trị viên.
4. Nhấn **Quay lại đăng nhập** để trở về trang đăng nhập cũ.

## Giới hạn backend
`Backend_Reference/Controllers/AuthController.cs` mới khai báo các tuyến `POST /api/auth/login`, `GET /api/auth/me` và `POST /api/auth/change-password`. Không có endpoint khôi phục/OTP không cần đăng nhập. Vì vậy nút **không gửi bất kỳ dữ liệu nào** và không được coi là khôi phục tài khoản thành công. Cần backend hỗ trợ thêm để dùng tính năng tự phục vụ sau này.

## Cấu trúc code
- `src/ForgotPasswordScreen.js`: màn hình mới.
- `src/BrandAuth.js`: thêm props tùy chọn `title`, `showHelp`, `onForgotPassword`; defaults giữ giao diện đăng nhập hiện có.
- `src/ApiWorkspace.js`: chuyển giữa trang đăng nhập và lấy lại mật khẩu, không làm thay đổi lệnh gọi API.
