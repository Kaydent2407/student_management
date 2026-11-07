import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {makeSeed} from '../src/seed.js';
import {demoOverview,apiOverview,lastSevenDays} from '../src/overviewData.js';
import {lowProducts,placeStock} from '../src/inventory.js';
import {mobileAlerts} from '../src/mobileFeatures.js';
const root=new URL('../',import.meta.url);
const read=path=>readFileSync(new URL(path,root),'utf8');

test('Biểu đồ có 7 ngày cố định theo mốc ngày truyền vào, không phải dữ liệu ngẫu nhiên',()=>{
 const days=lastSevenDays(new Date('2026-10-25T12:00:00'));
 assert.equal(days.length,7);assert.equal(days[0].label,'19/10');assert.equal(days[6].label,'25/10');
 assert.ok(days.every(d=>d.inbound===0&&d.outbound===null));
});
test('Dashboard demo lấy số từ seed và tính đúng sức chứa theo từng nơi',()=>{
 const state=makeSeed(); const overview=demoOverview(state,{scopePlaces:state.places,alerts:mobileAlerts(state,new Date('2026-10-25')),lowProducts,placeStock,now:new Date()});
 assert.equal(overview.productCount,state.products.length);
 assert.equal(overview.source,'demo');assert.equal(overview.capacities.length,3);
 assert.equal(overview.capacities[0].capacity,state.places[0].capacity);
 assert.ok(overview.capacities[0].used>=0);
 assert.equal(overview.pendingCount,overview.queue.length);
});
test('Dashboard demo chỉ hiển thị phiếu của các nơi được phân quyền',()=>{
 const state=makeSeed(); const scope=state.places.filter(p=>p.type==='store');
 const overview=demoOverview(state,{scopePlaces:scope,alerts:[],lowProducts,placeStock});
 assert.ok(overview.capacities.every(p=>scope.some(x=>x.id===p.id)));
 assert.equal(overview.capacities.length,2);
});
test('Dashboard API không giả số liệu cho tính năng backend chưa hỗ trợ',()=>{
 const d=apiOverview({products:{total:320},warehouses:[{id:1,name:'Kho A',capacity:1000}],receipts:{items:[{id:2,code:'PN-002',status:'PENDING',createdAt:'2026-10-25'}],total:1}});
 assert.equal(d.productCount,320);assert.equal(d.pendingCount,1);
 assert.equal(d.lowCount,null);assert.equal(d.transferringCount,null);
 assert.equal(d.totalOutbound,null);assert.equal(d.capacities[0].percent,null);
 assert.equal(d.weekly.length,7);assert.ok(d.weekly.every(x=>x.outbound===null));
});
test('Bảng phiếu API dùng số liệu thực và bỏ phiếu hoàn tất/hủy khỏi hàng chờ',()=>{
 const receipts={items:[
  {id:1,code:'PN-001',status:'DONE',createdAt:'2026-10-24'},
  {id:2,code:'PN-002',status:'DRAFT',createdAt:'2026-10-25'},
  {id:3,code:'PN-003',status:'CANCELLED',createdAt:'2026-10-25'},
 ]};
 const d=apiOverview({receipts});assert.deepEqual(d.queue.map(x=>x.id),['PN-002']);assert.equal(d.pendingCount,1);
});
test('Trang đăng nhập vẫn nằm tách biệt với trang Dashboard và có logo gốc',()=>{
 const app=read('App.js'),api=read('src/ApiWorkspace.js'),auth=read('src/BrandAuth.js');
 assert.ok(app.includes('<BrandAuthShell mode="demo"'));
 assert.ok(api.includes('<BrandAuthShell mode="api"'));
 assert.ok(auth.includes('<StorixLogo size={48}'));
 assert.match(read('src/OverviewDashboard.js'),/Phiếu nhập và xuất đã hoàn thành/);
 assert.match(read('src/OverviewDashboard.js'),/Phiếu cần xử lý/);
 assert.match(read('src/OverviewDashboard.js'),/Sức chứa theo nơi/);
 assert.match(read('src/OverviewDashboard.js'),/Cảnh báo mới/);
});
