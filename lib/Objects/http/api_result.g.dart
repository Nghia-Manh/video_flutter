// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIResult _$APIResultFromJson(Map<String, dynamic> json) => APIResult(
  Code: (json['Code'] as num?)?.toInt(),
  CodeName: json['CodeName'] as String?,
  ErrMessage: json['ErrMessage'] as String?,
  Data: json['Data'],
);

Map<String, dynamic> _$APIResultToJson(APIResult instance) => <String, dynamic>{
  'Code': instance.Code,
  'CodeName': instance.CodeName,
  'ErrMessage': instance.ErrMessage,
  'Data': instance.Data,
};
