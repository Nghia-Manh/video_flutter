// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Devices _$DevicesFromJson(Map<String, dynamic> json) => Devices(
  dateActive: json['DateActive'] == null
      ? null
      : DateTime.parse(json['DateActive'] as String),
  dateApproved: json['DateApproved'] == null
      ? null
      : DateTime.parse(json['DateApproved'] as String),
  dateExpired: json['DateExpired'] == null
      ? null
      : DateTime.parse(json['DateExpired'] as String),
  state: (json['State'] as num?)?.toInt(),
  customerName: json['CustomerName'] as String?,
  customerId: json['Customer_id'] as String?,
  id: json['Id'] as String?,
  userCreate: json['UserCreate'] as String?,
  userUpdate: json['UserUpdate'] as String?,
  dateCreate: json['DateCreate'] == null
      ? null
      : DateTime.parse(json['DateCreate'] as String),
  dateUpdate: json['DateUpdate'] == null
      ? null
      : DateTime.parse(json['DateUpdate'] as String),
);

Map<String, dynamic> _$DevicesToJson(Devices instance) => <String, dynamic>{
  'DateActive': instance.dateActive?.toIso8601String(),
  'DateApproved': instance.dateApproved?.toIso8601String(),
  'DateExpired': instance.dateExpired?.toIso8601String(),
  'State': instance.state,
  'CustomerName': instance.customerName,
  'Customer_id': instance.customerId,
  'Id': instance.id,
  'UserCreate': instance.userCreate,
  'UserUpdate': instance.userUpdate,
  'DateCreate': instance.dateCreate?.toIso8601String(),
  'DateUpdate': instance.dateUpdate?.toIso8601String(),
};
