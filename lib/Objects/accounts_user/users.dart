import 'package:json_annotation/json_annotation.dart';
part 'users.g.dart';

@JsonSerializable()
class Users {
  @JsonKey(name: 'Avatar')
  String? avatar;
  @JsonKey(name: 'Password')
  String? password;
  @JsonKey(name: 'FullName')
  String? fullName;
  @JsonKey(name: 'Buttons')
  List<String>? buttons;
  @JsonKey(name: 'GroupPermission_Id')
  String? groupPermissionId;
  @JsonKey(name: 'Address')
  String? address;
  @JsonKey(name: 'BirthDay')
  DateTime? birthDay;
  @JsonKey(name: 'Phone')
  String? phone;
  @JsonKey(name: 'Email')
  String? email;
  @JsonKey(name: 'Zalo_id')
  String? zaloId;
  @JsonKey(name: 'Apple_id')
  String? appleId;
  @JsonKey(name: 'City_id')
  String? cityId;
  @JsonKey(name: 'Token')
  String? token;
  @JsonKey(name: 'TrangThai')
  int? trangThai;
  @JsonKey(name: 'Id')
  String? id;
  @JsonKey(name: 'Customer_id')
  String? customerId;
  @JsonKey(name: 'UserCreate')
  String? userCreate;
  @JsonKey(name: 'UserUpdate')
  String? userUpdate;
  @JsonKey(name: 'DateCreate')
  DateTime? dateCreate;
  @JsonKey(name: 'DateUpdate')
  DateTime? dateUpdate;

  Users({
    this.avatar,
    this.password,
    this.fullName,
    this.buttons,
    this.groupPermissionId,
    this.address,
    this.birthDay,
    this.phone,
    this.email,
    this.zaloId,
    this.appleId,
    this.cityId,
    this.token,
    this.trangThai,
    this.id,
    this.customerId,
    this.userCreate,
    this.userUpdate,
    this.dateCreate,
    this.dateUpdate,
  });

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);

  static List<Users> fromList(List<Map<String, dynamic>> list) {
    return list.map(Users.fromJson).toList();
  }

  Map<String, dynamic> toJson() => _$UsersToJson(this);
}
