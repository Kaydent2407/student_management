import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const load = path => readFileSync(new URL(path, import.meta.url), 'utf8');
const auth=load('../src/BrandAuth.js');
const api=load('../src/ApiWorkspace.js');
const app=load('../App.js');
const shared=load('../src/ui.js');
const client=load('../src/apiClient.js');

test('Đăng nhập API dùng shell mint, thẻ trắng và chữ navy',()=>{
  assert.match(auth, /mint:'#D1F8EF'/);
  assert.match(auth, /navy:'#172B4D'/);
  assert.match(auth, /backgroundColor:BRAND\.white/);
  assert.match(api, /<BrandAuthShell mode="api"/);
});
test('Demo cũng dùng chung shell xác thực, không giả làm đăng nhập SQL Server',()=>{
  assert.match(app, /<BrandAuthShell mode="demo"/);
  assert.match(app, /không ghi vào API của nhóm/);
});
test('Có điều khiển hiện ẩn mật khẩu',()=>{
  assert.match(auth, /secureTextEntry=\{secure&&!visible\}/);
  assert.match(auth, /onPress=\{\(\)=>setVisible/);
});
test('Các trang nghiệp vụ dùng chung theme sáng Figma; đăng nhập vẫn tách biệt',()=>{
  assert.match(shared, /export const F=C/);
  assert.match(shared, /export function WorkspaceRibbon/);
  assert.match(app, /<UiThemeProvider mode="light">/);
  assert.match(api, /<UiThemeProvider mode="light">/);
  assert.ok(app.indexOf('if(!loggedIn)return') < app.indexOf('<UiThemeProvider mode="light">'));
  assert.ok(api.indexOf('if (!token || !user) return') < api.indexOf('<UiThemeProvider mode="light">'));
  assert.match(app, /<OverviewTopbar desktop=\{desktop\}/);
  assert.match(api, /<OverviewTopbar desktop=\{desktop\}/);
});
test('Thiết kế không thay đổi URL mặc định và token JWT của API',()=>{
  assert.match(client,/https:\/\/storixapi\.duckdns\.org/);
  assert.match(client,/Authorization: `Bearer \$\{token\}`/);
  assert.doesNotMatch(auth,/RetailStorage#2024|nv_kho_thuanduc/i);
});
