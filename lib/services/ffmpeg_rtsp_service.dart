import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Controller để tương thích với interface camera
class RtspController {
  bool _isStreamingImages = false;

  bool get isStreamingImages => _isStreamingImages;

  // Thêm property value để tương thích với CameraController
  RtspValue get value => RtspValue(_isStreamingImages);

  void setStreaming(bool streaming) {
    _isStreamingImages = streaming;
  }
}

// Class để tương thích với CameraValue
class RtspValue {
  final bool isStreamingImages;

  RtspValue(this.isStreamingImages);
}

class FfmpegRtspService {
  String? _rtspUrl;
  bool _isRecording = false;
  bool _isStreaming = false;
  bool _isInitialized = false;
  FFmpegSession? _recordSession;
  // _streamSession không dùng tới; lược bỏ để gọn code
  Timer? _frameTimer;
  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();

  // Thêm controller để tương thích với interface camera
  RtspController? _controller;

  bool get isRecording => _isRecording;
  bool get isStreaming => _isStreaming;
  bool get isInitialized => _isInitialized;
  RtspController? get controller => _controller;
  Stream<Uint8List> get frameStream => _frameController.stream;

  Future<void> initialize(String rtspUrl) async {
    _rtspUrl = rtspUrl;
    _isInitialized = true;
    _controller = RtspController();
    await _startFrameStream();
  }

  // Thêm method startImageStream để tương thích
  Future<void> startImageStream(Function(Uint8List) onImage) async {
    if (!_isInitialized || _rtspUrl == null) {
      throw StateError('RTSP service chưa được khởi tạo');
    }

    _isStreaming = true;
    _controller?.setStreaming(true);

    // Bắt đầu capture frame và gọi callback
    _frameTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) async {
      if (!_isStreaming) return;

      try {
        final frame = await grabCurrentFrame();
        if (frame != null) {
          onImage(frame);
        }
      } catch (e) {
        if (kDebugMode) print('Lỗi trong image stream: $e');
      }
    });
  }

  // Thêm method stopImageStream
  Future<void> stopImageStream() async {
    _isStreaming = false;
    _controller?.setStreaming(false);
    _frameTimer?.cancel();
  }

  Future<void> _startFrameStream() async {
    if (_rtspUrl == null) return;

    _isStreaming = true;

    // Đơn giản hóa: luôn dùng cơ chế chụp frame theo interval
    await _startFrameCapture();
  }

  Future<void> _startFrameCapture() async {
    if (_rtspUrl == null) return;

    // Sử dụng ffmpeg để capture frame từ RTSP stream
    // Output ra JPEG format để dễ xử lý
    final tempDir = await getTemporaryDirectory();
    final framePath = p.join(tempDir.path, 'current_frame.jpg');

    _frameTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) async {
      if (!_isStreaming) return;

      try {
        // Capture frame từ RTSP
        final args =
            '-rtsp_transport tcp -stimeout 5000000 -rw_timeout 5000000 -y -i "$_rtspUrl" -frames:v 1 -q:v 3 -f image2 "$framePath"';
        final session = await FFmpegKit.execute(args);
        final rc = await session.getReturnCode();

        if (ReturnCode.isSuccess(rc)) {
          final file = File(framePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            _frameController.add(bytes);
          }
        } else {
          if (kDebugMode) {
            print('RTSP frame grab failed: ${rc?.getValue()}');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Lỗi capture frame: $e');
      }
    });
  }

  Future<File> startRecording() async {
    if (_rtspUrl == null) throw StateError('RTSP chưa được khởi tạo');
    if (_isRecording) throw StateError('Đang ghi hình');

    final videosDir = await _ensureVideoDir();
    final outPath = p.join(videosDir.path, _timestampFile('mp4'));

    // Sử dụng ffmpeg để ghi video từ RTSP stream (timeout để kết nối rõ ràng hơn)
    final args =
        '-rtsp_transport tcp -stimeout 5000000 -rw_timeout 5000000 -i "$_rtspUrl" -c copy -f mp4 "$outPath"';
    _isRecording = true;

    final session = await FFmpegKit.executeAsync(args, (session) async {
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        if (kDebugMode) print('Ghi hình RTSP hoàn tất: $outPath');
      } else {
        if (kDebugMode) print('Ghi hình RTSP thất bại: ${rc?.getValue()}');
      }
    });

    _recordSession = session;
    return File(outPath);
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recordSession?.cancel();
    } catch (_) {
      await FFmpegKit.cancel();
    }

    _isRecording = false;
  }

  Future<String?> grabSnapshotTo(String path) async {
    try {
      if (_rtspUrl == null) return null;

      final args =
          '-rtsp_transport tcp -y -i "$_rtspUrl" -frames:v 1 -q:v 2 "$path"';
      final session = await FFmpegKit.execute(args);
      final rc = await session.getReturnCode();

      if (ReturnCode.isSuccess(rc)) {
        final exists = await File(path).exists();
        return exists ? path : null;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Lỗi chụp ảnh nhanh RTSP: $e');
      return null;
    }
  }

  Future<Uint8List?> grabCurrentFrame() async {
    try {
      if (_rtspUrl == null) return null;

      final tempDir = await getTemporaryDirectory();
      final framePath = p.join(tempDir.path, 'temp_frame.jpg');

      final args =
          '-rtsp_transport tcp -y -i "$_rtspUrl" -frames:v 1 -q:v 2 "$framePath"';
      final session = await FFmpegKit.execute(args);
      final rc = await session.getReturnCode();

      if (ReturnCode.isSuccess(rc)) {
        final file = File(framePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Lỗi lấy frame hiện tại: $e');
      return null;
    }
  }

  Future<Directory> _ensureVideoDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(doc.path, 'order_videos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _timestampFile(String ext) {
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'VID_$ts.$ext';
  }

  Future<void> dispose() async {
    _isStreaming = false;
    _frameTimer?.cancel();

    if (_isRecording) {
      await stopRecording();
    }

    await _frameController.close();
    _controller = null;
    _isInitialized = false;
  }
}
