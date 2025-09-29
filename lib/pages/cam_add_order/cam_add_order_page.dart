import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:viettech_video/Objects/Orders/orders.dart';
import 'package:viettech_video/apis/api.dart';
import 'package:viettech_video/models/order_record.dart';
import 'package:viettech_video/pages/cam_add_order/order_list/order_list_page.dart';
import 'package:viettech_video/services/phone_camera_service.dart';
import 'package:viettech_video/services/ffmpeg_rtsp_service.dart';
import 'package:viettech_video/components/rtsp_frame_viewer.dart';

enum CameraSource { phone, rtsp }

class CamAddOrderPage extends StatefulWidget {
  final String? userId;
  const CamAddOrderPage({super.key, this.userId});

  @override
  State<CamAddOrderPage> createState() => _CamAddOrderPageState();
}

class _CamAddOrderPageState extends State<CamAddOrderPage> {
  CameraSource _source = CameraSource.phone;
  final _rtspController = TextEditingController();
  final _phoneCamera = PhoneCameraService();
  final _rtsp = FfmpegRtspService();
  bool _rtspConnecting = false;
  String? _currentQr;
  DateTime? _startedAt;
  String? _currentVideoPath;
  String? _currentQrImagePath;
  List<OrderRecord> _records = [];
  bool _busyScanning = false;
  Timer? _rtspScanTimer;
  Timer? _qrScanTimer; // Timer để quét QR định kỳ
  DateTime? _lastScanAt; // Throttle quét trong khi đang quay

  @override
  void initState() {
    super.initState();
    // Khởi tạo camera với delay nhỏ để tránh lag
    // Future.delayed(const Duration(milliseconds: 200), () {
    _initPhone();
    // });
  }

  Future<void> _initPhone() async {
    try {
      await _ensurePermissions();

      await _phoneCamera.initialize();

      if (_phoneCamera.isInitialized) {
        // Tối ưu hóa: giảm độ phân giải để giảm lag
        await _phoneCamera.startImageStream(_onPhoneImage);

        // Bắt đầu timer quét QR định kỳ với tần suất cao hơn
        _startQrScanTimer();
      }
      if (mounted) setState(() {});
    } catch (e) {
      // Xử lý lỗi khởi tạo camera
      print('Lỗi khởi tạo camera: $e');
    }
  }

