// Tiện ích hiển thị của bản Android demo, dữ liệu được lưu cục bộ.
import {stockOf,placeStock} from './inventory.js';
export const assignedSlot=(state,productId,placeId)=>Number(state.slotAssignments?.[productId+'|'+placeId]??0);
export function positionGoods(state,placeId,slotIndex){
  return state.stocks.filter(x=>x.placeId===placeId&&x.qty>0&&assignedSlot(state,x.productId,placeId)===slotIndex)
    .map(x=>({...x,product:state.products.find(p=>p.id===x.productId)}));
}
export function findCode(state,code){
  const term=String(code||'').trim().toLowerCase();
  if(!term)return null;
  const product=state.products.find(p=>[p.sku,p.barcode,p.name].some(x=>String(x||'').toLowerCase()===term));
  if(product)return {type:'product',item:product};
  const lot=(state.lots||[]).find(x=>x.id.toLowerCase()===term);
  if(lot)return {type:'lot',item:lot};
  const place=(state.places||[]).find(x=>x.code.toLowerCase()===term);
  return place?{type:'place',item:place}:null;
}
export function mobileAlerts(state,today=new Date()){
  const alerts=[];
  state.products.forEach(p=>{
    const qty=stockOf(state,p.id);
    if(qty<Number(p.minStock||0))alerts.push({id:'low-'+p.id,kind:'Tồn thấp',title:p.name,body:`Còn ${qty} ${p.unit}; mức tối thiểu ${p.minStock}.`,severity:'warn'});
  });
  (state.lots||[]).forEach(l=>{
    if(!l.expires)return;
    const days=Math.ceil((new Date(l.expires+'T23:59:59').getTime()-today.getTime())/86400000);
    if(days<=30){const p=state.products.find(x=>x.id===l.productId);
      alerts.push({id:'exp-'+l.id,kind:days<0?'Lô hết hạn':'Lô sắp hết hạn',title:l.id+' · '+(p?.name||''),body:days<0?'Đã quá hạn sử dụng.':`Còn khoảng ${days} ngày đến hạn.`,severity:days<0?'danger':'warn'});}
  });
  state.places.forEach(p=>{
    const pct=placeStock(state,p.id)/Math.max(p.capacity,1)*100;
    if(pct>=90)alerts.push({id:'cap-'+p.id,kind:'Sức chứa',title:p.name,body:`Đã sử dụng khoảng ${Math.round(pct)}% sức chứa tham khảo.`,severity:'warn'});
  });
  state.requests.filter(r=>r.status==='PENDING').forEach(r=>alerts.push({id:'req-'+r.id,kind:'Yêu cầu bổ sung',title:r.id,body:'Có yêu cầu bổ sung hàng chờ duyệt.',severity:'info'}));
  return alerts;
}
export function stockLedger(state,productId=null){
 const movements=state.movements.filter(x=>x.status==='DONE'&&(!productId||x.productId===productId)).flatMap(m=>{
   const base={date:m.date,productId:m.productId,kind:m.kind};
   if(m.kind==='TRANSFER')return [
     {...base,id:m.id+'-OUT',placeId:m.fromId,delta:-m.qty,note:`Chuyển ra khỏi ${m.fromId}`},
     {...base,id:m.id+'-IN',placeId:m.toId,delta:m.qty,note:`Nhận điều chuyển từ ${m.fromId}`}
   ];
   return [{...base,id:m.id,placeId:m.kind==='IN'?m.toId:m.fromId,delta:m.kind==='IN'?m.qty:-m.qty,note:m.note||'Phiếu kho đã hoàn thành'}];
 });
 const counts=state.counts.filter(x=>!productId||x.productId===productId).map(x=>({id:x.id,date:x.date,productId:x.productId,placeId:x.placeId,kind:'COUNT',delta:x.delta,note:'Điều chỉnh sau kiểm kê'}));
 return [...movements,...counts].sort((a,b)=>new Date(b.date)-new Date(a.date));
}
