import 'package:viettech_video/Objects/Devices/device.dart';
import 'package:viettech_video/Objects/GroupPermission/groupPermission.dart';
import 'package:viettech_video/Objects/Orders/orders.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/Objects/base/login_result.dart';
import 'package:viettech_video/function/get_data_api.dart';

Uri get uri => Uri.parse('http://demo.quanlynoibo.com:8123/');
Uri api(String path) {
  // return uri.replace(path: path);
  return Uri.parse(uri.toString() + path);
}

class API {
  static GetDataAPI<LoginResult> get Account_Login_User => GetDataAPI(
    uri: api('Account/Login_User'),
    method: GetDataAPIMethod.post,
    formatter: (json) => LoginResult.fromJson(json),
  );
  static GetDataAPI<LoginResult> get Account_Login_Email => GetDataAPI(
    uri: api('Account/Login_Email'),
    method: GetDataAPIMethod.post,
    formatter: (json) => LoginResult.fromJson(json),
  );
  static GetDataAPI<LoginResult> get Account_Login_Zalo => GetDataAPI(
    uri: api('Account/Zalo_Login'),
    method: GetDataAPIMethod.post,
    formatter: (json) => LoginResult.fromJson(json),
  );
  static GetDataAPI<String> get Account_LinkApple =>
      GetDataAPI(uri: api('Account/Link_Apple'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Account_LinkGmail =>
      GetDataAPI(uri: api('Account/Link_Gmail'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Account_LinkZalo =>
      GetDataAPI(uri: api('Account/Link_Zalo'), method: GetDataAPIMethod.post);
  static GetDataAPI<LoginResult> get Account_GetUserInfo => GetDataAPI(
    uri: api('Account/GetUserInfo'),
    method: GetDataAPIMethod.post,
    formatter: (json) => LoginResult.fromJson(json),
  );
  static GetDataAPI<List<Users>> get Account_GetList => GetDataAPI(
    uri: api('Account/GetList'),
    formatter: (json) => (json as List).map((e) => Users.fromJson(e)).toList(),
  );
  static GetDataAPI<String> get Account_FirebaseToken => GetDataAPI(
    uri: api('Account/FirebaseToken'),
    method: GetDataAPIMethod.post,
  );
  static GetDataAPI<String> get Account_Register =>
      GetDataAPI(uri: api('Account/Register'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Account_ChangeAvatar => GetDataAPI(
    uri: api('Account/Change_Avatar'),
    method: GetDataAPIMethod.upload,
  );
  static GetDataAPI<String> get Account_ChangePassword => GetDataAPI(
    uri: api('Account/ChangePassword'),
    method: GetDataAPIMethod.post,
  );
  static GetDataAPI<String> get Account_CheckLogin =>
      GetDataAPI(uri: api('Account/CheckLogin'), method: GetDataAPIMethod.get);
  static GetDataAPI<Users> get Account_GetById => GetDataAPI(
    uri: api('Account'),
    method: GetDataAPIMethod.get,
    formatter: (json) => Users.fromJson(json),
  );
  static GetDataAPI<String> get Account_Add =>
      GetDataAPI(uri: api('Account'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Account_Edit =>
      GetDataAPI(uri: api('Account/{id}'), method: GetDataAPIMethod.put);
  static GetDataAPI<String> get Account_Delete =>
      GetDataAPI(uri: api('Account/{id}'), method: GetDataAPIMethod.delete);

  // Devices APIs
  static GetDataAPI<List<Devices>> get Devices_GetList => GetDataAPI(
    uri: api('Devices/Get_List'),
    formatter: (json) =>
        (json as List).map((e) => Devices.fromJson(e)).toList(),
  );
  static GetDataAPI<List<Devices>> get Devices_GetAll => GetDataAPI(
    uri: api('Devices/Get_All'),
    formatter: (json) =>
        (json as List).map((e) => Devices.fromJson(e)).toList(),
  );
  static GetDataAPI<List<Devices>> get Devices_Get_Approved => GetDataAPI(
    uri: api('Devices/Get_Approved'),
    formatter: (json) =>
        (json as List).map((e) => Devices.fromJson(e)).toList(),
  );
  static GetDataAPI<Devices> get Devices_GetInfo => GetDataAPI(
    uri: api('Devices/GetInfo'),
    method: GetDataAPIMethod.get,
    formatter: (json) => Devices.fromJson(json),
  );
  static GetDataAPI<String> get Devices_Register =>
      GetDataAPI(uri: api('Devices/Register'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Devices_Approved =>
      GetDataAPI(uri: api('Devices/Apprved'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Devices_Delete =>
      GetDataAPI(uri: api('Devices/Delete'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Devices_ServiceExtension => GetDataAPI(
    uri: api('Devices/Service_extension'),
    method: GetDataAPIMethod.post,
  );

  // Order
  static GetDataAPI<List<Orders>> get Order_GetList => GetDataAPI(
    uri: api('Orders/Get_List'),
    formatter: (json) => (json as List).map((e) => Orders.fromJson(e)).toList(),
  );
  static GetDataAPI<String> get Order_Add =>
      GetDataAPI(uri: api('Orders/Add'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Order_Delete =>
      GetDataAPI(uri: api('Orders/Delete'), method: GetDataAPIMethod.post);
  static GetDataAPI<String> get Order_UploadVideo => GetDataAPI(
    uri: api('Orders/Upload_Video'),
    method: GetDataAPIMethod.upload,
  );

  // Group Permission
  static GetDataAPI<List<GroupPermission>> get GroupPermission_GetList =>
      GetDataAPI(
        uri: api('GroupPermission'),
        formatter: (json) =>
            (json as List).map((e) => GroupPermission.fromJson(e)).toList(),
      );
}
