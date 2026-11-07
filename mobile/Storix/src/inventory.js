export const stockOf = (state,productId,placeId=null) => (state.stocks||[]).filter(s=>s.productId===productId&&(placeId===null||s.placeId===placeId)).reduce((a,s)=>a+Number(s.qty||0),0);
export const placeStock = (state,placeId) => (state.stocks||[]).filter(s=>s.placeId===placeId).reduce((a,s)=>a+Number(s.qty||0),0);
export const transitOf = (state,productId) => (state.movements||[]).filter(m=>m.kind==='TRANSFER'&&m.status==='IN_TRANSIT'&&m.productId===productId).reduce((a,m)=>a+m.qty,0);
export const totalValue = (state)=>state.products.reduce((a,p)=>a+stockOf(state,p.id)*Number(p.price||0),0);
export const lowProducts = (state)=>state.products.filter(p=>stockOf(state,p.id)<Number(p.minStock||0));
export const uid = (prefix='ID')=>`${prefix}-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).slice(2,6).toUpperCase()}`;
export function changeStock(stocks,productId,placeId,delta){
  const copy=stocks.map(s=>({...s}));
  const idx=copy.findIndex(s=>s.productId===productId&&s.placeId===placeId);
  if(idx===-1){if(delta<0)throw Error('Tồn kho không đủ.');if(delta>0)copy.push({productId,placeId,qty:delta});}
  else {const next=copy[idx].qty+delta;if(next<0)throw Error('Tồn kho không đủ để thực hiện.');if(next===0)copy.splice(idx,1);else copy[idx].qty=next;}
  return copy;
}
export function createMovement(state,form,by='Nhân viên'){
  const {kind,productId,qty,fromId,toId,note}=form;
  const n=Number(qty);
  if(!['IN','OUT','TRANSFER'].includes(kind))throw Error('Loại phiếu không hợp lệ.');
  if(!state.products.some(p=>p.id===productId&&p.status!=='INACTIVE'))throw Error('Sản phẩm không tồn tại hoặc đang ngừng kinh doanh.');
  if(!Number.isInteger(n)||n<=0)throw Error('Số lượng phải là số nguyên lớn hơn 0.');
  if(kind!=='IN'&&!state.places.some(p=>p.id===fromId))throw Error('Vui lòng chọn nơi xuất hợp lệ.');
  if(kind!=='OUT'&&!state.places.some(p=>p.id===toId&&p.enabled))throw Error('Vui lòng chọn nơi nhận hợp lệ.');
  if(kind==='TRANSFER'&&fromId===toId)throw Error('Nơi xuất và nơi nhận phải khác nhau.');
  const target=state.places.find(p=>p.id===toId);
  const slotIndex=kind==='OUT'?null:Math.max(0,Number(form.slotIndex||0));
  if(target?.slots?.length){
    if(!Number.isInteger(slotIndex)||slotIndex>=target.slots.length)throw Error('Vị trí nhận không hợp lệ.');
    if((target.slotLocks||[]).includes(slotIndex))throw Error('Vị trí nhận đang bị khóa.');
  }
  const code={IN:'PN',OUT:'PX',TRANSFER:'DC'}[kind];
  const movement={id:uid(code),kind,productId,qty:n,fromId:kind==='IN'?null:fromId,toId:kind==='OUT'?null:toId,status:'DRAFT',slotIndex,note:note||'',date:new Date().toISOString(),by};
  return {...state,movements:[movement,...state.movements]};
}
export function advanceMovement(state,id){
  const m=state.movements.find(x=>x.id===id);
  if(!m)throw Error('Không tìm thấy phiếu.');
  if(['DONE','CANCELLED'].includes(m.status))throw Error('Phiếu đã kết thúc.');
  let stocks=state.stocks;let nextStatus;let slotAssignments=state.slotAssignments||{};
  if(m.status==='DRAFT'){
    if(m.kind==='TRANSFER'){
      if(!state.places.some(p=>p.id===m.toId&&p.enabled))throw Error('Nơi nhận đang bị khóa.');
      stocks=changeStock(stocks,m.productId,m.fromId,-m.qty);
      nextStatus='IN_TRANSIT';
    } else {
      if(m.kind==='OUT'&&stockOf(state,m.productId,m.fromId)<m.qty)throw Error('Không đủ tồn kho để duyệt phiếu xuất.');
      nextStatus='APPROVED';
    }
  } else if(m.status==='APPROVED'){
    if(m.kind==='IN'&&!state.places.some(p=>p.id===m.toId&&p.enabled))throw Error('Nơi nhận đang bị khóa.');
    if(m.kind==='IN'){
      const p=state.places.find(x=>x.id===m.toId);
      if((p?.slotLocks||[]).includes(m.slotIndex||0))throw Error('Vị trí nhận đang bị khóa.');
    }
    stocks=changeStock(stocks,m.productId,m.kind==='IN'?m.toId:m.fromId,m.kind==='IN'?m.qty:-m.qty);
    if(m.kind==='IN')slotAssignments={...slotAssignments,[m.productId+'|'+m.toId]:m.slotIndex||0};
    nextStatus='DONE';
  } else if(m.status==='IN_TRANSIT'){
    if(!state.places.some(p=>p.id===m.toId&&p.enabled))throw Error('Nơi nhận đang bị khóa.');
    const p=state.places.find(x=>x.id===m.toId);
    if((p?.slotLocks||[]).includes(m.slotIndex||0))throw Error('Vị trí nhận đang bị khóa.');
    stocks=changeStock(stocks,m.productId,m.toId,m.qty);
    slotAssignments={...slotAssignments,[m.productId+'|'+m.toId]:m.slotIndex||0};
    nextStatus='DONE';
  } else throw Error('Trạng thái không được hỗ trợ.');
  return {...state,stocks,slotAssignments,movements:state.movements.map(x=>x.id===id?{...x,status:nextStatus,updatedAt:new Date().toISOString()}:x)};
}
export function cancelMovement(state,id){
  const m=state.movements.find(x=>x.id===id);
  if(!m||['DONE','CANCELLED'].includes(m.status))throw Error('Không thể hủy phiếu đã kết thúc.');
  const stocks=m.status==='IN_TRANSIT'?changeStock(state.stocks,m.productId,m.fromId,m.qty):state.stocks;
  return {...state,stocks,movements:state.movements.map(x=>x.id===id?{...x,status:'CANCELLED'}:x)};
}
export function updateCount(state,productId,placeId,actual,by){
  const n=Number(actual);
  if(!Number.isInteger(n)||n<0)throw Error('Số lượng thực tế phải là số nguyên không âm.');
  if(!state.products.some(x=>x.id===productId)||!state.places.some(x=>x.id===placeId))throw Error('Vui lòng chọn sản phẩm và nơi lưu trữ.');
  const before=stockOf(state,productId,placeId),delta=n-before;
  return {...state,stocks:changeStock(state.stocks,productId,placeId,delta),counts:[{id:uid('KK'),productId,placeId,expected:before,actual:n,delta,date:new Date().toISOString(),by},...state.counts]};
}
export function approveRequest(state,id){
  const r=state.requests.find(x=>x.id===id);
  if(!r||r.status!=='PENDING')throw Error('Yêu cầu không còn ở trạng thái chờ.');
  let next=createMovement(state,{kind:'TRANSFER',productId:r.productId,qty:r.qty,fromId:r.fromId,toId:r.storeId,note:`Từ yêu cầu ${r.id}: ${r.note||''}`},'Quản lý kho');
  return {...next,requests:next.requests.map(x=>x.id===id?{...x,status:'APPROVED',movementId:next.movements[0].id}:x)};
}
export function formatNumber(n){return new Intl.NumberFormat('vi-VN').format(Number(n||0));}
export function formatMoney(n){return formatNumber(n)+' ₫';}
export function formatDate(s){try{return new Date(s).toLocaleDateString('vi-VN',{day:'2-digit',month:'2-digit',year:'numeric'})}catch{return ''}}
export function csvReport(state){
  const esc=(v)=>'"'+String(v??'').replace(/"/g,'""')+'"';
  const rows=[['Mã SP','Sản phẩm','Đơn vị','Nơi lưu trữ','Loại','Tồn thực tế','Đơn giá','Giá trị'],...state.stocks.map(s=>{const p=state.products.find(x=>x.id===s.productId)||{};const l=state.places.find(x=>x.id===s.placeId)||{};return [p.sku,p.name,p.unit,l.name,l.type,s.qty,p.price,s.qty*(p.price||0)]})];
  return '\uFEFF'+rows.map(r=>r.map(esc).join(',')).join('\r\n');
}
