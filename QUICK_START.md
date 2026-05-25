# QUICK START - KHỞI ĐỘNG NHANH

## 🚀 5 Bước Chạy Ứng Dụng Ngay

### 1️⃣ Cập Nhật Flutter (Nếu Chưa Có)
```bash
# Tải Flutter: https://flutter.dev/docs/get-started/install
# Sau khi cài xong, mở Terminal/PowerShell tại folder:
cd C:\Users\Manh\DO_AN_TN
```

### 2️⃣ Cài Đặt Dependencies
```bash
flutter pub get
```

### 3️⃣ Cấu Hình Firebase (QUAN TRỌNG)
1. Truy cập: https://firebase.google.com/
2. Tạo dự án mới
3. Tạo Android/iOS app
4. Download `google-services.json` → Copy vào `android/app/`
5. Sửa `lib/firebase_options.dart` (thay các giá trị YOUR_*)

### 4️⃣ Cấu Hình Google Generative AI
1. Truy cập: https://ai.google.dev/
2. Nhấp "Get API Key"
3. Copy API key
4. Thêm vào `lib/services/ai_service.dart`:
```dart
final apiKey = 'YOUR_API_KEY_HERE';
```

### 5️⃣ Chạy Ứng Dụng
```bash
# Android (cần emulator hoặc điện thoại kết nối)
flutter run

# iOS (macOS only)
flutter run -d iPhone

# Web (easy testing)
flutter run -d chrome
```

---

## 📂 File Quan Trọng Cần Chỉnh Sửa

| File | Chỉnh Sửa | Mục Đích |
|------|----------|---------|
| `lib/firebase_options.dart` | Thêm Firebase credentials | Kết nối Firebase |
| `lib/services/ai_service.dart` | Thêm Google API key | Sử dụng AI Gemini |
| `pubspec.yaml` | (Không cần) | Dependencies |
| `android/app/src/main/AndroidManifest.xml` | (Tự động) | Android config |

---

## 🎯 Các Màn Hình Chính

| Tên | Đường Dẫn | Mô Tả |
|-----|---------|--------|
| 📱 Login | `/login` | Đăng nhập |
| 📝 Signup | `/signup` | Đăng ký |
| 🏠 Home | `/home` | Trang chủ (Dashboard) |
| 📊 Charts | `/charts` | Xu hướng ngành học |
| 🤖 Chatbot | `/chatbot` | Chat Bot AI |
| 💬 Forum | `/forum` | Diễn đàn |
| 🎯 Guidance | `/guidance` | Định hướng (5 bước) |
| 👤 Profile | `/profile` | Hồ sơ cá nhân |

---

## 🔑 Tài Khoản Test

**Sau khi cấu hình Firebase**, bạn có thể tạo tài khoản test:

1. Trên app → "Đăng Ký"
2. Nhập:
   - Email: `test@example.com`
   - Password: `123456`
   - Họ tên: `Tester`
   - Số điện thoại: `0123456789`
   - Ngày sinh: `01/01/2005`
   - Khu vực: `Miền Bắc`
3. Tap "Đăng Ký"

---

## ⚙️ Các Lệnh Hữu Ích

```bash
# Kiểm tra thiết bị
flutter devices

# Xem logs
flutter logs

# Clean project
flutter clean

# Cập nhật packages
flutter pub upgrade

# Phân tích code
flutter analyze

# Format code
flutter format lib/

# Hot reload (sau khi chạy flutter run)
# Bấm 'r' trong terminal

# Hot restart
# Bấm 'R' trong terminal

# Quit app
# Bấm 'q' trong terminal
```

---

## 🆘 Lỗi Thường Gặp

### Lỗi: "No device found"
```bash
# Android emulator
flutter emulators launch android_emulator

# Hoặc kết nối điện thoại USB
```

### Lỗi: "firebase_core not found"
```bash
flutter pub get
flutter pub upgrade firebase_core
```

### Lỗi: "android/app/google-services.json not found"
- Download lại từ Firebase Console
- Copy vào `android/app/`

