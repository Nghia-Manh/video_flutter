// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registerinput.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Register_Input _$Register_InputFromJson(Map<String, dynamic> json) =>
    Register_Input(
      name: json['Name'] as String?,
      phone: json['Phone'] as String?,
      email: json['Email'] as String?,
      zaloToken: json['Zalo_Token'] as String?,
      emailToken: json['Email_Token'] as String?,
      appleId: json['Apple_id'] as String?,
    );

Map<String, dynamic> _$Register_InputToJson(Register_Input instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'Phone': instance.phone,
      'Email': instance.email,
      'Zalo_Token': instance.zaloToken,
      'Email_Token': instance.emailToken,
      'Apple_id': instance.appleId,
    };
