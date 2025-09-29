import 'package:get/get.dart';

class LoadingController extends GetxController {
  var count = 0.obs;

  showLoading() => count++;

  offLoading() {
    count = count - 1;
    if (count < 0) count(0);
  }
}
