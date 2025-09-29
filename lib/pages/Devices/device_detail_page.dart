import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:viettech_video/Objects/Devices/device.dart';
import 'package:viettech_video/apis/api.dart';

class DeviceDetailPage extends StatefulWidget {
  final Devices? device; // null nếu là thêm mới, có giá trị nếu là edit
  final Function? onEdit; // callback để refresh list
  const DeviceDetailPage({
    super.key,
    required this.device,
    required this.onEdit,
  });
  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late Devices _device;
  final _formKey = GlobalKey<FormState>();
  final _dateActiveController = TextEditingController();
  final _dateApprovedController = TextEditingController();
  final _dateExpiredController = TextEditingController();
  final _idController = TextEditingController();
  int state = 0;
  bool _autoValidate = false;
  bool _hasChanges = false;
  late Map<String, dynamic> _originalData;

  String _formatDatetime(String rawDate) {
    try {
      rawDate = rawDate.replaceAll("Z", "").replaceAll("+0000", "");
      DateTime parsedDate = DateTime.parse(rawDate);
      if (parsedDate.year <= 1) {
        return 'Chưa xác định';
      }
      return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
    } catch (e) {
      print("Lỗi khi chuyển đổi ngày: $e");
      return 'N/A';
    }
  }

  @override
  void initState() {
    super.initState();
    // Nếu là edit thì fill data vào form
    _idController.text = widget.device?.id ?? '';
    _dateActiveController.text =
        (widget.device?.dateActive != null &&
            widget.device!.dateActive!.year > 1)
        ? _formatDatetime(widget.device!.dateActive!.toLocal().toString())
        : 'Chưa xác định';
    _dateApprovedController.text =
        (widget.device?.dateApproved != null &&
            widget.device!.dateApproved!.year > 1)
        ? _formatDatetime(widget.device!.dateApproved!.toLocal().toString())
        : 'Chưa xác định';
    // : _formatDatetime(DateTime.now().toLocal().toString());
    _dateExpiredController.text =
        (widget.device?.dateExpired != null &&
            widget.device!.dateExpired!.year > 1)
        ? _formatDatetime(widget.device!.dateExpired!.toLocal().toString())
        : 'Chưa xác định';
    // _dateExpiredController.text = _buildDefaultExpiredText(widget.device);
    state = widget.device?.state ?? 0;
    _device = Devices.fromJson(widget.device?.toJson() ?? {});
    _originalData = _getCurrentFormData();

    _dateActiveController.addListener(_checkForChanges);
    _dateApprovedController.addListener(_checkForChanges);
    _dateExpiredController.addListener(_checkForChanges);
    _idController.addListener(_checkForChanges);
  }

  // void _saveDevice() async {
  //   setState(() {
  //     _autoValidate = true;
  //   });

  //   if (_formKey.currentState!.validate()) {
  //     try {
  //       DateFormat format = DateFormat("dd/MM/yyyy");
  //       DateTime localExpired = format.parse(_dateExpiredController.text);
  //       _device.dateExpired = DateTime(
  //         localExpired.year,
  //         localExpired.month,
  //         localExpired.day,
  //       );
  //       await API.Devices_Approved.call(params: _device.toJson());
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Cập nhật thiết bị thành công'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       }

