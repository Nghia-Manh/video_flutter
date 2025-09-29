import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viettech_video/function/global.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      offset: Offset(3, 3),
                      color: Colors.black12,
                      blurRadius: 3),
                ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.circular(30),
                  // border: Border.all(width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => Global.loadingController.count > 0
                          ? CircularProgressIndicator()
                          : CircleAvatar(
                              backgroundColor: Colors.greenAccent,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                              )),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text('Đang tải...'),
                    // TextButton(
                    //   onPressed: () {
                    //     Global.loadingController.offLoading();
                    //     // Get.back();
                    //   },
                    //   child: Text('Close'),
                    // )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
