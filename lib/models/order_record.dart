import 'dart:convert';

class OrderRecord {
  final String qrCode;
  final DateTime dateBegin;
  final DateTime dateEnd;
  final String fileName;
  final String qrFile;

  OrderRecord({
    required this.qrCode,
    required this.dateBegin,
    required this.dateEnd,
    required this.fileName,
    required this.qrFile,
  });

  Map<String, dynamic> toJson() => {
    "QRCode": qrCode,
    "DateBegin": dateBegin.toIso8601String(),
    "DateEnd": dateEnd.toIso8601String(),
    "FileName": fileName,
    "QRFile": qrFile,
  };

  static OrderRecord fromJson(Map<String, dynamic> json) {
    return OrderRecord(
      qrCode: json["QRCode"] as String? ?? "",
      dateBegin:
          DateTime.tryParse(json["DateBegin"] as String? ?? "") ??
          DateTime.now(),
      dateEnd:
          DateTime.tryParse(json["DateEnd"] as String? ?? "") ?? DateTime.now(),
      fileName: json["FileName"] as String? ?? "",
      qrFile: json["QRFile"] as String? ?? "",
    );
  }

  static String encodeList(List<OrderRecord> records) =>
      jsonEncode(records.map((e) => e.toJson()).toList());

  static List<OrderRecord> decodeList(String source) {
    final data = jsonDecode(source) as List<dynamic>;
    return data
        .map((e) => OrderRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
