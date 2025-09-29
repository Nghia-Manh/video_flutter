import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:viettech_video/Objects/http/api_result.dart';
import 'package:viettech_video/function/global.dart';
import 'package:viettech_video/function/local_storage.dart';

enum GetDataAPIMethod { get, post, put, delete, upload }

class GetDataAPI<T> {
  final Uri uri;
  final GetDataAPIMethod method;
  final T Function(dynamic json)? formatter;

  GetDataAPI({
    required this.uri,
    this.method = GetDataAPIMethod.get,
    this.formatter,
  });

  Future<T?> call({
    String? path,
    Map<String, dynamic>? params,
    bool wait = true,
    File? file,
    List<File>? files,
  }) async {
    return Future.delayed(Duration(seconds: 0), () async {
      print('${uri} - ${path} - ${params}');
      try {
        if (wait) {
          print('Hiển thị loading');

          Global.loadingController.showLoading();
        }
        http.Response? response = null;
        var headers = <String, String>{
          'Content-Type':
              'application/json; '
              'charset=UTF-8',
        };
        // if (uri.path == '/Account/Login') {
        //   headers['redirect_uri'] =
        //   "http://asset.quanlynoibo.com/Account/Callback";
        // }
        if (Global.loginResult != null &&
            Global.loginResult!.AccessToken != null) {
          headers['Authorization'] =
              "Bearer " + Global.loginResult!.AccessToken!;
        }
        if (Global.loginResult != null &&
            Global.loginResult!.UserName != null) {
          headers['identity'] = Global.loginResult!.Email ?? '';
        }

        print(jsonEncode(params));
        try {
          switch (method) {
            case GetDataAPIMethod.get:
              response = await http.get(
                uri.replace(queryParameters: params),
                headers: headers,
              );
              break;
            case GetDataAPIMethod.post:
              response = await http.post(
                uri,
                headers: headers,
                body: utf8.encode(jsonEncode(params)),
              );
              break;
            case GetDataAPIMethod.put:
              response = await http.put(
                path != null ? uri.replace(path: uri.path + '/' + path) : uri,
                headers: headers,
                body: utf8.encode(jsonEncode(params)),
              );
              break;
            case GetDataAPIMethod.delete:
              response = await http.delete(
                path != null ? uri.replace(path: uri.path + '/' + path) : uri,
                headers: headers,
              );
              break;
            case GetDataAPIMethod.upload:
              var request = http.MultipartRequest(
                'post',
                path != null ? uri.replace(path: uri.path + '/' + path) : uri,
              );
              if (Global.loginResult != null &&
                  Global.loginResult!.AccessToken != null) {
                request.headers['Authorization'] =
                    "Bearer ${Global.loginResult!.AccessToken!}";
              }
              print('Request headers: ${request.headers}');
              if (params != null) {
                print('Upload params: $params');
                for (var element in params.keys) {
                  print('Added field: $element = ${params[element]}');
                  request.fields[element] = params[element];
                }
              }
              print('Request fields: ${request.fields}');
              if (file != null) {
                request.files.add(
                  http.MultipartFile.fromBytes(
                    'file',
                    await file.readAsBytes(),
                    filename: file.path.split('/').last,
                  ),
                );
              }
              if (files != null && files.isNotEmpty) {
                print('Uploading ${files.length} files');
                for (int i = 0; i < files.length; i++) {
                  var file = files[i];
                  if (await file.exists()) {
                    print('Adding file ${i + 1}: ${file.path}');
                    request.files.add(
                      http.MultipartFile.fromBytes(
                        'file',
                        await file.readAsBytes(),
                        filename: file.path.split('/').last,
                      ),
                    );
                  }
                }
              }
              print('Request files count: ${request.files.length}');
              print(
                'Request files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}',
              );
              response = await request.send().then(
                (value) => http.Response.fromStream(value),
              );
          }
        } on http.ClientException catch (e) {
          Global.logout().then((value) {
            Global.loginResult = null;
            Get.offAllNamed('/');
            // throw Exception(apiResult.ErrMessage);
          });
          throw Exception("${e.message}");
        } catch (e) {
          throw e;
        }
        await Future.delayed(Duration(milliseconds: 250), () {});
        if (response == null) {
          throw Exception("Hệ thống lỗi, vui lòng thử lại.");
        }
        // if (response == null) {
        //   throw Exception('Đã có lỗi sảy ra');
        // }
        print('Response URL: ${response.request!.url.toString()}');
        print('Response Status: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');

        var json = jsonDecode(response.body);

        print('Parsed JSON: $json');
        print(uri.path);
        // if (uri.path == '/Account/Login') {
        //   var result = formatter?.call(json);
        //   return result;
        // } else {
        var apiResult = APIResult.fromJson(json);
        print('API Result Code: ${apiResult.Code}');
        print('API Result Message: ${apiResult.ErrMessage}');
        print(json);
        switch (apiResult.Code) {
          case 1: //Thành công
            if (apiResult.Data == null) return null;
            if (formatter != null) return formatter!(apiResult.Data);
            return apiResult.Data;
          case 2: //Lỗi
            print('API Error: ${apiResult.ErrMessage}');
            throw Exception(apiResult.ErrMessage);
          case 3: //Đăng nhập lại
            // LocalStorage.setLogin(null).then((value) {
            //   Get.offAllNamed('/');
            //   throw Exception(apiResult.ErrMessage);
            // });
            // break;
            Get.dialog(
              AlertDialog(
                title: const Text('Thông báo'),
                content: Text(
                  apiResult.ErrMessage ??
                      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Get.back(); // Close the dialog
                      LocalStorage.setLogin(null).then((_) {
                        Get.offAllNamed('/');
                      });
                    },
                    child: const Text('Đồng ý'),
                  ),
                ],
              ),
              barrierDismissible: false,
            );
            return null;
          default:
            throw Exception(response.body);
        }

        // throw Exception('Đã có lỗi sảy ra');
      } catch (e) {
        // Utilitys.showMessage(
        //   e.toString().replaceAll('Exception: ', ''),
        //   type: MyNotificationType.error,
        // );

        // Get.dialog(
        //   AlertDialog(
        //     content: Text(
        //       e.toString().replaceAll('Exception: ', ''),
        //       style: TextStyle(color: Colors.redAccent),
        //     ),
        //   ),
        // );
        print(e.toString());
        
        // Get.snackbar(
        //   'Thông báo',
        //   e.toString().replaceAll('Exception: ', ''),
        //   titleText: Text('Thông báo'),
        //   colorText: Colors.red,
        //   // messageText: Text('Abcd')
        // );
        throw e.toString().replaceAll('Exception: ', '');
      } finally {
        if (wait) {
          Future.delayed(Duration(seconds: 0), () {
            print('Tắt loading');
            Global.loadingController.offLoading();
          });
        }
      }
    });
  }
}
