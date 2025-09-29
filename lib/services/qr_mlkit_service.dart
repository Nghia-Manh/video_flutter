// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:image/image.dart' as img;

// class QrMlkitService {
//   final BarcodeScanner _scanner = BarcodeScanner(
//     formats: [BarcodeFormat.qrCode],
//   );

//   Future<List<Barcode>> detectBarcodesFromImageData(
//     Uint8List bytes,
//     int width,
//     int height,
//   ) async {
//     final inputImage = InputImage.fromBytes(
//       bytes: bytes,
//       metadata: InputImageMetadata(
//         size: Size(width.toDouble(), height.toDouble()),
//         rotation: InputImageRotation.rotation0deg,
//         format: InputImageFormat.nv21,
//         bytesPerRow: width,
//       ),
//     );
//     return _scanner.processImage(inputImage);
//   }

//   Future<String?> cropQrRegionToFile({
//     required Uint8List bytes,
//     required int width,
//     required int height,
//     required Barcode barcode,
//     required String outputPath,
//   }) async {
//     try {
//       final rect = barcode.boundingBox;
//       if (rect == null) return null;
//       final image = img.Image.fromBytes(
//         width: width,
//         height: height,
//         bytes: bytes.buffer,
//         numChannels: 4,
//       );
//       final cropRect = img.copyCrop(
//         image,
//         x: rect.left.toInt().clamp(0, width - 1),
//         y: rect.top.toInt().clamp(0, height - 1),
//         width: rect.width.toInt().clamp(1, width),
//         height: rect.height.toInt().clamp(1, height),
//       );
//       final pngBytes = img.encodePng(cropRect);
//       final file = File(outputPath);
//       await file.create(recursive: true);
//       await file.writeAsBytes(pngBytes, flush: true);
//       return file.path;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Lỗi cắt vùng QR: $e');
//       }
//       return null;
//     }
//   }

//   Future<void> dispose() async {
//     await _scanner.close();
//   }
// }
