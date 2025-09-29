import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/function/global.dart';
import 'package:viettech_video/pages/account_page/account_detail_page.dart';
import 'package:viettech_video/pages/account_page/account_filter_page.dart';

class AccountPage extends StatefulWidget {
  final String? userid;
  const AccountPage({super.key, this.userid});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<Users> listAccounts = [];
  String? userid;
  Users? account;
  bool resident = true;

  // Vị trí của nút floating
  Offset fabPosition = const Offset(0, 0);
  late double screenWidth;
  late double screenHeight;
  final double fabSize = 56;
  final GlobalKey stackKey = GlobalKey();

  // Filter display variables
  final _khudothiSearchController = TextEditingController();
  final _toanhaSearchController = TextEditingController();
  final _tangSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userid = widget.userid;
    _loadUserLogin();
    loadData();

    // Vị trí mặc định: bottom right
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        screenWidth = MediaQuery.of(context).size.width;
        screenHeight = MediaQuery.of(context).size.height;
        fabPosition = Offset(
          screenWidth - fabSize - 20,
          screenHeight - fabSize - 120,
        );
      });
    });
  }

  Future _loadUserLogin() async {
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

  Future loadData() async {
    try {
      final response = await API.Account_GetList.call(
        params: {"UserType_id": null, "City_id": null, "Customer_id": null},
      );
      setState(() {
        if (response != null) {
          listAccounts = response.toList();
        } else {
          listAccounts = [];
        }
      });
      // setState(() {
      //   listAccounts = (response ?? []).toList();
      // });
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách tài khoản'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.blue.shade600),
          SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.blue.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
            title: const Text(
              'Danh sách tài khoản',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF768CEB),
            iconTheme: const IconThemeData(color: Colors.white),
            // actions: [
            //   IconButton(
            //     icon: Icon(Icons.filter_list, color: Colors.white),
            //     onPressed: () async {
            //       final result = await Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder: (context) => AccountFilterPage(
            //             // kdtId: kdtId,
            //             // toanhaId: toanhaId,
            //             // tangId: tangId,
            //             resident: resident,
            //             khudothiName: _khudothiSearchController.text,
            //             toanhaName: _toanhaSearchController.text,
            //             tangName: _tangSearchController.text,
            //           ),
            //         ),
            //       );

            //       if (result != null) {
            //         setState(() {
            //           // kdtId = result['kdtId'];
            //           // toanhaId = result['toanhaId'];
            //           // tangId = result['tangId'];
            //           resident = result['resident'] ?? true;
            //           _khudothiSearchController.text =
            //               result['khudothiName'] ?? '';
            //           _toanhaSearchController.text = result['toanhaName'] ?? '';
            //           _tangSearchController.text = result['tangName'] ?? '';
            //         });
            //         loadData();
            //       }
            //     },
            //   ),
            // ],
          ),
          body: SafeArea(
            child: SizedBox.expand(
              // BẮT BUỘC Stack chiếm hết màn hình
              child: Stack(
                key: stackKey,
                children: [
                  Column(
                    children: [
                      SizedBox(height: 10),
                      // Container(
                      //   padding: const EdgeInsets.all(16),
                      //   child: Column(
                      //     children: [
                      //       // Filter display section
                      //       if (_khudothiSearchController.text.isNotEmpty ||
                      //           _toanhaSearchController.text.isNotEmpty ||
                      //           _tangSearchController.text.isNotEmpty) ...[
                      //         Container(
                      //           padding: EdgeInsets.all(12),
                      //           decoration: BoxDecoration(
                      //             color: Colors.blue.shade50,
                      //             borderRadius: BorderRadius.circular(8),
                      //             border: Border.all(
                      //               color: Colors.blue.shade200,
                      //             ),
                      //           ),
                      //           child: Column(
                      //             crossAxisAlignment:
                      //                 CrossAxisAlignment.start,
                      //             children: [
                      //               Text(
                      //                 'Bộ lọc hiện tại:',
                      //                 style: TextStyle(
                      //                   fontWeight: FontWeight.bold,
                      //                   color: Colors.blue.shade700,
                      //                 ),
                      //               ),
                      //               SizedBox(height: 8),
                      //               if (_khudothiSearchController
                      //                   .text
                      //                   .isNotEmpty)
                      //                 _buildFilterChip(
                      //                   'Khu đô thị',
                      //                   _khudothiSearchController.text,
                      //                 ),
                      //               if (_toanhaSearchController
                      //                   .text
                      //                   .isNotEmpty)
                      //                 _buildFilterChip(
                      //                   'Tòa nhà',
                      //                   _toanhaSearchController.text,
                      //                 ),
                      //               if (_tangSearchController.text.isNotEmpty)
                      //                 _buildFilterChip(
                      //                   'Tầng',
                      //                   _tangSearchController.text,
                      //                 ),
                      //               if (!resident)
                      //                 _buildFilterChip(
                      //                   'Loại tài khoản',
                      //                   'Không phải cư dân',
                      //                 ),
                      //               if (resident)
                      //                 _buildFilterChip(
                      //                   'Loại tài khoản',
                      //                   'Cư dân',
                      //                 ),
                      //             ],
                      //           ),
                      //         ),
                      //         SizedBox(height: 16),
                      //       ],
                      //     ],
                      //   ),
                      // ),
                      Expanded(
                        child: listAccounts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.manage_accounts,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Không có dữ liệu tài khoản',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: listAccounts.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) =>
                                    buildItem(listAccounts[index]),
                              ),
                      ),
                    ],
                  ),

                  // // Nút có thể di chuyển
                  // Positioned(
                  //   left: fabPosition.dx,
                  //   top: fabPosition.dy,
                  //   child: Draggable(
                  //     feedback: _buildFab(),
                  //     childWhenDragging: const SizedBox.shrink(),
                  //     onDragEnd: (details) {
                  //       final RenderBox? stackBox =
                  //           stackKey.currentContext?.findRenderObject()
                  //               as RenderBox?;
                  //       if (stackBox != null) {
                  //         final Offset stackOrigin = stackBox.localToGlobal(
                  //           Offset.zero,
                  //         );
                  //         double x = details.offset.dx - stackOrigin.dx;
                  //         double y = details.offset.dy - stackOrigin.dy;
                  //         x = x.clamp(0, stackBox.size.width - fabSize);
                  //         y = y.clamp(0, stackBox.size.height - fabSize);
                  //         setState(() {
                  //           fabPosition = Offset(x, y);
                  //         });
                  //       }
                  //     },
                  //     child: _buildFab(),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      width: fabSize,
      height: fabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF768CEB),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF768CEB),
        onPressed: () {
          Global.to(
            () => AccountDetailPage(
              accounts: null,
              userId: userid,
              onEdit: () {
                loadData();
              },
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget buildItem(Users e) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        Global.to(
          () => AccountDetailPage(
            accounts: e,
            onEdit: () {
              loadData();
            },
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar căn giữa dọc
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        (e.avatar != null && e.avatar!.isNotEmpty)
                            ? Container(
                                width: 45.0,
                                height: 45.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'http://demo.quanlynoibo.com:8123/Avatars/${e.avatar!}',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 22.5,
                                backgroundColor: Color(
                                  0xFF768CEB,
                                ).withOpacity(0.7),
                                child: Text(
                                  e.fullName![0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Nội dung
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.fullName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (e.phone != null && e.phone!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: Color(0xff559955),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.phone ?? '',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                          if (e.address != null && e.address!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Color(0xff559955),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.address!,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(
          phoneUri,
          // mode: LaunchMode.platformDefault, // chỉ mở ứng dụng gọi điện
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể gọi số điện thoại: $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gọi điện thoại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _khudothiSearchController.dispose();
    _toanhaSearchController.dispose();
    _tangSearchController.dispose();
    super.dispose();
  }
}
