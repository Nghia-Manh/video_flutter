// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResult _$LoginResultFromJson(Map<String, dynamic> json) => LoginResult(
  Phone: json['Phone'] as String?,
  Email: json['Email'] as String?,
  FullName: json['FullName'] as String?,
  UserName: json['UserName'] as String?,
  AccessToken: json['AccessToken'] as String?,
  TokenType: json['TokenType'] as String?,
  ImgUrl: json['ImgUrl'] as String?,
  ExpiresIn: (json['ExpiresIn'] as num?)?.toInt(),
  GroupPermission_Id: json['GroupPermission_Id'] as String?,
);

Map<String, dynamic> _$LoginResultToJson(LoginResult instance) =>
    <String, dynamic>{
      'Phone': instance.Phone,
      'Email': instance.Email,
      'FullName': instance.FullName,
      'UserName': instance.UserName,
      'AccessToken': instance.AccessToken,
      'TokenType': instance.TokenType,
      'ImgUrl': instance.ImgUrl,
      'ExpiresIn': instance.ExpiresIn,
      'GroupPermission_Id': instance.GroupPermission_Id,
    };

UserServices _$UserServicesFromJson(Map<String, dynamic> json) => UserServices(
  Service: (json['Service'] as num?)?.toInt(),
  Permission_id: json['Permission_id'] as String?,
  Customer_id: json['Customer_id'] as String?,
);

Map<String, dynamic> _$UserServicesToJson(UserServices instance) =>
    <String, dynamic>{
      'Service': instance.Service,
      'Permission_id': instance.Permission_id,
      'Customer_id': instance.Customer_id,
    };
