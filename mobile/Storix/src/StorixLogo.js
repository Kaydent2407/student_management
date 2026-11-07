/** Official STORIX mark provided by the project team (local bundled asset). */
import React from 'react';
import {Image} from 'react-native';

const STORIX_LOGO=require('../assets/brand/storix-logo.png');

export default function StorixLogo({size=44,style={}}){
  return <Image source={STORIX_LOGO} accessibilityLabel="Logo STORIX" accessible
    resizeMode="contain" style={[{width:size,height:size,borderRadius:Math.round(size*.18)},style]}/>;
}
