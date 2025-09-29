import 'package:json_annotation/json_annotation.dart';
part 'device.g.dart';

@JsonSerializable()
class Devices {
  @JsonKey(name: 'DateActive')
  DateTime? dateActive;
  @JsonKey(name: 'DateApproved')
  DateTime? dateApproved;
  @JsonKey(name: 'DateExpired')
  DateTime? dateExpired;
  @JsonKey(name: 'State')
  int? state;
  @JsonKey(name: 'CustomerName')
  String? customerName;
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

  Devices({
    this.dateActive,
    this.dateApproved,
    this.dateExpired,
    this.state,
    this.customerName,
    this.customerId,
    this.id,
    this.userCreate,
    this.userUpdate,
    this.dateCreate,
    this.dateUpdate,
  });

  factory Devices.fromJson(Map<String, dynamic> json) =>
      _$DevicesFromJson(json);

  static List<Devices> fromList(List<Map<String, dynamic>> list) {
    return list.map(Devices.fromJson).toList();
  }

  Map<String, dynamic> toJson() => _$DevicesToJson(this);
}
