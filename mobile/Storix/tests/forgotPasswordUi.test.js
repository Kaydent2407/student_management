import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const read=name=>readFileSync(new URL(name,import.meta.url),'utf8');
const screen=read('../src/ForgotPasswordScreen.js');
const shell=read('../src/BrandAuth.js');
const api=read('../src/ApiWorkspace.js');
const backend=read('../Backend_Reference/Controllers/AuthController.cs');

test('Trang đăng nhập API có liên kết mở lấy lại mật khẩu và quay lại',()=>{
  assert.match(api,/onForgotPassword=\{\(\) => setForgotPasswordOpen\(true\)\}/);
  assert.match(api,/if \(forgotPasswordOpen\) return <ForgotPasswordScreen/);
  assert.match(api,/onBackToLogin=\{\(\) => setForgotPasswordOpen\(false\)\}/);
});
test('Màu, tiêu đề, nội dung đăng nhập mặc định giữ nguyên',()=>{
  assert.match(shell,/title='Đăng nhập'/);
  assert.match(shell,/mode='api'/);
  assert.match(shell,/mint:'#D1F8EF'/);
  assert.match(shell,/backgroundColor:BRAND\.white/);
  assert.match(shell,/Quên mật khẩu\? Liên hệ quản trị viên/);
});
test('Trang lấy lại mật khẩu có trường nhận diện, thông tin hỗ trợ và nút quay lại',()=>{
  assert.match(screen,/title="Lấy lại mật khẩu"/);
  assert.match(screen,/label="Tên đăng nhập hoặc email"/);
  assert.match(screen,/Xem hướng dẫn khôi phục/);
  assert.match(screen,/Quay lại đăng nhập/);
  assert.match(screen,/if \(!identifier\.trim\(\)\)/);
});
test('Không gửi OTP, đặt lại mật khẩu, ghi database hay gọi endpoint không tồn tại',()=>{
  assert.doesNotMatch(screen,/apiRequest\(|fetch\(|axios\.|\/api\/auth\/forgot-password/);
  assert.match(screen,/chưa có chức năng tự gửi mã OTP/);
  assert.match(backend,/HttpPost\("change-password"\)/);
  assert.doesNotMatch(backend,/HttpPost\("(?:forgot-password|reset-password)"\)/);
});
