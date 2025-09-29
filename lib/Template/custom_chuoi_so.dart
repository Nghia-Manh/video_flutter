import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// format số với dấu phẩy numberFormat.format(1000000) => 1.000.000
final numberFormat = NumberFormat('#,##0', 'vi_VN');

// Format số với dấu cách ở input
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Chỉ giữ lại số từ chuỗi nhập vào
    String newText = newValue.text.replaceAll(',', '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    // Parse số và format lại với dấu cách ở sau mỗi 3 số
    try {
      int number = int.parse(newText);
      String formatted = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}

// Format số với dấu cách thêm cách ở sau mỗi 3 số
String formatNumber(dynamic number) {
  if (number == null) return '0';
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]} ',
  );
}

// Hàm chuyển đổi chuỗi có dấu cách thành số (loại bỏ dấu cách)
int parseNumberString(String text) {
  // Loại bỏ tất cả dấu cách từ chuỗi
  String cleanText = text.replaceAll(' ', '');
  // Chuyển thành số
  return int.tryParse(cleanText) ?? 0;
}

// Hàm chuyển đổi chuỗi có dấu cách thành số thập phân (loại bỏ dấu cách)
double parseNumberStringDouble(String text) {
  if (text.isEmpty) return 0.0;
  // Loại bỏ tất cả dấu cach từ chuỗi
  String cleanText = text.replaceAll(' ', '');
  // Chuyển thành số
  return double.tryParse(cleanText) ?? 0.0;
}

String formatLargeNumber(int number) {
  if (number >= 10000000000) {
    // 10 tỷ
    double billion = number / 1000000000; // Chuyển sang tỷ
    return '${billion.toStringAsFixed(2)} tỷ';
  }
  return numberFormat.format(number);
}
