import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viettech_video/Objects/base/login_result.dart';

enum StorageType { UserName, Password, LoginResult }

class LocalStorage {
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<LoginResult?> getLogin() async {
    String? json = await getData(StorageType.LoginResult);
    if (json == 'null' || json == null) return null;
    return LoginResult.fromJson(jsonDecode(json));
  }

  static Future<bool?> setLogin(LoginResult? value) {
    return setData(StorageType.LoginResult, jsonEncode(value?.toJson()));
  }

  static Future<String?> getData(StorageType key) {
    print('$key');
    return _prefs
        .then((p) {
          return p.getString('$key');
        })
        .catchError((onError) {
          return null;
        });
  }

  static Future<bool?> setData(StorageType key, String value) {
    print('$key');
    return _prefs.then((p) {
      return p.setString('$key', value);
    });
  }

  // Thêm hàm lưu và lấy dữ liệu với key là String (dùng cho access token Zalo)
  static Future<String?> getString(String key) {
    return _prefs
        .then((p) {
          return p.getString(key);
        })
        .catchError((onError) {
          return null;
        });
  }

  static Future<bool?> setString(String key, String value) {
    return _prefs.then((p) {
      return p.setString(key, value);
    });
  }
}
