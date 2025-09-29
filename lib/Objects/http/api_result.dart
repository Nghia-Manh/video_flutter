import 'package:json_annotation/json_annotation.dart';
part 'api_result.g.dart';

@JsonSerializable()
class APIResult {
  int? Code;
  String? CodeName;
  String? ErrMessage;
  dynamic Data;

  APIResult({this.Code, this.CodeName, this.ErrMessage, this.Data});

  factory APIResult.fromJson(Map<String, dynamic> json) =>
      _$APIResultFromJson(json);

  Map<String, dynamic> toJson() => _$APIResultToJson(this);
}

class PagingResult<T> {
  num? CurentPage;
  T? Data;
  num? RecordOfPage;
  num? TotalPage;
  num? TotalRecord;

  PagingResult({
    this.CurentPage,
    this.Data,
    this.RecordOfPage,
    this.TotalPage,
    this.TotalRecord,
  });
}
