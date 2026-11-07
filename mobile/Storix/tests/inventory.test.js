import test from 'node:test';
import assert from 'node:assert/strict';
import {makeSeed} from '../src/seed.js';
import {stockOf,changeStock,createMovement,advanceMovement,cancelMovement,updateCount,approveRequest,csvReport} from '../src/inventory.js';
test('số dư ban đầu và cập nhật tồn',()=>{let s=makeSeed();assert.equal(stockOf(s,'p1','l1'),20);assert.equal(stockOf(s,'p1'),30);assert.equal(changeStock(s.stocks,'p1','l1',5).find(x=>x.productId==='p1'&&x.placeId==='l1').qty,25);assert.throws(()=>changeStock(s.stocks,'p1','l1',-21));});
test('phiếu nhập duyệt rồi hoàn thành mới tăng tồn',()=>{let s=makeSeed();s=createMovement(s,{kind:'IN',productId:'p1',qty:10,toId:'l2'});let id=s.movements[0].id;assert.equal(stockOf(s,'p1','l2'),8);s=advanceMovement(s,id);assert.equal(stockOf(s,'p1','l2'),8);s=advanceMovement(s,id);assert.equal(stockOf(s,'p1','l2'),18)});
test('chuyển kho không đếm trùng khi đang vận chuyển',()=>{let s=makeSeed();s=createMovement(s,{kind:'TRANSFER',productId:'p1',qty:7,fromId:'l1',toId:'l2'});let id=s.movements[0].id;s=advanceMovement(s,id);assert.equal(stockOf(s,'p1','l1'),13);assert.equal(stockOf(s,'p1','l2'),8);assert.equal(s.movements[0].status,'IN_TRANSIT');s=advanceMovement(s,id);assert.equal(stockOf(s,'p1','l2'),15)});
test('hủy chuyến đang đi trả hàng về nguồn',()=>{let s=makeSeed();s=createMovement(s,{kind:'TRANSFER',productId:'p1',qty:10,fromId:'l1',toId:'l2'});let id=s.movements[0].id;s=advanceMovement(s,id);s=cancelMovement(s,id);assert.equal(stockOf(s,'p1','l1'),20);});
test('xuất quá số lượng bị chặn',()=>{let s=makeSeed();s=createMovement(s,{kind:'OUT',productId:'p1',qty:900,fromId:'l1'});assert.throws(()=>advanceMovement(s,s.movements[0].id),/Không đủ/)});
test('kiểm kê điều chỉnh tồn, yêu cầu bổ sung sinh phiếu',()=>{let s=makeSeed();s=updateCount(s,'p1','l1',17,'tester');assert.equal(stockOf(s,'p1','l1'),17);s=approveRequest(s,'YC-1001');assert.equal(s.requests[0].status,'APPROVED');assert.equal(s.movements[0].status,'DRAFT');assert.ok(csvReport(s).startsWith('\uFEFF'))});
test('nơi bị khóa không nhận hàng mới nhưng vẫn được xuất hàng cũ',()=>{
  let s=makeSeed();s.places=s.places.map(p=>p.id==='l1'?{...p,enabled:false}:p);
  assert.throws(()=>createMovement(s,{kind:'IN',productId:'p1',qty:2,toId:'l1'}),/hợp lệ/);
  s=createMovement(s,{kind:'OUT',productId:'p1',qty:2,fromId:'l1'});
  const id=s.movements[0].id;s=advanceMovement(s,id);s=advanceMovement(s,id);
  assert.equal(stockOf(s,'p1','l1'),18);
});
test('hàng nhập bị ngăn khi điểm nhận bị khóa sau lúc lập phiếu',()=>{
  let s=makeSeed();s=createMovement(s,{kind:'IN',productId:'p1',qty:2,toId:'l2'});let id=s.movements[0].id;s=advanceMovement(s,id);
  s.places=s.places.map(p=>p.id==='l2'?{...p,enabled:false}:p);
  assert.throws(()=>advanceMovement(s,id),/khóa/);assert.equal(stockOf(s,'p1','l2'),8);
});
