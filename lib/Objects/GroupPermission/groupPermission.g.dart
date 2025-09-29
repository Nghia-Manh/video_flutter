// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groupPermission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupPermission _$GroupPermissionFromJson(Map<String, dynamic> json) =>
    GroupPermission(
      name: json['Name'] as String?,
      description: json['Description'] as String?,
      permission: (json['Permission'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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

Map<String, dynamic> _$GroupPermissionToJson(GroupPermission instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'Description': instance.description,
      'Permission': instance.permission,
      'Customer_id': instance.customerId,
      'Id': instance.id,
      'UserCreate': instance.userCreate,
      'UserUpdate': instance.userUpdate,
      'DateCreate': instance.dateCreate?.toIso8601String(),
      'DateUpdate': instance.dateUpdate?.toIso8601String(),
    };
