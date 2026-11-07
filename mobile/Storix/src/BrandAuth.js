/**
 * STORIX authentication screen inspired by the project's Figma/Web login reference.
 * Authentication surfaces use readable dark text on a white card; operational
 * screens use a separate dark theme with all text white.
 */
import React, {useState} from 'react';
import {View, Text, TextInput, Pressable, ScrollView, Platform, useWindowDimensions} from 'react-native';
import {MaterialCommunityIcons as Icon} from '@expo/vector-icons';
import StorixLogo from './StorixLogo';

export const BRAND={mint:'#D1F8EF',mintSoft:'#E8FCF8',navy:'#172B4D',blue:'#165F9F',blueHover:'#3674B5',slate:'#475569',border:'#E4EAF2',white:'#FFFFFF'};
const shadow=Platform.select({web:{boxShadow:'0px 22px 65px rgba(23,43,77,.14)'},ios:{shadowColor:'#172B4D',shadowOpacity:0.14,shadowRadius:22,shadowOffset:{width:0,height:14}},android:{elevation:7}});

export function BrandAuthShell({children,mode='api',onSwitchMode,onForgotPassword,title='Đăng nhập',showHelp=true,footer,subtitle='Quản lý sản phẩm, kho hàng và bãi lưu trữ'}){
  const {width}=useWindowDimensions(),small=width<450;
  return <View style={{flex:1,backgroundColor:BRAND.mint}}>
    <View pointerEvents="none" style={{position:'absolute',top:-130,left:-110,width:335,height:335,borderRadius:180,backgroundColor:'#E7FFFF',opacity:.60}}/>
    <View pointerEvents="none" style={{position:'absolute',bottom:-160,right:-90,width:380,height:380,borderRadius:200,backgroundColor:'#C7F4F4',opacity:.72}}/>
    <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={{flexGrow:1,alignItems:'center',justifyContent:'center',paddingHorizontal:small?15:25,paddingVertical:35}}>
      <View style={{width:'100%',maxWidth:470}}>
        <View style={{backgroundColor:'#E7F0FF',borderRadius:30,alignSelf:'center',paddingVertical:9,paddingHorizontal:16,marginBottom:16,borderWidth:1,borderColor:'#D4E5FA',flexDirection:'row',alignItems:'center',gap:9,flexWrap:'wrap',justifyContent:'center'}}>
          <Icon name="shield-check-outline" size={16} color={BRAND.blue}/>
          <Text style={{fontSize:11,fontWeight:'700',color:BRAND.navy}}>STORIX</Text>
          <Text style={{fontSize:11,color:BRAND.slate}}>·</Text>
          <Text style={{fontSize:11,fontWeight:'700',color:BRAND.blue}}>{mode==='api'?'Kết nối API':'Trải nghiệm demo'}</Text>
          {onSwitchMode?<Pressable onPress={onSwitchMode} accessibilityRole="button" style={{paddingHorizontal:9,paddingVertical:4,backgroundColor:BRAND.white,borderRadius:16,borderWidth:1,borderColor:'#CFDFF1'}}><Text style={{fontSize:11,fontWeight:'700',color:BRAND.blue}}>{mode==='api'?'Xem demo':'Về API'}</Text></Pressable>:null}
        </View>
        <View style={[{backgroundColor:BRAND.white,borderRadius:15,padding:small?23:32,borderWidth:1,borderColor:'#E9EFF5'},shadow]}>
          <View style={{flexDirection:'row',alignItems:'center',marginBottom:27,gap:12}}>
            <StorixLogo size={48}/>
            <View style={{flex:1}}><Text style={{fontWeight:'800',color:BRAND.navy,fontSize:19,letterSpacing:.3}}>STORIX</Text><Text style={{fontWeight:'700',fontSize:9,letterSpacing:1,color:BRAND.slate}}>RETAIL LOGISTICS</Text></View>
            <View style={{flexDirection:'row',alignItems:'center',gap:4,backgroundColor:'#F2FAFB',paddingHorizontal:9,paddingVertical:6,borderRadius:16}}><View style={{height:6,width:6,borderRadius:4,backgroundColor:'#27B495'}}/><Text style={{color:BRAND.slate,fontSize:10}}>UI v1.5</Text></View>
          </View>
          <Text style={{fontSize:24,lineHeight:31,fontWeight:'800',color:'#13213C',marginBottom:5}}>{title}</Text>
          <Text style={{fontSize:12,lineHeight:18,color:BRAND.slate,marginBottom:22}}>{subtitle}</Text>
          {children}
          {showHelp ? <>
            <View style={{height:1,backgroundColor:BRAND.border,marginTop:22,marginBottom:15}}/>
            <Pressable disabled={!onForgotPassword} onPress={onForgotPassword} accessibilityRole={onForgotPassword?'button':undefined} accessibilityLabel="Quên mật khẩu? Mở hướng dẫn lấy lại mật khẩu" style={{flexDirection:'row',alignItems:'center',justifyContent:'center',gap:7,paddingVertical:4}}><Icon name="help-circle-outline" size={15} color={BRAND.blue}/><Text style={{fontSize:11,color:BRAND.slate}}>Quên mật khẩu? Liên hệ quản trị viên</Text></Pressable>
            <Text style={{fontSize:10,color:'#82909F',textAlign:'center',marginTop:14}}>Tài khoản được cấp bởi quản trị viên hệ thống</Text>
          </> : null}
        </View>
        <View style={{flexDirection:'row',alignItems:'center',gap:6,justifyContent:'center',marginTop:17,paddingHorizontal:4}}><View style={{width:6,height:6,borderRadius:3,backgroundColor:'#22AC8D'}}/><Text style={{fontSize:10,color:'#476A70',textAlign:'center'}}>{footer || 'STORIX · Hệ thống quản lý kho và bãi lưu trữ'}</Text></View>
      </View>
    </ScrollView>
  </View>;
}

