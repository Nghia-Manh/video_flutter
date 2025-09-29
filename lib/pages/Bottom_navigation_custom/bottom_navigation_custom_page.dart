import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:viettech_video/Template/bottom_navigation_page.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/pages/Devices/device_page.dart';
import 'package:viettech_video/pages/order/order_page.dart';
import 'package:viettech_video/pages/person_page/person_page.dart';
import 'package:viettech_video/pages/cam_add_order/cam_add_order_page.dart';

class BottomNavigationCustomPage extends StatefulWidget {
  final String? userid;
  final String? token;
  const BottomNavigationCustomPage({super.key, this.userid, this.token});

  @override
  State<BottomNavigationCustomPage> createState() =>
      _BottomNavigationCustomPageState();
}

class _BottomNavigationCustomPageState
    extends State<BottomNavigationCustomPage> {
  //firebase token
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentToken;

  // Lấy token hiện tại
  Future<String?> getToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      print('Token Firebase: $_currentToken');
      return _currentToken;
    } catch (e) {
      print('Lỗi lấy Firebase token: $e');
      if (e.toString().contains('No Firebase App')) {
        print('Firebase chưa được khởi tạo');
      }
      return null;
    }
  }

  // Cập nhật token lên server
  Future<bool> updateTokenOnServer(String? token) async {
    if (token == null || token.isEmpty) {
      print('Token rỗng hoặc null, không thể cập nhật lên server');
      return false;
    }
    try {
      // Gọi API để cập nhật token
      await API.Account_FirebaseToken.call(params: {"Token": token});
      return true;
    } catch (e) {
      print('Lỗi Firebase token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi Firebase token'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  // Hàm cập nhật token
  Future<void> _updateToken() async {
    try {
      // Lấy token mới
      String? newToken = await getToken();

      if (newToken != null && newToken.isNotEmpty) {
        // Cập nhật token lên server
        bool success = await updateTokenOnServer(newToken);
        if (success) {
          print('Cập nhật token thành công: $newToken');
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(
          //       content: Text('Cập nhật token thành công'),
          //       backgroundColor: Colors.green,
          //       duration: Duration(seconds: 3),
          //     ),
          //   );
          // }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể cập nhật token lên server'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thể lấy token từ Firebase. Vui lòng kiểm tra cấu hình Firebase.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi khi cập nhật token';
        if (e.toString().contains('No Firebase App')) {
          errorMessage =
              'Firebase chưa được khởi tạo. Vui lòng khởi động lại ứng dụng.';
        } else if (e.toString().contains('Failed to load FirebaseOptions')) {
          errorMessage =
              'Cấu hình Firebase không đúng. Vui lòng kiểm tra file google-services.json.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Sử dụng post-frame callback để đảm bảo widget được khởi tạo hoàn toàn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationPage(
      index: 0,
      items: [
        BottomNavigationItem(
          item: Icon(Icons.menu, color: Color(0xffffffff)),
          child: DevicePage(userId: widget.userid),
        ),
        BottomNavigationItem(
          item: Icon(Icons.assignment, color: Color(0xffffffff)),
          child: OrderPage(userId: widget.userid),
        ),
        BottomNavigationItem(
          item: Icon(Icons.camera_alt, color: Color(0xffffffff)),
          child: CamAddOrderPage(userId: widget.userid),
          // child: null,
        ),
        BottomNavigationItem(
          item: Icon(FontAwesomeIcons.user, color: Color(0xffffffff)),
          child: PersonPage(
            usernameId: widget.userid ?? '',
            token: widget.token ?? '',
          ),
        ),
      ],
    );
  }
}
