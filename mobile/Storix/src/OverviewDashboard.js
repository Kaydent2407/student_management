import React from 'react';
import {View,Text,Pressable,ScrollView,Platform} from 'react-native';
import {MaterialCommunityIcons as Icon} from '@expo/vector-icons';
import StorixLogo from './StorixLogo';

// STORIX | Màn Tổng quan theo mẫu Web. Không thay đổi BrandAuth / trang xác thực.
const P={background:'#F9F9FF',paper:'#FFFFFF',border:'#E2E8F0',ink:'#172B4D',sub:'#64748B',blue:'#3674B5',blue2:'#115B9B',mint:'#D1F8EF',pale:'#EAF2FF',orange:'#F36521',red:'#D84656',green:'#1E946F'};
const font = Platform.select({web:'Inter, system-ui, -apple-system, Segoe UI, sans-serif',default:undefined});
const fmt=value=>value===null||value===undefined?'—':Number(value).toLocaleString('vi-VN');
const SText=({children,size=13,bold=false,color=P.ink,style={},lines})=><Text numberOfLines={lines} style={[{fontSize:size,fontWeight:bold?'700':'400',color,lineHeight:Math.round(size*1.5),fontFamily:font},style]}>{children}</Text>;
const Glyph=({name='cube-outline',size=18,color=P.blue})=><Icon name={name} size={size} color={color}/>;
const cardShadow=Platform.select({web:{boxShadow:'0 3px 18px rgba(33,57,88,.045)'},default:{elevation:1}});
const Card=({children,style={}})=><View style={[{backgroundColor:P.paper,borderRadius:13,borderColor:P.border,borderWidth:1,padding:17,...cardShadow},style]}>{children}</View>;
const Action=({label,onPress,icon='arrow-right',disabled=false})=><Pressable accessibilityRole="button" disabled={disabled||!onPress} onPress={onPress} style={{flexDirection:'row',alignItems:'center',gap:4,paddingVertical:5}}><SText size={11} color={disabled?P.sub:P.blue} bold>{label}</SText><Glyph name={icon} size={13} color={disabled?P.sub:P.blue}/></Pressable>;
const statusLabel=status=>({PENDING:'Chờ xử lý',DRAFT:'Chờ duyệt',APPROVED:'Đã duyệt',IN_TRANSIT:'Đang chuyển',DONE:'Hoàn thành',COMPLETED:'Hoàn thành',REJECTED:'Từ chối'}[String(status||'').toUpperCase()]||status||'Chờ xử lý');
const Badge=({text,tone='blue'})=>{const color=tone==='orange'?P.orange:tone==='green'?P.green:P.blue;const bg=tone==='orange'?'#FFF1E9':tone==='green'?'#EAF9F2':P.pale;return <View style={{paddingVertical:4,paddingHorizontal:8,borderRadius:6,backgroundColor:bg,alignSelf:'flex-start'}}><SText size={10} bold color={color}>{text}</SText></View>};
const onClickBox=(onPress,children,style={})=><Pressable accessibilityRole="button" disabled={!onPress} onPress={onPress} style={style}>{children}</Pressable>;

