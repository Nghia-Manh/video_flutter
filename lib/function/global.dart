import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viettech_video/Objects/base/login_result.dart';
import 'package:viettech_video/function/local_storage.dart';
import 'package:viettech_video/get_controller/loading_controller.dart';

class Global {
  static LoginResult? loginResult;

  static late LoadingController loadingController;

  static void init() {
    loadingController = Get.put(LoadingController(), permanent: true);
  }

  static Future logout() {
    return LocalStorage.setLogin(null);
  }

  static void to(Widget Function() page) {
    Get.to(page, preventDuplicates: false);
    // Get.to(
    //   () => PopScope(
    //     key: UniqueKey(),
    //     // canPop: false,
    //     // onPopInvoked: (didPop) {
    //     //   print(didPop);
    //     //   if (!didPop) {
    //     //     if (Global.loadingController.count <= 0) {
    //     //       Get.back();
    //     //     }
    //     //   }
    //     // },
    //     child: page(),
    //   ),
    // );
  }
}
