/**
 * Giao diện lấy lại mật khẩu cho tài khoản API STORIX.
 * Backend tham chiếu hiện chỉ có login/me/change-password, không có reset-password.
 * Vì thế màn hình này KHÔNG gửi yêu cầu mạng, không tạo OTP, không đổi dữ liệu.
 */
import React, {useState} from 'react';
import {View,Text,Pressable,StatusBar} from 'react-native';
import {SafeAreaView} from 'react-native-safe-area-context';
import {MaterialCommunityIcons as Icon} from '@expo/vector-icons';
import {BrandAuthShell,BrandAuthField,BrandAuthButton,BrandAuthNote,BRAND} from './BrandAuth';

export default function ForgotPasswordScreen({onBackToLogin,initialIdentifier=''}) {
  const [identifier,setIdentifier]=useState(initialIdentifier);
  const [showInstructions,setShowInstructions]=useState(false);
  const [validation,setValidation]=useState('');

  function showRecoveryInstructions() {
    if (!identifier.trim()) {
      setValidation('Vui lòng nhập tên đăng nhập hoặc email để chuẩn bị thông tin hỗ trợ.');
      setShowInstructions(false);
      return;
    }
    setValidation('');
    setShowInstructions(true);
  }

  return <SafeAreaView style={{flex:1,backgroundColor:BRAND.mint}}>
    <StatusBar barStyle="dark-content" backgroundColor={BRAND.mint}/>
    <BrandAuthShell
      mode="api"
      title="Lấy lại mật khẩu"
      subtitle="Hướng dẫn khôi phục quyền truy cập tài khoản STORIX"
      showHelp={false}
      footer="STORIX · Bảo mật tài khoản người dùng"
    >
      <View style={{alignItems:'center',marginBottom:18}}>
        <View style={{width:62,height:62,borderRadius:31,backgroundColor:'#E8F2FF',alignItems:'center',justifyContent:'center',borderWidth:1,borderColor:'#CDE2FB'}}>
          <Icon name="lock-reset" size={31} color={BRAND.blue}/>
        </View>
        <Text style={{fontSize:12,color:BRAND.slate,textAlign:'center',lineHeight:19,marginTop:10}}>
          Nhập tên đăng nhập hoặc email tài khoản cần hỗ trợ.
        </Text>
      </View>
      <BrandAuthField
        label="Tên đăng nhập hoặc email"
        placeholder="Nhập tên đăng nhập hoặc email"
        value={identifier}
        onChangeText={value=>{setIdentifier(value);setValidation('');setShowInstructions(false);}}
      />
      {validation ? <BrandAuthNote error>{validation}</BrandAuthNote> : null}
      <BrandAuthButton title="Xem hướng dẫn khôi phục" icon="lifebuoy" onPress={showRecoveryInstructions}/>
      {showInstructions ? <View accessibilityRole="alert" style={{backgroundColor:'#E9F5FA',borderRadius:10,borderWidth:1,borderColor:'#CFE4F5',padding:15,marginTop:16}}>
        <View style={{flexDirection:'row',alignItems:'center',gap:8,marginBottom:8}}>
          <Icon name="information-outline" size={19} color={BRAND.blue}/>
          <Text style={{fontWeight:'800',fontSize:13,color:BRAND.navy}}>Hướng dẫn lấy lại mật khẩu</Text>
        </View>
        <Text style={{fontSize:12,lineHeight:20,color:BRAND.slate}}>
          STORIX chưa có chức năng tự gửi mã OTP hoặc liên kết đặt lại mật khẩu. Bạn hãy liên hệ quản trị viên của nhóm và cung cấp tên đăng nhập để được xác minh, đặt lại mật khẩu theo quy trình nội bộ.

Thông tin trên biểu mẫu chỉ được hiển thị trên thiết bị, chưa được gửi tới máy chủ.
        </Text>
      </View> : <BrandAuthNote>Hiện backend chưa hỗ trợ khôi phục tự động. Bạn có thể xem hướng dẫn để liên hệ quản trị viên; không có email hay OTP nào được gửi.</BrandAuthNote>}
      <Pressable accessibilityRole="button" accessibilityLabel="Quay lại đăng nhập" onPress={onBackToLogin} style={{minHeight:44,flexDirection:'row',justifyContent:'center',alignItems:'center',gap:7,marginTop:15}}>
        <Icon name="arrow-left" size={18} color={BRAND.blue}/>
        <Text style={{fontSize:13,fontWeight:'700',color:BRAND.blue}}>Quay lại đăng nhập</Text>
      </Pressable>
    </BrandAuthShell>
  </SafeAreaView>;
}
