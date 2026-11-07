import test from 'node:test';
import assert from 'node:assert/strict';
import {makeSeed} from '../src/seed.js';
import {createMovement,advanceMovement,stockOf} from '../src/inventory.js';
import {findCode,mobileAlerts,positionGoods,stockLedger} from '../src/mobileFeatures.js';

test('tra cứu mã barcode / sku / lô / nơi',()=>{
  const s=makeSeed();
  assert.equal(findCode(s,'8936000000001').item.id,'p1');
  assert.equal(findCode(s,'sp-001').item.id,'p1');
  assert.equal(findCode(s,'LOT-260902').type,'lot');
  assert.equal(findCode(s,'kho-hcm').type,'place');
  assert.equal(findCode(s,'mã không tồn tại'),null);
});
test('cảnh báo tồn thấp và lô hết hạn',()=>{
  const s=makeSeed();
  const a=mobileAlerts(s,new Date('2026-10-20T12:00:00'));
  assert.ok(a.some(x=>x.id==='low-p4'));
  assert.ok(a.some(x=>x.id==='exp-LOT-260905'&&x.severity==='danger'));
  assert.ok(a.some(x=>x.id==='exp-LOT-260903'));
});
test('vị trí mặc định có hàng theo mức tồn nơi',()=>{
  const s=makeSeed();
  const list=positionGoods(s,'l1',0);
  assert.equal(list.find(x=>x.productId==='p1').qty,20);
  assert.equal(positionGoods(s,'l1',1).length,0);
});
test('vị trí bị khóa không cho nhận mới',()=>{
  const s=makeSeed();s.places=s.places.map(p=>p.id==='l1'?{...p,slotLocks:[0]}:p);
  assert.throws(()=>createMovement(s,{kind:'IN',productId:'p1',qty:3,toId:'l1',slotIndex:'0'}),/khóa/);
  let moved=createMovement(s,{kind:'IN',productId:'p1',qty:3,toId:'l1',slotIndex:'1'});
  let id=moved.movements[0].id;
  moved=advanceMovement(advanceMovement(moved,id),id);
  assert.equal(stockOf(moved,'p1','l1'),23);
  assert.equal(positionGoods(moved,'l1',1).find(x=>x.productId==='p1').qty,23);
});
test('thẻ kho phản ánh cả xuất nguồn và nhập đích của phiếu chuyển',()=>{
  let s=makeSeed();s=createMovement(s,{kind:'TRANSFER',productId:'p1',qty:2,fromId:'l1',toId:'l2'});const id=s.movements[0].id;
  s=advanceMovement(s,id);s=advanceMovement(s,id);
  const entries=stockLedger(s,'p1').filter(x=>x.id.startsWith(id));
  assert.equal(entries.length,2);
  assert.deepEqual(entries.map(x=>x.delta).sort((a,b)=>a-b),[-2,2]);
});
