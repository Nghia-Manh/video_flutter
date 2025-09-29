import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/function/global.dart';
import 'package:viettech_video/function/local_storage.dart';
import 'package:viettech_video/pages/Register/register_page.dart';
import 'package:zalo_flutter/zalo_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Khởi tạo GoogleSignIn
  final GoogleSignIn googleSignIn = GoogleSignIn();
  String zalo = '';
  String email = '';

  // Thêm biến để kiểm soát việc hiện/ẩn mật khẩu
  bool _isPasswordVisible = false;
  bool _autoValidate = false;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  // thêm đăng nhập gmail
  void _handleGmailLogin() async {
    try {
      // chọn lại tk gmail
      await googleSignIn.signOut();

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      print('Đăng nhập gmail: $account');

      if (account != null) {
        try {
          final GoogleSignInAuthentication auth = await account.authentication;

          // Kiểm tra cả idToken và accessToken
          if (auth.idToken == null && auth.accessToken == null) {
            Get.snackbar(
              'Lỗi',
              'Không thể lấy token xác thực từ Google',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red[100],
            );
            return;
          }

          String authCode = auth.accessToken ?? '';

          print('Auth code được sử dụng: $authCode');

          setState(() {
            email = authCode;
          });

          try {
            final value = await API.Account_Login_Email.call(
              params: {"code": auth.accessToken},
            );

            Global.loginResult = value;
            await LocalStorage.setLogin(value);
            Get.offAllNamed('/');

            // Hiển thị thông báo thành công
            // Get.snackbar(
            //   'Thành công',
            //   'Đăng nhập thành công',
            //   snackPosition: SnackPosition.BOTTOM,
            //   backgroundColor: Colors.green[100],
            // );
          } catch (apiError) {
            Get.snackbar(
              'Lỗi',
              'Đăng nhập thất bại: ${apiError.toString()}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red[100],
            );
          }
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
      print(e);
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  void _handleAppleLogin() async {
    try {
      print('Bắt đầu đăng nhập Apple...');

      Get.snackbar(
        'Thông báo',
        'Chức năng này chưa được triển khai.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Lỗi tổng quát: $e');
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _handleZaloLogin() async {
    try {
      print('Bắt đầu đăng nhập Zalo...');

      // xác thực lại mỗi lần đăng nhập
      // await ZaloFlutter.logout();
      // print('Đã logout Zalo');

      final Map<dynamic, dynamic>? data = await ZaloFlutter.login();
      print('Kết quả đăng nhập Zalo: $data');

      if (data == null) {
        print('Lỗi: data từ Zalo là null');
        Get.snackbar(
          'Lỗi',
          'Không thể kết nối với Zalo. Vui lòng kiểm tra kết nối mạng và thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          duration: const Duration(seconds: 5),
        );
        return;
      }

      print('Zalo isSuccess: [38;5;2m${data['isSuccess']}[0m');
      print('Zalo data: ${data['data']}');

      if (data['isSuccess'] == true) {
        var accessToken = data["data"]["access_token"] as String?;
        if (accessToken != null && accessToken.isNotEmpty) {
          await LocalStorage.setString('zalo_access_token', accessToken);
          setState(() {
            zalo = accessToken;
          });
          print('Zalo access token: $accessToken');

          try {
            print('Gọi API đăng nhập với token: $accessToken');
            final value = await API.Account_Login_Zalo.call(
              params: {"AccessToken": accessToken},
            );

            print('API response: $value');
            Global.loginResult = value;
            await LocalStorage.setLogin(value);
            Get.offAllNamed('/');

            // Hiển thị thông báo thành công
            // Get.snackbar(
            //   'Thành công',
            //   'Đăng nhập thành công',
            //   snackPosition: SnackPosition.BOTTOM,
            //   backgroundColor: Colors.green[100],
            // );
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
      } else {
        print(
          'Đăng nhập Zalo không thành công: ${data['message'] ?? 'Không có thông báo lỗi'}',
        );
        Get.snackbar(
          'Thông báo',
          'Đăng nhập Zalo không thành công. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('Lỗi tổng quát: $e');
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Hàm lấy access token Zalo từ LocalStorage
  Future<String?> getZaloAccessToken() async {
    return await LocalStorage.getString('zalo_access_token');
  }

  @override
  Widget build(BuildContext context) {
    var cr = MediaQuery.of(context).size.width;
    var cd = MediaQuery.of(context).size.height;
    print(ZaloHashKeyAndroid());
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFF6A7FDD), // Đặt màu nền cho thanh trạng thái
        statusBarIconBrightness: Brightness.light, // Màu biểu tượng
      ),
    );
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFFf093fb),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autoValidate
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                // Login form section
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      padding: EdgeInsets.all(30),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 30,
                                            offset: Offset(0, 20),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          // Username field
                                          Container(
                                            padding: EdgeInsets.only(top: 10),
                                            child: Text(
                                              'Hệ thống video tmdt'
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Color(0xFF667eea),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            width: 80,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                0xFF667eea,
                                              ).withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          // Container(
                                          //   decoration: BoxDecoration(
                                          //     color: Colors.grey[50],
                                          //     borderRadius:
                                          //         BorderRadius.circular(16),
                                          //     border: Border.all(
                                          //       color: Colors.grey[200]!,
                                          //       width: 1,
                                          //     ),
                                          //   ),
                                          //   child: TextFormField(
                                          //     controller: _usernameController,
                                          //     decoration: InputDecoration(
                                          //       label: Row(
                                          //         mainAxisSize:
                                          //             MainAxisSize.min,
                                          //         children: [
                                          //           Text(
                                          //             'Tài khoản',
                                          //             style: TextStyle(
                                          //               color: Colors.grey[600],
                                          //               fontSize: 16,
                                          //             ),
                                          //           ),
                                          //           Text(
                                          //             ' *',
                                          //             style: TextStyle(
                                          //               color: Colors.red[400],
                                          //             ),
                                          //           ),
                                          //         ],
                                          //       ),
                                          //       prefixIcon: Icon(
                                          //         Icons.person_outline,
                                          //         color: Color(0xFF667eea),
                                          //         size: 24,
                                          //       ),
                                          //       border: InputBorder.none,
                                          //       contentPadding:
                                          //           EdgeInsets.symmetric(
                                          //             horizontal: 20,
                                          //             vertical: 16,
                                          //           ),
                                          //     ),
                                          //     style: TextStyle(
                                          //       color: Colors.black87,
                                          //       fontSize: 16,
                                          //     ),
                                          //     validator: (value) {
                                          //       if (value == null ||
                                          //           value.isEmpty) {
                                          //         return 'Vui lòng nhập tài khoản';
                                          //       }
                                          //       return null;
                                          //     },
                                          //   ),
                                          // ),
                                          // SizedBox(height: 20),

                                          // // Password field
                                          // Container(
                                          //   decoration: BoxDecoration(
                                          //     color: Colors.grey[50],
                                          //     borderRadius:
                                          //         BorderRadius.circular(16),
                                          //     border: Border.all(
                                          //       color: Colors.grey[200]!,
                                          //       width: 1,
                                          //     ),
                                          //   ),
                                          //   child: TextFormField(
                                          //     controller: _passwordController,
                                          //     obscureText: !_isPasswordVisible,
                                          //     decoration: InputDecoration(
                                          //       label: Row(
                                          //         mainAxisSize:
                                          //             MainAxisSize.min,
                                          //         children: [
                                          //           Text(
                                          //             'Mật khẩu',
                                          //             style: TextStyle(
                                          //               color: Colors.grey[600],
                                          //               fontSize: 16,
                                          //             ),
                                          //           ),
                                          //           Text(
                                          //             ' *',
                                          //             style: TextStyle(
                                          //               color: Colors.red[400],
                                          //             ),
                                          //           ),
                                          //         ],
                                          //       ),
                                          //       prefixIcon: Icon(
                                          //         Icons.lock_outline,
                                          //         color: Color(0xFF667eea),
                                          //         size: 24,
                                          //       ),
                                          //       border: InputBorder.none,
                                          //       contentPadding:
                                          //           EdgeInsets.symmetric(
                                          //             horizontal: 20,
                                          //             vertical: 16,
                                          //           ),
                                          //       suffixIcon: IconButton(
                                          //         icon: Icon(
                                          //           _isPasswordVisible
                                          //               ? Icons.visibility
                                          //               : Icons.visibility_off,
                                          //           color: Colors.grey[600],
                                          //         ),
                                          //         onPressed: () {
                                          //           setState(() {
                                          //             _isPasswordVisible =
                                          //                 !_isPasswordVisible;
                                          //           });
                                          //         },
                                          //       ),
                                          //     ),
                                          //     style: TextStyle(
                                          //       color: Colors.black87,
                                          //       fontSize: 16,
                                          //     ),
                                          //     validator: (value) {
                                          //       if (value == null ||
                                          //           value.isEmpty) {
                                          //         return 'Vui lòng nhập mật khẩu';
                                          //       }
                                          //       return null;
                                          //     },
                                          //   ),
                                          // ),

                                          // // Forgot password
                                          // Container(
                                          //   padding: EdgeInsets.only(
                                          //     top: 16,
                                          //     bottom: 8,
                                          //   ),
                                          //   child: Row(
                                          //     mainAxisAlignment:
                                          //         MainAxisAlignment.end,
                                          //     children: <Widget>[
                                          //       InkWell(
                                          //         onTap: () {
                                          //           Get.snackbar(
                                          //             'Thông báo',
                                          //             'Tính năng này đang bổ sung',
                                          //             snackPosition:
                                          //                 SnackPosition.BOTTOM,
                                          //             backgroundColor:
                                          //                 Colors.blue[100],
                                          //           );
                                          //         },
                                          //         child: Text(
                                          //           'Quên mật khẩu?',
                                          //           style: TextStyle(
                                          //             color: Color(0xFF667eea),
                                          //             fontStyle:
                                          //                 FontStyle.italic,
                                          //             fontWeight:
                                          //                 FontWeight.w600,
                                          //             fontSize: 14,
                                          //           ),
                                          //         ),
                                          //       ),
                                          //     ],
                                          //   ),
                                          // ),

                                          // // Login button
                                          // SizedBox(height: 20),
                                          // SizedBox(
                                          //   width: double.infinity,
                                          //   height: 56,
                                          //   child: ElevatedButton(
                                          //     onPressed: _isLoading
                                          //         ? null
                                          //         : () async {
                                          //             setState(() {
                                          //               _autoValidate = true;
                                          //               _isLoading = true;
                                          //             });
                                          //             if (_formKey.currentState!
                                          //                 .validate()) {
                                          //               try {
                                          //                 final response =
                                          //                     await API
                                          //                         .Account_Login_User.call(
                                          //                       params: {
                                          //                         "iUsername":
                                          //                             _usernameController
                                          //                                 .text,
                                          //                         "iPassword":
                                          //                             _passwordController
                                          //                                 .text,
                                          //                       },
                                          //                     );
                                          //                 print(
                                          //                   'API response: $response',
                                          //                 );
                                          //                 if (response !=
                                          //                     null) {
                                          //                   await LocalStorage.setLogin(
                                          //                     response,
                                          //                   );
                                          //                   Get.offAllNamed(
                                          //                     '/',
                                          //                   );
                                          //                 }
                                          //               } catch (e) {
                                          //                 print(
                                          //                   'Lỗi đăng nhập: $e',
                                          //                 );
                                          //                 String message = e
                                          //                     .toString();
                                          //                 Get.snackbar(
                                          //                   'Thông báo',
                                          //                   message,
                                          //                   snackPosition:
                                          //                       SnackPosition
                                          //                           .BOTTOM,
                                          //                   backgroundColor:
                                          //                       Colors.red[100],
                                          //                   duration:
                                          //                       const Duration(
                                          //                         seconds: 3,
                                          //                       ),
                                          //                 );
                                          //               } finally {
                                          //                 setState(() {
                                          //                   _isLoading = false;
                                          //                 });
                                          //               }
                                          //             } else {
                                          //               setState(() {
                                          //                 _isLoading = false;
                                          //               });
                                          //             }
                                          //           },
                                          //     style: ElevatedButton.styleFrom(
                                          //       backgroundColor: Color(
                                          //         0xFF667eea,
                                          //       ),
                                          //       shape: RoundedRectangleBorder(
                                          //         borderRadius:
                                          //             BorderRadius.circular(16),
                                          //       ),
                                          //       elevation: 8,
                                          //       shadowColor: Color(
                                          //         0xFF667eea,
                                          //       ).withOpacity(0.3),
                                          //     ),
                                          //     child: _isLoading
                                          //         ? SizedBox(
                                          //             width: 24,
                                          //             height: 24,
                                          //             child: CircularProgressIndicator(
                                          //               strokeWidth: 2,
                                          //               valueColor:
                                          //                   AlwaysStoppedAnimation<
                                          //                     Color
                                          //                   >(Colors.white),
                                          //             ),
                                          //           )
                                          //         : Text(
                                          //             'Đăng Nhập',
                                          //             style: TextStyle(
                                          //               fontSize: 18,
                                          //               fontWeight:
                                          //                   FontWeight.w600,
                                          //               color: Colors.white,
                                          //             ),
                                          //           ),
                                          //   ),
                                          // ),
                                          SizedBox(height: 30),
                                          // Social login section
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                                child: Text(
                                                  'Đăng nhập với',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 20),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Gmail Login
                                              _buildSocialButton(
                                                onTap: _handleGmailLogin,
                                                icon:
                                                    'assets/images/google_logo.png',
                                                label: 'Google',
                                              ),
                                              // Zalo Login
                                              _buildSocialButton(
                                                onTap: _handleZaloLogin,
                                                icon:
                                                    'assets/images/zalo_icon.png',
                                                label: 'Zalo',
                                              ),
                                              // Apple Login
                                              _buildSocialButton(
                                                onTap: _handleAppleLogin,
                                                icon:
                                                    'assets/images/apple_logo.png',
                                                label: 'Apple',
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 30),

                                          // Register section
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Chưa có tài khoản?',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          RegisterPage(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Đăng ký ngay',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFF667eea),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String icon,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, height: 32, width: 32),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
