# RTSP + Camera Real-time Video Processing

## Tổng quan

Tính năng này cho phép ghép real-time giữa RTSP stream và camera điện thoại, sử dụng OpenGL ES để xử lý video hiệu suất cao và MediaCodec để encode H.264.

## Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   RTSP Stream   │    │  Phone Camera   │    │  OpenGL ES     │
│   (ExoPlayer)   │    │   (CameraX)     │    │   Shader       │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VideoProcessor (Native)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ RTSP Decode │  │Camera Frame │  │    Frame Blending       │ │
│  │             │  │  Capture    │  │   (OpenGL Shader)       │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│                              │                                │
│                              ▼                                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              Output Processing                              │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │Flutter View │  │ H.264 Encode│  │   File Output       │ │ │
│  │  │(Texture)    │  │(MediaCodec) │  │   (MP4)             │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Tính năng chính

### 1. **RTSP Stream Processing**
- Sử dụng ExoPlayer với RTSP extension
- Hỗ trợ các định dạng RTSP phổ biến
- Timeout và error handling

### 2. **Phone Camera Integration**
- CameraX API cho hiệu suất cao
- Preview use case cho real-time frame capture
- Resolution 1920x1080 (Full HD)

### 3. **Real-time Frame Blending**
- OpenGL ES 2.0 shader pipeline
- Fragment shader cho blending logic
- QR overlay positioning (320x240)

### 4. **Video Encoding**
- MediaCodec H.264 encoder
- 30fps, 4Mbps bitrate
- Surface-based encoding

### 5. **Flutter Integration**
- Texture widget cho video preview
- Method channel cho native communication
- Real-time display với 60fps

## Cài đặt và cấu hình

### Dependencies Android

```kotlin
// build.gradle.kts
dependencies {
    // Media3 for RTSP
    implementation("androidx.media3:media3-datasource-rtsp:1.2.1")
    
    // CameraX
    implementation("androidx.camera:camera-core:1.3.4")
    implementation("androidx.camera:camera-camera2:1.3.4")
    
    // OpenCV
    implementation("org.opencv:opencv-android:4.8.0")
    
    // ExoPlayer (fallback)
    implementation("com.google.android.exoplayer:exoplayer:2.19.1")
    implementation("com.google.android.exoplayer:extension-rtsp:2.19.1")
}
```

### Native Code Structure

```
android/app/src/main/kotlin/com/viettech/viettech_video/
├── VideoProcessor.kt          # Core video processing
├── VideoTexturePlugin.kt      # Flutter plugin interface
└── MainActivity.kt            # Plugin registration
```

## Sử dụng

### 1. Khởi tạo Video Processor

```dart
// Khởi tạo với RTSP URL
final textureId = await VideoProcessorService.initialize(
  rtspUrl: 'rtsp://192.168.1.100:554/stream',
  lifecycleOwner: 'main',
);
```

### 2. Hiển thị Video

```dart
// Sử dụng Texture widget
if (textureId != null) {
  Texture(textureId: textureId)
}
```

### 3. Bắt đầu Preview

```dart
// Bắt đầu xử lý frame
await VideoProcessorService.startPreview();
```

### 4. Ghi Video

```dart
// Bắt đầu ghi
await VideoProcessorService.startRecording(
  outputPath: '/path/to/output.mp4'
);

// Dừng ghi
await VideoProcessorService.stopRecording();
```

## Luồng xử lý Frame

### 1. **Frame Capture**
```
RTSP Stream → ExoPlayer → Surface
Camera → CameraX → Surface
```

### 2. **Frame Processing**
```
OpenGL ES Pipeline:
├── Vertex Shader: Position & UV coordinates
├── Fragment Shader: Texture blending
└── Output: Blended frame
```

### 3. **Frame Output**
```
Blended Frame → Multiple outputs:
├── Flutter Texture (preview)
├── MediaCodec (recording)
└── File (MP4)
```

## Shader Implementation

### Vertex Shader
```glsl
attribute vec4 aPosition;
attribute vec2 aTexCoord;
varying vec2 vTexCoord;

void main() {
    gl_Position = aPosition;
    vTexCoord = aTexCoord;
}
```

### Fragment Shader
```glsl
precision mediump float;
uniform sampler2D uRTSPTexture;
uniform sampler2D uCameraTexture;
uniform vec2 uQRPosition;
uniform vec2 uQRSize;
varying vec2 vTexCoord;

void main() {
    vec4 rtspColor = texture2D(uRTSPTexture, vTexCoord);
    vec4 cameraColor = texture2D(uCameraTexture, vTexCoord);
    
    // QR overlay blending
    if (vTexCoord.x >= uQRPosition.x && 
        vTexCoord.x <= uQRPosition.x + uQRSize.x &&
        vTexCoord.y >= uQRPosition.y && 
        vTexCoord.y <= uQRPosition.y + uQRSize.y) {
        gl_FragColor = mix(rtspColor, cameraColor, 0.8);
    } else {
        gl_FragColor = rtspColor;
    }
}
```

## Performance Optimization

### 1. **Memory Management**
- Surface texture pooling
- Frame buffer reuse
- OpenGL context sharing

### 2. **Rendering Pipeline**
- EGL surface optimization
- Shader program caching
- Vertex buffer optimization

### 3. **Encoding Efficiency**
- Hardware acceleration (MediaCodec)
- Surface-based encoding
- Minimal memory copies

## Troubleshooting

### Common Issues

1. **RTSP Connection Failed**
   - Kiểm tra network connectivity
   - Verify RTSP URL format
   - Check firewall settings

2. **Camera Permission Denied**
   - Request camera permission
   - Check manifest permissions
   - Runtime permission handling

3. **OpenGL Context Error**
   - EGL initialization check
   - Surface creation validation
   - Context sharing setup

4. **Performance Issues**
   - Frame rate monitoring
   - Memory usage tracking
   - Shader optimization

### Debug Logs

```kotlin
// Enable debug logging
Log.d("VideoProcessor", "Frame processed: ${System.currentTimeMillis()}")
Log.d("VideoProcessor", "Memory usage: ${Runtime.getRuntime().totalMemory()}")
```

## Future Enhancements

### 1. **Advanced Blending**
- Alpha channel support
- Multiple overlay positions
- Dynamic positioning

### 2. **Codec Support**
- H.265/HEVC encoding
- Multiple output formats
- Quality presets

### 3. **AI Integration**
- QR code detection
- Object tracking
- Scene analysis

### 4. **Network Optimization**
- Adaptive bitrate
- Connection pooling
- Error recovery

## API Reference

### VideoProcessorService

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `initialize` | `rtspUrl`, `lifecycleOwner` | `int?` | Initialize video processor |
| `startPreview` | - | `bool` | Start frame processing |
| `startRecording` | `outputPath` | `bool` | Start video recording |
| `stopRecording` | - | `bool` | Stop video recording |
| `dispose` | - | `bool` | Cleanup resources |

### VideoProcessor (Native)

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `startRTSPStream` | `rtspUrl` | - | Start RTSP connection |
| `startCameraPreview` | `surfaceTexture` | - | Initialize camera |
| `startProcessing` | `outputFile` | - | Start frame processing |
| `startRecording` | - | - | Start encoding |
| `stopRecording` | - | - | Stop encoding |

## License

This implementation is part of the VietTech Video application.