### Lỗi: "API key invalid"
- Kiểm tra lại Google Generative AI API key
- Chắc chắn key hợp lệ và còn quota

---

## 📚 Tài Liệu Đầy Đủ

Để hiểu chi tiết về project:

1. **README.md** (5 phút đọc)
   - Tổng quan project
   - Danh sách tính năng

2. **SETUP_GUIDE.md** (15 phút đọc)
   - Hướng dẫn cập nhật dependencies
   - Firebase rules
   - Troubleshooting

3. **DETAILED_GUIDE.md** (30 phút + đọc)
   - Hướng dẫn chi tiết (2000+ dòng)
   - Cách dùng từng tính năng
   - Cấu hình Firebase chi tiết
   - Debugging tips

4. **PROJECT_SUMMARY.md** (10 phút đọc)
   - Thống kê project
   - Cấu trúc files
   - Roadmap tương lai

---

## 🎨 Tùy Chỉnh Nhanh

### Thay Đổi Tên Ứng Dụng
Sửa `lib/main.dart`:
```dart
title: 'Tên Ứng Dụng Mới'
```

### Thay Đổi Màu Chính
Sửa `lib/constants/app_constants.dart`:
```dart
static const Color primary = Color(0xFFYOUR_COLOR);
```

### Thay Đổi Logo/Icon
Thay thế ở `assets/images/` hoặc `assets/icons/`

---

## 📱 Testing Checklist

- [ ] Signup works
- [ ] Login works
- [ ] Dashboard loads
- [ ] Career guidance form works
- [ ] AI chatbot responds
- [ ] Forum posts visible
- [ ] Charts display
- [ ] Profile can be edited
- [ ] Logout works

---

## 🚀 Deploy (Sau Này)

### Build APK (Android)
```bash
flutter build apk --release
# File: build/app/outputs/apk/release/app-release.apk
```

### Build App Bundle (Google Play)
```bash
flutter build appbundle --release
# File: build/app/outputs/bundle/release/app-release.aab
```

### Build IPA (iOS App Store)
```bash
flutter build ipa --release
```

### Build Web
```bash
flutter build web --release
# Folder: build/web/
```

---

## 🎓 Học Tập Tiếp Theo

Sau khi chạy được app:

1. **Chỉnh sửa UI**
   - Đổi màu sắc
   - Thêm widget mới
   - Thay đổi layouts

2. **Thêm Tính Năng**
   - Notifications
   - Video streaming
   - Advanced search

3. **Tối Ưu Hóa**
   - Performance
   - Database queries
   - Image caching

4. **Deploy**
   - Google Play Store
   - Apple App Store
   - Firebase Hosting (Web)

---

## 📞 Cần Giúp Đỡ?

1. ✅ Kiểm tra DETAILED_GUIDE.md (2000+ dòng)
2. ✅ Xem phần Troubleshooting
3. ✅ Kiểm tra Firebase Console logs
4. ✅ Chạy `flutter doctor` để kiểm tra setup
5. ✅ Tìm lỗi trên Google/Stack Overflow

---

## ⭐ Pro Tips

1. **Hot Reload** - Bấm 'r' để reload code (nhanh)
2. **Hot Restart** - Bấm 'R' để restart app
3. **Flutter Logs** - Terminal hiển thị chi tiết lỗi
4. **Device Logs** - Xem logs từ emulator/điện thoại
5. **Breakpoints** - Dùng IDE để debug

---

## ✅ Checklist Trước Khi Submit

- [ ] Tất cả tính năng hoạt động
- [ ] Không có lỗi trong console
- [ ] Firebase cấu hình đúng
- [ ] AI API key được thêm
- [ ] Tested trên ít nhất 1 device
- [ ] Build release thành công
- [ ] Tài liệu được cập nhật

---

**Chúc Bạn Thành Công! 🎉**

Nếu gặp vấn đề, đọc DETAILED_GUIDE.md hoặc kiểm tra phần Troubleshooting.

---

*Last Updated: 2024-12-12*  
*Version: 1.0.0*
