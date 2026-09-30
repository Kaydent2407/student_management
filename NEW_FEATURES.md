# Các chức năng đã bổ sung

Bản này mở rộng hệ thống quản lý sinh viên và **không có module quản lý giảng viên**, đúng phạm vi dự án.

## 1. Quên mật khẩu và đổi mật khẩu
- Trang đăng nhập có **Quên mật khẩu?**.
- Gửi email đặt lại mật khẩu bằng Firebase Authentication.
- Trang cá nhân có chức năng **Đổi mật khẩu**, yêu cầu nhập mật khẩu hiện tại trước khi cập nhật.

> Firebase Console cần bật Authentication > Sign-in method > Email/Password và cấu hình email reset password nếu muốn tùy biến mẫu thư.

## 2. Lớp học phần
- CRUD lớp học phần theo học kỳ.
- Gắn môn học, lớp sinh viên, phòng, thứ, tiết bắt đầu/kết thúc.
- Tự quy đổi tiết 1–12 theo thời gian HUFLIT.
- Mở/đóng đăng ký.
- Giới hạn sĩ số.
- Đồng bộ lớp học phần sang collection `schedules` để dùng chung màn hình thời khóa biểu.

## 3. Phòng học
- CRUD phòng học.
- Mã phòng, tên phòng, vị trí, sức chứa, trạng thái sử dụng.
- Không cho xóa phòng đang được lớp học phần sử dụng.
- Khi tạo lớp học phần, sĩ số không được vượt sức chứa phòng.
- Kiểm tra trùng phòng cùng ngày/tiết trong cùng học kỳ.

## 4. Kiểm tra đăng ký môn
Khi sinh viên đăng ký lớp học phần, hệ thống kiểm tra:
- Không đăng ký trùng môn trong cùng học kỳ.
- Không trùng lịch với lớp học phần đã đăng ký.
- Không vượt sĩ số lớp học phần.
- Không vượt số tín chỉ tối đa của học kỳ.
- Đúng lớp sinh viên nếu lớp học phần có giới hạn lớp.
- Đã đạt các môn tiên quyết.

## 5. Giới hạn tín chỉ và môn tiên quyết
Menu **Quy định học vụ** cho Admin:
- Thiết lập số tín chỉ tối đa/học kỳ, mặc định 24.
- Chọn môn tiên quyết cho từng môn học.
- Một môn tiên quyết được xem là đạt khi điểm tổng kết >= 4.0/10.

## 6. Lịch thi
- Admin CRUD lịch thi theo môn, học kỳ, ngày, giờ, phòng và hình thức thi.
- Sinh viên chỉ xem lịch thi của các môn đã đăng ký.

## 7. Kết quả học tập tổng hợp
Sinh viên có trang **Kết quả học tập**:
- GPA hệ 10.
- GPA hệ 4.
- Tổng tín chỉ đạt / chưa đạt.
- Xếp loại học lực.
- Bảng kết quả theo học kỳ.

## 8. Thông báo đã đọc / chưa đọc
- Thông báo hiển thị trạng thái chưa đọc.
- Mở chi tiết sẽ đánh dấu đã đọc.
- Có nút **Đánh dấu tất cả đã đọc**.
- Chuông trên thanh trên cùng hiển thị badge số thông báo chưa đọc.

## 9. Lịch sử thanh toán học phí
Collection `tuition_payments` lưu từng giao dịch:
- Sinh viên / học kỳ.
- Số tiền.
- Phương thức.
- Mã giao dịch.
- Trạng thái.
- Thời gian.

Admin có thể ghi nhận giao dịch; sinh viên chỉ xem lịch sử của mình.

## 10. Xuất báo cáo Excel / PDF
Trong **Báo cáo thống kê**:
- Xuất Excel nhiều sheet: Sinh viên, Lớp học, Môn học, Đăng ký môn, Điểm, Điểm danh, Học phí.
- Xuất PDF báo cáo tổng hợp và danh sách sinh viên.

## 11. Nhập sinh viên từ Excel
- Hỗ trợ `.xlsx`.
- Tối thiểu cần hai cột: `MSSV` và `Họ tên`.
- Có thể thêm: `Email`, `Số điện thoại`, `Lớp`, `Chuyên ngành`.
- MSSV đã tồn tại sẽ được cập nhật thay vì tạo trùng.

## 12. Nhật ký hệ thống
Admin có menu **Nhật ký hệ thống**.
- Ghi người thực hiện, email, vai trò, thời gian, hành động, chức năng, đối tượng và dữ liệu liên quan.
- Có tìm kiếm và lọc theo module.
- Nhật ký được ghi cho các thao tác quan trọng như đăng nhập/đăng xuất, CRUD, đăng ký/hủy môn, điểm, điểm danh, học phí, thông báo, xuất/nhập báo cáo, thay đổi quy định học vụ...

## Collections mới
- `rooms`
- `course_sections`
- `academic_settings` (`general`)
- `exam_schedules`
- `notification_reads`
- `tuition_payments`
- `audit_logs`

Các collection cũ vẫn được giữ nguyên.

## Thứ tự thử nghiệm khuyến nghị
1. Vào **Học phí** tạo/chọn một học kỳ đang Active.
2. Vào **Phòng học** tạo phòng.
3. Vào **Lớp học phần** tạo lớp học phần trong học kỳ Active.
4. Vào **Quy định học vụ** đặt giới hạn tín chỉ / môn tiên quyết nếu cần.
5. Đăng nhập tài khoản sinh viên và thử **Đăng ký môn học**.
6. Kiểm tra **Lịch học**, **Lịch thi**, **Kết quả học tập**, **Học phí**, **Thông báo**.
7. Đăng nhập Admin và mở **Nhật ký hệ thống** để xem các thao tác vừa thực hiện.

## Chạy project
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-port 8080
```

Nếu trình duyệt còn cache giao diện cũ, nhấn `Ctrl + Shift + R`.
