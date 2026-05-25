# Hướng dẫn chi tiết - Ứng dụng AI hỗ trợ tuyển sinh và tư vấn ngành học

## 📋 Mục lục
1. [Giới Thiệu](#giới-thiệu)
2. [Cài Đặt Môi Trường](#cài-đặt-môi-trường)
3. [Chạy Ứng Dụng](#chạy-ứng-dụng)
4. [Cấu Trúc Project](#cấu-trúc-project)
5. [Hướng Dẫn Sử Dụng](#hướng-dẫn-sử-dụng)
6. [Tích Hợp Firebase](#tích-hợp-firebase)
7. [Tích Hợp AI](#tích-hợp-ai)

---

## 🎯 Giới thiệu

**Tên đồ án:** Ứng dụng AI trong việc hỗ trợ tuyển sinh và tư vấn ngành học

**Mục tiêu:**
- Giúp học sinh tìm ra ngành học phù hợp dựa trên điểm số, sở thích và ưu điểm
- Cung cấp thông tin chi tiết về xu hướng ngành học hiện nay
- Tạo cộng đồng học sinh có thể trao đổi kinh nghiệm và kiến thức
- Hỗ trợ bằng chatbot AI thông minh

**Công Nghệ Sử Dụng:**
- Flutter & Dart (Frontend)
- Firebase (Backend)
- Google Generative AI - Gemini (AI Assistant)
- Cloud Firestore (Database)
- Firebase Authentication (Auth)

---

## 💻 Cài Đặt Môi Trường

### Yêu Cầu Hệ Thống
- Windows 10/11, macOS, hoặc Linux
- 2GB RAM tối thiểu
- 2GB disk space
- Git (tùy chọn)

### Bước 1: Cài Đặt Flutter
1. Tải Flutter SDK từ https://flutter.dev/docs/get-started/install
2. Giải nén vào thư mục `C:\src\flutter` (Windows)
3. Thêm vào PATH:
   ```
   C:\src\flutter\bin
   ```
4. Xác minh cài đặt:
   ```bash
   flutter --version
   flutter doctor
   ```

### Bước 2: Cài Đặt Android Studio (cho Android development)
1. Tải từ https://developer.android.com/studio
2. Cài đặt Android SDK
3. Cài đặt Android Emulator hoặc kết nối điện thoại

### Bước 3: Cài Đặt Xcode (cho iOS development - macOS only)
```bash
xcode-select --install
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Bước 4: Clone hoặc Tải Project
```bash
# Nếu dùng Git
git clone <repository-url>
cd education_guidance_app

# Hoặc download file ZIP và giải nén
cd education_guidance_app
```

### Bước 5: Cài Đặt Dependencies
```bash
flutter pub get
```

---

## 🚀 Chạy Ứng Dụng

### Chạy trên Android
```bash
# Kiểm tra thiết bị kết nối
flutter devices

# Chạy app
flutter run

# Hoặc chạy release build
flutter run --release
```

### Chạy trên iOS (macOS)
```bash
cd ios
pod install
cd ..
flutter run

# Hoặc
flutter run -d iPhone
```

### Chạy trên Web
```bash
flutter run -d chrome

# Build cho web
flutter build web
```

### Chạy trên Emulator
```bash
# Android
flutter emulators
flutter emulators launch android_emulator
flutter run

# iOS (macOS)
xcrun simctl list devices
flutter run -d "iPhone 13"
```

---

## 📁 Cấu Trúc Project

```
education_guidance_app/
│
├── android/                  # Native Android code
├── ios/                      # Native iOS code
├── web/                      # Web build
│
├── lib/                      # Dart code chính
│   ├── main.dart            # Entry point
│   ├── firebase_options.dart # Firebase config
│   │
│   ├── models/              # Data models
│   │   ├── user.dart
│   │   ├── career_guidance.dart
│   │   ├── chat_message.dart
│   │   ├── forum.dart
│   │   └── major_trend.dart
│   │
│   ├── services/            # API & Business logic
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── ai_service.dart
│   │   ├── chat_service.dart
│   │   ├── forum_service.dart
│   │   ├── career_guidance_service.dart
│   │   └── trend_service.dart
│   │
│   ├── providers/           # State management
│   │   ├── auth_provider.dart
│   │   ├── chat_provider.dart
│   │   └── career_guidance_provider.dart
│   │
│   ├── screens/             # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── charts/
│   │   │   └── charts_screen.dart
│   │   ├── chatbot/
│   │   │   └── chatbot_screen.dart
│   │   ├── forum/
│   │   │   └── forum_screen.dart
│   │   ├── career_guidance/
│   │   │   └── career_guidance_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   │
│   ├── widgets/             # Reusable components
│   │   └── common_widgets.dart
│   │
│   ├── constants/           # App constants
│   │   ├── app_constants.dart
│   │   └── app_theme.dart
│   │
│   ├── utils/               # Helper functions
│   │   ├── helpers.dart
│   │   └── routes.dart
│   │
│   └── assets/              # Resources
│       ├── images/
│       ├── icons/
│       ├── fonts/
│       └── animations/
│
├── pubspec.yaml             # Dependencies configuration
├── pubspec.lock             # Lock file
├── README.md                # Project description
├── SETUP_GUIDE.md          # Setup instructions
├── DETAILED_GUIDE.md       # Chi tiết hướng dẫn này
├── app_config.txt          # App configuration
└── .gitignore              # Git ignore rules

```

---

## 📖 Hướng Dẫn Sử Dụng

### 1️⃣ Đăng Ký & Đăng Nhập

**Đăng Ký:**
1. Tap "Đăng Ký" trên màn hình đăng nhập
2. Nhập thông tin cá nhân:
   - Họ và tên
   - Email
   - Mật khẩu (tối thiểu 6 ký tự)
   - Xác nhận mật khẩu
   - Số điện thoại
   - Ngày sinh
   - Khu vực
3. Tap "Đăng Ký"

**Đăng Nhập:**
1. Nhập email
2. Nhập mật khẩu
3. Tap "Đăng Nhập"

---

### 2️⃣ Xem Biểu Đồ Xu Hướng

1. Tap tab "Biểu Đồ" ở bottom navigation
2. Xem danh sách các ngành có nhu cầu cao
3. Thấy % nhu cầu của mỗi ngành bằng progress bar

---

### 3️⃣ Chat với AI Bot

1. Tap tab "Chat Bot" ở bottom navigation
2. Gõ câu hỏi về ngành học
3. Nhận phản hồi từ AI
4. Tiếp tục hỏi thêm

**Ví dụ câu hỏi:**
- "Ngành Công Nghệ Thông Tin học những gì?"
- "Tôi thích code, nên học ngành nào?"
- "Mức lương sau khi tốt nghiệp là bao nhiêu?"

---

### 4️⃣ Tham Gia Diễn Đàn

1. Tap tab "Diễn Đàn"
2. Xem danh sách bài đăng từ các thành viên khác
3. Tap bài đăng để xem chi tiết và bình luận
4. Tap ❤️ để like bài đăng

**Tạo bài đăng mới:**
1. Tap nút ➕ (floating action button)
2. Nhập tiêu đề
3. Nhập nội dung
4. Tap "Đăng"

---

### 5️⃣ Định hướng Ngành Học (Core Feature)

**Quy trình 5 bước:**

**Bước 1: Nhập Điểm Số**
- Điểm Toán (0-10)
- Điểm Văn (0-10)
- Điểm Tiếng Anh (0-10)
- Tap "Tiếp Tục"

**Bước 2: Chọn Sở Thích**
- Chọn 1-3 sở thích:
  - Công Nghệ
  - Nghệ Thuật
  - Y Tế
  - Giáo Dục
  - Kinh Tế
  - Môi Trường
- Tap "Tiếp Tục"

**Bước 3: Chọn Ưu Điểm**
- Chọn 2-3 ưu điểm:
  - Tư Duy Logic
  - Sáng Tạo
  - Giao Tiếp
  - Lãnh Đạo
  - Phân Tích
  - Giải Quyết Vấn Đề
- Tap "Tiếp Tục"

**Bước 4: Chọn Khu Vực**
- Miền Bắc
- Miền Trung
- Miền Nam
- Tây Nguyên
- Tap "Tiếp Tục"

**Bước 5: Xem Kết Quả**
- Danh sách Top 3 ngành phù hợp
- Mức độ phù hợp (%) cho mỗi ngành
- Các trường đại học được gợi ý
- Lời khuyên chi tiết

---

### 6️⃣ Quản Lý Hồ Sơ

1. Tap tab "Hồ Sơ"
2. Xem thông tin cá nhân
3. Tap ✏️ để chỉnh sửa:
   - Số điện thoại
   - Khu vực
   - Ảnh đại diện (chạm vào ảnh)
4. Tap ✓ để lưu
5. Xem các cài đặt:
   - Thông Báo
   - Quyền Riêng Tư
   - Trợ Giúp
   - Về Ứng Dụng
6. Tap "Đăng Xuất" để đăng xuất

---

## 🔥 Tích Hợp Firebase

### Bước 1: Tạo Firebase Project

1. Truy cập https://firebase.google.com/
2. Tap "Go to console"
3. Tap "Tạo dự án" (Create Project)
4. Nhập tên: "education-guidance-app"
5. Tiếp tục và hoàn thành

### Bước 2: Tạo Ứng Dụng Android/iOS

**Android:**
1. Tap nút Android
2. Nhập package name: `com.example.education_guidance_app`
3. Nhập tên app: "Tư Vấn Ngành Học"
4. Download `google-services.json`
5. Copy vào `android/app/`

**iOS:**
1. Tap nút iOS
2. Nhập Bundle ID: `com.example.educationGuidanceApp`
3. Download `GoogleService-Info.plist`
4. Copy vào `ios/Runner/` bằng Xcode

### Bước 3: Cấu Hình Firebase Options

Sửa `lib/firebase_options.dart`:
```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: 'YOUR_API_KEY_FROM_FIREBASE',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'education-guidance-app',
      authDomain: 'education-guidance-app.firebaseapp.com',
      databaseURL: 'https://education-guidance-app.firebaseio.com',
      storageBucket: 'education-guidance-app.appspot.com',
    );
  }
}
```

### Bước 4: Tạo Collections trong Firestore

1. Vào Firebase Console → Firestore
2. Tạo collections:
   - `users` - lưu thông tin người dùng
   - `forum_posts` - bài đăng diễn đàn
   - `chat_rooms` - phòng chat
   - `career_guidance` - kết quả định hướng
   - `major_trends` - xu hướng ngành

### Bước 5: Thiết Lập Authentication

1. Vào Firebase Console → Authentication
2. Tap "Bắt đầu"
3. Kích hoạt "Email/Password"

### Bước 6: Thiết Lập Storage

1. Vào Firebase Console → Storage
2. Tap "Bắt đầu"
3. Dùng quy tắc mặc định

---

## 🤖 Tích Hợp Google Generative AI

### Bước 1: Lấy API Key

1. Truy cập https://ai.google.dev/
2. Tap "Get API key"
3. Copy API key

### Bước 2: Cập Nhật AI Service

Sửa `lib/services/ai_service.dart`:
```dart
class AIService {
  late GenerativeModel _model;
  
  AIService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey, // Paste API key ở đây
    );
  }
  // ...
}
```

### Bước 3: Sử Dụng AI Service

```dart
final aiService = AIService(apiKey: 'YOUR_API_KEY');

// Chat
final response = await aiService.sendMessage(message: 'Hỏi gì đó');

// Career guidance
final guidance = await aiService.getCareerGuidance(
  mathScore: 8.5,
  literatureScore: 7.5,
  englishScore: 8.0,
  interests: ['Công Nghệ'],
  strengths: ['Tư Duy Logic'],
  region: 'Miền Bắc',
);
```

---

## 🔧 Các Lệnh Hữu Ích

```bash
# Kiểm tra phiên bản
flutter --version

# Kiểm tra thiết bị
flutter devices

# Chạy app
flutter run

# Chạy release
flutter run --release

# Build APK (Android)
flutter build apk

# Build app bundle (Android)
flutter build appbundle

# Build IPA (iOS)
flutter build ipa

# Build Web
flutter build web

# Clean
flutter clean

# Cập nhật dependencies
flutter pub upgrade

# Phân tích code
flutter analyze

# Test
flutter test
```

---

## 📱 Debugging

### VS Code / Android Studio Debug
```bash
flutter run
# Sau đó bạn có thể dùng:
# - r: reload
# - R: restart
# - q: quit
# - p: show performance overlay
```

### Xem Logs
```bash
flutter logs
```

### Hot Reload Disable
```bash
flutter run --no-fast-start
```

---

## 🎨 Tùy Chỉnh Giao Diện

### Thay Đổi Màu Chính
Sửa `lib/constants/app_constants.dart`:
```dart
static const Color primary = Color(0xFF6C63FF); // Đổi màu ở đây
```

### Thêm Font Custom
1. Copy font file vào `assets/fonts/`
2. Cập nhật `pubspec.yaml`:
```yaml
fonts:
  - family: MyFont
    fonts:
      - asset: assets/fonts/MyFont.ttf
```
3. Sử dụng:
```dart
Text('Hello', style: TextStyle(fontFamily: 'MyFont'))
```

---

## 🚨 Xử Lý Lỗi Phổ Biến

### Lỗi: "Error: No named argument 'enableNullSafety'."
**Giải pháp:** Update Flutter
```bash
flutter upgrade
```

### Lỗi: "android/app/google-services.json not found"
**Giải pháp:** Download lại từ Firebase Console

### Lỗi: "Firestore permission denied"
**Giải pháp:** Cập nhật Firestore rules (xem phần Tích Hợp Firebase)

### Lỗi: "AI API key invalid"
**Giải pháp:** Kiểm tra lại API key từ ai.google.dev

---

## 📚 Tài Liệu Thêm

- Flutter Docs: https://flutter.dev/docs
- Firebase Docs: https://firebase.google.com/docs
- Google Generative AI: https://ai.google.dev/
- Dart Language: https://dart.dev/

---

## ✅ Checklist Trước Khi Deploy

- [ ] Cấu hình Firebase hoàn tất
- [ ] API key AI được thêm
- [ ] Icons & splash screen được tùy chỉnh
- [ ] Tất cả lỗi đã được fix
- [ ] Testing hoàn tất
- [ ] Version được cập nhật
- [ ] Build APK/IPA thành công

---

## 📞 Liên Hệ & Hỗ Trợ

Nếu có vấn đề, vui lòng:
1. Kiểm tra lại hướng dẫn
2. Xem phần Debugging
3. Kiểm tra logs
4. Tìm giải pháp online

**Chúc bạn thành công với ứng dụng! 🎉**
