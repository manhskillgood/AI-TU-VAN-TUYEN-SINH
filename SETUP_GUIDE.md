# Hướng Dẫn Thêm Dependencies

Nếu khi chạy ứng dụng gặp lỗi thiếu packages, vui lòng chạy:

```bash
flutter pub get
```

## Danh Sách Dependencies Chính

1. **provider** - State management
2. **firebase_core** - Firebase core
3. **firebase_auth** - Firebase authentication
4. **cloud_firestore** - Firebase database
5. **firebase_storage** - File storage
6. **google_generative_ai** - AI API
7. **http** & **dio** - HTTP requests
8. **image_picker** - Chọn ảnh
9. **cached_network_image** - Cache ảnh
10. **fl_chart** - Biểu đồ
11. **lottie** - Animations
12. **uuid** - Generate unique IDs
13. **intl** - Localization
14. **google_fonts** - Google fonts

## Cấu Hình Firebase Rules

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid != null;
      allow create, update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }

    // Forum posts
    match /forum_posts/{postId} {
      allow read: if request.auth.uid != null;
      allow create: if request.auth.uid != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
      
      // Replies
      match /replies/{replyId} {
        allow read: if request.auth.uid != null;
        allow create: if request.auth.uid != null;
        allow delete: if request.auth.uid == resource.data.userId;
      }
    }

    // Chat messages
    match /chat_rooms/{roomId} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.uid != null;
      
      match /messages/{messageId} {
        allow read: if request.auth.uid != null;
        allow create, update, delete: if request.auth.uid == request.resource.data.senderId;
      }
      
      match /active_users/{userId} {
        allow read: if request.auth.uid != null;
        allow write: if request.auth.uid == userId;
      }
    }

    // Career guidance
    match /career_guidance/{guidanceId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid != null;
    }

    // Trends
    match /major_trends/{trendId} {
      allow read: if request.auth.uid != null;
    }
  }
}
```

### Firebase Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## Biến Môi Trường

Tạo file `.env` (không commit vào git):

```
GOOGLE_GENERATIVE_AI_KEY=your_key_here
FIREBASE_API_KEY=your_key_here
```

## Troubleshooting

### Lỗi "firebase_core" not found
```bash
flutter pub get
flutter pub upgrade firebase_core
```

### Lỗi Android build
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Lỗi iOS build
```bash
cd ios
rm -rf Pods
rm Podfile.lock
cd ..
flutter clean
flutter pub get
flutter run
```

### Lỗi Hot Reload
```bash
flutter run --no-fast-start
```
