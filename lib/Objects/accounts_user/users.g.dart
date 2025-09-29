// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Users _$UsersFromJson(Map<String, dynamic> json) => Users(
  avatar: json['Avatar'] as String?,
  password: json['Password'] as String?,
  fullName: json['FullName'] as String?,
  buttons: (json['Buttons'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  groupPermissionId: json['GroupPermission_Id'] as String?,
  address: json['Address'] as String?,
  birthDay: json['BirthDay'] == null
      ? null
      : DateTime.parse(json['BirthDay'] as String),
  phone: json['Phone'] as String?,
  email: json['Email'] as String?,
  zaloId: json['Zalo_id'] as String?,
  appleId: json['Apple_id'] as String?,
  cityId: json['City_id'] as String?,
  token: json['Token'] as String?,
  trangThai: (json['TrangThai'] as num?)?.toInt(),
  id: json['Id'] as String?,
  customerId: json['Customer_id'] as String?,
  userCreate: json['UserCreate'] as String?,
  userUpdate: json['UserUpdate'] as String?,
  dateCreate: json['DateCreate'] == null
      ? null
      : DateTime.parse(json['DateCreate'] as String),
  dateUpdate: json['DateUpdate'] == null
      ? null
      : DateTime.parse(json['DateUpdate'] as String),
);

Map<String, dynamic> _$UsersToJson(Users instance) => <String, dynamic>{
  'Avatar': instance.avatar,
  'Password': instance.password,
  'FullName': instance.fullName,
  'Buttons': instance.buttons,
  'GroupPermission_Id': instance.groupPermissionId,
  'Address': instance.address,
  'BirthDay': instance.birthDay?.toIso8601String(),
  'Phone': instance.phone,
  'Email': instance.email,
  'Zalo_id': instance.zaloId,
  'Apple_id': instance.appleId,
  'City_id': instance.cityId,
  'Token': instance.token,
  'TrangThai': instance.trangThai,
  'Id': instance.id,
  'Customer_id': instance.customerId,
  'UserCreate': instance.userCreate,
  'UserUpdate': instance.userUpdate,
  'DateCreate': instance.dateCreate?.toIso8601String(),
  'DateUpdate': instance.dateUpdate?.toIso8601String(),
};