export function OverviewSidebar({groups=[],activeId='home',onLogout,footer='',compact=false}){
  return <View style={{backgroundColor:P.paper,flex:1,borderRightWidth:1,borderColor:P.border,paddingHorizontal:compact?12:16,paddingTop:15}}>
    <View style={{flexDirection:'row',alignItems:'center',gap:9,paddingBottom:14,borderBottomWidth:1,borderColor:P.border,marginBottom:11}}><StorixLogo size={35}/><View style={{flex:1}}><SText bold size={17} color={P.blue}>STORIX</SText><SText size={9} color={P.sub}>Quản lý chuỗi cung ứng</SText></View></View>
    <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{paddingBottom:20}}>
      {groups.map((group,i)=><View key={group.title||i} style={{marginBottom:14}}><SText color={P.sub} bold size={10} style={{letterSpacing:.8,marginBottom:5}}>{group.title.toUpperCase()}</SText>
        {group.items.map(item=><Pressable key={item.id} accessibilityRole="button" disabled={item.disabled||!item.onPress} onPress={item.onPress} style={({pressed})=>({paddingVertical:9,paddingHorizontal:9,borderRadius:8,marginBottom:2,backgroundColor:activeId===item.id?'#EAF1FF':pressed?'#F3F7FD':'transparent',flexDirection:'row',alignItems:'center',gap:9,opacity:item.disabled?.4:1})}>
          <Glyph name={item.icon||'circle-outline'} size={15} color={activeId===item.id?P.blue:P.ink}/><SText size={12} bold={activeId===item.id} color={activeId===item.id?P.blue:P.ink} lines={1}>{item.label}</SText>
        </Pressable>)}
      </View>)}
      <View style={{padding:10,borderRadius:9,backgroundColor:'#F1F5FC',marginTop:7}}><SText color={P.sub} size={10}>{footer}</SText></View>
      {onLogout?<Pressable onPress={onLogout} style={{flexDirection:'row',alignItems:'center',gap:8,padding:11,marginTop:11}}><Glyph name="logout" size={17}/><SText size={12}>Đăng xuất</SText></Pressable>:null}
    </ScrollView>
  </View>;
}
export function OverviewTopbar({userName='STORIX',onRefresh,onAccount,onAlerts,desktop=false,activeLabel='Tổng quan'}){
  return <View style={{minHeight:59,backgroundColor:P.paper,borderBottomWidth:1,borderBottomColor:P.border,paddingHorizontal:desktop?24:16,paddingVertical:10,flexDirection:'row',alignItems:'center',gap:12}}>
    {!desktop?<StorixLogo size={30}/>:null}
    <View style={{flex:1,flexDirection:'row',gap:5,alignItems:'center'}}><SText size={11} color={P.sub}>Trang chủ</SText><Glyph name="chevron-right" size={13} color={P.sub}/><SText size={11} bold color={P.blue}>{activeLabel}</SText></View>
    <Pressable onPress={onRefresh} accessibilityLabel="Làm mới" style={{padding:8,backgroundColor:'#F3F7FF',borderRadius:7}}><Glyph name="refresh" size={18}/></Pressable>
    {onAlerts?<Pressable onPress={onAlerts} accessibilityLabel="Xem cảnh báo" style={{padding:8}}><Glyph name="bell-badge-outline" size={19} color={P.orange}/></Pressable>:null}
    <Pressable onPress={onAccount} accessibilityLabel="Tài khoản" style={{flexDirection:'row',alignItems:'center',gap:8,maxWidth:desktop?200:115}}><View style={{width:28,height:28,borderRadius:7,backgroundColor:'#EAF1FF',alignItems:'center',justifyContent:'center'}}><Glyph name="account" color={P.blue}/></View>{desktop?<View style={{maxWidth:140}}><SText size={11} bold lines={1}>{userName}</SText><SText size={9} color={P.sub}>Tài khoản</SText></View>:null}</Pressable>
  </View>
}
function SummaryCard({item,onPress,wide}){
  return <Card style={{flexGrow:1,flexBasis:wide?'21%':'44%',minWidth:0,padding:14,justifyContent:'space-between',minHeight:142}}>
    <View style={{flexDirection:'row',justifyContent:'space-between',alignItems:'flex-start',gap:5}}><View style={{flex:1}}><SText size={11} color={P.sub}>{item.title}</SText><View style={{flexDirection:'row',alignItems:'baseline',flexWrap:'wrap',gap:5,marginTop:5}}><SText bold size={27} color={item.warn?P.orange:P.ink}>{fmt(item.value)}</SText>{item.unit?<SText size={10} color={P.sub}>{item.unit}</SText>:null}</View></View><View style={{height:31,width:31,borderRadius:7,alignItems:'center',justifyContent:'center',backgroundColor:item.warn?'#FFF2DE':'#EBF3FF'}}><Glyph name={item.icon} color={item.warn?P.orange:P.blue} size={19}/></View></View>
    <SText size={10} color={P.sub} style={{marginTop:7,marginBottom:7}}>{item.caption}</SText><Action label={item.action} onPress={onPress} disabled={!onPress}/>
  </Card>
}
function BarsChart({weekly=[],inTotal,outTotal}){
  const max=Math.max(1,...weekly.flatMap(d=>[d.inbound||0,d.outbound||0]));
  const axisHeight=162; const ticks=[4,3,2,1,0];const chartHeight=axisHeight;
  const displayedMax=max<=4?4:Math.ceil(max/2)*2;
  const incoming=weekly.reduce((s,d)=>s+(d.inbound||0),0);
  return <Card style={{flex:1,minWidth:0}}>
    <View style={{flexDirection:'row',alignItems:'flex-start',justifyContent:'space-between',gap:9,marginBottom:15}}><View style={{flex:1}}><SText bold size={16}>Phiếu nhập và xuất đã hoàn thành</SText><SText size={10} color={P.sub}>Theo ngày tạo phiếu · 7 ngày gần nhất</SText></View><View style={{gap:5}}><View style={{flexDirection:'row',alignItems:'center',gap:5}}><View style={{width:8,height:8,backgroundColor:P.blue,borderRadius:2}}/><SText size={10}>Phiếu nhập</SText></View><View style={{flexDirection:'row',alignItems:'center',gap:5}}><View style={{width:8,height:8,backgroundColor:P.orange,borderRadius:2,opacity:outTotal===null?.4:1}}/><SText size={10}>Phiếu xuất</SText></View></View></View>
    <View style={{height:chartHeight+27,flexDirection:'row'}}><View style={{width:23,justifyContent:'space-between',paddingBottom:25}}>{ticks.map(t=><SText key={t} size={9} color={P.sub}>{Math.round(displayedMax*t/4)}</SText>)}</View>
      <View style={{flex:1}}><View style={{position:'absolute',left:0,right:0,top:0,bottom:25,justifyContent:'space-between'}}>{ticks.map(t=><View key={t} style={{borderBottomWidth:1,borderColor:P.border}}/>)}</View>
        <View style={{flex:1,flexDirection:'row',alignItems:'flex-end',justifyContent:'space-around',paddingBottom:24}}>{weekly.map((d,i)=><View key={d.key||i} style={{flex:1,height:chartHeight,justifyContent:'flex-end',alignItems:'center',minWidth:0}}><View style={{height:chartHeight-20,flexDirection:'row',alignItems:'flex-end',gap:3}}><View style={{width:11,height:Math.max(0,(d.inbound||0)/displayedMax*(chartHeight-20)),backgroundColor:P.blue,borderTopLeftRadius:3,borderTopRightRadius:3}}/>{d.outbound!==null?<View style={{width:11,height:Math.max(0,(d.outbound||0)/displayedMax*(chartHeight-20)),backgroundColor:P.orange,borderTopLeftRadius:3,borderTopRightRadius:3}}/>:<View style={{width:11,height:0}}/>}</View><SText size={9} color={P.sub} style={{marginTop:7}}>{d.label}</SText></View>)}</View>
      </View></View>
    <View style={{paddingTop:12,borderTopWidth:1,borderColor:P.border,flexDirection:'row',justifyContent:'space-between',flexWrap:'wrap',gap:7}}><SText size={11} color={P.sub}>7 ngày: <SText bold color={P.blue}>{incoming} phiếu nhập</SText>{outTotal!==null?` · ${weekly.reduce((s,d)=>s+(d.outbound||0),0)} phiếu xuất`:' · Phiếu xuất: chưa có API'}</SText></View>
  </Card>;
}
function CapacityCard({items=[],onOpen}){
  return <Card style={{flex:1,minWidth:0}}><SText bold size={16}>Sức chứa theo nơi</SText><SText size={10} color={P.sub} style={{marginTop:2,marginBottom:15}}>Sức chứa sử dụng tại nơi được phân quyền</SText>
    {items.length===0?<SText size={12} color={P.sub}>Chưa có nơi lưu trữ được phân quyền.</SText>:items.map((place,i)=><Pressable accessibilityRole="button" disabled={!onOpen} onPress={()=>onOpen(place)} key={place.id||i} style={{padding:11,backgroundColor:i%2===0?'#F1F5FF':'#FFF8F4',borderRadius:10,marginBottom:10,borderWidth:1,borderColor:P.border}}>
      <View style={{flexDirection:'row',gap:6,alignItems:'center'}}><Glyph name="warehouse" size={16} color={P.blue}/><SText size={12} bold lines={1} style={{flex:1}}>{place.name}</SText>{place.percent!==null?<Badge text={place.percent>=85?'Gần đầy':'Bình thường'} tone={place.percent>=85?'orange':'green'}/>:<Badge text="Chưa có tỷ lệ"/>}</View>
      <View style={{flexDirection:'row',justifyContent:'space-between',gap:4,marginTop:5}}><SText size={10} color={P.sub}>Đã dùng / sức chứa</SText><SText size={11} bold>{place.used===null?'—':fmt(place.used)} / {fmt(place.capacity)} {place.unit}</SText></View>
      <View style={{height:6,backgroundColor:'#E0E8F3',borderRadius:9,overflow:'hidden',marginTop:7}}>{place.percent!==null?<View style={{height:6,width:`${Math.max(0,Math.min(100,place.percent))}%`,backgroundColor:place.percent>=85?P.orange:P.blue,borderRadius:9}}/>:null}</View>
    </Pressable>)}<Action label="Xem chi tiết quản lý sức chứa" onPress={onOpen}/>
  </Card>;
}
function QueueTable({queue=[],onRow,onAll}){
  return <Card style={{flex:1,minWidth:0}}><View style={{flexDirection:'row',justifyContent:'space-between',gap:8,alignItems:'center',marginBottom:14}}><View><SText bold size={16}>Phiếu cần xử lý</SText><SText size={10} color={P.sub}>Danh sách phiếu chưa hoàn thành</SText></View><Badge text={`${queue.length} đang hiển thị`}/></View>
    <ScrollView horizontal showsHorizontalScrollIndicator={false}><View style={{minWidth:500,width:'100%'}}><View style={{backgroundColor:'#F1F5FF',flexDirection:'row',paddingVertical:10,paddingHorizontal:10,gap:8}}><View style={{flex:1.2}}><SText bold size={10}>MÃ PHIẾU</SText></View><View style={{flex:1.1}}><SText bold size={10}>NGHIỆP VỤ</SText></View><View style={{flex:2}}><SText bold size={10}>NƠI LIÊN QUAN</SText></View><View style={{flex:1}}><SText bold size={10}>TRẠNG THÁI</SText></View></View>
      {queue.length===0?<View style={{padding:15}}><SText size={12} color={P.sub}>Không có phiếu chờ xử lý trong dữ liệu hiện có.</SText></View>:queue.map((r,i)=><Pressable accessibilityRole="button" disabled={!onRow} onPress={()=>onRow(r)} key={`${r.id}-${i}`} style={{flexDirection:'row',gap:8,alignItems:'center',paddingVertical:12,paddingHorizontal:10,borderBottomWidth:1,borderBottomColor:P.border}}><View style={{flex:1.2}}><SText bold size={11} color={P.blue}>{r.id}</SText></View><View style={{flex:1.1}}><SText size={11}>{r.kind}</SText></View><View style={{flex:2}}><SText size={11} lines={2}>{r.placeName}</SText></View><View style={{flex:1}}><Badge text={statusLabel(r.status)} tone={r.status==='IN_TRANSIT'?'orange':'blue'}/></View></Pressable>)}
    </View></ScrollView><Action label="Xem tất cả phiếu" onPress={onAll}/>
  </Card>;
}
function AlertCard({alerts=[],onOpen,source}){
  return <Card style={{flex:1,minWidth:0}}><View style={{flexDirection:'row',gap:8,alignItems:'center',justifyContent:'space-between'}}><SText bold size={16}>Cảnh báo mới</SText><Badge text={source==='api'?'Chưa có API':`${alerts.length} cảnh báo`} tone="orange"/></View>
    <SText size={10} color={P.sub} style={{marginTop:4,marginBottom:13}}>Tồn kho thấp · Hết hạn · Sức chứa</SText>
    {source==='api'?<View style={{padding:12,backgroundColor:'#F1F5FF',borderRadius:8}}><SText size={12} color={P.sub}>Backend hiện chưa cung cấp endpoint cảnh báo. Không hiển thị cảnh báo giả.</SText></View>:alerts.length===0?<SText size={12} color={P.sub}>Không có cảnh báo mới.</SText>:alerts.map((a,i)=><Pressable key={a.id||i} onPress={onOpen} disabled={!onOpen} style={{padding:11,backgroundColor:i%2===0?'#FFF4F2':'#F2F5FF',borderRadius:9,marginBottom:9}}><View style={{flexDirection:'row',alignItems:'center',gap:6,marginBottom:4}}><Glyph name="alert-circle-outline" size={15} color={a.severity==='danger'?P.red:P.orange}/><SText size={11} bold color={a.severity==='danger'?P.red:P.orange}>{a.kind}</SText></View><SText size={11} bold lines={2}>{a.title}</SText><SText size={10} color={P.sub} lines={3}>{a.body}</SText></Pressable>)}
    {source!=='api'?<Action label="Xem tất cả cảnh báo" onPress={onOpen}/>:null}
  </Card>;
}
export default function OverviewDashboard({data,screenWidth=1200,onNavigate=()=>{},onOpenQueue,onOpenCapacity,onOpenAlerts}){
  const wide=screenWidth>=1160,compact=screenWidth<850;
  const metric=[
    {title:'Tổng sản phẩm',value:data.productCount,unit:'mã SP',icon:'package-variant-closed',caption:data.source==='api'?'Dữ liệu sản phẩm từ API':'Danh mục trong hệ thống',action:'Xem danh mục sản phẩm',route:'products'},
    {title:'Phiếu cần xử lý',value:data.pendingCount,unit:'phiếu',icon:'clipboard-text-clock-outline',caption:data.source==='api'?'Phiếu nhập trong trang đã tải':'Nhập · xuất · điều chuyển',action:'Chuyển đến danh sách',route:'flows'},
    {title:'Sản phẩm tồn thấp',value:data.lowCount,unit:'sản phẩm',icon:'alert-outline',caption:data.source==='api'?'Chưa có endpoint tổng hợp':'Số mặt hàng dưới ngưỡng',action:'Xem danh sách tồn thấp',route:'low',warn:true},
    {title:'Phiếu đang điều chuyển',value:data.transferringCount,unit:'phiếu',icon:'truck-delivery-outline',caption:data.source==='api'?'Chưa có endpoint điều chuyển':'Đang trên đường vận chuyển',action:'Theo dõi điều chuyển',route:'transfer'},
  ];
  const nav=(route)=>onNavigate(route);
  return <View style={{paddingTop:8,paddingBottom:36}}>
    <View style={{flexDirection:compact?'column':'row',justifyContent:'space-between',alignItems:compact?'flex-start':'center',marginBottom:17,gap:10}}>
      <View style={{maxWidth:370}}><SText size={25} bold>Tổng quan</SText><SText size={12} color={P.sub}>Theo dõi hàng hóa và công việc trong phạm vi được phân công</SText></View>
      <View style={{gap:8,alignItems:compact?'flex-start':'flex-end'}}><Badge text={data.source==='api'?'Dữ liệu từ API':'Chế độ demo'}/><View style={{flexDirection:'row',alignItems:'center',gap:6}}><Glyph name="map-marker-outline" size={14}/><SText color={P.sub} size={10}>{data.scopeLabel}</SText></View></View>
    </View>
    <View style={{flexDirection:'row',flexWrap:'wrap',gap:12,marginBottom:16}}>{metric.map(m=><SummaryCard key={m.title} item={m} wide={wide} onPress={data.source==='api'&&['low','transfer'].includes(m.route)?null:()=>nav(m.route)}/>)}</View>
    <View style={{flexDirection:compact?'column':'row',gap:14,alignItems:'stretch',marginBottom:14}}><View style={{flex:compact?undefined:1.6}}><BarsChart weekly={data.weekly} inTotal={data.totalInbound} outTotal={data.totalOutbound}/></View><View style={{flex:compact?undefined:1}}><CapacityCard items={data.capacities} onOpen={onOpenCapacity||(()=>nav('places'))}/></View></View>
    <View style={{flexDirection:compact?'column':'row',gap:14,alignItems:'stretch'}}><View style={{flex:compact?undefined:1.6}}><QueueTable queue={data.queue} onRow={onOpenQueue} onAll={()=>nav('flows')}/></View><View style={{flex:compact?undefined:1}}><AlertCard source={data.source} alerts={data.alerts} onOpen={onOpenAlerts}/></View></View>
    <View style={{marginTop:15,paddingVertical:12,paddingHorizontal:14,borderRadius:9,backgroundColor:'#EBF2FA',borderWidth:1,borderColor:P.border}}><SText color={P.sub} size={10}>{data.note}</SText></View>
  </View>;
}
