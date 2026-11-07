# STORIX v1.3 · Figma đồng bộ & chữ trắng

## Nguồn thiết kế
- Figma: https://www.figma.com/design/kJTpeIKVA2oKxLva3sjNBJ/cnpm-nc?node-id=0-1
- Tham khảo các frame **45:2 Tổng quan**, **45:640 Sản phẩm**, **71:3359 Nơi lưu trữ**.
- Figma gốc dùng màu nền xanh mint #D1F8EF và nội dung trên nền sáng. Theo yêu cầu **tất cả font ở khu vực sau đăng nhập màu trắng**, giao diện vận hành được chuyển sang **dark adaptation** (xanh navy) giữ hệ thống nhóm menu, khoảng đệm, hình dáng thẻ và xanh dương chủ đạo #3674B5. Đây không phải bản sao pixel-by-pixel của các frame web rộng 1280px.

## Phạm vi thay đổi
- `src/ui.js`: giao diện sáng C cho xác thực, giao diện tối D cho nghiệp vụ. `UiThemeProvider(mode="dark")` buộc chữ trong mọi `Txt` luôn là #FFFFFF. Ô tìm kiếm, form, ô lựa chọn, modal cũng dùng chữ trắng.
- `src/ApiWorkspace.js`: áp dụng theme dark sau đăng nhập, sidebar nhóm menu và breadcrumb; màn hình đăng nhập API giữ nguyên theme sáng.
- `App.js`: chế độ Demo offline áp dụng dark theme sau đăng nhập; màn hình chọn tài khoản demo giữ nguyên theme sáng.
- Không chỉnh sửa logic JWT, endpoint API, database hoặc triển khai VPS.

## Kiểm thử
- `npm.cmd install`
- `npm.cmd run check`
- `npx.cmd expo start` rồi nhấn `w` để xem web (hoặc chạy Expo Go trên Android).
- Đối chiếu màn hình Tổng quan, Sản phẩm, Kho/bãi, Phiếu kho, Tiện ích ở Demo; và Dashboard, Sản phẩm, Kho/bãi, Phiếu nhập, Quét mã, Tài khoản ở chế độ API.
- API đã cấu hình: `https://storixapi.duckdns.org`, chỉ xác nhận API thực bằng tài khoản hợp lệ.

## Lưu ý
- Màn hình đăng nhập, đăng ký, đăng xuất được miễn yêu cầu đổi màu chữ; hệ thống hiện chưa có trang đăng ký riêng hoặc trang xác nhận đăng xuất riêng.
- Các biểu tượng sử dụng MaterialCommunityIcons có sẵn của dự án; chưa tái tạo toàn bộ hình minh họa và thành phần Figma.
- Chưa kiểm thử render trực tiếp trên trình duyệt/thiết bị trong môi trường đóng gói; cần kiểm tra trực quan bằng Expo.
