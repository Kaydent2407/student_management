# STORIX Android + API: chạy VS Code và triển khai web lên VPS

## Hệ thống trong bản ZIP này

- **Storix App**: React Native + Expo, dùng cho web và Android qua Expo Go.
- **Storix API**: ASP.NET Core .NET 10 + SQL Server + JWT, nguồn được chép trong `Backend_Reference/`.
- `https://storixapi.duckdns.org` là URL backend mà nhóm cung cấp. Chưa thể xác minh trạng thái thực tế của URL này từ môi trường đóng gói.
- **Không có thông tin SSH của VPS** nên bản ZIP chỉ chuẩn bị mã, không có thao tác triển khai trực tiếp lên máy chủ.
- Chưa có script tạo database/migration trong file API được tải lên. Backend thật cần cơ sở dữ liệu đã sẵn sàng.

## A. Chạy trên Windows bằng VS Code

Mở Terminal CMD trong thư mục có file `package.json`:

```bat
npm.cmd install
npm.cmd run check
npx.cmd expo start
```

Nhấn `w` để xem web. Expo Go quét QR để chạy Android. Tài khoản đăng nhập phải tồn tại trong bảng `NGUOI_DUNG` của SQL Server backend (không dùng các vai trò demo làm tài khoản thật).

**Kiểm tra API** trên Windows PowerShell hoặc Command Prompt:

```powershell
curl.exe -i https://storixapi.duckdns.org/api/products
```

Đối với endpoint cần đăng nhập, phản hồi HTTP **401** khi không có token là dấu hiệu backend có thể đang trả lời bình thường; 404 có thể do route/reverse proxy, 502 do upstream backend, lỗi SSL/DNS do kết nối hoặc cấu hình domain. 401 không chứng minh database hoạt động.

## B. Build web để đưa lên VPS

Ở thư mục dự án:

```bat
npm.cmd install
npm.cmd run check
npx.cmd expo export --platform web
```

Expo xuất website tĩnh vào thư mục `dist/` (kiểm tra lại output của lệnh để xác nhận). `EXPO_PUBLIC_API_URL` mặc định là `https://storixapi.duckdns.org`. Có thể cấu hình bằng `.env` từ `.env.example` **trước khi build**. Chú ý: mọi biến `EXPO_PUBLIC_*` xuất hiện trong bundle frontend đều công khai, không chứa mật khẩu hay JWT cố định.

## C. Upload bản web qua SSH từ máy tính Windows

Thay `VPS_USER` và `VPS_IP` bằng thông tin SSH thật (KHÔNG phải URL API):

```powershell
scp -r .\dist VPS_USER@VPS_IP:~/storix-web-release
```

SSH vào VPS:

```bash
ssh VPS_USER@VPS_IP
```

Giả sử VPS dùng **Ubuntu + Nginx** và `www-data`:

```bash
sudo mkdir -p /var/www/storix-web
sudo cp -a ~/storix-web-release/. /var/www/storix-web/
sudo chown -R www-data:www-data /var/www/storix-web
```

Xác định cấu hình Nginx hiện tại:

```bash
sudo nginx -T | grep -n -C 5 'server_name storixapi.duckdns.org'
```

Sao lưu cấu hình web đang dùng **trước khi sửa**, rồi mở chính file của HTTPS vhost `storixapi.duckdns.org`. Chỉ thêm phần nội dung ở `nginx-storix-frontend-location.conf` **vào trong `server {}` đang có SSL/TLS**. Không ghi đè hoặc xóa `location /api/` đang proxy tới API. Nếu đã có `location /`, hãy sửa location đó (không tạo location trùng).

Kiểm tra cú pháp và tải lại dịch vụ:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Mở `https://storixapi.duckdns.org/` để xem giao diện. Kiểm tra API vẫn còn hoạt động sau cập nhật:

```bash
curl -i https://storixapi.duckdns.org/api/products
```

**Quan trọng:** bản web và API nằm cùng domain/port HTTPS nên KHÔNG cần sửa CORS. Nginx phải giữ proxy `/api/` cũ. Nếu cần sử dụng **tên miền web khác** như `https://storix.duckdns.org`, cần DNS/HTTPS và khai báo origin chính xác trên backend bằng `Cors__AllowedOrigins__0` rồi triển khai lại API đã hỗ trợ CORS. Không bật CORS dạng `*` cho hệ thống thật.

## D. Trường hợp cần đưa API .NET 10 lên VPS lần đầu

