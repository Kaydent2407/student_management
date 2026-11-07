// Storix API client. JWT chỉ nằm trong bộ nhớ phiên, KHÔNG lưu AsyncStorage/localStorage.
// EXPO_PUBLIC_API_URL được đóng gói tại thời điểm Expo web export.
export const API_URL = String(process.env.EXPO_PUBLIC_API_URL || 'https://storixapi.duckdns.org').replace(/\/+$/, '');

export class ApiError extends Error {
  constructor(message, status = 0) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

export function pathWithQuery(path, args = {}) {
  const query = Object.entries(args)
    .filter(([, value]) => value !== undefined && value !== null && value !== '')
    .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`)
    .join('&');
  return path + (query ? `?${query}` : '');
}

export async function apiRequest(path, { method = 'GET', body, token, timeoutMs = 15000, onUnauthorized } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${API_URL}${path}`, {
      method,
      headers: {
        Accept: 'application/json',
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      signal: controller.signal,
    });
    const contentType = response.headers.get('content-type') || '';
    let payload = null;
    if (contentType.includes('application/json')) {
      try { payload = await response.json(); } catch { /* response JSON lỗi */ }
    } else {
      const plainText = await response.text();
      payload = plainText ? { message: plainText.slice(0, 240) } : null;
    }
    if (!response.ok) {
      if (response.status === 401 && typeof onUnauthorized === 'function') onUnauthorized();
      const message = payload?.message || payload?.title ||
        (response.status === 401 ? 'Phiên đăng nhập đã hết hạn hoặc thông tin đăng nhập không hợp lệ.' :
          response.status === 403 ? 'Tài khoản không có quyền thực hiện chức năng này.' :
          response.status === 404 ? 'Không tìm thấy dữ liệu hoặc bạn không có quyền xem.' :
          response.status === 409 ? 'Dữ liệu đã thay đổi. Hãy tải lại và thử lại.' :
          response.status === 503 ? 'API không truy cập được database.' :
          `Máy chủ trả về lỗi HTTP ${response.status}.`);
      throw new ApiError(message, response.status);
    }
    return payload;
  } catch (error) {
    if (error.name === 'AbortError') throw new ApiError('API phản hồi quá lâu. Kiểm tra VPS hoặc mạng Internet.');
    if (error instanceof ApiError) throw error;
    throw new ApiError(`Không kết nối được tới ${API_URL}. Kiểm tra DNS, HTTPS, kết nối Internet và cấu hình CORS nếu chạy trên web.`);
  } finally {
    clearTimeout(timer);
  }
}

export const apiEndpoints = Object.freeze({
  login: '/api/auth/login',
  me: '/api/auth/me',
  changePassword: '/api/auth/change-password',
  products: '/api/products',
  categories: '/api/catalogs/categories',
  units: '/api/catalogs/units',
  barcode: '/api/catalogs/barcodes',
  warehouses: '/api/warehouses',
  receipts: '/api/inbound-receipts',
  databaseHealth: '/api/health/database',
});
