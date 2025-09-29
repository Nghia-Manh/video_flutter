// import 'package:flutter/services.dart';

// // Flutter side để gọi native code
// class VideoProcessorService {
//   static const MethodChannel _channel = MethodChannel('video_texture_channel');

//   /// Initialize video processor with RTSP stream and phone camera
//   static Future<int?> initialize({
//     required String rtspUrl,
//     required String lifecycleOwner,
//   }) async {
//     try {
//       final int? textureId = await _channel.invokeMethod('initialize', {
//         'rtspUrl': rtspUrl,
//         'lifecycleOwner': lifecycleOwner,
//       });

//       print('Video processor initialized with texture ID: $textureId');
//       return textureId;
//     } on PlatformException catch (e) {
//       print('Failed to initialize video processor: ${e.message}');
//       return null;
//     }
//   }

//   /// Start video preview
//   static Future<bool> startPreview() async {
//     try {
//       final bool success = await _channel.invokeMethod('startPreview');
//       print('Preview started: $success');
//       return success;
//     } on PlatformException catch (e) {
//       print('Failed to start preview: ${e.message}');
//       return false;
//     }
//   }

//   /// Start recording to file
//   static Future<bool> startRecording({required String outputPath}) async {
//     try {
//       final bool success = await _channel.invokeMethod('startRecording', {
//         'outputPath': outputPath,
//       });
//       print('Recording started: $success');
//       return success;
//     } on PlatformException catch (e) {
//       print('Failed to start recording: ${e.message}');
//       return false;
//     }
//   }

//   /// Stop recording
//   static Future<bool> stopRecording() async {
//     try {
//       final bool success = await _channel.invokeMethod('stopRecording');
//       print('Recording stopped: $success');
//       return success;
//     } on PlatformException catch (e) {
//       print('Failed to stop recording: ${e.message}');
//       return false;
//     }
//   }

//   /// Dispose video processor
//   static Future<bool> dispose() async {
//     try {
//       final bool success = await _channel.invokeMethod('dispose');
//       print('Video processor disposed: $success');
//       return success;
//     } on PlatformException catch (e) {
//       print('Failed to dispose video processor: ${e.message}');
//       return false;
//     }
//   }
// }