import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:viettech_video/Objects/Devices/device.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/function/global.dart';
import 'package:viettech_video/pages/Devices/device_detail_page.dart';

class DevicePage extends StatefulWidget {
  final String? userId;
  const DevicePage({super.key, this.userId});
  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  List<Devices> listDevices = [];
  String? userid = '';
  Users? account;
  // Lưu ngày hết hạn người dùng chọn cho từng thiết bị theo Id
  final Map<String, DateTime> _selectedExpiryByDeviceId = {};

  final List<int> _selectedStates = [];

  @override
  void initState() {
    super.initState();
    userid = widget.userId;
    _loadUserLogin().then((value) {
      loadData();
    });
  }

  Future _loadUserLogin() async {
    try {
      final response = await API.Account_GetById.call(
        params: {"id": widget.userId},
      );
      if (mounted) {
        setState(() {
          account = response ?? Users();
          if (account?.groupPermissionId == '1') {
            _selectedStates.add(0);
          } else {
            _selectedStates.add(1);
          }
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

  void loadData() async {
    try {
      if (_selectedStates.isEmpty) {
        if (account?.groupPermissionId == '1') {
          final response = await API.Devices_GetAll.call();
          setState(() {
            listDevices = (response ?? []).toList()
              ..sort((a, b) {
                // Ưu tiên state = 0 lên đầu
                if ((a.state ?? 0) == 0 && (b.state ?? 0) != 0) return -1;
                if ((a.state ?? 0) != 0 && (b.state ?? 0) == 0) return 1;
                // Nếu cùng state, sắp xếp theo ngày tạo mới nhất
                return (b.dateCreate ?? DateTime.now()).compareTo(
                  a.dateCreate ?? DateTime.now(),
                );
              });
          });
        } else {
          final response = await API.Devices_GetList.call(
            params: {"iUser_id": widget.userId},
          );
          setState(() {
            listDevices = (response ?? []).toList()
              ..sort((a, b) {
                // Ưu tiên state = 0 lên đầu
                if ((a.state ?? 1) == 0 && (b.state ?? 1) != 0) return -1;
                if ((a.state ?? 1) != 0 && (b.state ?? 1) == 0) return 1;
                // Nếu cùng state, sắp xếp theo ngày tạo mới nhất
                return (b.dateCreate ?? DateTime.now()).compareTo(
                  a.dateCreate ?? DateTime.now(),
                );
              });
          });
        }
      } else {
        if (account?.groupPermissionId == '1') {
          final response = await API.Devices_GetAll.call();
          setState(() {
            listDevices =
                (response ?? [])
                    .where((e) => _selectedStates.contains(e.state))
                    .toList()
                  ..sort((a, b) {
                    // Ưu tiên state = 0 lên đầu
                    if ((a.state ?? 0) == 0 && (b.state ?? 0) != 0) return -1;
                    if ((a.state ?? 0) != 0 && (b.state ?? 0) == 0) return 1;
                    // Nếu cùng state, sắp xếp theo ngày tạo mới nhất
                    return (b.dateCreate ?? DateTime.now()).compareTo(
                      a.dateCreate ?? DateTime.now(),
                    );
                  });
          });
        } else {
          final response = await API.Devices_GetList.call(
            params: {"iUser_id": widget.userId},
          );
          setState(() {
            listDevices =
                (response ?? [])
                    .where((e) => _selectedStates.contains(e.state))
                    .toList()
                  ..sort((a, b) {
                    // Ưu tiên state = 0 lên đầu
                    if ((a.state ?? 1) == 0 && (b.state ?? 1) != 0) return -1;
                    if ((a.state ?? 1) != 0 && (b.state ?? 1) == 0) return 1;
                    // Nếu cùng state, sắp xếp theo ngày tạo mới nhất
                    return (b.dateCreate ?? DateTime.now()).compareTo(
                      a.dateCreate ?? DateTime.now(),
                    );
                  });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi khi tải danh sách thiết bị: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách thiết bị'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
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
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF768CEB),
              statusBarIconBrightness: Brightness.light,
            ),
            title: Text(
              'Danh sách thiết bị',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF768CEB),
            iconTheme: const IconThemeData(
              color: Colors.white, // Màu của mũi tên quay lại
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (int state in _selectedStates)
                              Chip(
                                label: _buildStateChip(state),
                                onDeleted: () {
                                  setState(() {
                                    _selectedStates.remove(state);
                                    loadData();
                                  });
                                },
                                backgroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.grey.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                deleteIconColor: Colors.redAccent,
                                labelPadding: EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.filter_list, color: Color(0xFF768CEB)),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                            ),
                            builder: (context) {
                              List<int> tempSelectedStates = List.from(
                                _selectedStates,
                              );
                              return StatefulBuilder(
                                builder: (context, setModalState) => Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(15),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.filter_alt,
                                                color: Color(0xFF768CEB),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Lọc theo trạng thái',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF768CEB),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  setModalState(() {
                                                    tempSelectedStates.clear();
                                                  });
                                                },
                                                child: Text(
                                                  'Xóa lọc',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Divider(),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          for (var i = 0; i < 3; i++)
                                            FilterChip(
                                              label: _buildStateChip(i),
                                              selected: tempSelectedStates
                                                  .contains(i),
                                              onSelected: (bool selected) {
                                                setModalState(() {
                                                  if (selected) {
                                                    tempSelectedStates.add(i);
                                                  } else {
                                                    tempSelectedStates.remove(
                                                      i,
                                                    );
                                                  }
                                                });
                                              },
                                              backgroundColor: Colors.white,
                                              selectedColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    225,
                                                    230,
                                                    255,
                                                  ),
                                              checkmarkColor: Color(0xFF768CEB),
                                              elevation: 2,
                                              shadowColor: Colors.grey
                                                  .withOpacity(0.3),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              labelPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFF768CEB,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                'Áp dụng',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedStates.clear();
                                                  _selectedStates.addAll(
                                                    tempSelectedStates,
                                                  );
                                                  loadData();
                                                });
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: listDevices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.devices, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Không có dữ liệu danh sách thiết bị nào',
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
                          padding: const EdgeInsets.all(12),
                          itemCount: listDevices.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              buildItem(listDevices[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildItem(Devices e) {
    final String deviceId = e.id ?? '';
    final int state = e.state ?? 0;
    final DateTime defaultExpiry = _getDefaultExpiry(e, state);
    final DateTime selectedExpiry =
        _selectedExpiryByDeviceId[deviceId] ?? defaultExpiry;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/device.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  width: 42,
                  height: 42,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deviceId.isEmpty ? 'Chưa xác định' : deviceId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Bỏ nút xóa trên header để tránh trùng lặp, chỉ hiển thị ở hàng hành động phía dưới
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.customerName ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (e.dateExpired != null &&
                    !_isUnknownDate(e.dateExpired)) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_off,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hết hạn: ${_formatDatetime(e.dateExpired!.toLocal().toString())}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                _buildStateChip(state),
              ],
            ),
            const SizedBox(height: 12),
            // Theo trạng thái
            if (state == 0 && account?.groupPermissionId == '1')
              _buildApproveSection(e, selectedExpiry),
            if (state == 1 && account?.groupPermissionId == '2')
              _buildExtendSection(e, selectedExpiry),
            if (state == 2 && account?.groupPermissionId == '2')
              _buildExtendSection(e, selectedExpiry),
            const SizedBox(height: 4),
            Row(
              children: [
                if (state == 1 && account?.groupPermissionId == '2')
                  TextButton.icon(
                    onPressed: () => _deleteDevice(e),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text(
                      'Xóa thiết bị',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Global.to(
                      () => DeviceDetailPage(
                        device: e,
                        onEdit: () {
                          loadData();
                        },
                      ),
                    );
                  },
                  child: const Text('Xem chi tiết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(int state) {
    late Color color;
    late String text;
    switch (state) {
      case 0:
        color = const Color(0xFF8E8E00);
        text = 'Chưa duyệt';
        break;
      case 1:
        color = const Color(0xFF2E7D32);
        text = 'Đang sử dụng';
        break;
      case 2:
        color = const Color.fromARGB(255, 211, 26, 26);
        text = 'Không sử dụng';
        break;
      default:
        color = Colors.grey;
        text = 'Không rõ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDatePickerInline(Devices e, DateTime selected) {
    final String deviceId = e.id ?? '';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _selectedExpiryByDeviceId[deviceId] = DateTime(
              picked.year,
              picked.month,
              picked.day,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF8F8F8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(selected),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproveSection(Devices e, DateTime selectedExpiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ngày hết hạn'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildDatePickerInline(e, selectedExpiry)),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _approveDevice(e, selectedExpiry),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                backgroundColor: const Color(0xFF559955),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtendSection(Devices e, DateTime selectedExpiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ngày hết hạn'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildDatePickerInline(e, selectedExpiry)),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _extendService(e, selectedExpiry),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Gia hạn',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateTime _getDefaultExpiry(Devices e, int state) {
    DateTime base;
    if (state == 0) {
      base = DateTime.now();
    } else {
      if (e.dateExpired != null && e.dateExpired!.isAfter(DateTime.now())) {
        base = e.dateExpired!;
      } else {
        base = DateTime.now();
      }
    }
    final next = _addMonths(base, 1);
    return DateTime(next.year, next.month, next.day);
  }

  DateTime _addMonths(DateTime input, int monthsToAdd) {
    final int year = input.year + ((input.month + monthsToAdd - 1) ~/ 12);
    final int month = ((input.month + monthsToAdd - 1) % 12) + 1;
    final int day = input.day;
    final DateTime tentative = DateTime(year, month, 1);
    final int lastDayOfMonth = DateTime(
      tentative.year,
      tentative.month + 1,
      0,
    ).day;
    return DateTime(year, month, day > lastDayOfMonth ? lastDayOfMonth : day);
  }

  Future<void> _approveDevice(Devices device, DateTime expiry) async {
    try {
      final Devices payload = Devices.fromJson(device.toJson());
      payload.dateExpired = DateTime(expiry.year, expiry.month, expiry.day);
      payload.state = 1; // Sau duyệt -> đang dùng
      await API.Devices_Approved.call(params: payload.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phê duyệt thiết bị thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phê duyệt thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extendService(Devices device, DateTime expiry) async {
    try {
      final Devices payload = Devices.fromJson(device.toJson());
      payload.dateExpired = DateTime(expiry.year, expiry.month, expiry.day);
      await API.Devices_ServiceExtension.call(params: payload.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gia hạn sử dụng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gia hạn thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDevice(Devices device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa thiết bị này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await API.Devices_Delete.call(params: device.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thiết bị'),
            backgroundColor: Colors.green,
          ),
        );
      }
      loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDatetime(String rawDate) {
    try {
      rawDate = rawDate.replaceAll("Z", "").replaceAll("+0000", "");
      DateTime parsedDate = DateTime.parse(rawDate);
      if (parsedDate.year <= 1) {
        return 'Chưa xác định';
      }
      return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year.toString().padLeft(4, '0')}";
    } catch (e) {
      print("Lỗi khi chuyển đổi ngày: $e");
      return 'Chưa xác định';
    }
  }

  bool _isUnknownDate(DateTime? date) {
    if (date == null) return true;
    return date.year <= 1;
  }

  // String _formatDatetime(String rawDate) {
  //   if (rawDate.isEmpty) return 'Chưa xác định';

  //   try {
  //     rawDate = rawDate.replaceAll("Z", "").replaceAll("+0000", "");
  //     DateTime parsedDate = DateTime.parse(rawDate);
  //     String day = parsedDate.day.toString().padLeft(2, '0');
  //     String month = parsedDate.month.toString().padLeft(2, '0');
  //     String year = parsedDate.year.toString().substring(
  //       2,
  //     ); // Lấy 2 số cuối của năm
  //     String hour = parsedDate.hour.toString().padLeft(2, '0');
  //     String minute = parsedDate.minute.toString().padLeft(2, '0');
  //     return "$day/$month/$year $hour:$minute";
  //   } catch (e) {
  //     print("Lỗi khi chuyển đổi ngày: $e");
  //     return 'Chưa xác định';
  //   }
  // }
}
