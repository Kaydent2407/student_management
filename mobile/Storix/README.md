# STORIX v1.8 – Tổng quan theo mẫu Web của nhóm

Bản cập nhật phát triển tiếp từ **v1.5**. Chỉ thiết kế lại **trang Tổng quan** theo ảnh Web dashboard do nhóm cung cấp ngày 25/10/2026; không chỉnh sửa phần đăng nhập, đăng xuất, đăng ký hoặc logo.

## Logo mới STORIX

Logo chữ **S** xanh dương của nhóm đã được tích hợp vào giao diện đăng nhập, header/sidebar, icon Expo và favicon web. Xem `LOGO_STORIX_V1.5.md`.

## Chạy với Visual Studio Code (Windows)

Mở đúng thư mục `Storix` (nơi chứa file `package.json`). Trong PowerShell, dùng:

```powershell
npm.cmd install
npm.cmd run check
npx.cmd expo start -c
```

Nhấn **w** để xem giao diện web. Hoặc dùng **Expo Go** trên Android để quét mã QR. Muốn dùng Command Prompt (cmd) thì các lệnh tương đương là `npm install`, `npm run check`, `npx expo start -c`.

## Phạm vi giao diện

- Màn hình **đăng nhập API** và **chọn vai trò demo**: nền xanh mint (`#D1F8EF`), thẻ trắng ở giữa, biểu tượng kho xanh dương, nhãn và nội dung màu navy. Có nút hiện/ẩn mật khẩu API.
- **Riêng trang Tổng quan**: nền trắng/xám nhạt, menu trái, 4 thẻ KPI, biểu đồ 7 ngày, danh sách sức chứa, phiếu chờ và cảnh báo theo đúng bố cục ảnh dashboard; chữ xanh navy để dễ đọc trên nền trắng. Responsive trên Android.
- **Các trang nghiệp vụ khác**: giữ giao diện navy và chữ trắng của v1.5. Không đổi bố cục phần đăng nhập, đăng ký hay đăng xuất.
- Giữ phân biệt rõ **API thật** và **Demo offline**; chỉ các endpoint backend đã tồn tại mới thực hiện thao tác lên SQL Server.
- Giữ nguyên cấu hình **`https://storixapi.duckdns.org`** và logic JWT; chưa triển khai lên VPS.
- Bản demo hiện không có trang đăng ký độc lập; không tự tạo API đăng ký.

Chi tiết màu/kiến trúc xem `DESIGN_SYSTEM_V1.4.md`. Các file gốc của backend trong `Backend_Reference` là tư liệu đối chiếu, không phải ứng dụng VPS đã được triển khai.

## Xuất bản web khi đã xác nhận chạy đúng

```powershell
npx.cmd expo export --platform web
```

Thư mục xuất là `dist`. Việc sửa code trong VS Code không tự động triển khai lên VPS; tránh ghi đè cấu hình Nginx và backend đang dùng.

## Chưa xác nhận

Dù có kiểm thử logic và cú pháp JSX, cần chạy kiểm tra thị giác trong Chrome/Expo Go trên máy của bạn; kết nối API thật phụ thuộc máy chủ, tài khoản và phân quyền.

## Dashboard v1.6

Chi tiết nguồn số liệu, cách chuyển trang, điểm chưa có API và những điểm khác biệt so với ảnh mẫu xem `DASHBOARD_STORIX_V1.6.md`.

## Đồng bộ giao diện Figma (UI-only)

Bản cập nhật giao diện dựa trên bản thiết kế Figma hiện có của nhóm, xem `FIGMA_UI_SYNC_V1.7.md`. Chỉ thay phần giao diện các màn hình hiện hữu và navigation, không thêm hoặc sửa chức năng, không thay đổi đăng nhập, dữ liệu nghiệp vụ, API và cấu hình VPS. UI đang dùng nền sáng, chữ navy theo Figma để bảo đảm tương phản; nút màu xanh dùng chữ trắng.

## Trang Lấy lại mật khẩu (v1.8 – chỉ giao diện)

- Mở từ liên kết **Quên mật khẩu? Liên hệ quản trị viên** ở cuối thẻ đăng nhập API.
- Nhập tên đăng nhập/email, nhấn **Xem hướng dẫn khôi phục** để xem quy trình liên hệ quản trị viên, hoặc nhấn **Quay lại đăng nhập**.
- **Không có API reset-password** trong backend tham chiếu (`AuthController.cs` chỉ có login, me, change-password). Do đó màn hình **không gửi email, không tạo OTP, không đổi mật khẩu, không xác nhận đã gửi yêu cầu**.
- Trang đăng nhập giữ nguyên bố cục, màu và nội dung; chỉ liên kết quên mật khẩu được kích hoạt. Các nghiệp vụ, JWT, API và VPS không thay đổi.