Nếu `https://storixapi.duckdns.org` **đã chạy API thành công**, không thực hiện phần này, tránh làm gián đoạn backend hiện hữu. Nếu chưa có API và muốn tự triển khai:

1. Cài .NET SDK **10** trên máy build (Windows hoặc Linux). VPS cần .NET **10 runtime**, hoặc dùng Docker với image ASP.NET 10.
2. Đảm bảo SQL Server đã chạy và schema đúng như backend yêu cầu; ZIP chưa có SQL schema.
3. Ở thư mục `Backend_Reference`, chạy `dotnet restore`, `dotnet build -c Release` và `dotnet publish -c Release -o publish`.
4. Tải thư mục `publish` vào `/opt/storix-api` qua SCP/SSH.
5. Cấp chuỗi kết nối SQL và Jwt__Issuer, Jwt__Audience, Jwt__Key qua biến môi trường hoặc file systemd EnvironmentFile riêng trên VPS, **không commit thông tin đăng nhập vào repo hay đóng vào app**.
6. Tùy hạ tầng, chạy systemd (mẫu `storix-api.service.example`) hoặc Docker. Cho backend lắng nghe **127.0.0.1** và Nginx proxy `/api/` tới cổng backend.
7. Cấu hình HTTPS (Let's Encrypt/Nginx) trước khi dùng đăng nhập. Bảo vệ SSH, SQL Server và JWT key. Giới hạn CORS theo origin nếu tách domain.

**Không tự động ghi đè cấu hình API hiện hành** nếu chưa xác nhận máy chủ đang dùng Docker, systemd, Nginx hay Caddy; cần kiểm tra thực tế VPS trước.

## E. API đã nối vào màn hình nào?

| Màn hình | API được gọi | Ghi chú |
| --- | --- | --- |
| Đăng nhập | `POST /api/auth/login` | JWT ở RAM, không ghi vào localStorage |
| Tài khoản | `POST /api/auth/change-password` | JWT cũ vô hiệu sau đổi mật khẩu |
| Tổng quan | `GET /api/products`, `GET /api/warehouses`, `GET /api/inbound-receipts` | Tương ứng phạm vi quyền |
| Sản phẩm | `GET /api/products`, `GET /api/products/{id}` | Có tìm kiếm và phân trang |
| Tạo sản phẩm | `POST /api/products` | Dùng danh mục và đơn vị API |
| Ngừng/kích hoạt sản phẩm | `PATCH /api/products/{id}/status` | Dùng rowVersion từ API |
| Kho/bãi/cửa hàng | `GET /api/warehouses`, `POST /api/warehouses` | Kho mới cần gán quyền |
| Vị trí | `GET /api/warehouses/{id}/positions` | Xem trạng thái |
| Tồn kho | `GET /api/warehouses/{id}/stock` | Phân trang, theo lô/vị trí |
| Phiếu nhập | `GET /api/inbound-receipts`, `GET /api/inbound-receipts/{id}` | Xem dòng và phân bổ |
| Hoàn thành nhập | `POST /api/inbound-receipts/{id}/complete` | Thay đổi DB thật, có xác nhận |
| Barcode / QR | `GET /api/catalogs/barcodes?code=...` | Dùng camera hoặc nhập mã |

**Chưa có API trong ZIP** cho tạo/duyệt phiếu xuất, điều chuyển, kiểm kê, yêu cầu bổ sung, bán hàng, báo cáo nâng cao. Các chức năng cũ vẫn chạy trong **Demo offline** và hoàn toàn tách biệt database thật.

## F. Xử lý lỗi

- **PowerShell chặn npm.ps1**: dùng `npm.cmd`, `npx.cmd` hoặc chuyển Terminal sang CMD.
- **401 tại login**: tên đăng nhập hoặc mật khẩu không đúng; hoặc tài khoản bị khóa; sau 15 phút token có thể hết hạn.
- **403 sau login**: user thiếu quyền API `HasPermission(...)`.
- **404 hoặc 502**: kiểm tra định tuyến Nginx tới `/api/...`, service backend, port.
- **503**: backend không kết nối được SQL Server hoặc chưa cấu hình `ConnectionStrings__StorixDb`.
- **Web báo CORS**: frontend khác origin API; whitelist chính xác origin trong backend, không tự thêm header từ phía client.
- **Android quét camera**: cần cấp quyền camera cho Expo Go.
- **Nginx có lỗi `duplicate location /`**: đã thêm location trùng; sửa location gốc thay vì thêm mới.
