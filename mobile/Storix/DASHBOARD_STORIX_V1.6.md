# STORIX v1.6 – Thiết kế lại trang Tổng quan

## Theo ảnh dashboard do nhóm gửi

- Sidebar nền trắng với logo STORIX và phân nhóm Tổng quan, Danh mục, Nghiệp vụ, Kiểm soát, Hệ thống.
- Header: breadcrumb **Trang chủ / Tổng quan**, nút làm mới, tên người dùng.
- 4 thẻ KPI: Tổng sản phẩm, Phiếu cần xử lý, Sản phẩm tồn thấp, Phiếu đang điều chuyển.
- Hai cột: biểu đồ phiếu nhập/xuất 7 ngày và tình hình sức chứa 3 nơi.
- Hai cột phía dưới: bảng phiếu cần xử lý và bảng cảnh báo.
- Trên màn hình hẹp, các thẻ chia 2 cột và các panel xếp dọc.

## Giữ nguyên trang đăng nhập

`src/BrandAuth.js`, `src/StorixLogo.js`, `assets/brand/*`, luồng đăng nhập JWT và URL API được giữ nguyên từ v1.5. Không bổ sung UI đăng ký hay thay đổi giao diện xác thực. Các trang nghiệp vụ khác vẫn sử dụng navy đậm/chữ trắng.

## API thật và demo

- Demo lấy dữ liệu từ AsyncStorage: sản phẩm, phiếu nhập/xuất/chuyển, sức chứa tham khảo và cảnh báo. Mọi nút đang có tính năng đều điều hướng đến đúng màn hình nghiệp vụ.
- API thật chỉ lấy `GET /api/products`, `GET /api/warehouses` và `GET /api/inbound-receipts` theo JWT/phân quyền hiện tại.
- Backend chưa hỗ trợ Dashboard thống kê tổng hợp, xuất kho, chuyển kho, hàng tồn thấp và cảnh báo; hiển thị **—** hoặc **Chưa có API**, tuyệt đối không bịa số.
- Biểu đồ API chỉ tổng hợp phiếu nhập trả về ở trang đã tải. Thời gian biểu đồ nhóm theo **ngày tạo** thay vì ngày hoàn thành, vì API hiện chưa cấp trường ngày hoàn thành.
- Số phiếu chờ trên API chỉ tính các phiếu **trong trang vừa tải** chứ không phải tổng toàn hệ thống.
- Sức chứa API có thể có `capacity` nhưng không có `used`, do đó thanh tiến độ không tự vẽ tỷ lệ.

## Những file được chỉnh

- `App.js`: thay trang Tổng quan demo bằng component mới, thêm menu tổng quan, không đụng màn đăng nhập.
- `src/ApiWorkspace.js`: thay Tổng quan API, thêm điều hướng/sidebar tổng quan, không đụng màn đăng nhập.
- `src/OverviewDashboard.js`: component giao diện chung cho demo và API.
- `src/overviewData.js`: tính toán số liệu đúng nguồn; không tự tạo số mẫu trên môi trường API.
- `tests/overviewDashboard.test.js`: test dữ liệu, phạm vi kho, cấu trúc giao diện.

## Chạy trên VS Code / Windows

```powershell
npm.cmd install
npm.cmd run check
npx.cmd expo start -c
```

Nhấn **w** để xem web; Android qua Expo Go. Chưa triển khai lên VPS và chưa kiểm thử giao diện trực tiếp trên điện thoại thật.