  //       widget.onEdit?.call();
  //       Get.back();
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(e.toString().replaceAll('Exception:', '')),
  //             backgroundColor: Colors.red,
  //             duration: const Duration(seconds: 3),
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }

  Future<void> _selectDateExpired(BuildContext context) async {
    DateTime? _selectedDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          _parseDateFromController(_dateExpiredController.text) ??
          DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateExpiredController.text =
            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      });
    }
  }

  void _checkForChanges() {
    final currentData = _getCurrentFormData();
    if (!_hasChanges && !_mapEquals(currentData, _originalData)) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Map<String, dynamic> _getCurrentFormData() {
    return {
      'id': _idController.text,
      'dateActive': _dateActiveController.text,
      'dateApproved': _dateApprovedController.text,
      'dateExpired': _dateExpiredController.text,
      'state': state,
    };
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final v1 = a[key];
      final v2 = b[key];
      if (v1 is List && v2 is List) {
        if (!_listEquals(v1, v2)) return false;
      } else if (v1 != v2) {
        return false;
      }
    }
    return true;
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] is Map && b[i] is Map) {
        if (!_mapEquals(a[i], b[i])) return false;
      } else if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận'),
          content: Text(
            'Bạn có chắc chắn muốn quay lại? Các thay đổi sẽ không được lưu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('HỦY'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('ĐỒNG Ý', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _handleBack() async {
    if (_hasChanges) {
      final shouldPop = await _onWillPop();
      if (shouldPop) {
        Get.back();
      }
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF768CEB),
              statusBarIconBrightness: Brightness.light,
            ),
            title: Text(
              'Chi tiết thiết bị',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF768CEB),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _idController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Mã thiết bị',
                        prefixIcon: Icon(Icons.perm_identity),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFEEEEEE),
                        labelStyle: TextStyle(color: Colors.black87),
                      ),
                      style: const TextStyle(color: Colors.black),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateActiveController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Ngày kích hoạt',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        labelStyle: const TextStyle(color: Colors.black87),
                      ),
                      style: const TextStyle(color: Colors.black),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateApprovedController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Ngày phê duyệt',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        border: OutlineInputBorder(),
                        filled: widget.device?.dateApproved != null
                            ? true
                            : false,
                        fillColor: widget.device?.dateApproved != null
                            ? const Color(0xFFEEEEEE)
                            : Colors.transparent,
                        labelStyle: widget.device?.dateApproved != null
                            ? const TextStyle(color: Colors.black87)
                            : null,
                      ),
                      style: widget.device?.dateApproved != null
                          ? const TextStyle(color: Colors.black)
                          : null,
                      enabled: widget.device?.dateApproved != null
                          ? false
                          : true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateExpiredController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Ngày hết hạn',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        // suffixIcon: IconButton(
                        //   icon: Icon(Icons.calendar_today),
                        //   onPressed: () => _selectDateExpired(context),
                        // ),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        labelStyle: const TextStyle(color: Colors.black87),
                      ),
                      style: const TextStyle(color: Colors.black),
                      enabled: false,
                      // validator: (value) {
                      //   if (value == null || value.isEmpty) {
                      //     return 'Vui lòng chọn ngày hết hạn';
                      //   }
                      //   return null;
                      // },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: TextEditingController(
                        text: _getStateText(state),
                      ),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái thiết bị',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        labelStyle: const TextStyle(color: Colors.black87),
                      ),
                      style: const TextStyle(color: Colors.black),
                      enabled: false,
                    ),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 12,
                    //     vertical: 12,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     border: Border.all(color: Colors.grey.shade400),
                    //     borderRadius: BorderRadius.circular(4),
                    //     color: const Color(0xFFEEEEEE),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.info_outline, color: Colors.grey.shade700),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const Text(
                    //               'Trạng thái thiết bị',
                    //               style: TextStyle(
                    //                 fontSize: 12,
                    //                 color: Colors.grey,
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),
                    //             const SizedBox(height: 4),
                    //             Text(
                    //               _getStateText(state),
                    //               style: TextStyle(
                    //                 fontSize: 16,
                    //                 fontWeight: FontWeight.w600,
                    //                 color: _getStateColor(state),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 24),
                    // Action theo trạng thái
                    // if (state == 0)
                    //   SizedBox(
                    //     width: double.infinity,
                    //     height: 50,
                    //     child: ElevatedButton(
                    //       onPressed: _saveDevice,
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: const Color(0xff559955),
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(8),
                    //         ),
                    //       ),
                    //       child: const Text(
                    //         'PHÊ DUYỆT',
                    //         style: TextStyle(fontSize: 18, color: Colors.white),
                    //       ),
                    //     ),
                    //   )
                    // else ...[
                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: SizedBox(
                    //           height: 48,
                    //           child: ElevatedButton(
                    //             onPressed: _extendService,
                    //             style: ElevatedButton.styleFrom(
                    //               backgroundColor: const Color(0xFF1976D2),
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(8),
                    //               ),
                    //             ),
                    //             child: const Text(
                    //               'GIA HẠN',
                    //               style: TextStyle(color: Colors.white),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //       if (state == 1) ...[
                    //         const SizedBox(width: 12),
                    //         SizedBox(
                    //           height: 48,
                    //           child: TextButton.icon(
                    //             onPressed: _deleteDevice,
                    //             icon: const Icon(
                    //               Icons.delete_forever,
                    //               color: Colors.red,
                    //             ),
                    //             label: const Text(
                    //               'XÓA',
                    //               style: TextStyle(color: Colors.red),
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ],
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateActiveController.removeListener(_checkForChanges);
    _dateApprovedController.removeListener(_checkForChanges);
    _dateExpiredController.removeListener(_checkForChanges);
    _idController.removeListener(_checkForChanges);
    super.dispose();
  }

  String _buildDefaultExpiredText(Devices? device) {
    final now = DateTime.now();
    DateTime base;
    final int currentState = device?.state ?? 0;
    if (currentState == 0) {
      base = now;
    } else {
      final DateTime? exp = device?.dateExpired;
      if (exp != null && exp.year > 1 && exp.isAfter(now)) {
        base = exp;
      } else {
        base = now;
      }
    }
    final next = _addMonths(base, 1);
    return '${next.day.toString().padLeft(2, '0')}/${next.month.toString().padLeft(2, '0')}/${next.year}';
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

  DateTime? _parseDateFromController(String input) {
    try {
      final parts = input.split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  String _getStateText(int state) {
    switch (state) {
      case 0:
        return 'Chưa duyệt';
      case 1:
        return 'Đang sử dụng';
      case 2:
        return 'Không sử dụng';
      default:
        return 'Không xác định';
    }
  }

  Color _getStateColor(int state) {
    switch (state) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _extendService() async {
    try {
      DateFormat format = DateFormat('dd/MM/yyyy');
      final picked = format.parse(_dateExpiredController.text);
      _device.dateExpired = DateTime(picked.year, picked.month, picked.day);
      await API.Devices_ServiceExtension.call(params: _device.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gia hạn sử dụng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      widget.onEdit?.call();
      Get.back();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDevice() async {
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
      await API.Devices_Delete.call(params: _device.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thiết bị'),
            backgroundColor: Colors.green,
          ),
        );
      }
      widget.onEdit?.call();
      Get.back();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