  /// Khởi tạo timer quét QR định kỳ khi đang quay video
  /// Timer này hoạt động mỗi 500ms để quét QR liên tục
  /// mà không bị gián đoạn bởi image stream
  void _startQrScanTimer() {
    _qrScanTimer?.cancel();
    _qrScanTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (mounted) {
        if (_source == CameraSource.phone &&
            _phoneCamera.isInitialized &&
            _phoneCamera.isRecording) {
          // Quét QR định kỳ khi đang quay phone camera
          await _scanQrPeriodically();
        } else if (_source == CameraSource.rtsp && _rtsp.isRecording) {
          // Quét QR định kỳ khi đang quay RTSP
          await _scanQrPeriodicallyRtsp();
        }
      }
    });
  }

  /// Quét QR định kỳ từ phone camera khi đang quay video
  /// Sử dụng takePicture() để chụp ảnh và quét QR
  /// Method này được gọi mỗi 500ms bởi timer
  Future<void> _scanQrPeriodically() async {
    if (_busyScanning) return;
    _busyScanning = true;

    try {
      // Chụp ảnh từ camera hiện tại
      final image = await _phoneCamera.controller!.takePicture();
      final input = InputImage.fromFilePath(image.path);
      final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
      final barcodes = await scanner.processImage(input);
      await scanner.close();

      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue ?? '';
        await _handleQrDetected(code, qrImagePath: image.path);
      }
    } catch (e) {
      // Quét QR định kỳ thất bại
      print('Quét QR định kỳ thất bại: $e');
    } finally {
      _busyScanning = false;
    }
  }

  /// Quét QR định kỳ từ RTSP stream khi đang quay video
  /// Sử dụng grabCurrentFrame() để lấy frame và quét QR
  /// Method này được gọi mỗi 500ms bởi timer
  Future<void> _scanQrPeriodicallyRtsp() async {
    if (_busyScanning) return;
    _busyScanning = true;

    try {
      // Lấy frame từ RTSP stream
      final frameBytes = await _rtsp.grabCurrentFrame();
      if (frameBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final snapshotPath = p.join(tempDir.path, 'rtsp_periodic_snapshot.jpg');
        await File(snapshotPath).writeAsBytes(frameBytes);

        final input = InputImage.fromFilePath(snapshotPath);
        final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
        final barcodes = await scanner.processImage(input);
        await scanner.close();

        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue ?? '';
          final cropped = await _cropQrFromImageFile(
            snapshotPath,
            barcodes.first.boundingBox,
          );
          await _handleQrDetected(code, qrImagePath: cropped ?? snapshotPath);
        }
      }
    } catch (e) {
      // Quét QR định kỳ thất bại
      print('Quét RTSP QR định kỳ thất bại: $e');
    } finally {
      _busyScanning = false;
    }
  }

  Future<void> _initRtsp() async {
    setState(() {
      _rtspConnecting = true;
    });
    // Fully dispose old session to avoid controller/view race conditions
    await _rtsp.dispose();
    await _rtsp.initialize(_rtspController.text.trim());
    _startRtspScanLoop();
    if (mounted) {
      setState(() {
        _rtspConnecting = false;
      });
    }
  }

  // Future<bool> _connectRtspAndSwitch() async {
  //   try {
  //     await _initRtsp();
  //     // Tắt camera điện thoại khi chuyển sang RTSP
  //     await _phoneCamera.stopImageStream();
  //     if (_phoneCamera.isRecording) {
  //       try {
  //         await _phoneCamera.stopVideoRecording();
  //       } catch (_) {}
  //     }
  //     if (mounted) {
  //       setState(() {
  //         _source = CameraSource.rtsp;
  //       });
  //     }
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Đã kết nối RTSP, chuyển sang camera RTSP'),
  //         ),
  //       );
  //     }
  //     return true;
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Kết nối RTSP thất bại: $e')));
  //     }
  //     return false;
  //   }
  // }

  // Future<void> _disconnectRtspAndSwitchToPhone() async {
  //   try {
  //     _rtspScanTimer?.cancel();
  //     if (_rtsp.isRecording) {
  //       await _rtsp.stopRecording();
  //     }
  //     await _rtsp.dispose();

  //     // Reset trạng thái đơn hàng hiện tại
  //     _currentQr = null;
  //     _startedAt = null;
  //     _currentVideoPath = null;
  //     _currentQrImagePath = null;

  //     // Khởi động lại camera điện thoại (nếu cần)
  //     if (_phoneCamera.isInitialized) {
  //       await _phoneCamera.startImageStream(_onPhoneImage);
  //     } else {
  //       await _initPhone();
  //     }

  //     if (mounted) {
  //       setState(() {
  //         _source = CameraSource.phone;
  //         _rtspConnecting = false;
  //       });
  //     }
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Đã ngắt kết nối RTSP, chuyển về camera điện thoại'),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Không thể ngắt RTSP: $e')));
  //     }
  //   }
  // }

  /// Mở dialog cài đặt RTSP
  /// Cho phép người dùng nhập địa chỉ RTSP và kết nối
  Future<void> _openRtspSettingsDialog() async {
    final controller = TextEditingController(text: _rtspController.text);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cài đặt RTSP'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ RTSP',
              hintText: 'rtsp://tên:mk@ip:554/...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                _rtspController.text = controller.text.trim();
                final ok = await _connectRtspAndSwitch();
                if (ok && ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: const Text('Kết nối'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      // Đã chuyển sang RTSP trong quá trình kết nối
    }
  }

  /// Kết nối RTSP và chuyển đổi từ phone camera sang RTSP
  /// Khởi tạo RTSP service và bắt đầu quét QR
  Future<bool> _connectRtspAndSwitch() async {
    try {
      await _initRtsp();
      if (_rtsp.isInitialized) {
        _source = CameraSource.rtsp;
        if (mounted) setState(() {});
        return true;
      }
    } catch (e) {
      // Xử lý lỗi kết nối RTSP
    }
    return false;
  }

  /// Ngắt kết nối RTSP và chuyển về phone camera
  /// Dừng RTSP service và khởi động lại phone camera
  Future<void> _disconnectRtspAndSwitchToPhone() async {
    try {
      await _rtsp.dispose();
      _source = CameraSource.phone;
      await _initPhone();
      if (mounted) setState(() {});
    } catch (e) {
      // Xử lý lỗi chuyển về phone camera
    }
  }

  Future<void> _ensurePermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  /// Khởi tạo vòng lặp quét QR từ RTSP stream
  /// Quét mỗi 400ms để phát hiện QR code
  void _startRtspScanLoop() {
    _rtspScanTimer?.cancel();
    _rtspScanTimer = Timer.periodic(const Duration(milliseconds: 400), (
      _,
    ) async {
      if (_busyScanning) return;
      _busyScanning = true;
      try {
        final frameBytes = await _rtsp.grabCurrentFrame();
        if (frameBytes != null) {
          final tempDir = await getTemporaryDirectory();
          final snapshotPath = p.join(tempDir.path, 'rtsp_snapshot.jpg');
          await File(snapshotPath).writeAsBytes(frameBytes);

          final input = InputImage.fromFilePath(snapshotPath);
          final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
          final barcodes = await scanner.processImage(input);
          if (barcodes.isNotEmpty) {
            final first = barcodes.first;
            final code = first.rawValue ?? '';
            final cropped = await _cropQrFromImageFile(
              snapshotPath,
              first.boundingBox,
            );
            await _handleQrDetected(code, qrImagePath: cropped ?? snapshotPath);
          }
          await scanner.close();
        }
      } catch (_) {}
      _busyScanning = false;
    });
  }

  /// Xử lý frame từ phone camera để quét QR code
  /// Method này được gọi liên tục từ image stream
  /// Khi đang quay, chỉ quét mỗi 500ms để tránh quá tải
  Future<void> _onPhoneImage(CameraImage image, InputImage inputImage) async {
    // Cho phép quét QR liên tục - chỉ skip nếu đang xử lý QR
    // Khi đang quay, chỉ quét mỗi 500ms để tránh quá tải
    final now = DateTime.now();
    if (_phoneCamera.isRecording) {
      if (_lastScanAt != null &&
          now.difference(_lastScanAt!) < const Duration(milliseconds: 500)) {
        return;
      }
      _lastScanAt = now;
    }

    if (_busyScanning) {
      return; // Skip frame nếu đang xử lý QR
    }

    _busyScanning = true;
    try {
      // Thử quét QR trực tiếp trước - tối ưu hóa để giảm lag
      try {
        final barcodes = await _phoneCamera.detectQrs(inputImage);
        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue ?? '';
          final qrPath = await _phoneCamera.saveCroppedQr(
            image,
            barcodes.first,
          );
          await _handleQrDetected(code, qrImagePath: qrPath);
          return;
        }
      } catch (e) {
        print('Quét QR trực tiếp thất bại: $e');
      }

      // Fallback: Lưu ảnh vào file và quét từ file
      try {
        final tempDir = await getTemporaryDirectory();
        final imagePath = p.join(tempDir.path, 'camera_frame.jpg');

        // Chuyển đổi camera image sang file với chất lượng thấp hơn để giảm lag
        final rgbImage = _phoneCamera.convertYuv420ToImage(image);
        final bytes = img.encodeJpg(
          rgbImage,
          quality: 50,
        ); // Giảm chất lượng từ 70 xuống 50 để giảm lag
        await File(imagePath).writeAsBytes(bytes);

        // Quét QR từ file
        final input = InputImage.fromFilePath(imagePath);
        final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
        final barcodes = await scanner.processImage(input);
        await scanner.close();

        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue ?? '';
          final qrPath = await _cropQrFromImageFile(
            imagePath,
            barcodes.first.boundingBox,
          );
          await _handleQrDetected(code, qrImagePath: qrPath ?? imagePath);
        }
      } catch (e) {
        print('Quét QR fallback thất bại: $e');
      }
    } catch (e) {
      print('Xử lý lỗi quét QR: $e');
    } finally {
      // Reset busy flag ngay lập tức để cho phép quét tiếp
      _busyScanning = false;
    }
  }

  /// Xử lý frame từ RTSP stream để quét QR code
  /// Method này được gọi liên tục từ RTSP image stream
  Future<void> _onRtspImage(Uint8List frameBytes) async {
    if (_busyScanning) {
      return; // Skip frame nếu đang xử lý QR
    }

    _busyScanning = true;
    try {
      // Lưu frame vào file tạm thời
      final tempDir = await getTemporaryDirectory();
      final imagePath = p.join(tempDir.path, 'rtsp_frame.jpg');
      await File(imagePath).writeAsBytes(frameBytes);

      // Quét QR từ file
      final input = InputImage.fromFilePath(imagePath);
      final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
      final barcodes = await scanner.processImage(input);
      await scanner.close();

      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue ?? '';
        final qrPath = await _cropQrFromImageFile(
          imagePath,
          barcodes.first.boundingBox,
        );
        await _handleQrDetected(code, qrImagePath: qrPath ?? imagePath);
      }
    } catch (e) {
      print('Xử lý lỗi quét QR từ RTSP: $e');
    } finally {
      _busyScanning = false;
    }
  }

  /// Cắt ảnh QR từ file ảnh gốc dựa trên bounding box
  /// Lưu ảnh đã cắt vào thư mục qr_frames
  /// Trả về đường dẫn file ảnh đã cắt
  Future<String?> _cropQrFromImageFile(String filePath, Rect? box) async {
    try {
      if (box == null) return null;
      final bytes = await File(filePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final left = box.left.round().clamp(0, decoded.width - 1);
      final top = box.top.round().clamp(0, decoded.height - 1);
      final width = box.width.round().clamp(1, decoded.width - left);
      final height = box.height.round().clamp(1, decoded.height - top);
      final cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: width,
        height: height,
      );
      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory(p.join(dir.path, 'qr_frames'));
      if (!await outDir.exists()) await outDir.create(recursive: true);
      final outPath = p.join(
        outDir.path,
        'QR_${DateTime.now().toIso8601String().replaceAll(':', '-')}.png',
      );
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(cropped), flush: true);
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Xử lý khi phát hiện QR code
  /// Method này xử lý logic chính của việc quay video theo QR code
  /// - Nếu chưa có QR: bắt đầu quay video đầu tiên
  /// - Nếu QR khác: dừng video cũ, bắt đầu video mới
  /// - Nếu QR giống: tiếp tục quay video hiện tại
  Future<void> _handleQrDetected(
    String code, {
    required String qrImagePath,
  }) async {
    // Nếu chưa có QR nào được quét
    if (_currentQr == null) {
      _currentQr = code;
      _startedAt = DateTime.now();
      _currentQrImagePath = qrImagePath;

      // Bắt đầu quay video
      if (_source == CameraSource.phone) {
        await _phoneCamera.startVideoRecording();
        // Bắt đầu timer quét QR định kỳ khi đang quay
        _startQrScanTimer();
        // Tạm dừng image stream trong lúc quay để tránh giật lag, sẽ bật lại khi dừng quay
        try {
          await _phoneCamera.stopImageStream();
        } catch (_) {}
      } else {
        final file = await _rtsp.startRecording();
        _currentVideoPath = file.path;
        // Bắt đầu timer quét QR định kỳ khi đang quay
        _startQrScanTimer();
        // Tạm dừng image stream trong lúc quay để tránh giật lag, sẽ bật lại khi dừng quay
        try {
          await _rtsp.stopImageStream();
        } catch (_) {}
      }

      if (mounted) setState(() {});
      return;
    }

    // Nếu quét được QR khác với QR hiện tại
    if (_currentQr != code) {
      final endedAt = DateTime.now();
      String filePath = '';

      // Dừng video hiện tại
      if (_source == CameraSource.phone) {
        if (_phoneCamera.isRecording) {
          final file = await _phoneCamera.stopVideoRecording();
          filePath = file.path;
        }
      } else {
        if (_rtsp.isRecording) {
          await _rtsp.stopRecording();
          filePath = _currentVideoPath ?? '';
        }
      }

      // Lưu order cũ
      final record = OrderRecord(
        qrCode: _currentQr ?? '',
        dateBegin: _startedAt ?? endedAt,
        dateEnd: endedAt,
        fileName: filePath,
        qrFile: _currentQrImagePath ?? qrImagePath,
      );
      _records.add(record);
      // Lưu danh sách order records vào file JSON
      await _persistRecords();

      // Bắt đầu quay video mới với QR code mới
      _currentQr = code;
      _startedAt = DateTime.now();
      _currentQrImagePath = qrImagePath;

      if (_source == CameraSource.phone) {
        await _phoneCamera.startVideoRecording();
        // Bắt đầu timer quét QR định kỳ khi đang quay
        _startQrScanTimer();
        // Tạm dừng image stream trong lúc quay để tránh giật lag, sẽ bật lại khi dừng quay
        try {
          await _phoneCamera.stopImageStream();
        } catch (_) {}
      } else {
        final file = await _rtsp.startRecording();
        _currentVideoPath = file.path;
        // Bắt đầu timer quét QR định kỳ khi đang quay
        _startQrScanTimer();
        // Tạm dừng image stream trong lúc quay để tránh giật lag, sẽ bật lại khi dừng quay
        try {
          await _rtsp.stopImageStream();
        } catch (_) {}
      }

      if (mounted) setState(() {});

      // Hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chuyển sang đơn hàng mới: $code'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // QR giống nhau - không làm gì cả, tiếp tục quay
    }

    // Đảm bảo scanning có thể tiếp tục ngay sau khi xử lý QR
    _busyScanning = false;
  }

  /// Kết thúc video clip hiện tại
  /// Dừng recording, lưu order record và upload video
  /// Bật lại image stream để tiếp tục quét QR
  Future<void> _endCurrentClip() async {
    if (_currentQr == null) return;
    final endedAt = DateTime.now();
    String filePath = '';
    if (_source == CameraSource.phone) {
      if (_phoneCamera.isRecording) {
        final file = await _phoneCamera.stopVideoRecording();
        filePath = file.path;
      }
      // Dừng timer quét QR định kỳ
      _qrScanTimer?.cancel();
      // Đảm bảo bật lại image stream sau khi dừng quay để tiếp tục quét QR
      try {
        if (_phoneCamera.isInitialized &&
            _phoneCamera.controller?.value.isStreamingImages != true) {
          await _phoneCamera.startImageStream(_onPhoneImage);
        }
      } catch (_) {}
    } else {
      if (_rtsp.isRecording) {
        await _rtsp.stopRecording();
        filePath = _currentVideoPath ?? '';
      }
      // Dừng timer quét QR định kỳ
      _qrScanTimer?.cancel();
      // Đảm bảo bật lại image stream sau khi dừng quay để tiếp tục quét QR
      try {
        if (_rtsp.isInitialized &&
            _rtsp.controller?.value.isStreamingImages != true) {
          await _rtsp.startImageStream(_onRtspImage);
        }
      } catch (_) {}
    }

    final record = OrderRecord(
      qrCode: _currentQr ?? '',
      dateBegin: _startedAt ?? endedAt,
      dateEnd: endedAt,
      fileName: filePath,
      qrFile: _currentQrImagePath ?? '',
    );
    _records.add(record);
    await _persistRecords();

    final order = Orders(
      qrCode: _currentQr ?? '',
      dateBegin: _startedAt ?? endedAt,
      dateEnd: endedAt,
      fileName: filePath,
      qrFile: _currentQrImagePath ?? '',
    );
    try {
      final orderbyQR = await API.Order_GetList.call(
        params: {"Dtime": null, "QRCode": _currentQr ?? '', "Serial": null},
      );
      final bool hasExisting =
          orderbyQR is List && (orderbyQR as List).isNotEmpty;
      if (hasExisting) {
        if (mounted) {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text(
                'Đã có đơn hàng. Bạn có muốn xóa đơn hàng cũ và thay thế bằng đơn hàng mới không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Đồng ý'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            try {
              final orderDelete = orderbyQR?.firstWhereOrNull(
                (g) => g.qrCode == _currentQr,
              );
              if (orderDelete != null) {
                await API.Order_Delete.call(params: orderDelete.toJson());
              }
              await API.Order_Add.call(params: order.toJson());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thay thế đơn hàng thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              try {
                Map<String, dynamic> params = {"iQRCode": _currentQr ?? ''};
                await API.Order_UploadVideo.call(
                  params: params,
                  file: File(filePath),
                );
              } catch (e) {
                if (mounted) {
                  print('Lỗi upload video đơn hàng (thay thế): $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Có lỗi khi upload video đơn hàng: $e'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                print('Lỗi thay thế đơn hàng: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Có lỗi khi thay thế đơn hàng: $e'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        }
      } else {
        await API.Order_Add.call(params: order.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm đơn hàng thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
        try {
          Map<String, dynamic> params = {"iQRCode": _currentQr ?? ''};
          await API.Order_UploadVideo.call(
            params: params,
            file: File(filePath),
          );
        } catch (e) {
          if (mounted) {
            print('Lỗi upload video đơn hàng: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Có lỗi khi upload video đơn hàng: $e'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi thêm đơn hàng: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi khi thêm đơn hàng: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    _currentQr = null;
    _startedAt = null;
    _currentVideoPath = null;
    _currentQrImagePath = null;

    // Continuous QR scanning is handled by image stream

    // Reset scanning state để có thể quét QR mới
    _busyScanning = false;

    if (mounted) setState(() {});
  }

  /// Lưu danh sách order records vào file JSON
  /// File được lưu trong thư mục documents của app
  Future<void> _persistRecords() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'order_records.json'));
    await file.writeAsBytes(
      OrderRecord.encodeList(_records).codeUnits,
      flush: true,
    );
  }

  @override
  void dispose() {
    // Hủy tất cả timer để tránh memory leak
    _rtspScanTimer?.cancel();
    _qrScanTimer?.cancel();

    // Giải phóng tài nguyên RTSP và phone camera
    _rtsp.dispose();
    _phoneCamera.dispose();

    // Giải phóng controller
    _rtspController.dispose();

    super.dispose();
  }

  // Không còn chuyển tab nguồn thủ công; dùng kết nối RTSP để tự chuyển

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF768CEB),
          statusBarIconBrightness: Brightness.light,
        ),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đóng gói - Quét QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Camera & RTSP Scanner',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Color(0xFF768CEB),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Danh sách Order',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderListPage(),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt, color: Colors.white),
            ),
          ),
          if (_rtspConnecting == false)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                tooltip: 'Cài đặt RTSP',
                onPressed: _openRtspSettingsDialog,
                icon: const Icon(Icons.settings_ethernet, color: Colors.white),
              ),
            ),
          if (_source == CameraSource.rtsp)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                tooltip: 'Ngắt RTSP',
                onPressed: _disconnectRtspAndSwitchToPhone,
                icon: const Icon(Icons.link_off, color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[100]!, Colors.grey[200]!],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: _buildCameraView(),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _currentQr != null
                                ? Colors.green
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _currentQr != null
                                ? Icons.qr_code_scanner
                                : Icons.qr_code,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'QR Code hiện tại',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currentQr ?? 'Chưa có QR',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (_currentQr != null) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Đang quay',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                _phoneCamera.isInitialized
                                    ? 'Camera: Hoạt động'
                                    : 'Camera: Không khởi tạo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _phoneCamera.isInitialized
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_startedAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Bắt đầu: ${_startedAt.toString().substring(0, 19)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _source == CameraSource.phone
                                ? (_phoneCamera.isRecording
                                      ? Colors.red
                                      : Colors.blue)
                                : (_rtsp.isRecording
                                      ? Colors.red
                                      : Colors.blue),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _source == CameraSource.phone
                                    ? (_phoneCamera.isRecording
                                          ? Icons.videocam
                                          : Icons.videocam_off)
                                    : (_rtsp.isRecording
                                          ? Icons.videocam
                                          : Icons.videocam_off),
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _source == CameraSource.phone
                                    ? (_phoneCamera.isRecording
                                          ? 'Đang quay'
                                          : 'Chờ')
                                    : (_rtsp.isRecording ? 'Đang quay' : 'Chờ'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _currentQr != null
                              ? () async {
                                  await _endCurrentClip();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('Kết thúc'),
                        ),
                      ],
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

  /// Xây dựng giao diện camera view
  /// Hiển thị phone camera hoặc RTSP stream tùy theo nguồn được chọn
  Widget _buildCameraView() {
    if (_source == CameraSource.phone) {
      if (!_phoneCamera.isInitialized) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Đang khởi tạo camera...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CameraPreview(_phoneCamera.controller!),
              // QR Scanner Overlay
              // Positioned.fill(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.black.withOpacity(0.3),
              //     ),
              //     child: Center(
              //       child: LayoutBuilder(
              //         builder: (context, constraints) {
              //           final size = constraints.maxWidth * 0.6;
              //           return Container(
              //             width: size,
              //             height: size,
              //             decoration: BoxDecoration(
              //               border: Border.all(color: Colors.green, width: 2),
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //             child: Stack(
              //               children: [
              //                 // Corner indicators
              //                 Positioned(
              //                   top: 0,
              //                   left: 0,
              //                   child: Container(
              //                     width: 16,
              //                     height: 16,
              //                     decoration: BoxDecoration(
              //                       color: Colors.green,
              //                       borderRadius: BorderRadius.only(
              //                         topLeft: Radius.circular(8),
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //                 Positioned(
              //                   top: 0,
              //                   right: 0,
              //                   child: Container(
              //                     width: 16,
              //                     height: 16,
              //                     decoration: BoxDecoration(
              //                       color: Colors.green,
              //                       borderRadius: BorderRadius.only(
              //                         topRight: Radius.circular(8),
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //                 Positioned(
              //                   bottom: 0,
              //                   left: 0,
              //                   child: Container(
              //                     width: 16,
              //                     height: 16,
              //                     decoration: BoxDecoration(
              //                       color: Colors.green,
              //                       borderRadius: BorderRadius.only(
              //                         bottomLeft: Radius.circular(8),
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //                 Positioned(
              //                   bottom: 0,
              //                   right: 0,
              //                   child: Container(
              //                     width: 16,
              //                     height: 16,
              //                     decoration: BoxDecoration(
              //                       color: Colors.green,
              //                       borderRadius: BorderRadius.only(
              //                         bottomRight: Radius.circular(8),
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           );
              //         },
              //       ),
              //     ),
              //   ),
              // ),
              // // Scanning indicator
              // Positioned(
              //   bottom: 12,
              //   left: 8,
              //   right: 8,
              //   child: Center(
              //     child: Container(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 12,
              //         vertical: 6,
              //       ),
              //       decoration: BoxDecoration(
              //         color: Colors.black.withOpacity(0.7),
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           Icon(
              //             Icons.qr_code_scanner,
              //             color: Colors.green,
              //             size: 14,
              //           ),
              //           const SizedBox(width: 6),
              //           Flexible(
              //             child: Text(
              //               'Đang quét QR...',
              //               style: const TextStyle(
              //                 color: Colors.white,
              //                 fontSize: 12,
              //                 fontWeight: FontWeight.w500,
              //               ),
              //               overflow: TextOverflow.ellipsis,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      );
    } else {
      if (_rtspConnecting) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Đang kết nối RTSP...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RtspFrameViewer(rtspService: _rtsp, aspectRatio: 16 / 9),
        ),
      );
    }
  }
}
