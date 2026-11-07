// Chỉ sử dụng dữ liệu từ API hoặc bộ nhớ demo thực sự. Không tạo KPI/biểu đồ ngẫu nhiên.
const finalStatuses = new Set(['DONE', 'COMPLETED', 'COMPLETE', 'HOAN_THANH', 'DA_HOAN_THANH', 'FINISHED']);
const pendingStatuses = new Set(['DRAFT', 'PENDING', 'APPROVED', 'WAITING', 'SUBMITTED', 'CHO_DUYET', 'DA_DUYET', 'IN_TRANSIT', 'PROCESSING']);
export const completed = value => finalStatuses.has(String(value || '').trim().toUpperCase());
export const pendingStatus = value => pendingStatuses.has(String(value || '').trim().toUpperCase());
const n = value => Number.isFinite(Number(value)) ? Number(value) : 0;
const nonneg = value => Math.max(0, n(value));
const dateKey = value => {const date = new Date(value); return Number.isNaN(date.getTime()) ? null : `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`};
export function lastSevenDays(now = new Date()) {
  const base = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Array.from({length:7}, (_,i) => { const date = new Date(base); date.setDate(base.getDate()-6+i); return {key:dateKey(date),label:`${String(date.getDate()).padStart(2,'0')}/${String(date.getMonth()+1).padStart(2,'0')}`,inbound:0,outbound:null}; });
}
const byRecent = list => [...list].sort((a,b)=>new Date(b.createdAt || b.date || 0)-new Date(a.createdAt || a.date || 0));
export function demoOverview(state, {scopePlaces,alerts,lowProducts,placeStock,stockOf,now=new Date()}) {
  const visible = scopePlaces || state.places || [];
  const visibleSet = new Set(visible.map(p=>p.id));
  const movements = (state.movements||[]).filter(m => visibleSet.has(m.fromId)||visibleSet.has(m.toId));
  const pends = byRecent(movements.filter(m=>pendingStatus(m.status)).map(m=>({id:m.id,kind:m.kind==='IN'?'Nhập hàng':m.kind==='OUT'?'Xuất hàng':'Điều chuyển',placeName:visible.find(p=>p.id===m.fromId||p.id===m.toId)?.name||'Kho hàng',status:m.status,createdAt:m.date,route:'flows'})));
  const reqs = byRecent((state.requests||[]).filter(r=>pendingStatus(r.status)&&visibleSet.has(r.storeId)).map(r=>({id:r.id,kind:'Bổ sung hàng',placeName:visible.find(p=>p.id===r.storeId)?.name||'Cửa hàng',status:r.status,createdAt:r.date,route:'requests'})));
  const queue = byRecent([...pends,...reqs]);
  const weekly = lastSevenDays(now).map(d=>({...d,outbound:0}));
  for(const m of movements.filter(m=>completed(m.status))){const day=weekly.find(x=>x.key===dateKey(m.date));if(!day)continue;if(m.kind==='IN')day.inbound++;if(m.kind==='OUT')day.outbound++;}
  const capacities=visible.map(place=>{const used=nonneg(placeStock(state,place.id));const capacity=nonneg(place.capacity);return {id:place.id,name:place.name,used,capacity,percent:capacity?Math.round(used/capacity*100):null,unit:'đv',status:place.enabled===false?'Tạm khóa':'Hoạt động'};});
  const lowest=(lowProducts(state)||[]).length;
  return {source:'demo',productCount:(state.products||[]).length, pendingCount:queue.length, lowCount:lowest, transferringCount:movements.filter(m=>m.status==='IN_TRANSIT').length,
    queue:queue.slice(0,6), alerts:(alerts||[]).slice(0,5), capacities:capacities.slice(0,3), weekly, totalInbound:movements.filter(m=>completed(m.status)&&m.kind==='IN').length, totalOutbound:movements.filter(m=>completed(m.status)&&m.kind==='OUT').length,
    scopeLabel:`${visible.length} nơi lưu trữ · Dữ liệu mô phỏng`, note:'Số liệu từ dữ liệu demo trên thiết bị; sức chứa tính theo đơn vị tham khảo.'};
}
export function apiOverview({products={},warehouses=[],receipts={},now=new Date()}) {
  const list=Array.isArray(receipts.items)?receipts.items:[];
  const latestPending=byRecent(list.filter(r=>!completed(r.status)&&!['CANCELLED','REJECTED','HUY'].includes(String(r.status||'').toUpperCase())));
  const weekly=lastSevenDays(now); // Xuất kho chưa có endpoint, không thể ghi là 0.
  for(const r of list.filter(x=>completed(x.status))){const day=weekly.find(x=>x.key===dateKey(r.createdAt));if(day)day.inbound++;}
  return {source:'api',productCount:products.total??null,pendingCount:latestPending.length,lowCount:null,transferringCount:null,
    queue:latestPending.slice(0,6).map(r=>({id:r.code||`PN-${r.id}`,kind:'Nhập hàng',placeName:r.warehouseName||'—',status:r.status,createdAt:r.createdAt,route:'receipts',raw:r})), alerts:[],
    capacities:(warehouses||[]).slice(0,3).map(w=>({id:w.id,name:w.name||w.code||'Kho hàng',capacity:w.capacity===null||w.capacity===undefined?null:nonneg(w.capacity),used:null,percent:null,unit:w.capacityUnit||'',status:w.status||''})),
    weekly,totalInbound:list.filter(r=>completed(r.status)).length,totalOutbound:null, scopeLabel:`${warehouses.length} nơi được phân quyền · API thật`,
    note:'Các số liệu chưa có API (xuất kho, điều chuyển, tồn thấp, sức chứa đã dùng, cảnh báo) hiển thị “—”. Phiếu chờ và biểu đồ chỉ tính các phiếu nhập trong trang dữ liệu API đang tải.'};
}
