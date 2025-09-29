# Ứng dụng Quay Video Đóng Gói Đơn Hàng

## Mô tả
Ứng dụng Flutter để quay video quá trình đóng gói, nhận diện mã QR đơn hàng và lưu trữ dữ liệu phục vụ đối soát.

## Chức năng chính

### 1. Quay Video Đóng Gói
- **Camera điện thoại**: Quay video quá trình đóng gói
- **QR Scanner**: Nhận diện mã QR liên tục
- **Video Recording**: Ghi video MP4 (H.264) với timestamp gốc
- **Image Capture**: Chụp và xử lý ảnh QR (320x240)

### 2. Xử lý Video
- **FFmpeg Integration**: Xử lý video với H.264 encoding
- **Timestamp Preservation**: Giữ nguyên timestamp gốc, không bị tua nhanh
- **File Management**: Tự động quản lý file video và ảnh

### 3. Quản lý Đơn Hàng
- **Order Creation**: Tự động tạo đơn hàng khi quét QR hoặc kết thúc
- **Local Storage**: Lưu trữ cục bộ với cấu trúc JSON
- **Server Sync**: Đồng bộ dữ liệu lên server (cần implement API)
- **Order List**: Xem danh sách và chi tiết đơn hàng

## Cấu trúc Dự án

### Pages
- `PackagingRecordingPage`: Trang chính quay video
- `OrderListPage`: Danh sách đơn hàng đã quay

### Services
- `OrderRecordingService`: Xử lý logic nghiệp vụ

### Models
- `OrderRecording`: Model dữ liệu đơn hàng

## Luồng Hoạt Động

### TH1: 2 Camera (Camera điện thoại + RTSP)
1. **Camera điện thoại**:
   - Quét mã QR liên tục
   - Khi quét được QR → chụp frame chứa QR
   - Cắt thu nhỏ frame (320x240) để ghép vào video RTSP

2. **Camera RTSP**:
   - Video chính của quá trình đóng gói
   - Ghép frame thu nhỏ từ camera điện thoại vào góc trên bên phải

3. **Xử lý Video**:
   - OpenCV ghép frame
   - Ghi video MP4 với FFmpeg
   - Tạo đối tượng Order khi đổi QR hoặc kết thúc

### TH2: 1 Camera (Camera điện thoại)
- Camera vừa quét QR vừa quay video đóng gói
- Khi đổi QR hoặc kết thúc → lưu video và ảnh QR vào Order

## Cài đặt và Sử dụng

### 1. Dependencies
Các package đã được thêm vào `pubspec.yaml`:
```yaml
camera: ^0.11.2
mobile_scanner: ^7.0.1
google_mlkit_barcode_scanning: ^0.14.1
ffmpeg_kit_flutter_new: ^3.2.0
image: ^4.5.4
path_provider: ^2.0.11
```

### 2. Permissions
Cần cấp quyền trong `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 3. Sử dụng
1. Mở ứng dụng và chọn tab Camera
2. Cấp quyền camera khi được yêu cầu
3. Đặt mã QR vào khung hình camera
4. Nhấn "BẮT ĐẦU QUAY" để bắt đầu ghi video
5. Khi quét được QR mới hoặc nhấn "DỪNG QUAY", video sẽ được lưu
6. Nhấn icon danh sách để xem các đơn hàng đã quay

## Cấu trúc Dữ liệu Order

```json
{
  "id": "unique_order_id",
  "qrCode": "mã_qr_đơn_hàng",
  "dateBegin": "2024-01-01T10:00:00Z",
  "dateEnd": "2024-01-01T10:05:00Z",
  "fileName": "/path/to/video.mp4",
  "qrFile": "/path/to/qr_image.jpg",
  "userId": "user_id",
  "status": "completed",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:05:00Z"
}
```

## Tính năng Nâng cao

### 1. File Management
- Tự động dọn dẹp file không sử dụng
- Kiểm tra tính toàn vẹn file
- Quản lý dung lượng lưu trữ

### 2. Error Handling
- Xử lý lỗi camera
- Fallback khi FFmpeg thất bại
- Retry mechanism cho API calls

### 3. Performance
- Video streaming mượt 30fps
- QR detection real-time
- Background processing cho video encoding

## API Integration

### Endpoints cần implement:
```dart
// Tạo đơn hàng mới
POST /api/orders
{
  "qrCode": "string",
  "dateBegin": "datetime",
  "dateEnd": "datetime",
  "fileName": "string",
  "qrFile": "string",
  "userId": "string"
}

// Lấy danh sách đơn hàng
GET /api/orders?userId={userId}

// Cập nhật trạng thái đơn hàng
PUT /api/orders/{id}
{
  "status": "string"
}
```

## Troubleshooting

### Lỗi thường gặp:
1. **Camera không khởi tạo**: Kiểm tra quyền camera
2. **FFmpeg processing failed**: Kiểm tra FFmpeg installation
3. **QR detection không hoạt động**: Kiểm tra lighting và focus
4. **Video file corrupt**: Kiểm tra dung lượng lưu trữ

### Debug:
- Sử dụng `print()` statements trong code
- Kiểm tra logs trong Flutter DevTools
- Verify file paths và permissions

## Tương lai

### Roadmap:
- [ ] RTSP camera integration
- [ ] Multi-camera support
- [ ] Cloud storage integration
- [ ] Real-time analytics
- [ ] Batch processing
- [ ] Export functionality

### Optimizations:
- [ ] Video compression algorithms
- [ ] QR detection accuracy improvement
- [ ] Memory usage optimization
- [ ] Battery life optimization

## Liên hệ
Để hỗ trợ kỹ thuật hoặc báo cáo lỗi, vui lòng liên hệ team phát triển.
