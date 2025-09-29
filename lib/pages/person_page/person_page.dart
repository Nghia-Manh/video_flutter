import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/Template/custom_avatar.dart';
import 'package:viettech_video/Template/custom_item.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/function/global.dart';
import 'package:viettech_video/pages/account_page/account_page.dart';
import 'package:viettech_video/pages/chang_password_page/change_password.dart';
import 'package:viettech_video/pages/person_page/profile_page/MyAccount.dart';
import 'package:viettech_video/pages/person_page/profile_page/profile_page.dart';

class PersonPage extends StatefulWidget {
  final String? usernameId;
  final String? token;
  const PersonPage({super.key, this.usernameId, this.token});
  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  String? userid;
  Users? account;

  @override
  void initState() {
    super.initState();
    userid = widget.usernameId;
    _loadUserLogin();
  }

  void _loadUserLogin() async {
    try {
      final response = await API.Account_GetById.call(params: {"id": userid});
      if (mounted) {
        setState(() {
          account = response ?? Users();
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
    // bool truefales = false;
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
            backgroundColor: Color(0xFF768CEB),
            title: Text('Thông tin cá nhân'),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(
                0xFF768CEB,
              ), // Đặt màu nền cho thanh trạng thái
              statusBarIconBrightness:
                  Brightness.light, // Màu biểu tượng: trắng
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Column(
                children: [
                  Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomAvatar(
                      color: Colors.white,
                      image:
                          account?.avatar != null && account!.avatar!.isNotEmpty
                          ? account!.avatar!.startsWith('assets')
                                ? account!.avatar!
                                : account!.avatar!.startsWith('http')
                                ? account!.avatar!
                          : 'http://demo.quanlynoibo.com:8123/Avatars/${account!.avatar!}'
                          : 'assets/images/user.png',
                      title: account?.fullName ?? '',
                      subtitle: 'Xem trang cá nhân',
                      icon: Icons.person_add_outlined,
                      coloricon: Colors.blue,
                      hasimg: true,
                      hassub: true,
                      onTap: () {
                        if (account != null) {
                          Global.to(() => MyAccount(userId: widget.usernameId));
                        }
                      },
                    ),
                  ),
                  if (account?.groupPermissionId == '1') ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          CustomItem(
                            image: '',
                            icon: Icons.manage_accounts,
                            title: 'Quản lý người dùng',
                            subtitle: '',
                            hasIcon1: true,
                            hasIcon2: true,
                            hasBorder: false,
                            onTap: () {
                              Global.to(() => AccountPage(userid: userid));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  // const SizedBox(height: 16),
                  // Card(
                  //   elevation: 2.0,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   clipBehavior: Clip.antiAlias,
                  //   child: CustomItem(
                  //     image: '',
                  //     icon: Icons.lock_outline,
                  //     title: 'Đổi mật khẩu',
                  //     subtitle: '',
                  //     hasIcon1: true,
                  //     onTap: () {
                  //       Global.to(
                  //         () => ChangePasswordPage(
                  //           usernameId: userid ?? '',
                  //           token: widget.token ?? '',
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        CustomItem(
                          image: '',
                          icon: Icons.local_police_outlined,
                          title: 'Điều khoản sử dụng',
                          subtitle: '',
                          hasIcon1: true,
                          hasIcon2: true,
                          hasBorder: true,
                          onTap: () {
                            Get.snackbar(
                              'Thông báo',
                              'Tính năng chưa triển khai',
                              titleText: Text('Thông báo'),
                              backgroundColor: Colors.purple[100],
                              snackPosition: SnackPosition.BOTTOM,
                              // messageText: Text('Abcd')
                            );
                          },
                        ),
                        CustomItem(
                          image: '',
                          icon: Icons.login_outlined,
                          title: 'Đăng xuất',
                          subtitle: '',
                          hasIcon1: true,
                          hasIcon2: true,
                          hasBorder: false,
                          onTap: () {
                            Global.logout().then((value) {
                              Get.offAllNamed('/');
                            });
                          },
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
}
