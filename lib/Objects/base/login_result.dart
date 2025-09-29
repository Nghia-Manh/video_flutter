import 'dart:ffi';
import 'package:json_annotation/json_annotation.dart';
part 'login_result.g.dart';

@JsonEnum(valueField: 'value')
enum eLogin_Type {
  User_Password(1),
  Email(2),
  Zalo(3),
  Apple(4);

  const eLogin_Type(this.value);
  final num value;
}

@JsonEnum(valueField: 'value')
enum Emp_Role {
  None(0),
  Nhanvien(1),
  Quanly_pho(2),
  Quanly_truong(3);

  const Emp_Role(this.value);
  final num value;
}

@JsonSerializable(explicitToJson: true)
class LoginResult {
  String? Phone;
  String? Email;
  String? FullName;
  String? UserName;
  String? AccessToken;
  // eLogin_Type? Token_Type;
  String? TokenType;
  String? ImgUrl;
  int? ExpiresIn;
  String? GroupPermission_Id;

  LoginResult({
    this.Phone,
    this.Email,
    this.FullName,
    this.UserName,
    this.AccessToken,
    // this.Token_Type,
    this.TokenType,
    this.ImgUrl,
    this.ExpiresIn,
    this.GroupPermission_Id,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) =>
      _$LoginResultFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResultToJson(this);
}

@JsonEnum(valueField: 'value')
enum eServices {
  GSHT(1),
  Gara(2),
  DoiXe(3);

  final num value;

  const eServices(this.value);
}

@JsonSerializable()
class UserServices {
  int? Service;
  String? Permission_id;
  String? Customer_id; // Thêm trường customerid nếu cần thiết

  UserServices({this.Service, this.Permission_id, this.Customer_id});

  factory UserServices.fromJson(Map<String, dynamic> json) =>
      _$UserServicesFromJson(json);

  Map<String, dynamic> toJson() => _$UserServicesToJson(this);
}
