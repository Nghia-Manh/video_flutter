import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:viettech_video/services/ffmpeg_rtsp_service.dart';

class RtspFrameViewer extends StatefulWidget {
  final FfmpegRtspService rtspService;
  final double aspectRatio;

  const RtspFrameViewer({
    super.key,
    required this.rtspService,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<RtspFrameViewer> createState() => _RtspFrameViewerState();
}

class _RtspFrameViewerState extends State<RtspFrameViewer> {
  Uint8List? _currentFrame;
  StreamSubscription<Uint8List>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToFrames();
  }

  void _subscribeToFrames() {
    _frameSubscription = widget.rtspService.frameStream.listen((frame) {
      if (mounted) {
        setState(() {
          _currentFrame = frame;
        });
      }
    });
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrame == null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Đang kết nối RTSP...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: Colors.black,
        child: Image.memory(
          _currentFrame!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: frame != null ? child : const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
