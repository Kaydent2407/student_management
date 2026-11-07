# STORIX Android v1.1 — Đối chiếu Jira CNPM

Nguồn tham chiếu: https://trantran14082006.atlassian.net/jira/software/projects/CNPM/boards/3/backlog

Ngày đối chiếu: 20/10/2026. Các mục được xem từ Jira của nhóm, ưu tiên subtask có nhãn `[App]` và Story phụ huynh. **Đây là bản demo học tập chạy Expo, chưa tích hợp Backend/Database; không đánh dấu Jira là hoàn tất.**

## Trạng thái triển khai trong bản demo

| Mục Jira | Chức năng | Trạng thái demo / phạm vi |
|---|---|---|
| CNPM-127 | Màn hình đăng nhập App | Có màn hình chọn tài khoản demo, đăng nhập/đăng xuất; chưa xác thực mật khẩu/API |
| CNPM-149, CNPM-456, CNPM-459 | Hồ sơ và vai trò | Xem tên tài khoản, vai trò; chưa đổi mật khẩu |
| CNPM-154, 158, 162 | Dashboard | Có thống kê tồn, nơi lưu trữ, phiếu chờ, hiển thị theo vai trò ở mức giao diện |
| CNPM-461, 463 | Menu và phạm vi theo quyền | Có ẩn thao tác theo vai trò và lọc nơi cửa hàng; chưa bảo mật theo API |
| CNPM-182, 471, 472, 477, 480 | Sản phẩm | Tìm kiếm, hiển thị danh mục, đơn vị, giá, mức tồn, trạng thái |
| CNPM-187 | Quét Barcode / QR | Camera qua Expo Camera và nhập mã thủ công; tra SKU, barcode, mã lô, mã kho |
| CNPM-213, 217, 485, 487, 489, 493, 494 | Kho/bãi/cửa hàng/vị trí | Xem chi tiết, sức chứa tham khảo, hàng theo ô mặc định; khóa/mở vị trí |
| CNPM-229, 233, 237, 502, 505 | Lô và nhà cung cấp | Xem danh sách NCC/lô, NSX/HSD, nguồn gốc theo mẫu; chưa trừ tồn theo lô |
| CNPM-252, 256, 261, 265 | Nhận/nhập hàng | Phiếu nhập cơ bản, chọn ô, duyệt/hoàn thành; chưa có phân loại số nhận thiếu/thừa/hỏng và ảnh |
| CNPM-286, 302, 306, 310, 532, 535 | Xuất và điều chuyển | Có phiếu, duyệt, giao và nhận bằng thay đổi trạng thái demo; chưa phân quyền bước riêng theo bộ phận |
| CNPM-319 | Yêu cầu bổ sung | Cửa hàng tạo yêu cầu, quản lý duyệt tạo phiếu điều chuyển |
| CNPM-327, 331, 339, 348, 352 | Tồn, lọc, thẻ kho, kiểm kê | Tồn theo nơi, biến động, kiểm kê nhập số thực tế; chưa chụp quét mã ngay trong màn hình kiểm kê và chưa duyệt điều chỉnh riêng |
| CNPM-392, 569, 574 | Báo cáo | Tổng hợp tồn, xuất CSV; chưa xuất PDF/Excel định dạng chuẩn |
| CNPM-414, 418, 529 | Thông báo, cảnh báo | Sinh cảnh báo tồn thấp/hạn dùng/sức chứa và đánh dấu đã đọc cục bộ |
| CNPM-582, 590, 593 | Component, điều hướng, giao diện App | Có component dùng chung, thanh tab trên điện thoại, sidebar trên trình duyệt lớn |

## Cần Backend/Database hoặc công việc tiếp theo

1. Xác thực tài khoản thực, quản lý vai trò/phạm vi, bảo vệ API và lưu session an toàn.
2. Quản lý tồn kho theo sản phẩm - lô - vị trí, hỗ trợ nhiều ô cho cùng sản phẩm, FIFO/FEFO, giữ hàng và chặn lô hỏng/hết hạn khi xuất.
3. Quy trình phiếu chi tiết: gửi duyệt, từ chối, giao hàng, nhận chênh lệch, hàng hỏng, số thực nhận, lưu bằng chứng và duyệt điều chỉnh kiểm kê.
4. Đồng bộ dữ liệu nhiều người dùng, thông báo đẩy, lưu nhật ký, import Excel, xuất PDF/Excel, cấu hình hệ thống.
5. Đối chiếu Figma từ CNPM-432/437/447/450, kiểm thử Android thực tế, nhiều kích thước màn hình.

## Dữ liệu, quyền và giới hạn

- Mọi số liệu hiện tại nằm trên thiết bị với AsyncStorage; không gửi dữ liệu lên server.
- Màn hình đăng nhập chỉ để chọn vai trò **không có bảo mật**. Các quyền hiện có chỉ giới hạn giao diện, không thể thay thế xác thực/phân quyền Backend.
- Các lô hàng và nhà cung cấp minh họa không phải dữ liệu nhập thực và chưa có lượng tồn theo lô. Mỗi sản phẩm tại mỗi nơi được gán tối đa một ô trong bản demo.
- Chỉ số sức chứa tính theo số **đơn vị sản phẩm** cộng lại, chưa quy đổi kg/m³/pallet nên chỉ tham khảo.
- Camera chạy tốt nhất trên điện thoại dùng Expo Go; trên trình duyệt cần quyền truy cập camera/localhost.
- Xuất báo cáo dưới dạng CSV; trên điện thoại dùng bảng chia sẻ hệ thống, trên trình duyệt tải tệp CSV.
