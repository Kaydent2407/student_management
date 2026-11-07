# STORIX v1.5 — Logo nhận diện mới

Logo chữ **S** màu xanh dương được cung cấp bởi nhóm STORIX ngày 25/10/2026.

## Vị trí sử dụng

- Biểu tượng ứng dụng Expo iOS/Android: `assets/brand/app-icon.png`.
- Android adaptive icon: `assets/brand/adaptive-icon.png` (có vùng an toàn cho launcher).
- Favicon của bản web: `assets/brand/favicon.png`.
- Đăng nhập API và đăng nhập Demo: `src/BrandAuth.js`.
- Các thanh nhận diện của màn hình nghiệp vụ (API và Demo), bao gồm header, sidebar và nhãn mục: `src/ApiWorkspace.js`, `App.js`, `src/ui.js`.
- Nguồn logo nguyên bản: `assets/brand/storix-logo-original.png`.

## Những phần được giữ nguyên

- API backend mặc định `https://storixapi.duckdns.org` và cơ chế JWT.
- Luồng nghiệp vụ, dữ liệu demo, chế độ API/demo và quy tắc chữ trắng trên màn hình nghiệp vụ.
- Màu và nội dung biểu mẫu xác thực, ngoại trừ biểu tượng nhận diện.

## Chạy trên Windows qua VS Code

```powershell
npm.cmd install
npm.cmd run check
npx.cmd expo start -c
```

Nhấn `w` để xem giao diện web hoặc quét QR bằng Expo Go. Để cập nhật biểu tượng launcher thực tế trong bản APK/Android cài đặt, cần build lại ứng dụng; thay ảnh trong project không thay đổi icon của Expo Go.
