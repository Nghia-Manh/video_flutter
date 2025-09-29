import 'package:json_annotation/json_annotation.dart';
part 'customers.g.dart';

@JsonSerializable()
class Customers {
  @JsonKey(name: 'Name')
  String? name;
  @JsonKey(name: 'Address')
  String? address;
  @JsonKey(name: 'Description')
  String? description;
  @JsonKey(name: 'Total')
  int? total;
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
  @JsonKey(name: 'Customer_id')
  String? customerId;

  Customers({
    this.name,
    this.address,
    this.description,
    this.total,
    this.id,
    this.userCreate,
    this.userUpdate,
    this.dateCreate,
    this.dateUpdate,
    this.customerId,
  });

  factory Customers.fromJson(Map<String, dynamic> json) =>
      _$CustomersFromJson(json);

  static List<Customers> fromList(List<Map<String, dynamic>> list) {
    return list.map(Customers.fromJson).toList();
  }

  Map<String, dynamic> toJson() => _$CustomersToJson(this);
}
