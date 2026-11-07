import React,{useEffect,useMemo,useRef,useState} from 'react';
import {View,Text,Pressable,ScrollView,StatusBar,Platform,useWindowDimensions,Share,ActivityIndicator} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {SafeAreaView} from 'react-native-safe-area-context';
import {I,Txt,Flex,Btn,Tag,Panel,TitleBar,Section,Field,Choices,Search,Empty,Sheet,ProgressBar,C,D,F,UiThemeProvider,WorkspaceRibbon} from './src/ui';
import {makeSeed,ROLES,TYPES,KINDS} from './src/seed';
import {stockOf,placeStock,transitOf,totalValue,lowProducts,uid,createMovement,advanceMovement,cancelMovement,updateCount,approveRequest,formatNumber,formatMoney,formatDate,csvReport} from './src/inventory';
import {positionGoods,findCode,mobileAlerts,stockLedger} from './src/mobileFeatures';
import ScanCamera from './src/ScanCamera';
import ApiWorkspace from './src/ApiWorkspace';
import {BrandAuthShell,BrandAuthButton,BrandAuthNote,BRAND} from './src/BrandAuth';
import StorixLogo from './src/StorixLogo';
import OverviewDashboard,{OverviewSidebar,OverviewTopbar} from './src/OverviewDashboard';
import {demoOverview} from './src/overviewData';

const STORE_KEY='storix_demo_v1'; // Giữ khóa cũ để dữ liệu trước vẫn tải được.
const NAV=[{id:'home',icon:'view-dashboard-outline',label:'Tổng quan'},{id:'products',icon:'package-variant-closed',label:'Sản phẩm'},{id:'places',icon:'warehouse',label:'Kho & bãi'},{id:'flows',icon:'swap-horizontal',label:'Phiếu kho'},{id:'more',icon:'dots-grid',label:'Tiện ích'}];
const STATUS={DRAFT:{label:'Chờ duyệt',color:'#AC7B1E',bg:'#FFF5DD'},APPROVED:{label:'Đã duyệt',color:'#4D68B6',bg:'#EFF3FF'},IN_TRANSIT:{label:'Đang vận chuyển',color:'#6855C9',bg:'#F0ECFF'},DONE:{label:'Hoàn thành',color:'#098965',bg:'#E5F7EF'},CANCELLED:{label:'Đã hủy',color:'#8F9BAA',bg:'#EEF1F5'},PENDING:{label:'Chờ xử lý',color:'#AD7C1C',bg:'#FFF5DD'},REJECTED:{label:'Từ chối',color:F.red,bg:'#FEECEF'}};
const typeInfo=(id)=>TYPES.find(x=>x.id===id)||TYPES[0];
const kindInfo=(id)=>KINDS.find(x=>x.id===id)||KINDS[0];
const roleInfo=(id)=>ROLES.find(x=>x.id===id)||ROLES[0];
const snapshot={products:[],places:[],stocks:[],movements:[],requests:[],counts:[],role:'admin',suppliers:[],lots:[],readAlerts:[],slotAssignments:{}};

function ProductTile({p,data,onPress}){
  const qty=stockOf(data,p.id),low=qty<p.minStock;
  return <Pressable onPress={onPress} style={({pressed})=>({backgroundColor:pressed?F.surfaceAlt:F.surface,borderWidth:1,borderColor:F.line,borderRadius:10,padding:15,marginBottom:10})}>
    <Flex style={{gap:12}}><View style={{width:51,height:54,backgroundColor:F.surfaceAlt,borderRadius:15,alignItems:'center',justifyContent:'center'}}><I name={p.icon||'package-variant'} size={26} color={F.blue}/></View><View style={{flex:1,minWidth:0}}><Txt size={11} color={F.muted}>{p.sku} · {p.category}</Txt><Txt size={14} bold numberOfLines={2} style={{marginTop:2}}>{p.name}</Txt><Txt size={11} color={F.muted} style={{marginTop:3}}>{formatMoney(p.price)} / {p.unit}</Txt></View><View style={{alignItems:'flex-end',gap:7}}><Txt size={18} bold color={low?F.red:F.ink}>{formatNumber(qty)}</Txt><Tag text={low?'Sắp hết':'Còn hàng'} color={low?F.red:F.green} bg={low?'#FEEDF0':F.pale}/></View></Flex>
  </Pressable>;
}
function PlaceTile({place,data,onPress}){
  const count=placeStock(data,place.id),pct=count/Math.max(place.capacity,1)*100,t=typeInfo(place.type);
  return <Pressable onPress={onPress} style={({pressed})=>({backgroundColor:pressed?F.surfaceAlt:F.surface,borderRadius:10,borderColor:F.line,borderWidth:1,padding:17,marginBottom:12})}>
    <Flex style={{gap:12,marginBottom:12}}><View style={{width:46,height:46,borderRadius:14,backgroundColor:place.type==='yard'?F.surfaceAlt:place.type==='store'?F.surfaceAlt:F.surfaceAlt,alignItems:'center',justifyContent:'center'}}><I name={t.icon} size={24} color={place.type==='yard'?'#D18A37':place.type==='store'?F.blue:F.green}/></View><View style={{flex:1}}><Txt size={11} color={F.muted}>{place.code} · {t.label}</Txt><Txt bold size={15}>{place.name}</Txt></View><I name="chevron-right" color={F.muted}/></Flex>
    <Flex style={{gap:5,marginBottom:10}}><I name="map-marker-outline" size={15} color={F.muted}/><Txt color={F.muted} size={12}>{place.address}</Txt></Flex>
    <Flex style={{justifyContent:'space-between',marginBottom:7}}><Txt size={11} color={F.muted}>Mức sử dụng tham khảo</Txt><Txt size={12} bold>{formatNumber(count)} / {formatNumber(place.capacity)}</Txt></Flex><ProgressBar value={pct} color={pct>90?F.orange:F.green}/>
    <Flex style={{justifyContent:'space-between',marginTop:11}}><Txt size={11} color={F.muted}>{place.slots?.length||0} vị trí được khai báo</Txt>{!place.enabled?<Tag text="Tạm khóa" color={F.red} bg="#FFF0F0"/>:<Tag text="Hoạt động"/>}</Flex>
  </Pressable>;
}
function MovementTile({m,data,onPress}){
  const kind=kindInfo(m.kind),status=STATUS[m.status]||STATUS.DRAFT;
  const p=data.products.find(x=>x.id===m.productId);
  const from=data.places.find(x=>x.id===m.fromId),to=data.places.find(x=>x.id===m.toId);
  return <Pressable onPress={onPress} style={{borderWidth:1,borderColor:F.line,borderRadius:10,backgroundColor:F.surface,padding:16,marginBottom:11}}>
   <Flex style={{gap:10}}><View style={{width:43,height:43,borderRadius:13,backgroundColor:kind.tint+'16',alignItems:'center',justifyContent:'center'}}><I name={kind.icon} size={24} color={kind.tint}/></View><View style={{flex:1}}><Txt size={12} bold>{kind.label} <Txt size={11} color={F.muted}>· {formatDate(m.date)}</Txt></Txt><Txt size={11} color={F.muted}>{m.id}</Txt></View><Tag text={status.label} color={status.color} bg={status.bg}/></Flex>
   <Txt bold size={14} style={{marginTop:12}}>{p?.name||'Sản phẩm đã xóa'}</Txt>
   <Flex style={{justifyContent:'space-between',marginTop:5,gap:10}}><Txt size={12} color={F.muted} style={{flex:1}} numberOfLines={2}>{from?.name||'Nhà cung cấp'}  →  {to?.name||'Khách hàng'}</Txt><Txt size={13} bold color={kind.tint}>{m.kind==='OUT'?'-':'+'}{formatNumber(m.qty)} {p?.unit||''}</Txt></Flex>
  </Pressable>;
}
function Metric({icon,label,value,small,color=F.green,dark=false,style={}}){return <View style={[{padding:15,borderRadius:17,backgroundColor:dark?'#1E3A58':F.surface,borderWidth:dark?0:1,borderColor:F.line,minWidth:0},style]}><View style={{width:35,height:35,borderRadius:11,backgroundColor:dark?'#335572':color+'17',justifyContent:'center',alignItems:'center',marginBottom:13}}><I name={icon} color={dark?'#B3F5DA':color} size={20}/></View><Txt size={small?18:23} bold color={dark?C.white:F.ink} numberOfLines={1}>{value}</Txt><Txt size={11} color={dark?'#B6C8DB':F.muted} style={{marginTop:2}}>{label}</Txt></View>}

