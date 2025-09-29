import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:viettech_video/Objects/Register_Input/registerinput.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/function/local_storage.dart';
import 'package:viettech_video/pages/Login/login.dart';
import 'package:zalo_flutter/zalo_flutter.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  late Register_Input register_Input;
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _autoValidate = false;
  bool _isZaloVerified = true;
  bool _isGmailVerified = false;
  bool _isAppleVerified = false;
  // Biến lưu token từ Zalo và Gmail

  final GoogleSignIn googleSignIn = GoogleSignIn();
  String? _zaloToken;
  String? _gmailToken;
  String? _appleToken;

  // Thêm biến lưu lỗi cho từng trường
  String? _fullnameError;
  String? _emailError;
  String? _phoneError;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    register_Input = Register_Input();
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

  void _validateFields() {
    setState(() {
      _fullnameError = _fullnameController.text.isEmpty
          ? 'Vui lòng nhập họ tên!!'
          : null;
      // Email validation: required only when using Google
      if (_isGmailVerified) {
        if (_emailController.text.trim().isEmpty) {
          _emailError = 'Vui lòng nhập email!!';
        } else {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(_emailController.text.trim())) {
            _emailError = 'Email không hợp lệ!!';
          } else {
            _emailError = null;
          }
        }
      } else {
        // Not required when not using Google; only validate if non-empty
        if (_emailController.text.trim().isEmpty) {
          _emailError = null;
        }
        final RegExp emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
        if (!emailRegex.hasMatch(_emailController.text.trim())) {
          _emailError = 'Email không hợp lệ';
        }
      }
      // Phone validation
      if (_phoneController.text.isEmpty) {
        _phoneError = 'Vui lòng nhập số điện thoại!!';
      } else {
        final phone = _phoneController.text.trim();
        final phoneRegex = RegExp(r"^0[1-9]\d{8}$");
        if (!phoneRegex.hasMatch(phone)) {
          _phoneError = 'Số điện thoại không hợp lệ!!';
        } else {
          _phoneError = null;
        }
      }
    });
  }

  Future<void> _verifyZalo() async {
    try {
      await ZaloFlutter.logout();
      final Map<dynamic, dynamic>? data = await ZaloFlutter.login();
      print('Zalo login response: $data');

      if (data == null) {
        Get.snackbar(
          'Lỗi',
          'Không thể kết nối với Zalo',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
        return;
      }

      print('Zalo isSuccess: ${data['isSuccess']}');
      if (data['isSuccess'] == true) {
        print('Zalo data: ${data["data"]}');
        var accessToken = data["data"]["access_token"] as String?;
        print('Zalo access token: $accessToken');

        if (accessToken == null) {
          Get.snackbar(
            'Lỗi',
            'Không nhận được token từ Zalo',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
          );
          return;
        }

        // Lưu access token vào LocalStorage
        await LocalStorage.setString('zalo_access_token', accessToken);

        setState(() {
          _zaloToken = accessToken;
          _isZaloVerified = true;
        });
        print('Xác thực Zalo thành công. Token: $_zaloToken');
      }
    } catch (e) {
      print('Lỗi xác thực Zalo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xác thực Zalo thất bại')));
    }
  }

  // Hàm lấy access token Zalo từ LocalStorage
  Future<String?> getZaloAccessToken() async {
    return await LocalStorage.getString('zalo_access_token');
  }

  Future<void> _verifyGmail() async {
    try {
      await googleSignIn.signOut();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      print('Xác thực gmail: $account');

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
          String googleEmail = account.email ?? '';

          print('Auth code được sử dụng: $authCode');
          print('Gmail email: $googleEmail');

          // Kiểm tra email nhập vào có khớp với email Gmail không
          if (_emailController.text != googleEmail) {
            Get.snackbar(
              'Lỗi',
              'Email không khớp với tài khoản Gmail đã chọn',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red[100],
            );
            return;
          }

          setState(() {
            _gmailToken = authCode;
            _isGmailVerified = true;
          });
          print('Xác thực Gmail thành công. Token: $_gmailToken');
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
        print('Người dùng hủy xác thực Google');
      }
    } catch (e) {
      print('Lỗi xác thực Gmail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực Gmail thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveAccount() async {
    setState(() {
      _autoValidate = true;
    });
    _validateFields();
    final bool isEmailOk = _isGmailVerified ? _emailError == null : true;
    if (_fullnameError == null && _phoneError == null && isEmailOk) {
      try {
        print('Save account...');

        register_Input.name = _fullnameController.text;
        register_Input.phone = _phoneController.text;
        register_Input.email = _emailController.text;
        if (_isZaloVerified && _zaloToken != null) {
          register_Input.zaloToken = _zaloToken;
        }
        if (_isGmailVerified && _gmailToken != null) {
          register_Input.emailToken = _gmailToken;
        }
        if (_isAppleVerified && _appleToken != null) {
          register_Input.appleId = _appleToken;
        }
        print('Account data before API call: ${register_Input.toJson()}');
        await API.Account_Register.call(params: register_Input.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký tài khoản thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Get.back();
      } catch (e) {
        print('Error saving account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký tài khoản thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                                // Register form section
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
                                          // Title
                                          Container(
                                            padding: EdgeInsets.only(top: 10),
                                            child: Text(
                                              'Đăng ký tài khoản'.toUpperCase(),
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
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _buildSocialButton(
                                                onTap: () {
                                                  setState(() {
                                                    _isZaloVerified = true;
                                                    _isGmailVerified = false;
                                                    _isAppleVerified = false;
                                                  });
                                                  _formKey.currentState
                                                      ?.reset();
                                                },
                                                icon:
                                                    'assets/images/zalo_icon.png',
                                                label: 'Zalo',
                                              ),
                                              _buildSocialButton(
                                                onTap: () {
                                                  setState(() {
                                                    _isGmailVerified = true;
                                                    _isZaloVerified = false;
                                                    _isAppleVerified = false;
                                                  });
                                                  _formKey.currentState
                                                      ?.reset();
                                                },
                                                icon:
                                                    'assets/images/google_logo.png',
                                                label: 'Google',
                                              ),
                                              _buildSocialButton(
                                                onTap: () {
                                                  setState(() {
                                                    _isAppleVerified = true;
                                                    _isZaloVerified = false;
                                                    _isGmailVerified = false;
                                                  });
                                                  _formKey.currentState
                                                      ?.reset();
                                                },
                                                icon:
                                                    'assets/images/apple_logo.png',
                                                label: 'Apple',
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          // Fullname field
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.grey[200]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextFormField(
                                                  controller:
                                                      _fullnameController,
                                                  onChanged: (value) {
                                                    if (_fullnameError !=
                                                        null) {
                                                      setState(() {
                                                        _fullnameError = null;
                                                      });
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    label: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Họ tên',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Text(
                                                          ' *',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.red[400],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    prefixIcon: Icon(
                                                      Icons.person_outline,
                                                      color: Color(0xFF667eea),
                                                      size: 24,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 16,
                                                        ),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (_fullnameError != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12,
                                                        top: 5,
                                                      ),
                                                  child: Text(
                                                    _fullnameError!,
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          // Email field
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.grey[200]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextFormField(
                                                  controller: _emailController,
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  onChanged: (value) {
                                                    if (_emailError != null) {
                                                      setState(() {
                                                        _emailError = null;
                                                      });
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    label: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Email',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        if (_isGmailVerified ==
                                                            true)
                                                          Text(
                                                            ' *',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .red[400],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    prefixIcon: Icon(
                                                      Icons.email_outlined,
                                                      color: Color(0xFF667eea),
                                                      size: 24,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 16,
                                                        ),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (_emailError != null &&
                                                  _isGmailVerified == true)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12,
                                                        top: 5,
                                                      ),
                                                  child: Text(
                                                    _emailError!,
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          // Phone field
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.grey[200]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextFormField(
                                                  controller: _phoneController,
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  onChanged: (value) {
                                                    if (_phoneError != null) {
                                                      setState(() {
                                                        _phoneError = null;
                                                      });
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    label: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Số điện thoại',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Text(
                                                          ' *',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.red[400],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    prefixIcon: Icon(
                                                      Icons.phone_outlined,
                                                      color: Color(0xFF667eea),
                                                      size: 24,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 16,
                                                        ),
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (_phoneError != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12,
                                                        top: 5,
                                                      ),
                                                  child: Text(
                                                    _phoneError!,
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 30),
                                          // Register button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if (_isAppleVerified) {
                                                  Get.snackbar(
                                                    'Thông báo',
                                                    'Chức năng đăng ký bằng Apple chưa được triển khai.',
                                                    snackPosition:
                                                        SnackPosition.BOTTOM,
                                                    backgroundColor:
                                                        Colors.green[100],
                                                  );
                                                }
                                                if (_isZaloVerified) {
                                                  await _verifyZalo();
                                                  _saveAccount();
                                                }
                                                if (_isGmailVerified) {
                                                  await _verifyGmail();
                                                  _saveAccount();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFF667eea,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 8,
                                                shadowColor: Color(
                                                  0xFF667eea,
                                                ).withOpacity(0.3),
                                              ),
                                              child: Text(
                                                'Đăng Ký',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          // Login link
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Đã có tài khoản?',
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
                                                          LoginPage(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Đăng nhập ngay',
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
    // Determine if this button is selected
    bool isSelected = false;
    if (label == 'Zalo') isSelected = _isZaloVerified;
    if (label == 'Google') isSelected = _isGmailVerified;
    if (label == 'Apple') isSelected = _isAppleVerified;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF667eea) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF667eea) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(2),
              child: Image.asset(
                icon,
                height: 32,
                width: 32,
                color: isSelected ? null : Colors.grey[100],
                colorBlendMode: isSelected ? null : BlendMode.modulate,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
