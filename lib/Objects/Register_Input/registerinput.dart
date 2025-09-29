import 'package:json_annotation/json_annotation.dart';
part 'registerinput.g.dart';

@JsonSerializable()
class Register_Input {
  @JsonKey(name: 'Name')
  String? name;
  @JsonKey(name: 'Phone')
  String? phone;
  @JsonKey(name: 'Email')
  String? email;
  @JsonKey(name: 'Zalo_Token')
  String? zaloToken;
  @JsonKey(name: 'Email_Token')
  String? emailToken;
  @JsonKey(name: 'Apple_id')
  String? appleId;

  Register_Input({
    this.name,
    this.phone,
    this.email,
    this.zaloToken,
    this.emailToken,
    this.appleId,
  });

  factory Register_Input.fromJson(Map<String, dynamic> json) =>
      _$Register_InputFromJson(json);

  static List<Register_Input> fromList(List<Map<String, dynamic>> list) {
    return list.map(Register_Input.fromJson).toList();
  }

  Map<String, dynamic> toJson() => _$Register_InputToJson(this);
}
