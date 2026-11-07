import React,{useState} from 'react';
import {View,Platform} from 'react-native';
import {CameraView,useCameraPermissions} from 'expo-camera';
import {Txt,Btn,C} from './ui';
export default function ScanCamera({onScanned}){
  const [permission,requestPermission]=useCameraPermissions();
  const [locked,setLocked]=useState(false);
  if(!permission)return <Txt size={12}>Đang kiểm tra camera...</Txt>;
  if(!permission.granted)return <View style={{gap:10}}><Txt color={C.muted} size={12}>Cho phép sử dụng camera để quét Barcode hoặc QR. Trên web có thể nhập mã thủ công ở dưới.</Txt><Btn title="Cấp quyền camera" icon="camera" onPress={requestPermission}/></View>;
  return <View style={{gap:8}}><CameraView style={{height:245,borderRadius:14,overflow:'hidden'}} facing="back" barcodeScannerSettings={{barcodeTypes:['qr','ean13','ean8','code128','code39','upc_a']}} onBarcodeScanned={locked?undefined:({data})=>{setLocked(true);onScanned(data)}}/>
    <Txt size={11} color={C.muted}>Đưa mã của sản phẩm, lô hoặc kho vào khung hình. Trên web cần cấp quyền camera trình duyệt.</Txt>
    {locked?<Btn secondary title="Quét mã khác" icon="refresh" onPress={()=>setLocked(false)}/>:null}</View>;
}
