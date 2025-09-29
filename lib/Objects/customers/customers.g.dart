// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customers _$CustomersFromJson(Map<String, dynamic> json) => Customers(
  name: json['Name'] as String?,
  address: json['Address'] as String?,
  description: json['Description'] as String?,
  total: (json['Total'] as num?)?.toInt(),
  id: json['Id'] as String?,
  userCreate: json['UserCreate'] as String?,
  userUpdate: json['UserUpdate'] as String?,
  dateCreate: json['DateCreate'] == null
      ? null
      : DateTime.parse(json['DateCreate'] as String),
  dateUpdate: json['DateUpdate'] == null
      ? null
      : DateTime.parse(json['DateUpdate'] as String),
  customerId: json['Customer_id'] as String?,
);

Map<String, dynamic> _$CustomersToJson(Customers instance) => <String, dynamic>{
  'Name': instance.name,
  'Address': instance.address,
  'Description': instance.description,
  'Total': instance.total,
  'Id': instance.id,
  'UserCreate': instance.userCreate,
  'UserUpdate': instance.userUpdate,
  'DateCreate': instance.dateCreate?.toIso8601String(),
  'DateUpdate': instance.dateUpdate?.toIso8601String(),
  'Customer_id': instance.customerId,
};
