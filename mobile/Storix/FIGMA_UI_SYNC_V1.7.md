# STORIX – Đồng bộ giao diện Figma (UI only) v1.7

**Nguồn thiết kế:** https://www.figma.com/design/kJTpeIKVA2oKxLva3sjNBJ/cnpm-nc?node-id=0-1

## Phạm vi tuyệt đối

Chỉ thay đổi phần nhìn trên các trang **đã có trong ứng dụng**: màu, khoảng cách, typography, sidebar, topbar, panel, filter, form, layout responsive. Không thêm trang nghiệp vụ từ Figma, không đổi luồng nút hay quyền truy cập, không sửa API/SQL, không thay đổi dữ liệu demo, không thêm endpoint.

**Không chỉnh sửa:** `src/BrandAuth.js` (giao diện đăng nhập), `src/StorixLogo.js`, ảnh logo, `src/apiClient.js`, `src/inventory.js`, `src/overviewData.js`, `src/mobileFeatures.js`, `src/seed.js`, backend tham chiếu và cấu hình VPS.

## Thiết kế áp dụng

- Trang làm việc dùng nền sáng Figma `#F9F9FF`, sidebar và panel `#FFFFFF`, viền `#E2E8F0`, chữ chính `#172B4D`, chữ phụ `#64748B`.
- Màu tương tác STORIX `#3674B5`, xanh mint thương hiệu `#D1F8EF`; thẻ trạng thái dùng màu phân biệt phù hợp.
- Sidebar trắng, menu nhóm và active state xanh nhạt; topbar trắng có breadcrumb, tài khoản, làm mới.
- Trên Android, sidebar chuyển thành thanh điều hướng dưới cùng **không thay đổi danh sách mục điều hướng**.
- Form, panel, modal và danh sách dùng thiết kế sáng có viền và khoảng cách đồng nhất.
- Dashboard đã triển khai ở v1.6 tiếp tục hiển thị layout thống kê/biểu đồ/bảng/cảnh báo; chỉ tinh chỉnh design tokens và topbar.
- **Không sửa trang đăng nhập**; đăng nhập vẫn màu mint, thẻ trắng, sử dụng ảnh logo hiện có.

## Đối chiếu màn hình thiết kế với các giao diện sẵn có

| Nhóm | Frame Figma tham chiếu | App hiện có |
|---|---|---|
| Tổng quan | `45:2` | Dashboard API và demo |
| Danh sách sản phẩm | `45:640` | Sản phẩm API và demo |
| Tạo/chi tiết sản phẩm | `45:1255`, `66:3` | Biểu mẫu/chi tiết sản phẩm hiện có |
| Nơi lưu trữ, vị trí | `71:3359`, `71:4581` | Kho bãi API và demo |
| Nhà cung cấp, lô | `72:5505`, `72:6973` | Mục tiện ích trong demo (không bổ sung vào API) |
| Phiếu nhập | `74:8474` | Phiếu nhập API, nhóm phiếu kho demo |
| Điều chuyển | `84:7233` | Nhóm phiếu kho demo (API chưa có) |
| Tồn kho, thẻ kho | `204:417`, `204:1799` | Chi tiết kho API và báo cáo/thẻ kho demo |
| Kiểm kê | `204:3356` | Mục kiểm kê demo |
| Cảnh báo | `206:11944` | Mục cảnh báo demo |
| Báo cáo | `206:12545` | Mục báo cáo demo |
| Tài khoản | `206:19043` | Tài khoản API và demo |

**Ghi chú:** Nguồn Figma là các frame web 1280px. Giao diện Android được chuyển thể responsive chứ không thể dùng kích thước cố định của desktop. Một số frame Figma không có chức năng tương đương trong app hiện tại; chỉ tham khảo design system, không tự động bổ sung màn hình.

## Chạy trên Windows / VS Code

Mở thư mục `Storix`, mở Terminal và chạy:

```powershell
npm.cmd install
npm.cmd run check
npx.cmd expo start -c
```

Nhấn `w` để xem web hoặc quét QR bằng Expo Go để xem Android.

**VPS:** Việc thay đổi giao diện trong ZIP chưa tự triển khai lên VPS và không sửa API đang hoạt động.
