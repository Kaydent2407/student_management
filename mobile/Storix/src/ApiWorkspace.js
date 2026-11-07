import React, { useEffect, useState } from 'react';
import { View, ScrollView, TextInput, Pressable, StatusBar, ActivityIndicator, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { I, Txt, Flex, Btn, Tag, Panel, Section, Field, Choices, C, D, F, UiThemeProvider, useUiPalette, WorkspaceRibbon } from './ui';
import ScanCamera from './ScanCamera';
import {BrandAuthShell,BrandAuthField,BrandAuthButton,BrandAuthNote,BRAND} from './BrandAuth';
import ForgotPasswordScreen from './ForgotPasswordScreen';
import StorixLogo from './StorixLogo';
import OverviewDashboard,{OverviewSidebar,OverviewTopbar} from './OverviewDashboard';
import {apiOverview} from './overviewData';
import { API_URL, apiRequest, pathWithQuery } from './apiClient.js';

// Chế độ làm việc với SQL Server thực. Các chức năng chưa được backend cấp API KHÔNG được mô phỏng là đã ghi thành công.
const MENU = [
  { id: 'dashboard', label: 'Tổng quan', icon: 'view-dashboard-outline' },
  { id: 'products', label: 'Sản phẩm', icon: 'package-variant-closed' },
  { id: 'warehouses', label: 'Kho / bãi', icon: 'warehouse' },
  { id: 'receipts', label: 'Phiếu nhập', icon: 'clipboard-list-outline' },
  { id: 'barcode', label: 'Quét mã', icon: 'barcode-scan' },
  { id: 'account', label: 'Tài khoản', icon: 'account-circle-outline' },
];
const initialProduct = { code: '', name: '', categoryId: '', baseUnitId: '', purchasePrice: '', sellingPrice: '', trackExpiry: false };
const initialWarehouse = { code: '', name: '', type: 'KHO', address: '', capacity: '', capacityUnit: 'KG' };
const fmt = value => Number(value ?? 0).toLocaleString('vi-VN');
const date = value => value ? new Date(value).toLocaleDateString('vi-VN') : '—';

function Input({ label, value, onChangeText, secureTextEntry = false, numeric = false, placeholder = '' }) {
  const theme=useUiPalette();
  return <View style={{ marginBottom: 13 }}>
    <Txt color={C.muted} size={12} bold style={{ marginBottom: 6 }}>{label}</Txt>
    <TextInput value={String(value ?? '')} onChangeText={onChangeText} placeholder={placeholder} placeholderTextColor={theme===D?'#FFFFFF':'#9AA4B2'}
      autoCapitalize="none" secureTextEntry={secureTextEntry} keyboardType={numeric ? 'decimal-pad' : 'default'}
      style={{ borderWidth: 1, borderColor: theme.line, borderRadius: 8, padding: 12, color: theme.ink, backgroundColor: theme.surface, minHeight: 45 }} />
  </View>;
}
function Banner({ children, error = false }) {
  const theme=useUiPalette(),dark=theme===D;
  return <View style={{ backgroundColor: dark?(error?'#5A354B':'#245074'):(error?'#FFF0F0':'#E9F5FD'), borderLeftWidth:3, borderLeftColor:dark?(error?'#FF929C':'#8BC9FF'):(error?C.red:'#27618C'), borderRadius: 9, padding: 12, marginBottom: 13 }}>
    <Txt color={dark?'#FFFFFF':error?C.red:'#27618C'} size={12}>{children}</Txt>
  </View>;
}
function Empty({ text = 'Chưa có dữ liệu hoặc không có quyền xem dữ liệu này.' }) {
  return <Panel><Txt color={C.muted} size={13}>{text}</Txt></Panel>;
}
function ModeLine({ onOpenDemo }) {
  return <Pressable onPress={onOpenDemo} style={{ padding: 10, alignItems: 'center' }}><Txt color={C.muted} size={12}>Xem dữ liệu mô phỏng (offline) →</Txt></Pressable>;
}
function SelectItem({ label, items, value, onChange }) {
  return <Choices label={label} items={items} value={String(value || '')} onChange={onChange} />;
}

export default function ApiWorkspace({ onOpenDemo }) {
  const { width } = useWindowDimensions();
  const desktop = width > 840;
  const [token, setToken] = useState('');
  const [user, setUser] = useState(null);
  const [login, setLogin] = useState({ username: '', password: '' });
  const [forgotPasswordOpen, setForgotPasswordOpen] = useState(false);
  const [tab, setTab] = useState('dashboard');
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [products, setProducts] = useState({ items: [], total: 0, page: 1 });
  const [productSearch, setProductSearch] = useState('');
  const [appliedSearch, setAppliedSearch] = useState('');
  const [productPage, setProductPage] = useState(1);
  const [warehouses, setWarehouses] = useState([]);
  const [warehouse, setWarehouse] = useState(null);
  const [positions, setPositions] = useState([]);
  const [stocks, setStocks] = useState({ items: [], total: 0, page: 1 });
  const [stockPage, setStockPage] = useState(1);
  const [receipts, setReceipts] = useState({ items: [], total: 0, page: 1 });
  const [receiptPage, setReceiptPage] = useState(1);
  const [receipt, setReceipt] = useState(null);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [categories, setCategories] = useState([]);
  const [units, setUnits] = useState([]);
  const [form, setForm] = useState('');
  const [productForm, setProductForm] = useState(initialProduct);
  const [warehouseForm, setWarehouseForm] = useState(initialWarehouse);
  const [passwords, setPasswords] = useState({ current: '', next: '' });
  const [scanCode, setScanCode] = useState('');
  const [scanned, setScanned] = useState([]);
  const [cameraVisible, setCameraVisible] = useState(false);
  const [confirmReceipt, setConfirmReceipt] = useState(null);
  const [refreshIndex, setRefreshIndex] = useState(0);

  const logout = (message = '') => {
    setToken(''); setUser(null); setError(message); setNotice(''); setForgotPasswordOpen(false);
    setProducts({ items: [], total: 0, page: 1 }); setWarehouses([]);
    setPositions([]); setStocks({ items: [], total: 0, page: 1 });
    setReceipt(null); setReceipts({ items: [], total: 0, page: 1 });
    setSelectedProduct(null); setScanned([]); setForm(''); setLogin(s => ({ ...s, password: '' }));
  };
  const request = (path, opts = {}) => apiRequest(path, { ...opts, token, onUnauthorized: () => logout('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.') });
  const fail = e => setError(e?.message || 'Đã xảy ra lỗi không xác định.');
  const success = message => { setError(''); setNotice(message); };

  async function signIn() {
    if (!login.username.trim() || !login.password) { setError('Hãy nhập tên đăng nhập và mật khẩu SQL Server API.'); return; }
    setBusy(true); setError('');
    try {
      const auth = await apiRequest('/api/auth/login', { method: 'POST', body: { username: login.username.trim(), password: login.password } });
      if (!auth?.accessToken || !auth?.user) throw Error('API không trả accessToken và user.');
      setToken(auth.accessToken);
      setUser({ ...auth.user, mustChangePassword: auth.mustChangePassword });
      setLogin(s => ({ ...s, password: '' }));
      setTab('dashboard'); setRefreshIndex(x => x + 1);
      setNotice(auth.mustChangePassword ? 'Tài khoản bắt buộc đổi mật khẩu trước khi sử dụng chức năng khác.' : 'Đăng nhập API thành công.');
      if (auth.mustChangePassword) setTab('account');
    } catch (e) { fail(e); } finally { setBusy(false); }
  }

  useEffect(() => {
    if (!token || !user || (user.mustChangePassword && tab !== 'account')) return;
    let active = true;
    const attempt = async (promise, setter) => {
      try { const payload = await promise; if (active) setter(payload); }
      catch (e) { if (active) fail(e); }
    };
    setError(''); setLoading(true);
    (async () => {
      if (tab === 'dashboard') {
        // Dashboard chỉ tổng hợp dữ liệu API được phép đọc, không tính giá trị tồn giả.
        await Promise.allSettled([
          attempt(request(pathWithQuery('/api/products', { page: 1, pageSize: 30 })), setProducts),
          attempt(request('/api/warehouses'), result => setWarehouses(Array.isArray(result?.items) ? result.items : [])),
          attempt(request(pathWithQuery('/api/inbound-receipts', { page: 1, pageSize: 20 })), setReceipts),
        ]);
      } else if (tab === 'products') {
        await attempt(request(pathWithQuery('/api/products', { page: productPage, pageSize: 20, search: appliedSearch })), setProducts);
      } else if (tab === 'warehouses') {
        await attempt(request('/api/warehouses'), result => setWarehouses(Array.isArray(result?.items) ? result.items : []));
      } else if (tab === 'receipts') {
        await attempt(request(pathWithQuery('/api/inbound-receipts', { page: receiptPage, pageSize: 20 })), setReceipts);
      }
      if (active) setLoading(false);
    })();
    return () => { active = false; };
  }, [token, tab, productPage, appliedSearch, receiptPage, refreshIndex]);

  async function loadWarehouse(w, page = 1) {
    setWarehouse(w); setStockPage(page); setError(''); setBusy(true);
    try {
      const [p, s] = await Promise.all([
        request(`/api/warehouses/${w.id}/positions`),
        request(pathWithQuery(`/api/warehouses/${w.id}/stock`, { page, pageSize: 50 })),
      ]);
      setPositions(p.items || []); setStocks(s);
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function loadReceipt(r) {
    setBusy(true); setError('');
    try { setReceipt(await request(`/api/inbound-receipts/${r.id}`)); }
    catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function loadProduct(p) {
    setBusy(true); setError('');
    try { setSelectedProduct(await request(`/api/products/${p.id}`)); }
    catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function openCreateProduct() {
    setError(''); setBusy(true);
    try {
      const [cats, unitList] = await Promise.all([request('/api/catalogs/categories'), request('/api/catalogs/units')]);
      setCategories(cats); setUnits(unitList); setProductForm(initialProduct); setForm('createProduct');
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function createProduct() {
    const p = productForm;
    if (!p.code.trim() || !p.name.trim() || !Number(p.categoryId) || !Number(p.baseUnitId) || p.purchasePrice === '' || p.sellingPrice === '') {
      setError('Điền mã, tên, loại, đơn vị, giá nhập và giá bán.'); return;
    }
    setBusy(true); setError('');
    try {
      await request('/api/products', { method: 'POST', body: {
        code: p.code.trim(), name: p.name.trim(), categoryId: Number(p.categoryId), baseUnitId: Number(p.baseUnitId),
        purchasePrice: Number(p.purchasePrice), sellingPrice: Number(p.sellingPrice), trackExpiry: p.trackExpiry,
        description: null, imageUrl: null, weightKg: null, volumeM3: null,
      } });
      setForm(''); success('Đã tạo sản phẩm trong SQL Server.'); setRefreshIndex(x => x + 1);
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function changeProductStatus(p) {
    setBusy(true); setError('');
    try {
      const newStatus = p.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
      await request(`/api/products/${p.id}/status`, { method: 'PATCH', body: { status: newStatus, rowVersion: p.rowVersion } });
      setSelectedProduct(null); success(`Đã đổi trạng thái sản phẩm sang ${newStatus}.`); setRefreshIndex(x => x + 1);
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function createWarehouse() {
    const w = warehouseForm;
    if (!w.code.trim() || !w.name.trim() || !w.address.trim()) { setError('Mã kho, tên và địa chỉ là bắt buộc.'); return; }
    if (w.capacity !== '' && !(Number(w.capacity) > 0)) { setError('Sức chứa phải lớn hơn 0.'); return; }
    setBusy(true); setError('');
    try {
      const res = await request('/api/warehouses', { method: 'POST', body: {
        code: w.code.trim(), name: w.name.trim(), address: w.address.trim(), type: w.type,
        capacity: w.capacity === '' ? null : Number(w.capacity), capacityUnit: w.capacity === '' ? null : w.capacityUnit,
        notes: null,
      } });
      setForm(''); success(res?.assignmentRequired ? 'Tạo kho thành công. Quản trị viên cần gán kho cho tài khoản trên backend trước khi thấy kho trong danh sách.' : 'Đã tạo kho trong SQL Server.');
      setRefreshIndex(x => x + 1);
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function scan(value) {
    const code = String(value || '').trim();
    if (!code) { setError('Hãy quét hoặc nhập mã sản phẩm.'); return; }
    setCameraVisible(false); setScanCode(code); setBusy(true); setError(''); setScanned([]);
    try {
      const matches = await request(pathWithQuery('/api/catalogs/barcodes', { code }));
      setScanned(Array.isArray(matches) ? matches : []);
      if (!Array.isArray(matches) || matches.length === 0) setNotice('Không tìm thấy mã Barcode/QR được đăng ký trong database.');
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function completeReceipt() {
    const id = confirmReceipt;
    setConfirmReceipt(null); if (!id) return;
    setBusy(true); setError('');
    try {
      const result = await request(`/api/inbound-receipts/${id}/complete`, { method: 'POST' });
      success(result?.message || 'API đã xử lý hoàn thành phiếu nhập.');
      setReceipt(null); setRefreshIndex(x => x + 1);
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  async function changePassword() {
    if (passwords.next.length < 14 || passwords.next.length > 128) { setError('Mật khẩu mới phải dài 14–128 ký tự.'); return; }
    setBusy(true); setError('');
    try {
      await request('/api/auth/change-password', { method: 'POST', body: { currentPassword: passwords.current, newPassword: passwords.next } });
      setPasswords({ current: '', next: '' });
      logout('Đã đổi mật khẩu. Hãy đăng nhập lại bằng mật khẩu mới (JWT cũ đã bị vô hiệu hóa).');
    } catch (e) { fail(e); } finally { setBusy(false); }
  }
  const nav = id => {
    if (user?.mustChangePassword && id !== 'account') { setError('Bạn cần đổi mật khẩu trước khi tiếp tục.'); setTab('account'); return; }
    setTab(id); setForm(''); setWarehouse(null); setReceipt(null); setSelectedProduct(null); setNotice(''); setError('');
  };

  if (!token || !user) {
    if (forgotPasswordOpen) return <ForgotPasswordScreen initialIdentifier={login.username} onBackToLogin={() => setForgotPasswordOpen(false)} />;
    return <SafeAreaView style={{flex:1,backgroundColor:BRAND.mint}}>
    <StatusBar barStyle="dark-content" backgroundColor={BRAND.mint}/>
    <BrandAuthShell mode="api" onSwitchMode={onOpenDemo} onForgotPassword={() => setForgotPasswordOpen(true)} footer="Kết nối máy chủ do nhóm cấu hình · Đăng nhập an toàn">
      <BrandAuthField label="Tên đăng nhập" value={login.username} onChangeText={v => setLogin(s => ({...s,username:v}))} placeholder="Nhập tên đăng nhập" />
      <BrandAuthField label="Mật khẩu" secure value={login.password} onChangeText={v => setLogin(s => ({...s,password:v}))} placeholder="Nhập mật khẩu" />
      {error ? <BrandAuthNote error>{error}</BrandAuthNote> : null}
      <BrandAuthButton disabled={busy} title={busy?'Đang xử lý...':'Đăng nhập'} onPress={signIn}/>
      <View style={{marginTop:17,flexDirection:'row',alignItems:'center',gap:5}}><I name="shield-lock-outline" size={15} color={BRAND.blue}/><Txt color={BRAND.slate} size={10}>Xác thực JWT · Không lưu mật khẩu trên thiết bị</Txt></View>
      <Txt color={BRAND.slate} size={10} style={{marginTop:8}}>Máy chủ: {API_URL}</Txt>
    </BrandAuthShell>
  </SafeAreaView>;
  }

  const pageButton = (target, page, setter, current, total, size) => <Flex style={{ justifyContent: 'space-between', gap: 10, marginVertical: 14 }}>
    <Btn secondary small disabled={page <= 1} title="← Trước" onPress={() => setter(Math.max(1, page - 1))} />
    <Txt color={F.muted} size={12}>Trang {page} / {Math.max(1, Math.ceil((total || 0) / size))}</Txt>
    <Btn secondary small disabled={page * size >= (total || 0)} title="Tiếp →" onPress={() => setter(page + 1)} />
  </Flex>;
  const productRows = () => <>
    <Panel style={{padding:15}}>
      <Flex style={{gap:9, flexWrap:'wrap', alignItems:'flex-end'}}>
        <View style={{flexGrow:1,flexBasis:280}}><Input label="Tìm kiếm trong danh mục" value={productSearch} onChangeText={setProductSearch} placeholder="Tên, mã sản phẩm, mã vạch..." /></View>
        <View style={{paddingBottom:13}}><Btn small title="Áp dụng" icon="filter-variant" onPress={()=>{setProductPage(1);setAppliedSearch(productSearch.trim());}}/></View>
      </Flex>
    </Panel>
    {desktop ? <Panel style={{padding:0}}>
      <Flex style={{backgroundColor:F.surfaceAlt,padding:14,gap:12,borderTopLeftRadius:12,borderTopRightRadius:12}}>
        <View style={{width:108}}><Txt size={11} bold>MÃ SP</Txt></View>
        <View style={{flex:2}}><Txt size={11} bold>TÊN SẢN PHẨM</Txt></View>
        <View style={{flex:1}}><Txt size={11} bold>LOẠI</Txt></View>
        <View style={{width:95}}><Txt size={11} bold>ĐƠN VỊ</Txt></View>
        <View style={{width:116}}><Txt size={11} bold>GIÁ BÁN</Txt></View>
        <View style={{width:105}}><Txt size={11} bold>TRẠNG THÁI</Txt></View>
      </Flex>
      {(products.items||[]).map(p=><Pressable key={p.id} onPress={()=>loadProduct(p)} style={{padding:14,borderTopWidth:1,borderColor:F.line}}>
        <Flex style={{gap:12}}>
          <View style={{width:108}}><Txt bold size={12}>{p.code}</Txt></View>
          <View style={{flex:2}}><Txt bold size={13}>{p.name}</Txt><Txt size={11}>{p.trackExpiry?'Theo dõi HSD':'Không theo dõi HSD'}</Txt></View>
          <View style={{flex:1}}><Txt size={12}>{p.categoryName}</Txt></View>
          <View style={{width:95}}><Txt size={12}>{p.baseUnitName}</Txt></View>
          <View style={{width:116}}><Txt size={12} bold>{fmt(p.sellingPrice)} đ</Txt></View>
          <View style={{width:105}}><Tag text={p.status==='ACTIVE'?'Hoạt động':'Tạm dừng'}/></View>
        </Flex>
      </Pressable>)}
      {!products.items?.length?<Empty text="Chưa có dữ liệu sản phẩm trên API"/>:null}
    </Panel> : products.items?.length ? products.items.map(p => <Pressable key={p.id} onPress={() => loadProduct(p)}>
      <Panel><Flex style={{ gap: 10 }}><I name="package-variant" size={24} color={F.blue} /><View style={{ flex: 1 }}>
        <Txt size={11}>{p.code} · {p.categoryName} · {p.baseUnitName}</Txt>
        <Txt bold size={15}>{p.name}</Txt>
        <Txt size={12}>{fmt(p.sellingPrice)} đ · {p.trackExpiry ? 'Theo dõi HSD' : 'Không theo dõi HSD'}</Txt>
      </View><Tag text={p.status === 'ACTIVE' ? 'Hoạt động' : 'Tạm dừng'} /></Flex></Panel>
    </Pressable>) : <Empty />}
    {pageButton('products',productPage,setProductPage,productPage,products.total,20)}
  </>;

  const warehouseRows = () => <>
    {warehouses.length ? warehouses.map(w => <Pressable key={w.id} onPress={() => loadWarehouse(w)}>
      <Panel><Flex style={{ gap: 12 }}><I name={w.type === 'BAI' ? 'truck-cargo-container' : w.type === 'CUA_HANG' ? 'storefront' : 'warehouse'} size={24} color={F.green} />
        <View style={{ flex: 1 }}><Txt size={11} color={F.muted}>{w.code} · {w.type}</Txt><Txt bold size={15}>{w.name}</Txt><Txt color={F.muted} size={12}>{w.address}</Txt>
          <Txt color={F.muted} size={12}>Sức chứa: {w.capacity == null ? 'Chưa khai báo' : `${fmt(w.capacity)} ${w.capacityUnit || ''}`}</Txt></View>
        <I name="chevron-right" color={F.muted} />
      </Flex></Panel>
    </Pressable>) : <Empty text="Chưa có nơi lưu trữ được gán quyền. API lọc kho theo người dùng." />}
  </>;

  const receiptRows = () => <>
    {receipts.items?.length ? receipts.items.map(r => <Pressable key={r.id} onPress={() => loadReceipt(r)}>
      <Panel><Flex style={{ justifyContent: 'space-between' }}><Txt bold>{r.code}</Txt><Tag text={r.status} color={r.status === 'COMPLETED' ? F.green : F.blue} /></Flex>
        <Txt color={F.muted} size={12}>Kho: {r.warehouseName}</Txt>
        <Txt color={F.muted} size={12}>Nhà cung cấp: {r.supplierName}</Txt>
        <Txt color={F.muted} size={12}>Ngày tạo: {date(r.createdAt)}</Txt>
      </Panel>
    </Pressable>) : <Empty />}
    {pageButton('receipts', receiptPage, setReceiptPage, receiptPage, receipts.total, 20)}
  </>;

  const currentPage=MENU.find(m=>m.id===tab)?.label||'Tổng quan';
  const overview=tab==='dashboard'&&!form&&!warehouse&&!receipt&&!selectedProduct;
  const apiMenu=[
    {title:'Tổng quan',items:[{id:'dashboard',label:'Tổng quan',icon:'view-dashboard-outline',onPress:()=>nav('dashboard')}]},
    {title:'Danh mục',items:[{id:'products',label:'Sản phẩm',icon:'package-variant-closed',onPress:()=>nav('products')},
      {id:'warehouses',label:'Nơi lưu trữ',icon:'warehouse',onPress:()=>nav('warehouses')}]},
    {title:'Nghiệp vụ',items:[{id:'receipts',label:'Nhập hàng',icon:'clipboard-list-outline',onPress:()=>nav('receipts')},
      {id:'barcode',label:'Quét Barcode / QR',icon:'barcode-scan',onPress:()=>nav('barcode')},
      {id:'transfer',label:'Điều chuyển (chờ API)',icon:'swap-horizontal',disabled:true},
      {id:'inventory',label:'Kiểm kê (chờ API)',icon:'clipboard-check-outline',disabled:true}]},
    {title:'Hệ thống',items:[{id:'account',label:'Tài khoản',icon:'account-circle-outline',onPress:()=>nav('account')}]},
  ];
  return <UiThemeProvider mode="light"><SafeAreaView style={{ flex: 1, backgroundColor:F.bg }}>
    <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
    <View style={{flex:1,maxWidth:1440,width:"100%",alignSelf:"center",backgroundColor:F.bg,flexDirection:'row'}}>
      {desktop?<View style={{width:236}}><OverviewSidebar groups={apiMenu} activeId={tab} onLogout={()=>logout()} footer={API_URL}/></View>:null}
      <View style={{flex:1}}>
        <OverviewTopbar desktop={desktop} activeLabel={currentPage} userName={user.fullName||user.username} onRefresh={()=>setRefreshIndex(x=>x+1)} onAccount={()=>nav('account')}/>
      <ScrollView key={tab} style={{backgroundColor:F.bg}} keyboardShouldPersistTaps="handled" contentContainerStyle={{ padding: desktop?24:14, width: '100%', maxWidth:1300, alignSelf: 'center', paddingBottom: 90 }}>
        {!overview?<WorkspaceRibbon section={currentPage} subtitle="STORIX Retail Logistics · Dữ liệu từ API theo quyền tài khoản"/>:null}
        {notice ? <Banner>{notice}</Banner> : null}
        {error ? <Banner error>{error}</Banner> : null}
        {loading || busy ? <ActivityIndicator color={F.green} size="large" style={{ marginVertical: 7 }} /> : null}
        {form === 'createProduct' ? <>
          <Flex style={{ justifyContent: 'space-between', marginBottom: 14 }}><Txt size={22} bold>Thêm sản phẩm vào API</Txt><Btn secondary small title="Hủy" onPress={() => setForm('')} /></Flex>
          <Panel>
            <Input label="Mã sản phẩm *" value={productForm.code} onChangeText={v => setProductForm(s => ({ ...s, code: v }))} />
            <Input label="Tên sản phẩm *" value={productForm.name} onChangeText={v => setProductForm(s => ({ ...s, name: v }))} />
            <SelectItem label="Danh mục" items={categories.map(x => ({ id: String(x.id), label: x.name }))} value={productForm.categoryId} onChange={v => setProductForm(s => ({ ...s, categoryId: v }))} />
            <SelectItem label="Đơn vị cơ sở" items={units.map(x => ({ id: String(x.id), label: x.name }))} value={productForm.baseUnitId} onChange={v => setProductForm(s => ({ ...s, baseUnitId: v }))} />
            <Input numeric label="Giá nhập *" value={productForm.purchasePrice} onChangeText={v => setProductForm(s => ({ ...s, purchasePrice: v }))} />
            <Input numeric label="Giá bán *" value={productForm.sellingPrice} onChangeText={v => setProductForm(s => ({ ...s, sellingPrice: v }))} />
            <Flex style={{ gap: 9, marginBottom: 14 }}><Btn small secondary title={productForm.trackExpiry ? '☑ Theo dõi hạn sử dụng' : '□ Theo dõi hạn sử dụng'} onPress={() => setProductForm(s => ({ ...s, trackExpiry: !s.trackExpiry }))} /></Flex>
            <Btn disabled={busy} title="Ghi sản phẩm vào SQL Server" icon="content-save-outline" onPress={createProduct} />
          </Panel>
        </> : form === 'createWarehouse' ? <>
          <Flex style={{ justifyContent: 'space-between', marginBottom: 14 }}><Txt size={22} bold>Thêm nơi lưu trữ</Txt><Btn small secondary title="Hủy" onPress={() => setForm('')} /></Flex>
          <Panel><Input label="Mã kho *" value={warehouseForm.code} onChangeText={v => setWarehouseForm(s => ({ ...s, code: v }))} />
            <Input label="Tên nơi lưu trữ *" value={warehouseForm.name} onChangeText={v => setWarehouseForm(s => ({ ...s, name: v }))} />
            <SelectItem label="Loại" items={[{ id: 'KHO', label: 'Kho' }, { id: 'BAI', label: 'Bãi' }, { id: 'CUA_HANG', label: 'Cửa hàng' }]} value={warehouseForm.type} onChange={v => setWarehouseForm(s => ({ ...s, type: v }))} />
            <Input label="Địa chỉ *" value={warehouseForm.address} onChangeText={v => setWarehouseForm(s => ({ ...s, address: v }))} />
            <Input label="Sức chứa (để trống nếu chưa có)" numeric value={warehouseForm.capacity} onChangeText={v => setWarehouseForm(s => ({ ...s, capacity: v }))} />
            {warehouseForm.capacity !== '' ? <SelectItem label="Đơn vị sức chứa" items={[{ id: 'KG', label: 'KG' }, { id: 'M3', label: 'M³' }]} value={warehouseForm.capacityUnit} onChange={v => setWarehouseForm(s => ({ ...s, capacityUnit: v }))} /> : null}
            <Banner>Tạo kho mới có thể cần quản trị viên gán quyền truy cập trong database.</Banner>
            <Btn disabled={busy} title="Tạo kho trên server" icon="content-save-outline" onPress={createWarehouse} />
          </Panel>
        </> : selectedProduct ? <>
          <Btn secondary small title="← Danh sách sản phẩm" onPress={() => setSelectedProduct(null)} />
          <Panel style={{ marginTop: 16 }}><Txt size={12} color={F.muted}>{selectedProduct.code}</Txt><Txt size={22} bold>{selectedProduct.name}</Txt>
            <Txt color={F.muted}>Loại: {selectedProduct.categoryName}, đơn vị: {selectedProduct.baseUnitName}</Txt>
            <Txt>Giá bán: {fmt(selectedProduct.sellingPrice)} đ</Txt>
            <Txt>Trạng thái: {selectedProduct.status}</Txt>
            <Txt color={F.muted} size={11}>RowVersion: {selectedProduct.rowVersion ? 'Đã nhận từ API' : 'Chưa có'}</Txt>
            <View style={{ marginTop: 14 }}><Btn disabled={busy} secondary title={selectedProduct.status === 'ACTIVE' ? 'Ngừng kinh doanh' : 'Kích hoạt lại'} onPress={() => changeProductStatus(selectedProduct)} /></View>
          </Panel>
        </> : warehouse ? <>
          <Flex style={{ justifyContent: 'space-between', marginBottom: 13 }}><Txt size={21} bold style={{ flex: 1 }}>{warehouse.name}</Txt><Btn small secondary title="← Kho" onPress={() => setWarehouse(null)} /></Flex>
          <Panel><Txt color={F.muted} size={12}>{warehouse.code} • {warehouse.address}</Txt>
            <Txt bold style={{ marginTop: 8 }}>Tồn kho: {fmt(stocks.total)} dòng tồn theo vị trí / lô</Txt>
            <Txt size={12} color={F.muted}>Dữ liệu lấy trực tiếp từ /api/warehouses/{warehouse.id}/stock.</Txt>
          </Panel>
          <Section title={`Vị trí (${positions.length})`} />
          {positions.length ? positions.map(pos => <Panel key={pos.id}>
            <Flex style={{ justifyContent: 'space-between' }}><Txt bold>{pos.code} · {pos.name}</Txt><Tag text={pos.status} color={pos.status === 'ACTIVE' ? F.green : F.red} /></Flex>
            <Txt color={F.muted} size={12}>Cấp: {pos.level} • Kiểu: {pos.type}</Txt>
          </Panel>) : <Empty text="Kho này chưa có vị trí hoặc bạn chưa được cấp quyền xem." />}
          <Section title="Chi tiết tồn kho theo vị trí / lô" />
          {stocks.items?.length ? stocks.items.map((s, idx) => <Panel key={s.stockId || idx}>
            <Txt bold>{s.productCode} · {s.productName}</Txt>
            <Txt color={F.muted} size={12}>Lô: {s.lotCode} • Vị trí: {s.positionCode} ({s.positionName})</Txt>
            <Txt color={F.muted} size={12}>Hạn dùng: {date(s.expiryDate)}</Txt>
            <Flex style={{ gap: 12, marginTop: 8, flexWrap: 'wrap' }}>
              <Tag text={`Tốt: ${fmt(s.goodQuantity)}`} /><Tag text={`Giữ: ${fmt(s.reservedQuantity)}`} color={F.blue} bg="#EEF1FF" />
              <Tag text={`Hỏng: ${fmt(s.damagedQuantity)}`} color={F.red} bg="#FEF1F3" /><Tag text={`Khả dụng: ${fmt(s.availableGoodQuantity)}`} />
            </Flex>
          </Panel>) : <Empty text="Chưa có dòng tồn kho trong vị trí của kho này." />}
          {pageButton('stock', stockPage, p => loadWarehouse(warehouse, p), stockPage, stocks.total, 50)}
        </> : receipt ? <>
          <Btn secondary small title="← Danh sách phiếu" onPress={() => setReceipt(null)} />
          <Panel style={{ marginTop: 16 }}><Txt size={23} bold>{receipt.receipt?.code}</Txt>
            <Tag text={receipt.receipt?.status || ''} color={F.blue} />
            <Txt size={12} color={F.muted}>Kho nhận: {receipt.receipt?.warehouseName}</Txt>
            <Txt size={12} color={F.muted}>Nhà cung cấp: {receipt.receipt?.supplierName}</Txt>
            <Txt size={12} color={F.muted}>Dự kiến: {date(receipt.receipt?.expectedDate)}</Txt>
          </Panel>
          <Section title="Hàng trong phiếu nhập" />
          {(receipt.lines || []).map((l, i) => <Panel key={l.id || i}>
            <Txt bold>{l.productCode} · {l.productName}</Txt>
            <Txt color={F.muted} size={12}>Lô: {l.lotCode || '—'} • Dự kiến: {fmt(l.expectedTransactionQuantity)}</Txt>
            <Txt color={F.muted} size={12}>Nhận tốt: {fmt(l.receivedGoodBaseQuantity)} • Hỏng: {fmt(l.receivedDamagedBaseQuantity)} • Từ chối: {fmt(l.rejectedBaseQuantity)}</Txt>
          </Panel>)}
          <Section title="Phân bổ vào vị trí" />
          {(receipt.allocations || []).map((a, i) => <Panel key={a.id || i}>
            <Txt bold>{a.positionCode} · {a.positionName}</Txt><Txt color={F.muted}>Số lượng: {fmt(a.baseQuantity)} • {a.condition}</Txt>
          </Panel>)}
          <Banner>Thao tác Hoàn thành sẽ gọi stored procedure thật trên SQL Server và có thể thay đổi tồn kho. Cần xác nhận trước khi thực hiện.</Banner>
          <Btn disabled={busy} title="Hoàn thành phiếu nhập (API thật)" icon="check-circle-outline" onPress={() => setConfirmReceipt(receipt.receipt?.id)} />
          {confirmReceipt ? <Panel style={{ marginTop: 14, backgroundColor: F.surfaceAlt }}>
            <Txt bold>Xác nhận cập nhật tồn kho thật?</Txt><Txt color={F.muted} size={12}>Phiếu {receipt.receipt?.code} sẽ được xử lý trên SQL Server.</Txt>
            <Flex style={{ gap: 12, marginTop: 14 }}><Btn small danger title="Hủy" onPress={() => setConfirmReceipt(null)} /><Btn small title="Xác nhận hoàn thành" onPress={completeReceipt} /></Flex>
          </Panel> : null}
        </> : <>
          {tab === 'dashboard' ? <OverviewDashboard
            data={apiOverview({products,warehouses,receipts})}
            screenWidth={width}
            onNavigate={route=>{if(route==='products')nav('products');else if(route==='places')nav('warehouses');else nav('receipts');}}
            onOpenQueue={row=>{nav('receipts');if(row.raw)loadReceipt(row.raw);}}
            onOpenCapacity={item=>{nav('warehouses');if(item?.id)loadWarehouse(item);}}
          /> : null}
          {tab === 'products' ? <>
            <Flex style={{ justifyContent: 'space-between', marginBottom: 14 }}><View style={{ flex: 1 }}><Txt size={24} bold>Sản phẩm</Txt><Txt size={12} color={F.muted}>Tổng {fmt(products.total)} sản phẩm trên server</Txt></View>
              <Btn small title="Thêm" icon="plus" onPress={openCreateProduct} /></Flex>
            {productRows()}
          </> : null}
          {tab === 'warehouses' ? <>
            <Flex style={{ justifyContent: 'space-between', marginBottom: 14 }}><View style={{ flex: 1 }}><Txt size={24} bold>Kho, bãi và cửa hàng</Txt><Txt color={F.muted} size={12}>Chỉ các nơi được gán quyền</Txt></View><Btn small title="Thêm" icon="plus" onPress={() => { setWarehouseForm(initialWarehouse); setForm('createWarehouse'); }} /></Flex>
            {warehouseRows()}
          </> : null}
          {tab === 'receipts' ? <><Txt size={24} bold>Phiếu nhập</Txt><Txt color={F.muted} size={12} style={{ marginBottom: 15 }}>Xem chi tiết và hoàn thành những phiếu đã đủ điều kiện</Txt>{receiptRows()}</> : null}
          {tab === 'barcode' ? <>
            <Txt size={24} bold>Quét Barcode / QR</Txt><Txt color={F.muted} size={12} style={{ marginBottom: 14 }}>Tìm mã đã được đăng ký trong bảng MA_VACH của SQL Server.</Txt>
            <Panel><Input label="Mã sản phẩm" value={scanCode} onChangeText={setScanCode} placeholder="VD: 8936000000001" />
              <Flex style={{ gap: 9, flexWrap: 'wrap' }}><Btn small title="Tra mã" icon="magnify" onPress={() => scan(scanCode)} /><Btn small secondary title="Bật camera" icon="camera" onPress={() => setCameraVisible(!cameraVisible)} /></Flex>
              {cameraVisible ? <View style={{ marginTop: 18 }}><ScanCamera onScanned={scan} /></View> : null}
            </Panel>
            {scanned.map((item, i) => <Panel key={`${item.code}-${i}`}><Txt size={12} color={F.muted}>{item.code} • {item.type}</Txt><Txt size={16} bold>{item.productName}</Txt><Txt color={F.blue} size={12}>Mã sản phẩm: {item.productCode} · ID: {item.productId}</Txt></Panel>)}
          </> : null}
          {tab === 'account' ? <>
            <Txt size={24} bold>Tài khoản</Txt><Panel><Txt bold size={18}>{user.fullName}</Txt><Txt color={F.muted}>@{user.username}</Txt>
              <Txt>Vai trò trên backend: {user.role}</Txt><Txt color={F.muted} size={12}>Quyền thao tác được API kiểm tra bằng JWT + permission. Không giả lập quyền admin trên giao diện.</Txt></Panel>
            {user.mustChangePassword ? <Banner error>Tài khoản được yêu cầu đổi mật khẩu. Chỉ sử dụng phần đổi mật khẩu bên dưới.</Banner> : null}
            <Section title="Đổi mật khẩu" />
            <Panel><Input label="Mật khẩu hiện tại" secureTextEntry value={passwords.current} onChangeText={v => setPasswords(s => ({ ...s, current: v }))} />
              <Input label="Mật khẩu mới (14–128 ký tự)" secureTextEntry value={passwords.next} onChangeText={v => setPasswords(s => ({ ...s, next: v }))} />
              <Btn disabled={busy} title="Đổi mật khẩu thật" onPress={changePassword} icon="lock-reset" /></Panel>
            <Btn secondary title="Đăng xuất" icon="logout" onPress={() => logout()} />
            <View style={{ height: 12 }} /><ModeLine onOpenDemo={onOpenDemo} />
          </> : null}
        </>}
      </ScrollView>
    {!desktop ? <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ maxHeight: 72, backgroundColor:'#FFFFFF', borderTopColor:F.line, borderTopWidth: 1 }} contentContainerStyle={{ alignItems: 'center', paddingHorizontal: 7 }}>
      {MENU.map(m => <Pressable key={m.id} onPress={() => nav(m.id)} style={{ minWidth: 76, paddingHorizontal: 9, paddingVertical: 9, alignItems: 'center', gap: 4 }}>
        <I name={m.icon} size={22} color={tab===m.id?F.blue:F.muted} />
        <Txt size={10} color={tab===m.id?F.blue:F.muted} bold={tab === m.id}>{m.label}</Txt>
      </Pressable>)}
    </ScrollView> : null}
    </View>
    </View>
  </SafeAreaView></UiThemeProvider>;
}
