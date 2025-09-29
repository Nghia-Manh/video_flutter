import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:viettech_video/components/loading_dialog.dart';
import 'package:viettech_video/function/global.dart';
import 'package:viettech_video/function/local_storage.dart';
import 'package:viettech_video/pages/Bottom_navigation_custom/bottom_navigation_custom_page.dart';
import 'package:viettech_video/pages/Login/login.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Color(0xFF768CEB),
      statusBarIconBrightness: Brightness.light, // icon màu trắng
    ),
  );

  // Khởi tạo Firebase Core với error handling
  try {
    await Firebase.initializeApp();
    print('Firebase đã được khởi tạo thành công');
  } catch (e) {
    print('Lỗi khởi tạo Firebase: $e');
  }

  Global.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Color.fromARGB(
          255,
          253,
          253,
          253,
        ), // Nền mau toàn bộ app
      ),
      builder: (context, child) => Stack(
        children: [
          child ?? Container(),
          Obx(
            () => Global.loadingController.count > 0
                ? LoadingDialog()
                : Container(),
          ),
        ],
      ),
      getPages: [
        GetPage(
          name: '/',
          page: () {
            return FutureBuilder(
              future: LocalStorage.getLogin(),
              builder: (context, snapshot) {
                // Global.logout().then(
                //   (value) {
                //     Get.offAllNamed('/');
                //   },
                // );
                Global.loginResult = snapshot.data;
                return Global.loginResult != null
                    ? BottomNavigationCustomPage(
                        userid: snapshot.data?.UserName,
                        token: snapshot.data?.AccessToken,
                      )
                    : LoginPage();
              },
            );
          },
        ),
      ],
    );
  }
}
