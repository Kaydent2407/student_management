import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const ui = readFileSync(new URL('../src/ui.js', import.meta.url), 'utf8');
const app = readFileSync(new URL('../App.js', import.meta.url), 'utf8');
const api = readFileSync(new URL('../src/ApiWorkspace.js', import.meta.url), 'utf8');
const overview = readFileSync(new URL('../src/OverviewDashboard.js', import.meta.url), 'utf8');
const auth = readFileSync(new URL('../src/BrandAuth.js', import.meta.url), 'utf8');
const apiClient = readFileSync(new URL('../src/apiClient.js', import.meta.url), 'utf8');

test('Figma light theme: đúng màu STORIX và nền chung #F9F9FF', () => {
  for(const x of ['#3674B5','#F9F9FF','#E2E8F0','#172B4D','#FFFFFF','#D1F8EF']) assert.ok(ui.includes(x),x);
  assert.match(ui,/export const F=C/);
  assert.match(overview,/background:'#F9F9FF'/);
});
test('Đồng bộ cả API và demo cùng sidebar/topbar và theme sáng', () => {
  assert.match(app, /<UiThemeProvider mode="light">/);
  assert.match(api, /<UiThemeProvider mode="light">/);
  assert.match(app, /<OverviewSidebar groups=\{demoMenu\}/);
  assert.match(api, /<OverviewSidebar groups=\{apiMenu\}/);
  assert.match(app, /<OverviewTopbar desktop=\{desktop\}/);
  assert.match(api, /<OverviewTopbar desktop=\{desktop\}/);
});
test('Không đổi màn hình đăng nhập và không đổi giao thức API',()=>{
  assert.match(auth, /<StorixLogo size=\{48\}/);
  assert.match(auth, /backgroundColor:BRAND\.mint/);
  assert.match(apiClient,/https:\/\/storixapi\.duckdns\.org/);
  assert.match(apiClient,/Authorization: `Bearer \$\{token\}`/);
  assert.match(app,/<BrandAuthShell mode="demo"/);
  assert.match(api,/<BrandAuthShell mode="api"/);
});
