# STORIX — Quy ước giao diện v1.4

## Nguồn tham chiếu

- Ảnh tham chiếu: **Web / Đăng nhập** do nhóm gửi (nền mint nhạt, card trắng, logo xanh, nút đăng nhập xanh).
- Figma CNPM: `https://www.figma.com/design/kJTpeIKVA2oKxLva3sjNBJ/cnpm-nc?node-id=0-1`.
- Thiết kế Figma hiện bao gồm nhiều frame giao diện desktop 1280 px; app mobile là chuyển thể responsive theo thành phần và màu sắc, không sao chép từng điểm ảnh.

## Tỷ lệ và màu

| Thành phần | Màu | Công dụng |
| --- | --- | --- |
| Xanh mint | `#D1F8EF` | Nền màn hình xác thực; phần khung ngoài ở giao diện web desktop |
| Trắng | `#FFFFFF` | Thẻ đăng nhập; toàn bộ nội dung chữ trên trang nghiệp vụ |
| Navy thương hiệu | `#172B4D` | Chữ ở màn hình đăng nhập |
| Navy trang nghiệp vụ | `#102940` | Nền sau đăng nhập |
| Navy thẻ | `#1C3B58` | Thẻ, bảng và sheet chứa chữ trắng |
| Xanh dương | `#165F9F`, `#3674B5` | Nút đăng nhập, thao tác chính, nhãn điều hướng |
| Xanh mint điểm nhấn | `#43CAA6` | Chấm tín hiệu thị giác (không phải trạng thái API thật) |

## Quy tắc bắt buộc

1. Chữ trên các màn **sau đăng nhập** luôn trắng (`Txt` trong `UiThemeProvider mode="dark"`). Không đặt chữ trắng trên nền trắng.
2. Màn **đăng nhập**, màn lựa chọn tài khoản demo (và các màn đăng ký/xác thực có thể phát triển sau này) giữ chữ navy trên card trắng; không bọc bên trong `UiThemeProvider mode="dark"`.
3. Dùng `BrandAuthShell`, `BrandAuthField`, `BrandAuthButton` trong `src/BrandAuth.js` cho các biểu mẫu xác thực.
4. Dùng `WorkspaceRibbon`, `Panel`, `Field`, `Btn`, `Tag` từ `src/ui.js` cho các phần nghiệp vụ để thống nhất UI.
5. API thật và demo offline phải được phân biệt trực quan và không dùng dữ liệu mẫu để thể hiện là dữ liệu SQL Server.

## Tệp được thay đổi

- `App.js`: màn demo đăng nhập và khung nghiệp vụ.
- `src/ApiWorkspace.js`: màn đăng nhập API; khung các trang nghiệp vụ.
- `src/BrandAuth.js`: bộ màn đăng nhập chung.
- `src/ui.js`: palette, các thành phần và `WorkspaceRibbon`.
- `package.json`, `app.json`: nâng số phiên bản hiển thị lên 1.4.
- `tests/brandUi.test.js`: kiểm tra ranh giới theme và cấu trúc nguồn.

## Chú ý triển khai

`EXPO_PUBLIC_API_URL` là URL công khai, không chứa password, JWT hoặc connection string. Không cần sửa API/vPS chỉ để cập nhật giao diện; với web, phải build và upload riêng, sau khi sao lưu bản cũ.
