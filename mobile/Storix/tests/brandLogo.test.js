import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {join} from 'node:path';
const root = new URL('../',import.meta.url);
const read = path => readFileSync(new URL(path,root),'utf8');
const conf=JSON.parse(read('app.json')).expo;
const pkg=JSON.parse(read('package.json'));
const file=path=>new URL(path,root);

test('Icon ứng dụng, favicon và adaptive icon dùng ảnh STORIX tại máy',()=>{
  for(const path of [conf.icon,conf.android.adaptiveIcon.foregroundImage,conf.web.favicon]){
    assert.ok(existsSync(file(path)), `Thiếu file ${path}`);
    const raw=readFileSync(file(path));
    assert.ok(raw.length>2000,`Ảnh rỗng: ${path}`);
    assert.equal(raw.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  }
  assert.equal(conf.version,pkg.version);
});
test('Component logo dùng ảnh có sẵn chứ không gọi ảnh mạng',()=>{
  const s=read('src/StorixLogo.js');
  assert.ok(s.includes("require('../assets/brand/storix-logo.png')"));
  assert.match(s,/<Image /);
  assert.doesNotMatch(s,/https?:\/\//);
});
test('Đăng nhập API và demo dùng cùng logo STORIX',()=>{
  const auth=read('src/BrandAuth.js');
  assert.match(auth,/<StorixLogo size=\{48\}/);
  assert.match(read('src/ApiWorkspace.js'),/<BrandAuthShell mode="api"/);
  assert.match(read('App.js'),/<BrandAuthShell mode="demo"/);
});
test('Logo xuất hiện trên sidebar, topbar và breadcrumb của giao diện nghiệp vụ',()=>{
  const overview=read('src/OverviewDashboard.js');
  assert.match(overview,/export function OverviewSidebar/);
  assert.match(overview,/export function OverviewTopbar/);
  assert.match(overview,/<StorixLogo size=\{35\}/);
  assert.match(overview,/<StorixLogo size=\{30\}/);
  assert.match(read('src/ApiWorkspace.js'),/<OverviewSidebar groups=\{apiMenu\}/);
  assert.match(read('App.js'),/<OverviewSidebar groups=\{demoMenu\}/);
});
test('Logo không thay đổi địa chỉ API và chế độ chữ trắng trên trang nghiệp vụ',()=>{
  assert.match(read('src/apiClient.js'),/https:\/\/storixapi\.duckdns\.org/);
  assert.match(read('src/ui.js'),/dark\?\{color:'#FFFFFF'\}/);
});
