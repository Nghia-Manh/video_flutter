// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Orders _$OrdersFromJson(Map<String, dynamic> json) => Orders(
  active: json['Active'] as bool?,
  qrCode: json['QRCode'] as String?,
  dateBegin: json['DateBegin'] == null
      ? null
      : DateTime.parse(json['DateBegin'] as String),
  dateEnd: json['DateEnd'] == null
      ? null
      : DateTime.parse(json['DateEnd'] as String),
  serial: json['Serial'] as String?,
  fileName: json['FileName'] as String?,
  qrFile: json['QRFile'] as String?,
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

Map<String, dynamic> _$OrdersToJson(Orders instance) => <String, dynamic>{
  'Active': instance.active,
  'QRCode': instance.qrCode,
  'DateBegin': instance.dateBegin?.toIso8601String(),
  'DateEnd': instance.dateEnd?.toIso8601String(),
  'Serial': instance.serial,
  'FileName': instance.fileName,
  'QRFile': instance.qrFile,
  'Id': instance.id,
  'Customer_id': instance.customerId,
  'UserCreate': instance.userCreate,
  'UserUpdate': instance.userUpdate,
  'DateCreate': instance.dateCreate?.toIso8601String(),
  'DateUpdate': instance.dateUpdate?.toIso8601String(),
};
