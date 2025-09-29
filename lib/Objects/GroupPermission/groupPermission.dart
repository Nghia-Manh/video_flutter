import 'package:json_annotation/json_annotation.dart';
part 'groupPermission.g.dart';

@JsonSerializable()
class GroupPermission {
  @JsonKey(name: 'Name')
  String? name;
  @JsonKey(name: 'Description')
  String? description;
  @JsonKey(name: 'Permission')
  List<String>? permission;
  @JsonKey(name: 'Customer_id')
  String? customerId;
  @JsonKey(name: 'Id')
  String? id;
  @JsonKey(name: 'UserCreate')
  String? userCreate;
  @JsonKey(name: 'UserUpdate')
  String? userUpdate;
  @JsonKey(name: 'DateCreate')
  DateTime? dateCreate;
  @JsonKey(name: 'DateUpdate')
  DateTime? dateUpdate;

  GroupPermission({
    this.name,
    this.description,
    this.permission,
    this.customerId,
    this.id,
    this.userCreate,
    this.userUpdate,
    this.dateCreate,
    this.dateUpdate,
  });

  factory GroupPermission.fromJson(Map<String, dynamic> json) =>
      _$GroupPermissionFromJson(json);

  static List<GroupPermission> fromList(List<Map<String, dynamic>> list) {
    return list.map(GroupPermission.fromJson).toList();
  }

  Map<String, dynamic> toJson() => _$GroupPermissionToJson(this);
}
