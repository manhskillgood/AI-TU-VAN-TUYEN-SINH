# Ứng dụng AI hỗ trợ tuyển sinh & tư vấn ngành học

**Graduation project** — Mobile app giúp học sinh THPT nhập hồ sơ (điểm, khối thi, sở thích) và nhận **gợi ý ngành đại học** kèm **lý do giải thích** (Explainable AI).

| | |
|---|---|
| **Stack** | Flutter · Firebase · Rule-based AI (`GuidanceService`) · FastAPI/SBERT · Gemini |
| **Tác giả** | Lê Đức Mạnh |

> Sau khi push GitHub, ghi link repo vào CV, ví dụ: `https://github.com/<username>/do-an-tn`

## Clone & chạy nhanh

```bash
git clone <repo-url>
cd DO_AN_TN
flutter pub get
```

**Firebase (bắt buộc):** copy `lib/firebase_options.example.dart` → `lib/firebase_options.dart` và điền config, hoặc chạy `flutterfire configure`. File `firebase_options.dart` **không** commit lên public repo.

**Gemini (tùy chọn):**

```bash
flutter run --dart-define=GEN_AI_KEY=<your-google-ai-key>
```

---

Ứng dụng Flutter/Dart xây dựng các chức năng hỗ trợ tuyển sinh và tư vấn ngành học cho học sinh, sử dụng công nghệ AI.

## Các tính năng chính

### 1. **Đăng nhập & đăng ký (Authentication)**

### 2. **Biểu đồ xu hướng ngành học (Charts & Analytics)**

### 3. **Chat bot AI (AI Assistant)**

### 4. **Diễn đàn cộng đồng (Community Forum)**

### 5. **Định hướng cá nhân (Career Guidance)**
Quy trình 5 bước:

**Kết quả đưa ra:**

### 6. **Hồ sơ & cài đặt (Profile & Settings)**

## Service account & CI secrets

For operations that require Firebase Admin privileges (e.g., setting `admin` custom claims
or uploading guidance rules from the admin UI), the app-side helpers rely on a service
account. You can provide credentials locally using the `GOOGLE_APPLICATION_CREDENTIALS`
environment variable or via CI secrets. Example files and snippets below.

- Local developer (quick): create a `scripts/serviceAccountKey.json` file from the Firebase
  Console and point the env var to it, or copy `.env.example` to `.env` and update the path.

Example `.env.example` (already added at repository root): [.env.example](.env.example)

- GitHub Actions (recommended pattern): store the service account JSON in a repository secret
  called `SERVICE_ACCOUNT_JSON` (base64 or raw JSON) and write it to a file at runtime:

```yaml
name: Admin tasks
on: workflow_dispatch
jobs:
  set-claims:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Restore service account
        run: |
          echo "$SERVICE_ACCOUNT_JSON" > ./scripts/serviceAccountKey.json
        env:
          SERVICE_ACCOUNT_JSON: ${{ secrets.SERVICE_ACCOUNT_JSON }}
      - name: Install and run admin helper
        run: |
          npm ci
          node scripts/set_admin_claims.js --uid ${{ inputs.uid }} --admin true
```

- GitLab CI example (store `SERVICE_ACCOUNT_JSON` in CI/CD variables):

```yaml
set_admin:
  image: node:18
  script:
    - echo "$SERVICE_ACCOUNT_JSON" > ./scripts/serviceAccountKey.json
    - npm ci
    - node scripts/set_admin_claims.js --uid "$UID" --admin true
  variables:
    SERVICE_ACCOUNT_JSON: "$SERVICE_ACCOUNT_JSON"
  only:
    - schedules
```

Notes:
- Never commit service account JSON to the repository. Use project/organization secret stores instead.
- After changing custom claims, affected users must refresh their ID token (sign out/sign in) to pick up new claims.
- The repo contains `scripts/set_admin_claims.js` and `scripts/README_ADMIN_CLAIMS.md` with usage notes.

## Công Nghệ & Framework
- **Real-time Chat:** Firebase Cloud Messaging

## Cài đặt & chạy ứng dụng

### Yêu Cầu
- Flutter SDK 3.0 trở lên
- Dart SDK tương ứng
- Android Studio hoặc Xcode
- Firebase Project

### Bước 1: Clone hoặc Tải Project
```bash
# Nếu đã tải file, vào thư mục project
cd education_guidance_app
```

### Bước 2: Cài Đặt Dependencies
```bash
flutter pub get
```

### Bước 3: Cấu Hình Firebase
1. Tạo Firebase Project tại https://firebase.google.com/
2. Tạo ứng dụng Android/iOS
3. Download `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS)
4. Copy vào thư mục tương ứng:
   - Android: `android/app/`
   - iOS: `ios/Runner/`

### Bước 4: Cấu Hình Firebase Options
Sửa file `lib/firebase_options.dart`:
```dart
static FirebaseOptions get currentPlatform {
  return FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'your-project.firebaseapp.com',
    databaseURL: 'https://your-project.firebaseio.com',
    storageBucket: 'your-project.appspot.com',
  );
}
```

### Bước 5: Cấu Hình Google Generative AI
1. Lấy API key từ https://ai.google.dev/
2. Thêm vào `lib/services/ai_service.dart`:
```dart
final apiKey = 'YOUR_GOOGLE_GENERATIVE_AI_KEY';
```

### Bước 6: Chạy Ứng Dụng

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

**Web:**
```bash
flutter run -d chrome
```

## Cấu Trúc Project

```
lib/
├── main.dart                    # File chính
├── firebase_options.dart        # Cấu hình Firebase
│
├── models/                      # Data models
│   ├── user.dart
│   ├── career_guidance.dart
│   ├── chat_message.dart
│   ├── forum.dart
│   └── major_trend.dart
│
├── services/                    # API & Backend services
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── ai_service.dart
│   ├── chat_service.dart
│   ├── forum_service.dart
│   ├── career_guidance_service.dart
│   └── trend_service.dart
│
├── providers/                   # State management (Provider)
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   └── career_guidance_provider.dart
│
├── screens/                     # UI Screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── charts/
│   │   └── charts_screen.dart
│   ├── chatbot/
│   │   └── chatbot_screen.dart
│   ├── forum/
│   │   └── forum_screen.dart
│   ├── career_guidance/
│   │   └── career_guidance_screen.dart
│   └── profile/
│       └── profile_screen.dart
│
├── widgets/                     # Reusable widgets
│   └── common_widgets.dart
│
├── constants/                   # App constants & theme
│   ├── app_constants.dart
│   └── app_theme.dart
│
├── utils/                       # Utilities & helpers
│   └── [future utilities]
│
└── assets/                      # Images & resources
    ├── images/
    ├── icons/
    └── fonts/
```

## Tính Năng Nâng Cao (Future Features)

- [ ] Tích hợp video tutorial
- [ ] Phân tích chi tiết các ngành học
- [ ] Review từ sinh viên và nhà tuyển dụng
- [ ] Lịch sử tương tác với AI
- [ ] Backup hồ sơ
- [ ] Chia sẻ kết quả định hướng
- [ ] Cuộc thi và thử thách
- [ ] Thống kê tiến bộ cá nhân

## Support & Documentation

- Flutter Documentation: https://flutter.dev/docs
- Firebase Documentation: https://firebase.google.com/docs
- Google Generative AI: https://ai.google.dev/
- Provider Package: https://pub.dev/packages/provider

## Liên Hệ & Hỗ Trợ
Gmail: Leducmanh19102004@gmail.com

---

**Phiên bản:** 1.0.0  
**Cập nhật lần cuối:** Tháng 12, 2024
