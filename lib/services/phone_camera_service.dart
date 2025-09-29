import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhoneCameraService {
  CameraController? _controller;
  bool _isStreaming = false;
  bool _isRecording = false;
  StreamSubscription? _imageStreamSub;
  final BarcodeScanner _scanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized == true;
  bool get isRecording => _isRecording;

  Future<void> initialize({
    // Điều chỉnh độ phân giải cài đặt trước theo thiết bị
    ResolutionPreset preset = ResolutionPreset.low,
  }) async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      back,
      preset,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller!.initialize();
  }

  Future<void> dispose() async {
    await stopImageStream();
    if (_isRecording) {
      try {
        await stopVideoRecording();
      } catch (_) {}
    }
    await _controller?.dispose();
    await _scanner.close();
  }

  Future<void> startImageStream(
    Future<void> Function(CameraImage image, InputImage inputImage) onImage,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isStreaming) return;
    _isStreaming = true;
    await _controller!.startImageStream((image) async {
      if (!_isStreaming) return;
      try {
        final inputImage = _inputImageFromCameraImage(
          image,
          _controller!.description,
        );
        await onImage(image, inputImage);
      } catch (e) {
        if (kDebugMode) {
          print('Lỗi luồng hình ảnh: $e');
        }
      }
    });
  }

  Future<void> stopImageStream() async {
    _isStreaming = false;
    if (_controller?.value.isStreamingImages == true) {
      await _controller!.stopImageStream();
    }
    await _imageStreamSub?.cancel();
  }

  Future<List<Barcode>> detectQrs(InputImage inputImage) async {
    return _scanner.processImage(inputImage);
  }

  Future<XFile> startVideoRecording() async {
    if (_controller == null) throw StateError('Camera chưa khởi tạo');
    if (_isRecording) throw StateError('Đang ghi hình');
    final dir = await _ensureVideoDir();
    final path = p.join(dir.path, _timestampFile('mp4'));
    _isRecording = true;
    await _controller!.startVideoRecording();
    // Camera plugin manages path on stop; we will move file on stop.
    return XFile(path);
  }

  Future<XFile> stopVideoRecording() async {
    if (_controller == null) throw StateError('Camera chưa khởi tạo');
    if (!_isRecording) throw StateError('Không trong trạng thái ghi hình');
    final file = await _controller!.stopVideoRecording();
    _isRecording = false;
    // Move to app videos dir with timestamped name if needed
    final dir = await _ensureVideoDir();
    final newPath = p.join(dir.path, _timestampFile('mp4'));
    final newFile = await File(file.path).copy(newPath);
    return XFile(newFile.path);
  }

  Future<Directory> _ensureVideoDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(doc.path, 'order_videos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _timestampFile(String ext) {
    final now = DateTime.now();
    final ts = now.toIso8601String().replaceAll(':', '-');
    return 'VID_$ts.$ext';
  }

  // Build InputImage from CameraImage with correct rotation
  InputImage _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription description,
  ) {
    final sensorOrientation = description.sensorOrientation;
    InputImageRotation rotation;
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      default:
        rotation = InputImageRotation.rotation270deg;
        break;
    }

    // Determine the correct format based on image format group
    InputImageFormat format;
    if (image.format.group == ImageFormatGroup.yuv420) {
      format = InputImageFormat.yuv420;
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      format = InputImageFormat.bgra8888;
    } else {
      format = InputImageFormat.yuv420; // Default fallback
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // Convert YUV420 to RGB image for cropping
  img.Image convertYuv420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final imgData = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yValue =
            image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
        final uValue = image.planes[1].bytes[uvIndex];
        final vValue = image.planes[2].bytes[uvIndex];

        final yf = yValue.toDouble();
        final uf = uValue.toDouble() - 128.0;
        final vf = vValue.toDouble() - 128.0;

        var r = (yf + 1.370705 * vf).round();
        var g = (yf - 0.337633 * uf - 0.698001 * vf).round();
        var b = (yf + 1.732446 * uf).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        imgData.setPixelRgb(x, y, r, g, b);
      }
    }
    return imgData;
  }

  Future<String> saveCroppedQr(CameraImage image, Barcode barcode) async {
    final rect = barcode.boundingBox;
    if (rect == null) {
      throw Exception('Barcode không có bounding box');
    }

    // Khôi phục logic cắt chính xác như ban đầu
    final rgb = convertYuv420ToImage(image);

    // Cắt chính xác theo bounding box, không thêm margin
    final left = rect.left.round().clamp(0, rgb.width - 1);
    final top = rect.top.round().clamp(0, rgb.height - 1);
    final width = rect.width.round().clamp(1, rgb.width - left);
    final height = rect.height.round().clamp(1, rgb.height - top);

    // Cắt ảnh chính xác
    final cropped = img.copyCrop(
      rgb,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    // Lưu ảnh cắt
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, 'qr_frames'));
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final path = p.join(
      outDir.path,
      'QR_${DateTime.now().toIso8601String().replaceAll(':', '-')}.png',
    );
    final file = File(path);
    await file.writeAsBytes(img.encodePng(cropped), flush: true);

    print(
      'QR cropped (exact): left=$left, top=$top, width=$width, height=$height',
    );
    print(
      'Original rect: ${rect.left}, ${rect.top}, ${rect.width}, ${rect.height}',
    );

    // Debug: lưu ảnh gốc để so sánh
    try {
      final debugPath = p.join(
        dir.path,
        'DEBUG_ORIGINAL_${DateTime.now().toIso8601String().replaceAll(':', '-')}.png',
      );
      final debugFile = File(debugPath);
      await debugFile.writeAsBytes(img.encodePng(rgb), flush: true);
      print('Debug: Saved original image to: $debugPath');
    } catch (e) {
      print('Debug: Failed to save original image: $e');
    }

    return file.path;
  }
}
