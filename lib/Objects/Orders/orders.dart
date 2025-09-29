import 'package:json_annotation/json_annotation.dart';
part 'orders.g.dart';

@JsonSerializable()
class Orders {
  @JsonKey(name: 'Active')
  bool? active;
  @JsonKey(name: 'QRCode')
  String? qrCode;
  @JsonKey(name: 'DateBegin')
  DateTime? dateBegin;
  @JsonKey(name: 'DateEnd')
  DateTime? dateEnd;
  @JsonKey(name: 'Serial')
  String? serial;
  @JsonKey(name: 'FileName')
  String? fileName;
  @JsonKey(name: 'QRFile')
  String? qrFile;
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

  Orders({
    this.active,
    this.qrCode,
    this.dateBegin,
    this.dateEnd,
    this.serial,
    this.fileName,
    this.qrFile,
    this.id,
    this.customerId,
    this.userCreate,
    this.userUpdate,
    this.dateCreate,
    this.dateUpdate,
  });

  factory Orders.fromJson(Map<String, dynamic> json) => _$OrdersFromJson(json);

  static List<Orders> fromList(List<Map<String, dynamic>> list) {
    return list.map(Orders.fromJson).toList();
  }

  Map<String, dynamic> toJson() => _$OrdersToJson(this);
}
