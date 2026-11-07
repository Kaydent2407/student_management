import test from 'node:test';
import assert from 'node:assert/strict';
import { pathWithQuery, apiRequest, ApiError, API_URL } from '../src/apiClient.js';

test('Đúng HTTPS API của nhóm', () => assert.match(API_URL, /^https:\/\//));
test('Query string được mã hóa an toàn', () => assert.equal(pathWithQuery('/api/products', {search:'máy bơm & van',page:2,blank:''}), '/api/products?search=m%C3%A1y%20b%C6%A1m%20%26%20van&page=2'));
test('Không ghi Authorization nếu không có token', async () => {
  const before = globalThis.fetch;
  globalThis.fetch = async (_, init) => {
    assert.equal(init.headers.Authorization, undefined);
    return new Response(JSON.stringify({ok:true}), {status:200, headers:{'content-type':'application/json'}});
  };
  try { assert.deepEqual(await apiRequest('/x'), {ok:true}); } finally { globalThis.fetch=before; }
});
test('JWT được gửi đúng Authorization Bearer', async () => {
  const before = globalThis.fetch;
  globalThis.fetch = async (_, init) => {
    assert.equal(init.headers.Authorization, 'Bearer fake-token-for-unit-test');
    return new Response(JSON.stringify({items:[]}), {status:200, headers:{'content-type':'application/json'}});
  };
  try { await apiRequest('/api/products', {token:'fake-token-for-unit-test'}); } finally { globalThis.fetch=before; }
});
test('Lỗi 401 kích hoạt xử lý phiên hết hạn', async () => {
  const before = globalThis.fetch;
  let called=0;
  globalThis.fetch = async () => new Response(JSON.stringify({message:'JWT hết hạn'}), {status:401, headers:{'content-type':'application/json'}});
  try {await assert.rejects(apiRequest('/api/auth/me',{token:'invalid',onUnauthorized:()=>called++}), e=>e instanceof ApiError&&e.status===401);assert.equal(called,1);} finally {globalThis.fetch=before;}
});
test('Lỗi 403 vẫn giữ trạng thái đăng nhập', async () => {
  const before=globalThis.fetch;let called=0;
  globalThis.fetch=async()=>new Response(null,{status:403});
  try{await assert.rejects(apiRequest('/api/products',{token:'valid',onUnauthorized:()=>called++}),e=>e.status===403);assert.equal(called,0);}finally{globalThis.fetch=before;}
});