export function BrandAuthField({label,value,onChangeText,placeholder,secure=false,autoCapitalize='none'}){
  const [visible,setVisible]=useState(false);
  return <View style={{marginBottom:17}}>
    <Text style={{fontSize:11,fontWeight:'800',color:'#26354D',letterSpacing:.45,marginBottom:8}}>{label.toUpperCase()}</Text>
    <View style={{height:49,flexDirection:'row',alignItems:'center',borderRadius:9,borderWidth:1,borderColor:BRAND.border,backgroundColor:'#F7F9FD',paddingHorizontal:13,gap:8}}>
      <Icon name={secure?'lock-outline':'account-circle-outline'} size={18} color="#73859B"/>
      <TextInput value={value} onChangeText={onChangeText} placeholder={placeholder||label} autoCapitalize={autoCapitalize} autoCorrect={false} secureTextEntry={secure&&!visible} placeholderTextColor="#A0AABD" style={{flex:1,height:'100%',minWidth:0,color:BRAND.navy,fontSize:13,...Platform.select({web:{outlineStyle:'none'}})}}/>
      {secure?<Pressable accessibilityLabel={visible?'Ẩn mật khẩu':'Hiện mật khẩu'} onPress={()=>setVisible(s=>!s)} style={{padding:6}}><Icon name={visible?'eye-off-outline':'eye-outline'} size={19} color="#607185"/></Pressable>:null}
    </View>
  </View>;
}
export function BrandAuthButton({title,onPress,disabled=false,icon='login'}){
  return <Pressable accessibilityRole="button" disabled={disabled} onPress={onPress} style={({pressed})=>({height:47,borderRadius:8,backgroundColor:BRAND.blue,opacity:disabled?.55:pressed?.8:1,flexDirection:'row',alignItems:'center',justifyContent:'center',gap:8,marginTop:8,...Platform.select({web:{boxShadow:'0px 3px 6px rgba(22,95,159,.18)'}})})}><Icon name={icon} color="white" size={19}/><Text style={{color:'white',fontWeight:'800',fontSize:13}}>{title}</Text></Pressable>;
}
export function BrandAuthNote({children,error=false}){return <View style={{padding:11,borderRadius:8,backgroundColor:error?'#FFF0F2':'#E9F5FA',borderWidth:1,borderColor:error?'#FCC4CD':'#D0E8F3',marginVertical:6}}><Text style={{fontSize:11,lineHeight:17,color:error?'#B02C47':'#28516D'}}>{children}</Text></View>}
