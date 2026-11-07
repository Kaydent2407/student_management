export const ROLES = [
  {id:'admin',label:'Quản trị viên',name:'Nguyễn Minh Anh'},
  {id:'manager',label:'Quản lý kho',name:'Trần Quốc Bảo'},
  {id:'staff',label:'Nhân viên kho',name:'Lê Hoàng Nam'},
  {id:'store',label:'Nhân viên cửa hàng',name:'Phạm Ngọc Hà'},
];
export const TYPES = [
  {id:'warehouse',label:'Kho hàng',icon:'warehouse'},
  {id:'yard',label:'Bãi lưu trữ',icon:'truck-cargo-container'},
  {id:'store',label:'Cửa hàng',icon:'storefront-outline'},
];
export const KINDS = [
  {id:'IN',label:'Nhập kho',icon:'arrow-down-bold-box-outline',tint:'#079669'},
  {id:'OUT',label:'Xuất kho',icon:'arrow-up-bold-box-outline',tint:'#EA7D36'},
  {id:'TRANSFER',label:'Điều chuyển',icon:'swap-horizontal',tint:'#6366F1'},
];
const products = [
  {id:'p1',barcode:'8936000000001',status:'ACTIVE',sku:'SP-001',name:'Động cơ điện 3 pha 2.2kW',category:'Thiết bị',unit:'cái',minStock:15,price:2850000,icon:'engine-outline'},
  {id:'p2',barcode:'8936000000002',status:'ACTIVE',sku:'SP-002',name:'Bộ vòng bi công nghiệp 6205',category:'Phụ tùng',unit:'bộ',minStock:35,price:235000,icon:'cog-outline'},
  {id:'p3',barcode:'8936000000003',status:'ACTIVE',sku:'SP-003',name:'Thùng nhựa công nghiệp 60L',category:'Vật tư',unit:'thùng',minStock:30,price:185000,icon:'package-variant-closed'},
  {id:'p4',barcode:'8936000000004',status:'ACTIVE',sku:'SP-004',name:'Máy bơm nước ly tâm',category:'Thiết bị',unit:'cái',minStock:12,price:4250000,icon:'water-pump'},
  {id:'p5',barcode:'8936000000005',status:'ACTIVE',sku:'SP-005',name:'Dây cáp điện CV 2.5',category:'Vật tư',unit:'cuộn',minStock:25,price:920000,icon:'cable-data'},
  {id:'p6',barcode:'8936000000006',status:'ACTIVE',sku:'SP-006',name:'Pallet nhựa 1200 × 1000',category:'Kho vận',unit:'cái',minStock:40,price:520000,icon:'view-grid-outline'},
  {id:'p7',barcode:'8936000000007',status:'ACTIVE',sku:'SP-007',name:'Bộ cảm biến nhiệt độ',category:'Linh kiện',unit:'bộ',minStock:20,price:690000,icon:'thermometer-lines'},
  {id:'p8',barcode:'8936000000008',status:'ACTIVE',sku:'SP-008',name:'Van bi inox DN25',category:'Phụ tùng',unit:'cái',minStock:22,price:375000,icon:'pipe-valve'},
  {id:'p9',barcode:'8936000000009',status:'ACTIVE',sku:'SP-009',name:'Xe đẩy hàng 4 bánh',category:'Kho vận',unit:'cái',minStock:8,price:1680000,icon:'cart-outline'},
];
const places = [
  {id:'l1',code:'KHO-HCM',name:'Kho trung tâm TP.HCM',type:'warehouse',address:'Quận Bình Tân, TP.HCM',capacity:600,enabled:true,slots:['Khu A · Dãy 01 · Kệ 02 · Tầng 1 · Ô 03','Khu B · Dãy 02 · Kệ 01 · Tầng 2 · Ô 01']},
  {id:'l2',code:'KHO-BD',name:'Kho Bình Dương',type:'warehouse',address:'Dĩ An, TP.HCM',capacity:350,enabled:true,slots:['Khu A · Dãy 01 · Kệ 03 · Tầng 1 · Ô 02']},
  {id:'l3',code:'BAI-CL',name:'Bãi lưu trữ Cát Lái',type:'yard',address:'Phường Cát Lái, TP.HCM',capacity:450,enabled:true,slots:['Khu ngoài trời · Dãy C1 · Vị trí 04']},
  {id:'l4',code:'BAI-LA',name:'Bãi lưu trữ Long An',type:'yard',address:'Khu vực Bến Lức, Tây Ninh',capacity:400,enabled:true,slots:['Khu có mái · Dãy L2 · Vị trí 09']},
  {id:'l5',code:'CH-Q1',name:'Cửa hàng trung tâm',type:'store',address:'Quận 1, TP.HCM',capacity:150,enabled:true,slots:['Khu trưng bày · Kệ A1']},
  {id:'l6',code:'CH-TD',name:'Cửa hàng Thủ Đức',type:'store',address:'TP. Thủ Đức, TP.HCM',capacity:130,enabled:true,slots:['Kho phụ · Kệ B2']},
];
const stockPairs = [
  ['p1','l1',20],['p1','l2',8],['p1','l5',2],
  ['p2','l1',40],['p2','l2',11],['p2','l6',7],
  ['p3','l1',65],['p3','l3',80],['p3','l4',55],
  ['p4','l1',5],['p4','l2',4],
  ['p5','l1',12],['p5','l5',5],
  ['p6','l1',45],['p6','l3',110],['p6','l4',60],
  ['p7','l1',9],['p7','l6',4],
  ['p8','l1',42],['p8','l2',19],
  ['p9','l1',4],['p9','l3',3],
];
const timestamp = (days) => new Date(Date.now()-days*86400000).toISOString();
export const makeSeed = () => ({
  products:products.map(x=>({...x})),
  places:places.map(x=>({...x,slots:[...x.slots]})),
  stocks:stockPairs.map(([productId,placeId,qty])=>({productId,placeId,qty})),
  movements:[
    {id:'PX-2026-1003',kind:'OUT',productId:'p2',qty:8,fromId:'l1',toId:null,status:'DONE',note:'Xuất cho khách hàng',date:timestamp(.4),by:'Quản lý kho'},
    {id:'PN-2026-1002',kind:'IN',productId:'p6',qty:40,fromId:null,toId:'l3',status:'DONE',note:'Hàng nhập từ nhà cung cấp',date:timestamp(1),by:'Quản lý kho'},
    {id:'DC-2026-1001',kind:'TRANSFER',productId:'p3',qty:16,fromId:'l1',toId:'l5',status:'DONE',note:'Bổ sung cửa hàng',date:timestamp(2),by:'Quản lý kho'},
  ],
  requests:[{id:'YC-1001',productId:'p7',storeId:'l6',fromId:'l1',qty:8,status:'PENDING',date:timestamp(.2),note:'Bổ sung hàng cho cửa hàng'}],
  counts:[],
  role:'admin',
  readAlerts:[],
  slotAssignments:{},
  suppliers:[
    {id:'ncc1',code:'NCC-001',name:'Công ty Thiết bị An Phát',phone:'028 3822 0101',address:'TP.HCM',email:'contact@anphat.example'},
    {id:'ncc2',code:'NCC-002',name:'Vật tư Công nghiệp Việt',phone:'0274 377 0202',address:'Bình Dương',email:'kinhdoanh@vat-tu.example'},
    {id:'ncc3',code:'NCC-003',name:'Kho vận Đại Phát',phone:'028 3866 0303',address:'TP.HCM',email:'hello@daiphat.example'},
  ],
  lots:[
    {id:'LOT-260901',productId:'p1',supplierId:'ncc1',manufactured:'2026-09-01',expires:'2029-09-01',received:'2026-09-19',receiptId:'PN-2026-0901',quality:'GOOD'},
    {id:'LOT-260902',productId:'p2',supplierId:'ncc2',manufactured:'2026-08-01',expires:'2027-01-20',received:'2026-09-27',receiptId:'PN-2026-0902',quality:'GOOD'},
    {id:'LOT-260903',productId:'p3',supplierId:'ncc3',manufactured:'2026-05-05',expires:'2026-11-05',received:'2026-06-01',receiptId:'PN-2026-0903',quality:'GOOD'},
    {id:'LOT-260904',productId:'p4',supplierId:'ncc1',manufactured:'2026-07-01',expires:'2028-07-01',received:'2026-08-06',receiptId:'PN-2026-0904',quality:'GOOD'},
    {id:'LOT-260905',productId:'p5',supplierId:'ncc2',manufactured:'2026-01-15',expires:'2026-10-05',received:'2026-02-01',receiptId:'PN-2026-0905',quality:'DAMAGED'},
  ],
  seq:1004,
});
