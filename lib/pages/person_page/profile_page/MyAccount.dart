import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/Template/FormAccount.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/function/global.dart';
import 'package:zalo_flutter/zalo_flutter.dart';
import 'package:viettech_video/pages/person_page/profile_page/profile_page.dart';

class MyAccount extends StatefulWidget {
  final String? userId;
  const MyAccount({super.key, this.userId});

  @override
  _MyAccountState createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  Users? users;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    try {
      final response = await API.Account_GetById.call(
        params: {"id": widget.userId ?? ''},
      );
      if (mounted) {
        setState(() {
          users = response ?? Users();
        });
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi khi tải tài khoản đăng nhập: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi khi tải tài khoản đăng nhập: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF768CEB),
              statusBarIconBrightness: Brightness.light,
            ),
            backgroundColor: Color(0xFF768CEB),
            title: const Text(
              'Thông tin tài khoản',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Container(
            padding: EdgeInsets.all(5),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  FormAvatar(
                    image: users?.avatar != null && users!.avatar!.isNotEmpty
                        ? users!.avatar!.startsWith('assets')
                              ? users!.avatar!
                              : users!.avatar!.startsWith('http')
                              ? users!.avatar!
                              : 'http://demo.quanlynoibo.com:8123/Avatars/${users!.avatar!}'
                        : 'assets/images/user.png',
                    title: users?.fullName ?? '',
                    onTap: () {
                      Global.to(
                        () => ProfilePage(
                          accounts: users,
                          onEdit: () {
                            _loadUserInfo();
                          },
                        ),
                      );
                    },
                  ),
                  FormAccount(
                    title: 'Số điện thoại',
                    hintText: users?.phone ?? '',
                  ),
                  if (users?.email != null && users?.email != '')
                    FormAccount(title: 'Email', hintText: users?.email ?? ''),
                  FormAccount(
                    title: 'Apple Id',
                    entry: users?.appleId != null && users?.appleId != ''
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đã liên kết',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _verifyApple();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.apple),
                                    SizedBox(width: 5),
                                    Text('Liên kết'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  FormAccount(
                    title: 'Zalo Id',
                    entry: users?.zaloId != null && users?.zaloId != ''
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đã liên kết',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _verifyZalo();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/icons8-zalo-48.png',
                                      width: 25,
                                    ),
                                    SizedBox(width: 5),
                                    Text('Liên kết'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  FormAccount(
                    title: 'Email',
                    entry: users?.email != null && users?.email != ''
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đã liên kết',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _verifyGmail();
                                },
                                child: Row(
                                  spacing: 5,
                                  children: [
                                    Image.asset(
                                      'assets/images/Google__G__logo.png',
                                      width: 25,
                                      color: Colors.white,
                                    ),
                                    Text('Liên kết'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyGmail() async {
    try {
      // chọn lại tk gmail
      await googleSignIn.signOut();

      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        try {
          final GoogleSignInAuthentication auth = await account.authentication;

          // Kiểm tra cả idToken và accessToken
          if (auth.idToken == null && auth.accessToken == null) {
            Get.snackbar('Lỗi', 'Không thể lấy token xác thực từ Google');
            return;
          }
          API.Account_LinkGmail.call(params: {"code": auth.accessToken}).then((
            value,
          ) {
            if (value != null) {
              // Refresh thông tin user từ server sau khi liên kết thành công
              _loadUserInfo();
              Get.snackbar(
                'Thông báo',
                'Liên kết Gmail thành công',
                titleText: Text('Thông báo'),
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green[100],
                // messageText: Text('Abcd')
              );
            }
          });
        } catch (authError) {
          print('Lỗi xác thực Google: $authError');
          Get.snackbar(
            'Lỗi xác thực',
            'Không thể xác thực với Google: ${authError.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
          );
        }
      } else {
        // Người dùng hủy đăng nhập
        print('Người dùng hủy đăng nhập Google');
      }
    } catch (e) {
      print('${e.toString()}');
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  Future<void> _verifyZalo() async {
    try {
      await ZaloFlutter.logout();
      final Map<dynamic, dynamic>? data = await ZaloFlutter.login();

      if (data == null) {
        Get.snackbar(
          'Lỗi',
          'Không thể kết nối với Zalo',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
        return;
      }
      if (data['isSuccess'] == true) {
        var accessToken = data["data"]["access_token"] as String?;
        if (accessToken != null && accessToken.isNotEmpty) {
          try {
            API.Account_LinkZalo.call(
              params: {"AccessToken": accessToken},
            ).then((value) {
              if (value != null) {
                // Refresh thông tin user từ server sau khi liên kết thành công
                _loadUserInfo();
                Get.snackbar(
                  'Thông báo',
                  'Liên kết Zalo thành công',
                  titleText: Text('Thông báo'),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green[100],
                  // messageText: Text('Abcd')
                );
              }
            });
          } catch (apiError) {
            print('Lỗi API: $apiError');
            Get.snackbar(
              'Lỗi',
              'Đăng nhập thất bại: ${apiError.toString()}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red[100],
              duration: const Duration(seconds: 5),
            );
          }
        } else {
          print('Lỗi: access token rỗng');
          Get.snackbar(
            'Lỗi',
            'Không nhận được token từ Zalo. Vui lòng thử lại.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }
    } catch (e) {
      print('${e.toString()}');
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  Future<void> _verifyApple() async {
    Get.snackbar(
      'Thông báo',
      'Tính năng chưa triển khai',
      titleText: Text('Thông báo'),
      backgroundColor: Colors.purple[100],
      snackPosition: SnackPosition.BOTTOM,
      // messageText: Text('Abcd')
    );
  }
}