// API thật mặc định; dữ liệu demo nằm tách biệt và không bao giờ tự đồng bộ SQL Server.
export default function App(){
  const [mode,setMode]=useState('api');
  return mode==='api'
    ? <ApiWorkspace onOpenDemo={()=>setMode('demo')}/>
    : <LocalDemo onBackToApi={()=>setMode('api')}/>;
}

function LocalDemo({onBackToApi}){
  const {width}=useWindowDimensions(),desktop=width>=850;
  const [data,setData]=useState(snapshot),current=useRef(snapshot);
  const [ready,setReady]=useState(false),[tab,setTab]=useState('home'),[sub,setSub]=useState(null),[search,setSearch]=useState(''),[filter,setFilter]=useState('all');
  const [sheet,setSheet]=useState(''),[selected,setSelected]=useState(null),[toast,setToast]=useState('');
  const [loggedIn,setLoggedIn]=useState(false),[loginRole,setLoginRole]=useState('admin'),[codeInput,setCodeInput]=useState('');
  const [pForm,setPForm]=useState({}),[lForm,setLForm]=useState({}),[mForm,setMForm]=useState({}),[rForm,setRForm]=useState({}),[cForm,setCForm]=useState({});
  const role=roleInfo(data.role),canManage=['admin','manager'].includes(data.role),canOperate=data.role!=='store',canCount=['admin','manager','staff'].includes(data.role);
  useEffect(()=>{let live=true;AsyncStorage.getItem(STORE_KEY).then(raw=>{if(live){let v=raw?JSON.parse(raw):makeSeed();if(!v||!Array.isArray(v.products)||!Array.isArray(v.stocks))v=makeSeed();else v={...makeSeed(),...v};current.current=v;setData(v);setReady(true)}}).catch(()=>{const v=makeSeed();current.current=v;setData(v);setReady(true)});return ()=>{live=false}},[]);
  useEffect(()=>{if(ready)AsyncStorage.setItem(STORE_KEY,JSON.stringify(data)).catch(()=>setToast('Không thể lưu dữ liệu cục bộ.'))},[data,ready]);
  useEffect(()=>{if(!toast)return;const timer=setTimeout(()=>setToast(''),3200);return ()=>clearTimeout(timer)},[toast]);
  const commit=(fn,msg)=>{try{const next=fn(current.current);current.current=next;setData(next);if(msg)setToast(msg);return true}catch(e){setToast(e?.message||'Có lỗi xảy ra.');return false}};
  const navigate=(id,child=null)=>{setTab(id);setSub(child);setFilter('all');setSearch('');setSelected(null)};
  const product=(id)=>data.products.find(p=>p.id===id),place=(id)=>data.places.find(x=>x.id===id);
  const openProduct=(p=null)=>{setSelected(p);setPForm(p?{...p,price:String(p.price),minStock:String(p.minStock)}:{sku:'',barcode:'',status:'ACTIVE',name:'',category:'Thiết bị',unit:'cái',price:'',minStock:'10',icon:'package-variant-closed'});setSheet('product')};
  const openPlace=(p=null)=>{setSelected(p);setLForm(p?{...p,capacity:String(p.capacity),slotsText:(p.slots||[]).join('\n')}:{name:'',code:'',type:'warehouse',address:'',capacity:'100',slotsText:'Khu A · Dãy 01 · Kệ 01 · Tầng 1 · Ô 01',enabled:true});setSheet('place')};
  const openMovement=(kind='IN')=>{setSelected(null);setMForm({kind,productId:data.products[0]?.id||'',qty:'1',fromId:data.places.find(x=>x.type==='warehouse')?.id||'',toId:data.places.find(x=>x.type==='yard'&&x.enabled)?.id||'',slotIndex:'0',note:''});setSheet('movement')};
  const openRequest=()=>{setRForm({productId:data.products[0]?.id||'',storeId:data.places.find(x=>x.type==='store')?.id||'',fromId:data.places.find(x=>x.type==='warehouse')?.id||'',qty:'1',note:''});setSheet('request')};
  const openCount=()=>{setCForm({productId:data.products[0]?.id||'',placeId:data.places[0]?.id||'',actual:''});setSheet('count')};
  const saveProduct=()=>{const v={...pForm,sku:String(pForm.sku||'').trim().toUpperCase(),name:String(pForm.name||'').trim(),price:Number(pForm.price),minStock:Number(pForm.minStock)};
    if(!v.sku||!v.name||!v.category||!v.unit){setToast('Hãy điền đầy đủ thông tin sản phẩm.');return}
    if(!Number.isFinite(v.price)||v.price<0||!Number.isInteger(v.minStock)||v.minStock<0){setToast('Giá và tồn tối thiểu phải là số không âm.');return}
    if(data.products.some(p=>p.sku===v.sku&&p.id!==selected?.id)){setToast('Mã sản phẩm đã tồn tại.');return}
    if(v.barcode&&data.products.some(p=>p.barcode===v.barcode&&p.id!==selected?.id)){setToast('Barcode này đã được sử dụng.');return}
    if(commit(s=>({...s,products:selected?s.products.map(p=>p.id===selected.id?{...p,...v}:p):[{...v,id:uid('SP')},...s.products]}),selected?'Đã cập nhật sản phẩm.':'Đã thêm sản phẩm.'))setSheet('');
  };
  const savePlace=()=>{let v={...lForm,name:String(lForm.name||'').trim(),code:String(lForm.code||'').trim().toUpperCase(),address:String(lForm.address||'').trim(),capacity:Number(lForm.capacity),slots:String(lForm.slotsText||'').split('\n').map(x=>x.trim()).filter(Boolean)};delete v.slotsText;
    if(!v.name||!v.code){setToast('Vui lòng nhập tên và mã nơi lưu trữ.');return}
    if(!Number.isInteger(v.capacity)||v.capacity<=0){setToast('Sức chứa phải là số nguyên dương.');return}
    if(data.places.some(p=>p.code===v.code&&p.id!==selected?.id)){setToast('Mã nơi lưu trữ đã tồn tại.');return}
    if(commit(s=>({...s,places:selected?s.places.map(p=>p.id===selected.id?{...p,...v}:p):[{...v,id:uid('L')},...s.places]}),selected?'Đã cập nhật nơi lưu trữ.':'Đã tạo nơi lưu trữ.'))setSheet('');
  };
  const saveMovement=()=>{if(commit(s=>createMovement(s,mForm,role.name),'Đã tạo phiếu chờ xử lý.')){setSheet('');navigate('flows')}};
  const saveRequest=()=>{if(commit(s=>{
    const n=Number(rForm.qty);
    if(!Number.isInteger(n)||n<=0)throw Error('Số lượng yêu cầu phải là số nguyên dương.');
    if(!s.products.some(p=>p.id===rForm.productId)||!s.places.some(x=>x.id===rForm.storeId&&x.type==='store')||!s.places.some(x=>x.id===rForm.fromId&&x.type==='warehouse'))throw Error('Hãy chọn sản phẩm, kho nguồn và cửa hàng.');
    return {...s,requests:[{id:uid('YC'),productId:rForm.productId,storeId:rForm.storeId,fromId:rForm.fromId,qty:n,note:rForm.note,date:new Date().toISOString(),status:'PENDING'},...s.requests]}
  },'Đã gửi yêu cầu bổ sung hàng.'))setSheet('')};
  const saveCount=()=>{if(commit(s=>updateCount(s,cForm.productId,cForm.placeId,cForm.actual,role.name),'Đã ghi nhận kiểm kê và cập nhật tồn.'))setSheet('')};
  const downloadCSV=async()=>{const csv=csvReport(viewData);if(Platform.OS==='web'&&typeof document!=='undefined'){
    const blob=new Blob([csv],{type:'text/csv;charset=utf-8;'}),url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='storix-bao-cao-ton-kho.csv';document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);setToast('Đã xuất báo cáo CSV.');
  } else {try{await Share.share({title:'Storix – Báo cáo tồn kho CSV',message:csv})}catch(e){setToast('Không thể chia sẻ báo cáo.')}}};
  // Phạm vi mô phỏng ở UI; phân quyền bảo mật thực sự phải do backend kiểm soát.
  const visiblePlaces=data.role==='store'?data.places.filter(x=>x.id==='l5'):data.places;
  const visibleIds=new Set(visiblePlaces.map(x=>x.id));
  const viewData={...data,places:visiblePlaces,stocks:data.stocks.filter(x=>visibleIds.has(x.placeId)),movements:data.movements.filter(m=>data.role!=='store'||visibleIds.has(m.fromId)||visibleIds.has(m.toId)),requests:data.requests.filter(r=>data.role!=='store'||visibleIds.has(r.storeId)),counts:data.counts.filter(c=>visibleIds.has(c.placeId))};
  const inventoryValue=totalValue(viewData),low=lowProducts(viewData),pending=viewData.movements.filter(x=>!['DONE','CANCELLED'].includes(x.status));
  const alerts=mobileAlerts(viewData); const unread=alerts.filter(a=>!(data.readAlerts||[]).includes(a.id));
  const Home=()=> <OverviewDashboard
    data={demoOverview(viewData,{scopePlaces:visiblePlaces,alerts,lowProducts,placeStock})}
    screenWidth={width}
    onNavigate={route=>{
      if(route==='products')navigate('products');
      else if(route==='low'){navigate('products');setFilter('low');}
      else if(route==='transfer'){navigate('flows');setFilter('TRANSFER');}
      else if(route==='places')navigate('places');
      else navigate('flows');
    }}
    onOpenQueue={row=>{
      if(row.route==='requests'){navigate('more','requests');return;}
      const match=viewData.movements.find(m=>m.id===row.id);
      navigate('flows');if(match){setSelected(match);setSheet('movementDetail');}
    }}
    onOpenCapacity={item=>{navigate('places');if(item?.id){const target=data.places.find(x=>x.id===item.id);if(target){setSelected(target);setSheet('placeDetail');}}}}
    onOpenAlerts={()=>navigate('more','alerts')}
  />;
  const Products=()=>{
    const entries=data.products.filter(p=>(p.name+' '+p.sku+' '+p.category).toLowerCase().includes(search.toLowerCase())&&(filter!=='low'||stockOf(viewData,p.id)<p.minStock));
    return <><TitleBar title="Sản phẩm" caption={`${data.products.length} mặt hàng · ${low.length} mặt hàng cảnh báo`} right={canManage?<Btn title="Thêm mới" icon="plus" small onPress={()=>openProduct()}/>:null}/>
      <Search value={search} onChange={setSearch} placeholder="Tìm tên, mã SKU, danh mục..."/><Choices label="Hiển thị" items={[{id:'all',label:'Tất cả'},{id:'low',label:`Sắp hết (${low.length})`}]} value={filter==='low'?'low':'all'} onChange={setFilter}/>
      {entries.length===0?<Empty title="Không tìm thấy sản phẩm"/>:entries.map(p=><ProductTile key={p.id} p={p} data={viewData} onPress={()=>{setSelected(p);setSheet('productDetail')}}/>)}
    </>;
  };
  const Places=()=>{
    const entries=visiblePlaces.filter(p=>(p.name+' '+p.code+' '+p.address).toLowerCase().includes(search.toLowerCase())&&(filter==='all'||filter===p.type));
    return <><TitleBar title="Kho & bãi lưu trữ" caption="Quản lý kho hàng, bãi và cửa hàng" right={canManage?<Btn title="Tạo mới" icon="plus" small onPress={()=>openPlace()}/>:null}/>
      <Search value={search} onChange={setSearch} placeholder="Tìm nơi lưu trữ..."/><Choices label="Phân loại" items={[{id:'all',label:'Tất cả'},...TYPES]} value={filter} onChange={setFilter}/>
      {entries.length===0?<Empty title="Không có nơi lưu trữ"/>:entries.map(p=><PlaceTile key={p.id} place={p} data={viewData} onPress={()=>{setSelected(p);setSheet('placeDetail')}}/>)}
    </>;
  };
  const Flows=()=>{
    const entries=viewData.movements.filter(m=>(m.id+' '+(product(m.productId)?.name||'')).toLowerCase().includes(search.toLowerCase())&&(filter==='all'||filter===m.kind||filter==='pending'&&!['DONE','CANCELLED'].includes(m.status))&&(data.role!=='store'||visibleIds.has(m.fromId)||visibleIds.has(m.toId)));
    return <><TitleBar title="Phiếu nhập · xuất · chuyển" caption={`${pending.length} phiếu đang xử lý`} right={canOperate?<Btn title="Tạo phiếu" icon="plus" small onPress={()=>openMovement('IN')}/>:null}/>
      <Search value={search} onChange={setSearch} placeholder="Tìm mã phiếu hoặc tên hàng..."/><Choices label="Lọc phiếu" items={[{id:'all',label:'Tất cả'},{id:'pending',label:'Chờ xử lý'},...KINDS]} value={filter} onChange={setFilter}/>
      {entries.length===0?<Empty title="Chưa có phiếu phù hợp"/>:entries.map(m=><MovementTile key={m.id} m={m} data={data} onPress={()=>{setSelected(m);setSheet('movementDetail')}}/>)}
    </>;
  };
  const Requests=()=> <><TitleBar title="Yêu cầu bổ sung" caption="Cửa hàng đề xuất bổ sung hàng từ kho" right={<Btn title="Tạo yêu cầu" icon="plus" small onPress={openRequest}/>}/>
    {viewData.requests.length===0?<Empty title="Chưa có yêu cầu"/>:viewData.requests.map(r=>{
      const st=STATUS[r.status]||STATUS.PENDING;
      return <Panel key={r.id}><Flex style={{justifyContent:'space-between',marginBottom:8}}><Txt size={12} bold>{r.id} · {formatDate(r.date)}</Txt><Tag text={st.label} color={st.color} bg={st.bg}/></Flex>
        <Txt bold size={15}>{product(r.productId)?.name}</Txt><Txt size={12} color={C.muted} style={{marginTop:5}}>{place(r.fromId)?.name} → {place(r.storeId)?.name}</Txt><Txt size={12} style={{marginTop:7}}>Số lượng đề xuất: <Txt bold>{formatNumber(r.qty)} {product(r.productId)?.unit}</Txt></Txt>{r.note?<Txt color={C.muted} size={12} style={{marginTop:5}}>{r.note}</Txt>:null}
        {r.status==='PENDING'&&canManage?<Flex style={{gap:8,marginTop:13}}><Btn title="Từ chối" danger small onPress={()=>commit(s=>({...s,requests:s.requests.map(x=>x.id===r.id?{...x,status:'REJECTED'}:x)}),'Đã từ chối yêu cầu.')}/><Btn title="Duyệt và tạo phiếu chuyển" icon="check" small onPress={()=>commit(s=>approveRequest(s,r.id),'Đã duyệt. Phiếu điều chuyển được tạo ở mục Phiếu kho.')}/></Flex>:null}
        {r.movementId?<Pressable onPress={()=>navigate('flows')} style={{marginTop:10}}><Txt size={12} color={C.green} bold>Xem phiếu điều chuyển →</Txt></Pressable>:null}
      </Panel>})}
  </>;
  const Counts=()=> <><TitleBar title="Kiểm kê kho" caption="Đối chiếu số lượng thực tế với hệ thống" right={canCount?<Btn title="Kiểm kê" icon="plus" small onPress={openCount}/>:null}/>
    <Panel style={{backgroundColor:'#EFF7FD',borderColor:'#D8EBF7'}}><Flex style={{gap:9}}><I name="information-outline" color="#477BA1" size={22}/><Txt color="#416988" size={12} style={{flex:1}}>Khi xác nhận kiểm kê, số tồn được điều chỉnh theo số lượng thực tế và ghi lại lịch sử chênh lệch.</Txt></Flex></Panel>
    {viewData.counts.length===0?<Empty title="Chưa có phiên kiểm kê" sub="Chọn Kiểm kê để bắt đầu đối chiếu số liệu." icon="clipboard-check-outline"/>:viewData.counts.map(r=><Panel key={r.id}><Flex style={{justifyContent:'space-between'}}><Txt bold size={12}>{r.id}</Txt><Txt size={11} color={C.muted}>{formatDate(r.date)}</Txt></Flex><Txt size={15} bold style={{marginTop:8}}>{product(r.productId)?.name}</Txt><Txt size={12} color={C.muted}>{place(r.placeId)?.name}</Txt><Flex style={{justifyContent:'space-between',marginTop:12}}><Txt size={12}>Hệ thống: {r.expected} → Thực tế: {r.actual}</Txt><Tag text={`${r.delta>0?'+':''}${r.delta}`} color={r.delta<0?C.red:C.green} bg={r.delta<0?'#FFE9EE':C.pale}/></Flex></Panel>)}
  </>;
  const Reports=()=>{
    const qty=viewData.stocks.reduce((a,s)=>a+s.qty,0),stores=data.places.filter(p=>p.type==='store');
    return <><TitleBar title="Báo cáo tồn kho" caption="Thống kê theo dữ liệu được lưu trên thiết bị" right={<Btn small title="Xuất CSV" icon="download" onPress={downloadCSV}/>}/>
      <View style={{flexDirection:'row',gap:10,marginBottom:14}}><Metric icon="currency-usd" label="Giá trị tồn kho" value={(inventoryValue/1000000).toFixed(1)+' tr'} style={{flex:1}}/><Metric icon="package-variant" label="Tổng số đơn vị" value={formatNumber(qty)} style={{flex:1}}/></View>
      <Section title="Phân bổ tồn kho"/><Panel>{visiblePlaces.map(p=>{const total=placeStock(viewData,p.id),pct=qty?total/qty*100:0;return <View key={p.id} style={{marginBottom:16}}><Flex style={{justifyContent:'space-between',marginBottom:6}}><Txt size={12} bold>{p.name}</Txt><Txt size={11} color={C.muted}>{formatNumber(total)} ({Math.round(pct)}%)</Txt></Flex><ProgressBar value={pct}/></View>})}</Panel>
      <Section title="Cảnh báo tồn tối thiểu"/><Panel>{low.length?low.map(p=><Flex style={{justifyContent:'space-between',paddingVertical:9,borderBottomWidth:1,borderBottomColor:C.line}} key={p.id}><Txt size={12} style={{flex:1}}>{p.name}</Txt><Txt size={12} bold color={C.red}>{stockOf(viewData,p.id)} / {p.minStock}</Txt></Flex>):<Empty title="Không có hàng sắp hết"/>}</Panel>
      <Txt size={11} color={C.muted}>Lưu ý: Sức chứa kho/bãi là chỉ số đơn vị tham khảo, không quy đổi theo thể tích hoặc trọng lượng hàng hóa.</Txt>
    </>;
  };
  const More=()=> <><TitleBar title="Tiện ích Storix" caption="Tác vụ bổ sung và thông tin tài khoản"/>
     <Panel style={{backgroundColor:C.navy,borderWidth:0}}><Flex style={{gap:12}}><View style={{width:52,height:52,borderRadius:16,backgroundColor:'#31516D',alignItems:'center',justifyContent:'center'}}><I name="account-outline" size={28} color="#DDF4EC"/></View><View><Txt bold size={16} color={C.white}>{role.name}</Txt><Txt color="#C1D4E1" size={12}>{role.label} · Tài khoản mô phỏng</Txt></View></Flex></Panel>
     <Section title="Chức năng mở rộng"/>
     {[{id:'requests',title:'Yêu cầu bổ sung hàng',subtitle:'Cửa hàng gửi yêu cầu về kho',icon:'clipboard-list-outline',tint:C.blue,count:viewData.requests.filter(x=>x.status==='PENDING').length},
       {id:'counts',title:'Kiểm kê và điều chỉnh',subtitle:'Đối chiếu thực tế với số liệu',icon:'clipboard-check-outline',tint:C.green},
       {id:'reports',title:'Báo cáo và xuất dữ liệu',subtitle:'Giá trị tồn kho, cảnh báo, CSV',icon:'chart-box-outline',tint:'#D88D43'},
       {id:'suppliers',title:'Nhà cung cấp',subtitle:'Thông tin và nguồn cung liên quan',icon:'account-group-outline',tint:C.blue},
       {id:'lots',title:'Lô hàng & truy xuất',subtitle:'Ngày sản xuất, hạn dùng, nguồn hàng',icon:'layers-triple-outline',tint:C.orange},
       {id:'alerts',title:'Cảnh báo & thông báo',subtitle:'Tồn thấp, sắp hết hạn, gần đầy',icon:'bell-outline',tint:C.red,count:unread.length},
       {id:'ledger',title:'Thẻ kho & lịch sử',subtitle:'Biến động nhập, xuất và kiểm kê',icon:'history',tint:'#7B61C4'},
       {id:'scan',title:'Quét Barcode / QR',subtitle:'Camera hoặc nhập mã thủ công',icon:'qrcode-scan',tint:C.green},
      ].map(x=><Pressable key={x.id} onPress={()=>x.id==='scan'?(setCodeInput(''),setSheet('scan')):navigate('more',x.id)} style={{padding:14,borderRadius:16,backgroundColor:F.surface,borderColor:F.line,borderWidth:1,marginBottom:9}}><Flex style={{gap:12}}><View style={{width:43,height:43,backgroundColor:x.tint+'16',borderRadius:13,alignItems:'center',justifyContent:'center'}}><I name={x.icon} color={x.tint} size={23}/></View><View style={{flex:1}}><Txt bold size={14}>{x.title}</Txt><Txt size={11} color={C.muted}>{x.subtitle}</Txt></View>{x.count?<Tag text={String(x.count)} color={C.orange} bg="#FFF3E6"/>:null}<I name="chevron-right" color="#AFB8C4"/></Flex></Pressable>)}
     <Section title="Tài khoản và phiên đăng nhập"/>
     <Panel><Txt size={12} color={C.muted} style={{marginBottom:10}}>Tài khoản đang sử dụng: {role.name}. Màn hình đăng nhập demo không xác thực mật khẩu và không thay thế hệ thống phân quyền Backend.</Txt>
       <Btn title="Đăng xuất" secondary icon="logout" onPress={()=>{setLoggedIn(false);navigate('home')}}/>
       <View style={{borderTopWidth:1,borderTopColor:C.line,paddingTop:12,marginTop:3}}><Btn secondary title="Khôi phục dữ liệu mẫu" icon="refresh" onPress={()=>setSheet('reset')}/></View>
     </Panel><Txt size={11} color={C.muted} style={{textAlign:'center',marginTop:6}}>STORIX v1.1 · Đối chiếu Jira CNPM · Demo offline · React Native + Expo</Txt>
   </>;
  const Suppliers=()=> <><TitleBar title="Nhà cung cấp" caption="Thông tin đối tác và lô hàng liên quan (dữ liệu mẫu)"/>
    {(data.suppliers||[]).map(n=><Panel key={n.id}><Flex style={{gap:9,marginBottom:7}}><I name="truck-delivery-outline" size={23} color={C.green}/><View style={{flex:1}}><Txt size={11} color={C.muted}>{n.code}</Txt><Txt size={15} bold>{n.name}</Txt></View></Flex><Txt size={12} color={C.muted}>Địa chỉ: {n.address}</Txt><Txt size={12} color={C.muted}>Số điện thoại: {n.phone}</Txt><Txt size={12} color={C.muted}>Email: {n.email}</Txt><Txt size={12} color={C.blue} style={{marginTop:9}}>Số lô liên quan: {(data.lots||[]).filter(l=>l.supplierId===n.id).length}</Txt></Panel>)}
  </>;
  const Lots=()=> <><TitleBar title="Lô hàng & nguồn gốc" caption="Thông tin lô hàng minh họa, chưa tính tồn theo lô"/>
    <Search value={search} onChange={setSearch} placeholder="Tìm mã lô, sản phẩm, nhà cung cấp..."/>
    {(data.lots||[]).filter(l=>[l.id,product(l.productId)?.name,data.suppliers.find(n=>n.id===l.supplierId)?.name].join(' ').toLowerCase().includes(search.toLowerCase())).map(l=>{
      const supplier=(data.suppliers||[]).find(n=>n.id===l.supplierId);
      const expired=l.expires&&new Date(l.expires+'T23:59:59')<new Date();
      return <Pressable key={l.id} onPress={()=>{setSelected(l);setSheet('lotDetail')}}><Panel><Flex style={{justifyContent:'space-between',marginBottom:5}}><Txt bold color={C.blue}>{l.id}</Txt><Tag text={expired?'Hết hạn':l.quality==='DAMAGED'?'Cần kiểm tra':'Bình thường'} color={expired||l.quality==='DAMAGED'?C.red:C.green} bg={expired?'#FDEFF0':C.pale}/></Flex><Txt bold size={14}>{product(l.productId)?.name}</Txt><Txt size={12} color={C.muted}>{supplier?.name||'Chưa khai báo nguồn cung'}</Txt><Txt size={12} color={C.muted} style={{marginTop:8}}>Ngày sản xuất: {l.manufactured} · Hạn dùng: {l.expires||'Không áp dụng'}</Txt><Txt size={11} color={C.green} style={{marginTop:6}}>Xem nguồn gốc →</Txt></Panel></Pressable>})}
  </>;
  const Alerts=()=> <><TitleBar title="Cảnh báo và thông báo" caption={`${unread.length} thông báo chưa đọc · sinh tự động từ dữ liệu mẫu`}/>
    <Btn secondary title="Đánh dấu tất cả đã đọc" icon="check-all" style={{marginBottom:14}} onPress={()=>commit(st=>({...st,readAlerts:[...new Set([...(st.readAlerts||[]),...alerts.map(a=>a.id)])]}),'Đã đánh dấu đã đọc.')}/>
    {alerts.length===0?<Empty title="Chưa có cảnh báo"/>:alerts.map(a=>{const read=(data.readAlerts||[]).includes(a.id);return <Pressable key={a.id} onPress={()=>commit(st=>({...st,readAlerts:[...new Set([...(st.readAlerts||[]),a.id])]}))}><Panel style={{backgroundColor:F.surfaceAlt}}><Flex style={{justifyContent:'space-between',marginBottom:6}}><Tag text={a.kind} color={a.severity==='danger'?C.red:a.severity==='warn'?C.orange:C.blue} bg={a.severity==='danger'?'#FFE8ED':'#FFF4E7'}/>{!read?<Txt size={11} color={C.blue} bold>Mới</Txt>:null}</Flex><Txt bold size={14}>{a.title}</Txt><Txt size={12} color={C.muted} style={{marginTop:5}}>{a.body}</Txt></Panel></Pressable>})}
  </>;
  const Ledger=()=> <><TitleBar title="Thẻ kho và biến động" caption="Lịch sử phiếu đã hoàn tất, kiểm kê và điều chỉnh"/>
    {stockLedger(viewData).filter(row=>visibleIds.has(row.placeId)).length===0?<Empty title="Chưa có biến động"/>:stockLedger(viewData).filter(row=>visibleIds.has(row.placeId)).map(row=><Panel key={row.id}><Flex style={{justifyContent:'space-between',marginBottom:7}}><Txt size={12} color={C.blue} bold>{row.id}</Txt><Txt size={11} color={C.muted}>{formatDate(row.date)}</Txt></Flex><Txt bold>{product(row.productId)?.name||row.productId}</Txt><Txt size={12} color={C.muted}>{place(row.placeId)?.name||'Nơi lưu trữ không xác định'}</Txt><Flex style={{justifyContent:'space-between',marginTop:9}}><Txt size={11} color={C.muted} style={{flex:1}}>{row.note}</Txt><Txt bold color={row.delta<0?C.red:C.green}>{row.delta>0?'+':''}{row.delta}</Txt></Flex></Panel>)}
  </>;
  const Screen=()=>sub==='requests'?Requests():sub==='counts'?Counts():sub==='reports'?Reports():sub==='suppliers'?Suppliers():sub==='lots'?Lots():sub==='alerts'?Alerts():sub==='ledger'?Ledger():tab==='home'?Home():tab==='products'?Products():tab==='places'?Places():tab==='flows'?Flows():More();
  const filterProducts=data.products.map(x=>({id:x.id,label:x.sku+' · '+x.name}));
  const enabledPlaces=data.places.filter(x=>x.enabled).map(x=>({id:x.id,label:x.name}));
  const allPlaces=visiblePlaces.map(x=>({id:x.id,label:x.name}));
  const readPlace=data.places.find(x=>x.id===selected?.id);
  const readProduct=data.products.find(x=>x.id===selected?.id);
  const readMovement=data.movements.find(x=>x.id===selected?.id);
  const overview=tab==='home'&&!sub;
  const demoMenu=[
    {title:'Tổng quan',items:[{id:'home',label:'Tổng quan',icon:'view-dashboard-outline',onPress:()=>navigate('home')}]},
    {title:'Danh mục',items:[
      {id:'products',label:'Sản phẩm',icon:'package-variant-closed',onPress:()=>navigate('products')},
      {id:'places',label:'Nơi lưu trữ',icon:'warehouse',onPress:()=>navigate('places')},
      {id:'suppliers',label:'Nhà cung cấp',icon:'truck-outline',onPress:()=>navigate('more','suppliers')},
      {id:'lots',label:'Lô hàng',icon:'layers-outline',onPress:()=>navigate('more','lots')} ]},
    {title:'Nghiệp vụ',items:[
      {id:'flows',label:'Phiếu nhập / xuất',icon:'clipboard-list-outline',onPress:()=>navigate('flows')},
      {id:'transfer',label:'Điều chuyển',icon:'swap-horizontal',onPress:()=>{navigate('flows');setFilter('TRANSFER');}},
      {id:'requests',label:'Bổ sung hàng',icon:'truck-delivery-outline',onPress:()=>navigate('more','requests')} ]},
    {title:'Kiểm soát',items:[
      {id:'counts',label:'Kiểm kê',icon:'clipboard-check-outline',onPress:()=>navigate('more','counts')},
      {id:'ledger',label:'Thẻ kho',icon:'history',onPress:()=>navigate('more','ledger')},
      {id:'alerts',label:'Cảnh báo',icon:'bell-alert-outline',onPress:()=>navigate('more','alerts')},
      {id:'reports',label:'Báo cáo',icon:'chart-bar',onPress:()=>navigate('more','reports')} ]},
    {title:'Hệ thống',items:[{id:'more',label:'Tiện ích và tài khoản',icon:'cog-outline',onPress:()=>navigate('more')}]},
  ];
  if(!ready)return <SafeAreaView style={{flex:1,backgroundColor:C.bg,alignItems:'center',justifyContent:'center'}}><StorixLogo size={75} style={{marginBottom:18}}/><Txt bold size={27}>storix<Text style={{color:C.green}}>.</Text></Txt><ActivityIndicator style={{marginTop:20}} color={C.green}/></SafeAreaView>;
  if(!loggedIn)return <SafeAreaView style={{flex:1,backgroundColor:BRAND.mint}}><StatusBar barStyle="dark-content" backgroundColor={BRAND.mint}/>
    <BrandAuthShell mode="demo" onSwitchMode={onBackToApi} subtitle="Trải nghiệm giao diện theo vai trò, không cần tài khoản thật" footer="Chế độ mô phỏng offline · Không đồng bộ dữ liệu lên SQL Server">
      <Choices label="TÀI KHOẢN MÔ PHỎNG" value={loginRole} items={ROLES.map(x=>({id:x.id,label:x.label}))} onChange={setLoginRole}/>
      <View style={{backgroundColor:'#F4F8FD',padding:13,borderRadius:9,borderWidth:1,borderColor:BRAND.border,marginVertical:8,flexDirection:'row',alignItems:'center',gap:10}}><I name="account-check-outline" color={BRAND.blue}/><View style={{flex:1}}><Txt bold size={13} color={BRAND.navy}>{roleInfo(loginRole).name}</Txt><Txt color={BRAND.slate} size={11}>{roleInfo(loginRole).label}</Txt></View></View>
      <BrandAuthNote>Chế độ demo sử dụng dữ liệu thử nghiệm trên thiết bị, không ghi vào API của nhóm.</BrandAuthNote>
      <BrandAuthButton title="Vào không gian làm việc" onPress={()=>{commit(st=>({...st,role:loginRole}));setLoggedIn(true);navigate('home')}}/>
    </BrandAuthShell>
  </SafeAreaView>;
  return <UiThemeProvider mode="light"><SafeAreaView style={{flex:1,backgroundColor:F.bg}}><StatusBar barStyle="dark-content" backgroundColor="#FFFFFF"/>
    <View style={{flex:1,flexDirection:'row',maxWidth:1440,width:'100%',alignSelf:'center',backgroundColor:F.bg}}>
      {desktop?<View style={{width:236}}><OverviewSidebar groups={demoMenu} activeId={tab} footer={role.name+' · '+role.label+' · DEMO'} onLogout={()=>setLoggedIn(false)}/></View>:null}
      <View style={{flex:1}}><OverviewTopbar desktop={desktop} activeLabel={NAV.find(x=>x.id===tab)?.label||'Tổng quan'} userName={role.name} onRefresh={()=>setToast('Số liệu demo được cập nhật tự động khi thay đổi dữ liệu.')} onAccount={()=>navigate('more')} onAlerts={()=>navigate('more','alerts')}/>
      <ScrollView key={`${tab}-${sub||''}`} style={{backgroundColor:F.bg}} keyboardShouldPersistTaps="handled" contentContainerStyle={{paddingHorizontal:desktop?24:14,paddingTop:12,paddingBottom:35,maxWidth:1300,width:'100%',alignSelf:'center'}}>{!overview?<WorkspaceRibbon section={NAV.find(x=>x.id===tab)?.label||'Tổng quan'} subtitle="Quản lý kho bãi · STORIX Retail Logistics"/>:null}
        {sub?<Pressable onPress={()=>navigate('more')} style={{flexDirection:'row',alignItems:'center',gap:6,marginBottom:16}}><I name="arrow-left" size={18} color={F.muted}/><Txt color={F.muted} size={12}>Quay lại tiện ích</Txt></Pressable>:null}
        {Screen()}
      </ScrollView>
      {!desktop?<View style={{flexDirection:'row',backgroundColor:'#FFFFFF',borderTopWidth:1,borderTopColor:F.line,paddingBottom:Platform.OS==='android'?8:4,paddingTop:9,paddingHorizontal:5}}>{NAV.map(x=><Pressable key={x.id} onPress={()=>navigate(x.id)} style={{flex:1,alignItems:'center',paddingVertical:3,gap:3}}><I name={x.icon} size={23} color={tab===x.id?F.blue:F.muted}/><Txt size={10} bold={tab===x.id} color={tab===x.id?F.blue:F.muted}>{x.label}</Txt></Pressable>)}</View>:null}
      </View>
    </View>
    {toast?<View pointerEvents="none" style={{position:'absolute',bottom:desktop?38:87,left:24,right:24,alignItems:'center'}}><View style={{backgroundColor:F.navy,paddingVertical:12,paddingHorizontal:17,borderRadius:13,maxWidth:540}}><Txt color={C.white} size={12} style={{textAlign:'center'}}>{toast}</Txt></View></View>:null}
    <Sheet visible={sheet==='product'} title={selected?'Chỉnh sửa sản phẩm':'Thêm sản phẩm mới'} onClose={()=>setSheet('')}>
      <Field label="Mã sản phẩm (SKU) *" value={pForm.sku} onChangeText={v=>setPForm(s=>({...s,sku:v}))}/><Field label="Barcode/QR sản phẩm" value={pForm.barcode} onChangeText={v=>setPForm(st=>({...st,barcode:v}))}/><Field label="Tên sản phẩm *" value={pForm.name} onChangeText={v=>setPForm(s=>({...s,name:v}))}/><Field label="Danh mục" value={pForm.category} onChangeText={v=>setPForm(s=>({...s,category:v}))}/><Field label="Đơn vị tính" value={pForm.unit} onChangeText={v=>setPForm(s=>({...s,unit:v}))}/><Field label="Đơn giá (VNĐ)" keyboardType="numeric" value={pForm.price} onChangeText={v=>setPForm(s=>({...s,price:v}))}/><Field label="Ngưỡng cảnh báo tồn tối thiểu" keyboardType="numeric" value={pForm.minStock} onChangeText={v=>setPForm(s=>({...s,minStock:v}))}/><Choices label="Trạng thái sản phẩm" items={[{id:'ACTIVE',label:'Đang kinh doanh'},{id:'INACTIVE',label:'Ngừng kinh doanh'}]} value={pForm.status||'ACTIVE'} onChange={v=>setPForm(st=>({...st,status:v}))}/><Btn title={selected?'Lưu thay đổi':'Tạo sản phẩm'} onPress={saveProduct} icon="check"/>
    </Sheet>
    <Sheet visible={sheet==='productDetail'} title="Chi tiết sản phẩm" onClose={()=>setSheet('')}>
      {readProduct?<><Flex style={{gap:12,marginBottom:18}}><View style={{width:57,height:57,borderRadius:15,backgroundColor:F.surfaceAlt,alignItems:'center',justifyContent:'center'}}><I name={readProduct.icon||'package-variant'} size={30} color="#4A8794"/></View><View style={{flex:1}}><Txt color={F.muted} size={12}>{readProduct.sku} · {readProduct.category}</Txt><Txt size={11} color={F.blue}>Mã Barcode: {readProduct.barcode||readProduct.sku}</Txt><Tag text={readProduct.status==='INACTIVE'?'Ngừng kinh doanh':'Đang kinh doanh'} color={readProduct.status==='INACTIVE'?F.red:F.green}/><Txt bold size={17}>{readProduct.name}</Txt></View></Flex>
      <Panel style={{backgroundColor:F.bg}}><Flex style={{justifyContent:'space-between'}}><Txt size={12} color={F.muted}>Tồn kho toàn hệ thống</Txt><Txt size={24} bold>{stockOf(viewData,readProduct.id)} {readProduct.unit}</Txt></Flex><Txt color={F.muted} size={12} style={{marginTop:7}}>Giá tham khảo: {formatMoney(readProduct.price)}</Txt><Txt size={12} color={F.muted}>Ngưỡng cảnh báo: {readProduct.minStock}</Txt>{transitOf(data,readProduct.id)?<Txt color={F.blue} size={12}>Đang vận chuyển: {transitOf(data,readProduct.id)}</Txt>:null}</Panel>
      <Section title="Tồn theo từng nơi"/>{visiblePlaces.filter(p=>stockOf(viewData,readProduct.id,p.id)>0).map(p=><Flex key={p.id} style={{justifyContent:'space-between',paddingVertical:11,borderBottomWidth:1,borderBottomColor:F.line}}><Txt size={12} style={{flex:1}}>{p.name}</Txt><Txt size={13} bold>{stockOf(viewData,readProduct.id,p.id)} {readProduct.unit}</Txt></Flex>)}
      <Section title="Các lô liên quan"/>{(data.lots||[]).filter(l=>l.productId===readProduct.id).map(l=><Pressable key={l.id} onPress={()=>{setSelected(l);setSheet('lotDetail')}} style={{paddingVertical:11,borderBottomColor:F.line,borderBottomWidth:1}}><Txt bold color={F.blue} size={12}>{l.id} →</Txt><Txt size={11} color={F.muted}>Hạn dùng: {l.expires||'Không áp dụng'}</Txt></Pressable>)}
      {canManage?<Btn title="Chỉnh sửa sản phẩm" icon="pencil-outline" secondary style={{marginTop:20}} onPress={()=>openProduct(readProduct)}/>:null}</>:null}
    </Sheet>
    <Sheet visible={sheet==='place'} title={selected?'Cập nhật nơi lưu trữ':'Tạo kho / bãi / cửa hàng'} onClose={()=>setSheet('')}>
      <Choices label="Loại nơi lưu trữ" items={TYPES} value={lForm.type} onChange={v=>setLForm(s=>({...s,type:v}))}/><Field label="Mã kho / bãi *" value={lForm.code} onChangeText={v=>setLForm(s=>({...s,code:v}))}/><Field label="Tên nơi lưu trữ *" value={lForm.name} onChangeText={v=>setLForm(s=>({...s,name:v}))}/><Field label="Địa chỉ" value={lForm.address} onChangeText={v=>setLForm(s=>({...s,address:v}))}/><Field label="Sức chứa tham khảo (đơn vị)" value={lForm.capacity} keyboardType="numeric" onChangeText={v=>setLForm(s=>({...s,capacity:v}))}/><Field multiline label="Danh sách vị trí (mỗi dòng một vị trí)" value={lForm.slotsText} onChangeText={v=>setLForm(s=>({...s,slotsText:v}))}/>
      <Choices label="Trạng thái" items={[{id:'open',label:'Hoạt động'},{id:'lock',label:'Tạm khóa nhận hàng'}]} value={lForm.enabled?'open':'lock'} onChange={v=>setLForm(s=>({...s,enabled:v==='open'}))}/>
      <Btn title="Lưu thông tin" icon="check" onPress={savePlace}/>
    </Sheet>
    <Sheet visible={sheet==='placeDetail'} title="Chi tiết kho và vị trí" onClose={()=>setSheet('')}>
      {readPlace?<><View style={{backgroundColor:F.bg,borderRadius:17,padding:16,marginBottom:14}}><Txt color={F.muted} size={12}>{readPlace.code} · {typeInfo(readPlace.type).label}</Txt><Txt bold size={18} style={{marginTop:4}}>{readPlace.name}</Txt><Txt color={F.muted} size={12}>{readPlace.address}</Txt><Txt size={13} bold style={{marginTop:14}}>Đang lưu trữ: {placeStock(data,readPlace.id)} / {readPlace.capacity}</Txt><View style={{marginTop:8}}><ProgressBar value={placeStock(data,readPlace.id)/Math.max(readPlace.capacity,1)*100}/></View></View>
      <Section title="Vị trí: khu / dãy / kệ / ô"/>{(readPlace.slots||[]).length?(readPlace.slots||[]).map((slot,i)=>{const goods=positionGoods(data,readPlace.id,i),locked=(readPlace.slotLocks||[]).includes(i);return <Panel key={i} style={{backgroundColor:F.bg}}><Flex style={{gap:9}}><I name="map-marker-outline" color={locked?F.red:F.green} size={19}/><Txt size={12} bold style={{flex:1}}>{slot}</Txt><Tag text={locked?"Khóa":"Sẵn sàng"} color={locked?F.red:F.green}/></Flex>{goods.length?goods.map(g=><Txt key={g.productId} size={11} color={F.muted} style={{marginTop:6}}>• {g.product?.name}: {g.qty} {g.product?.unit}</Txt>):<Txt size={11} color={F.muted} style={{marginTop:6}}>Vị trí chưa có hàng được gán.</Txt>}{canManage?<Btn title={locked?"Mở vị trí":"Khóa vị trí"} secondary small style={{marginTop:9}} onPress={()=>commit(st=>({...st,places:st.places.map(x=>x.id===readPlace.id?{...x,slotLocks:locked?(x.slotLocks||[]).filter(n=>n!==i):[...(x.slotLocks||[]),i]}:x)}),locked?"Đã mở vị trí.":"Đã khóa vị trí.")}/>:null}</Panel>;}):<Empty title="Chưa khai báo vị trí"/>}
      <Section title="Hàng đang tồn tại nơi này"/>{viewData.stocks.filter(s=>s.placeId===readPlace.id).map(s=><Flex key={s.productId} style={{justifyContent:'space-between',paddingVertical:10,borderBottomWidth:1,borderBottomColor:F.line}}><Txt size={12} style={{flex:1}}>{product(s.productId)?.name}</Txt><Txt bold size={12}>{s.qty} {product(s.productId)?.unit}</Txt></Flex>)}
      <Txt size={11} color={F.muted} style={{marginTop:15}}>Vị trí mặc định là vị trí đầu tiên của mỗi nơi. Bản demo gán mỗi sản phẩm tại một nơi vào một ô; chưa phân bổ cùng sản phẩm trên nhiều ô/lô.</Txt>
      {canManage?<Btn title="Chỉnh sửa kho / bãi" icon="pencil" secondary style={{marginTop:18}} onPress={()=>openPlace(readPlace)}/>:null}</>:null}
    </Sheet>
    <Sheet visible={sheet==='movement'} title="Tạo phiếu kho mới" onClose={()=>setSheet('')}>
      <Choices label="Nghiệp vụ" items={KINDS} value={mForm.kind} onChange={v=>setMForm(s=>({...s,kind:v}))}/><Choices label="Sản phẩm *" items={filterProducts} value={mForm.productId} onChange={v=>setMForm(s=>({...s,productId:v}))}/><Field label="Số lượng *" keyboardType="numeric" value={mForm.qty} onChangeText={v=>setMForm(s=>({...s,qty:v}))}/>
      {mForm.kind!=='IN'?<Choices label="Nơi xuất *" items={allPlaces} value={mForm.fromId} onChange={v=>setMForm(s=>({...s,fromId:v}))}/>:null}
      {mForm.kind!=='OUT'?<><Choices label="Nơi nhận *" items={enabledPlaces} value={mForm.toId} onChange={v=>setMForm(s=>({...s,toId:v,slotIndex:'0'}))}/><Choices label="Vị trí xếp hàng tại nơi nhận" items={(place(mForm.toId)?.slots||[]).map((label,i)=>({id:String(i),label:((place(mForm.toId)?.slotLocks||[]).includes(i)?'🔒 ':'')+label})).filter(x=>!(place(mForm.toId)?.slotLocks||[]).includes(Number(x.id)))} value={String(mForm.slotIndex||0)} onChange={v=>setMForm(st=>({...st,slotIndex:v}))}/></>:null}
      {mForm.kind!=='IN'?<Txt size={12} color={F.muted} style={{marginBottom:10}}>Tồn tại nơi xuất: <Txt bold>{stockOf(data,mForm.productId,mForm.fromId)} {product(mForm.productId)?.unit}</Txt></Txt>:null}
      <Field label="Ghi chú" multiline value={mForm.note} onChangeText={v=>setMForm(s=>({...s,note:v}))}/><Panel style={{backgroundColor:F.surfaceAlt}}><Txt size={12} color="#5D788F">Phiếu mới ở trạng thái Chờ duyệt. Sau khi duyệt và hoàn thành, số tồn kho sẽ được cập nhật theo nghiệp vụ.</Txt></Panel>
      <Btn icon="content-save-check-outline" title="Lưu phiếu mới" onPress={saveMovement}/>
    </Sheet>
    <Sheet visible={sheet==='movementDetail'} title="Theo dõi phiếu kho" onClose={()=>setSheet('')}>
      {readMovement? <><Flex style={{justifyContent:'space-between',marginBottom:15}}><View><Txt size={12} color={F.muted}>{readMovement.id}</Txt><Txt size={19} bold>{kindInfo(readMovement.kind).label}</Txt></View><Tag text={STATUS[readMovement.status]?.label} color={STATUS[readMovement.status]?.color} bg={STATUS[readMovement.status]?.bg}/></Flex>
        <Panel style={{backgroundColor:F.bg}}><Txt size={15} bold>{product(readMovement.productId)?.name}</Txt><Txt size={13} color={F.muted}>{formatNumber(readMovement.qty)} {product(readMovement.productId)?.unit}</Txt><View style={{height:1,backgroundColor:F.line,marginVertical:13}}/><Txt size={12} color={F.muted}>Nơi xuất</Txt><Txt bold size={13}>{place(readMovement.fromId)?.name||'Nhà cung cấp'}</Txt><Txt size={12} color={F.muted} style={{marginTop:10}}>Nơi nhận</Txt><Txt bold size={13}>{place(readMovement.toId)?.name||'Khách hàng'}</Txt><Txt size={12} color={F.muted} style={{marginTop:10}}>Người tạo: {readMovement.by} · {formatDate(readMovement.date)}</Txt>{readMovement.note?<Txt size={12} color={F.muted} style={{marginTop:9}}>Ghi chú: {readMovement.note}</Txt>:null}</Panel>
        <Section title="Quy trình xử lý"/>
        <Flex style={{gap:6,marginBottom:18}}>{['DRAFT',readMovement.kind==='TRANSFER'?'IN_TRANSIT':'APPROVED','DONE'].map((st,i)=><View key={st} style={{flex:1,alignItems:'center',gap:6}}><View style={{width:30,height:30,borderRadius:15,backgroundColor:st===readMovement.status||readMovement.status==='DONE'?F.green:'#E9EEF3',alignItems:'center',justifyContent:'center'}}><I name={i===2?'check':i===1?'truck-outline':'file-document-outline'} size={17} color={st===readMovement.status||readMovement.status==='DONE'?C.white:F.muted}/></View><Txt size={10} color={F.muted} style={{textAlign:'center'}}>{i===0?'Tạo phiếu':i===1?(readMovement.kind==='TRANSFER'?'Đang chuyển':'Duyệt phiếu'):'Hoàn thành'}</Txt></View>)}</Flex>
        {canManage&&!['DONE','CANCELLED'].includes(readMovement.status)?<><Btn title={readMovement.status==='DRAFT'?'Duyệt phiếu':readMovement.status==='IN_TRANSIT'?'Xác nhận đã nhận hàng':'Xác nhận hoàn thành'} icon="check-circle-outline" onPress={()=>{if(commit(s=>advanceMovement(s,readMovement.id),'Đã cập nhật trạng thái phiếu.')){setSheet('')}}}/><Btn secondary danger title="Hủy phiếu" icon="close-circle-outline" style={{marginTop:9}} onPress={()=>{if(commit(s=>cancelMovement(s,readMovement.id),'Đã hủy phiếu.'))setSheet('')}}/></>:null}
        {!canManage?<Txt size={12} color={F.muted}>Việc duyệt hoặc hoàn thành phiếu dành cho Quản lý kho và Quản trị viên.</Txt>:null}
      </>:null}
    </Sheet>
    <Sheet visible={sheet==='request'} title="Yêu cầu bổ sung hàng" onClose={()=>setSheet('')}>
      <Choices label="Sản phẩm" items={filterProducts} value={rForm.productId} onChange={v=>setRForm(s=>({...s,productId:v}))}/><Choices label="Cửa hàng nhận" items={visiblePlaces.filter(x=>x.type==='store').map(x=>({id:x.id,label:x.name}))} value={rForm.storeId} onChange={v=>setRForm(s=>({...s,storeId:v}))}/><Choices label="Kho cung cấp" items={data.places.filter(x=>x.type==='warehouse').map(x=>({id:x.id,label:x.name}))} value={rForm.fromId} onChange={v=>setRForm(s=>({...s,fromId:v}))}/><Field label="Số lượng cần bổ sung" keyboardType="numeric" value={rForm.qty} onChangeText={v=>setRForm(s=>({...s,qty:v}))}/><Field label="Lý do / ghi chú" multiline value={rForm.note} onChangeText={v=>setRForm(s=>({...s,note:v}))}/><Btn title="Gửi yêu cầu" icon="send-outline" onPress={saveRequest}/>
    </Sheet>
    <Sheet visible={sheet==='count'} title="Tạo đợt kiểm kê" onClose={()=>setSheet('')}>
      <Choices label="Sản phẩm kiểm kê" items={filterProducts} value={cForm.productId} onChange={v=>setCForm(s=>({...s,productId:v}))}/><Choices label="Nơi kiểm kê" items={allPlaces} value={cForm.placeId} onChange={v=>setCForm(s=>({...s,placeId:v,actual:''}))}/><Panel style={{backgroundColor:F.bg}}><Txt size={12} color={F.muted}>Số lượng trong hệ thống</Txt><Txt size={24} bold>{stockOf(data,cForm.productId,cForm.placeId)} {product(cForm.productId)?.unit}</Txt></Panel><Field label="Số lượng thực tế đã đếm" value={cForm.actual} keyboardType="numeric" onChangeText={v=>setCForm(s=>({...s,actual:v}))}/><Txt color={F.orange} size={12} style={{marginBottom:14}}>Xác nhận sẽ cập nhật tồn kho ngay và lưu nhật ký kiểm kê.</Txt><Btn title="Xác nhận kiểm kê" icon="check-circle-outline" onPress={saveCount}/>
    </Sheet>
    <Sheet visible={sheet==='lotDetail'} title="Truy xuất nguồn gốc lô" onClose={()=>setSheet('')}>
      {selected?.id?.startsWith('LOT-')?<><Panel style={{backgroundColor:F.bg}}><Txt bold size={20} color={F.blue}>{selected.id}</Txt><Txt bold style={{marginTop:8}}>{product(selected.productId)?.name}</Txt><Txt size={12} color={F.muted}>Nhà cung cấp: {(data.suppliers||[]).find(n=>n.id===selected.supplierId)?.name}</Txt><Txt size={12} color={F.muted}>Ngày sản xuất: {selected.manufactured}</Txt><Txt size={12} color={F.muted}>Hạn sử dụng: {selected.expires||'Không áp dụng'}</Txt><Txt size={12} color={F.muted}>Ngày nhận: {selected.received}</Txt><Txt size={12} color={F.muted}>Phiếu nhập nguồn: {selected.receiptId}</Txt><Tag text={selected.quality==='DAMAGED'?'Cần kiểm tra chất lượng':'Lô đạt trạng thái mẫu'} color={selected.quality==='DAMAGED'?F.red:F.green}/></Panel><Txt size={12} color={F.muted}>Thông tin truy xuất trong bản demo được tạo mẫu và chưa liên kết tự động với số lượng tồn kho ở cấp lô.</Txt></>:null}
    </Sheet>
    <Sheet visible={sheet==='scan'} title="Quét Barcode / QR" onClose={()=>setSheet('')}>
      {sheet==='scan'?<ScanCamera onScanned={value=>setCodeInput(value)}/>:null}
      <View style={{marginTop:12}}><Field label="Nhập mã thủ công hoặc mã vừa quét" value={codeInput} onChangeText={setCodeInput} placeholder="SP-001, 8936000000001, LOT-260901, KHO-HCM..."/></View>
      {codeInput?<Panel style={{backgroundColor:F.bg}}>{findCode(viewData,codeInput)?<><Txt bold size={14}>Đã tìm thấy {findCode(viewData,codeInput).type==='product'?'sản phẩm':findCode(viewData,codeInput).type==='lot'?'lô hàng':'nơi lưu trữ'}</Txt><Txt size={13} color={F.muted} style={{marginVertical:8}}>{findCode(viewData,codeInput).item.name||findCode(viewData,codeInput).item.id}</Txt><Btn title="Xem chi tiết" onPress={()=>{let m=findCode(viewData,codeInput);setSelected(m.item);setSheet(m.type==='lot'?'lotDetail':m.type==='place'?'placeDetail':'productDetail')}}/></>:<><Txt color={F.red} size={12} bold>Không tìm thấy mã này</Txt><Txt size={11} color={F.muted}>Thử các mã demo: SP-001, 8936000000001, LOT-260901, KHO-HCM</Txt></>}</Panel>:<Txt color={F.muted} size={12}>Bạn có thể thử nhập mã bằng bàn phím nếu không có camera.</Txt>}
    </Sheet>
    <Sheet visible={sheet==='reset'} title="Khôi phục dữ liệu mẫu?" onClose={()=>setSheet('')}><Txt size={13} color={F.muted} style={{marginBottom:18}}>Tất cả sản phẩm, phiếu và thay đổi đã lưu trên thiết bị sẽ bị thay thế bằng dữ liệu mẫu ban đầu. Thao tác này không thể hoàn tác.</Txt><Btn danger title="Đồng ý khôi phục" icon="refresh" onPress={()=>{const v=makeSeed();current.current=v;setData(v);setSheet('');navigate('home');setToast('Đã khôi phục dữ liệu mẫu.')}}/><Btn secondary title="Hủy" style={{marginTop:9}} onPress={()=>setSheet('')}/></Sheet>
  </SafeAreaView></UiThemeProvider>;
}
