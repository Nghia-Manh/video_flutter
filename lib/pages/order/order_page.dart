import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:viettech_video/Objects/Orders/orders.dart';
import 'package:viettech_video/Objects/accounts_user/users.dart';
import 'package:viettech_video/apis/api.dart';

class OrderPage extends StatefulWidget {
  final String? userId;
  const OrderPage({super.key, this.userId});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Orders> listOrders = [];
  String? userid = '';
  Users? account;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _qrCodeController = TextEditingController();
  bool isLoading = false;
  bool hasPermission = false;
  String? deletingOrderId; // Để theo dõi đơn hàng đang được xóa

  @override
  void initState() {
    super.initState();
    userid = widget.userId;
    _loadUserLogin().then((value) {
      if (hasPermission) {
        loadData();
      }
    });
  }

  @override
  void dispose() {
    _qrCodeController.dispose();
    super.dispose();
  }

  Future _loadUserLogin() async {
    try {
      final response = await API.Account_GetById.call(
        params: {"id": widget.userId},
      );
      if (mounted) {
        setState(() {
          account = response ?? Users();
          // Kiểm tra quyền GroupPermission = "2"
          hasPermission = account?.groupPermissionId == "2";
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
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền xem danh sách đơn hàng'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> params = {
        "Dtime": DateFormat('dd/MM/yyyy').format(selectedDate),
        "Serial": null, // Bỏ qua mã máy
      };

      // Nếu có mã QR thì thêm vào params
      if (_qrCodeController.text.isNotEmpty) {
        params["QRCode"] = _qrCodeController.text;
      }

      final response = await API.Order_GetList.call(params: params);

      if (mounted) {
        setState(() {
          listOrders = (response ?? []).toList()
            ..sort(
              (a, b) => (b.dateCreate ?? DateTime.now()).compareTo(
                a.dateCreate ?? DateTime.now(),
              ),
            );
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi khi tải danh sách đơn hàng: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách đơn hàng: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      // Tự động load dữ liệu khi chọn ngày
      loadData();
    }
  }

  Future<void> _checkCameraPermission() async {
    try {
      // Kiểm tra quyền camera
      PermissionStatus status = await Permission.camera.status;

      if (status.isDenied) {
        // Yêu cầu quyền camera
        status = await Permission.camera.request();
      }

      if (status.isPermanentlyDenied) {
        // Quyền bị từ chối vĩnh viễn, hướng dẫn người dùng vào settings
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Quyền truy cập camera'),
                content: const Text(
                  'Ứng dụng cần quyền truy cập camera để quét mã QR. '
                  'Vui lòng vào Cài đặt > Ứng dụng > Viettech Video > Quyền > Camera để bật quyền.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text('Mở cài đặt'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      if (status.isGranted) {
        // Có quyền, mở scanner
        _showQRScanner();
      } else {
        // Quyền bị từ chối
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần quyền truy cập camera để quét mã QR'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Camera permission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi quyền camera: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF768CEB),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Quét mã QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      setState(() {
                        _qrCodeController.text = barcode.rawValue!;
                      });
                      Navigator.pop(context);
                      loadData(); // Load dữ liệu với mã QR
                      break;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearQRCode() {
    setState(() {
      _qrCodeController.clear();
    });
    // Tự động load lại dữ liệu theo ngày khi xóa mã QR
    loadData();
  }

  // Hàm xóa đơn hàng
  Future<void> _deleteOrder(Orders order) async {
    // Hiển thị dialog xác nhận
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc muốn xóa đơn hàng này?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (order.qrCode != null && order.qrCode!.isNotEmpty) ...[
                Text('• Mã QR: ${order.qrCode}'),
              ],
              if (order.serial != null && order.serial!.isNotEmpty) ...[
                Text('• Mã máy: ${order.serial}'),
              ],
              if (order.fileName != null && order.fileName!.isNotEmpty) ...[
                Text('• Tên file: ${order.fileName}'),
              ],
              const SizedBox(height: 8),
              const Text(
                '⚠️ Hành động này không thể hoàn tác.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() {
        deletingOrderId = order.id;
      });

      // Gọi API xóa đơn hàng
      await API.Order_Delete.call(params: order.toJson());

      if (mounted) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa đơn hàng thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Load lại danh sách đơn hàng
        loadData();
      }
    } catch (e) {
      if (mounted) {
        // Hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa đơn hàng: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          deletingOrderId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF768CEB),
            statusBarIconBrightness: Brightness.light,
          ),
          title: const Text('Danh sách đơn hàng'),
          backgroundColor: Color(0xFF768CEB),
          iconTheme: const IconThemeData(
            color: Colors.white, // Màu của mũi tên quay lại
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bạn không có quyền xem danh sách đơn hàng',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF768CEB),
          statusBarIconBrightness: Brightness.light,
        ),
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: Color(0xFF768CEB),
        iconTheme: const IconThemeData(
          color: Colors.white, // Màu của mũi tên quay lại
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header với các controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chọn ngày
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mã QR
                  Row(
                    children: [
                      const Icon(Icons.qr_code, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _qrCodeController,
                          decoration: InputDecoration(
                            hintText: 'Nhập mã QR hoặc quét',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_qrCodeController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearQRCode,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  onPressed: _checkCameraPermission,
                                ),
                              ],
                            ),
                          ),
                          onChanged: (value) {
                            loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Danh sách đơn hàng
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listOrders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Không có đơn hàng nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: listOrders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          buildOrderItem(listOrders[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderItem(Orders order) {
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(0xFF768CEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Color(0xFF768CEB),
                    size: 24,
                  ),
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
                              order.qrCode ?? 'Chưa có mã QR',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.dateBegin != null && order.dateEnd != null) ...[
                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDatetime(order.dateBegin!.toLocal().toString())} - ${_formatDatetime(order.dateEnd!.toLocal().toString())}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (order.serial != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.devices, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mã máy: ${order.serial}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (order.fileName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.file_present,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${order.fileName}',
                      style: const TextStyle(fontSize: 13),
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Nút xóa đơn hàng
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (deletingOrderId == order.id)
                  // Hiển thị loading khi đang xóa
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Đang xóa...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Nút xóa bình thường
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _deleteOrder(order),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_forever_outlined,
                                size: 18,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDatetime(String rawDate) {
    if (rawDate.isEmpty) return 'N/A';

    try {
      rawDate = rawDate.replaceAll("Z", "").replaceAll("+0000", "");
      DateTime parsedDate = DateTime.parse(rawDate);
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String year = parsedDate.year.toString();
      String hour = parsedDate.hour.toString().padLeft(2, '0');
      String minute = parsedDate.minute.toString().padLeft(2, '0');
      String second = parsedDate.second.toString().padLeft(2, '0');
      return "$hour:$minute:$second $day/$month/$year";
    } catch (e) {
      print("Lỗi khi chuyển đổi ngày: $e");
      return 'N/A';
    }
  }
}
