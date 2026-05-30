# Đẩy đồ án lên GitHub (link CV)

Repo hiện đang trỏ **GitLab**: `https://gitlab.com/manhskillgood/do-an-tn`

Bạn có thể **thêm GitHub** (giữ GitLab) hoặc chỉ dùng GitHub.

---

## Bước 0 — Bảo mật (bắt buộc trước khi public)

1. **Google AI (Gemini):** Nếu từng dán `GEN_AI_KEY` vào chat/terminal/log → vào [Google AI Studio](https://aistudio.google.com/apikey) **tạo key mới**, xóa key cũ.
2. **Firebase:** File `lib/firebase_options.dart` có API key thật — **không** đưa lên GitHub public.
   - Trong project: copy `lib/firebase_options.example.dart` → `lib/firebase_options.dart` (file thật chỉ giữ trên máy).
   - Trên Firebase Console → giới hạn API key (HTTP referrer / app restriction) nếu vẫn dùng key cũ đã lộ.
3. Chạy lệnh (một lần) để Git ngừng theo dõi file nhạy cảm:

```powershell
cd C:\Users\Manh\DO_AN_TN
git rm --cached lib/firebase_options.dart
git commit -m "chore: stop tracking firebase_options (secrets)"
```

File vẫn nằm trên máy bạn; chỉ không lên GitHub nữa.

---

## Bước 1 — Tạo repo trên GitHub

1. Đăng nhập https://github.com
2. **New repository**
   - Name: `do-an-tn` hoặc `ai-tuyen-sinh-tu-van-nganh` (tên CV-friendly)
   - **Public** (để ghi link CV)
   - **Không** tick "Add README" (repo local đã có code)
3. Copy URL, ví dụ: `https://github.com/TEN_GITHUB/do-an-tn.git`

---

## Bước 2 — Thêm remote GitHub & push

Trong PowerShell / Terminal tại thư mục project:

```powershell
cd C:\Users\Manh\DO_AN_TN

# Thêm remote GitHub (giữ origin GitLab)
git remote add github https://github.com/TEN_GITHUB/ten-repo.git

# Commit thay đổi chưa push (nếu có)
git add .
git commit -m "docs: slide thuyết trình + hướng dẫn GitHub"

# Đẩy nhánh main lên GitHub
git push -u github main
```

Nếu GitHub hỏi đăng nhập:
- Dùng **Personal Access Token** (Settings → Developer settings → Tokens) thay mật khẩu, hoặc
- Cài [GitHub Desktop](https://desktop.github.com/) / đăng nhập Git Credential Manager.

---

## Bước 3 — Link ghi vào CV

Sau khi push xong, dùng:

```
https://github.com/TEN_GITHUB/ten-repo
```

**Ví dụ dòng CV (tiếng Việt):**

> Đồ án tốt nghiệp — Ứng dụng AI hỗ trợ tuyển sinh & tư vấn ngành (Flutter, Firebase, Rule-based AI, Gemini)  
> GitHub: https://github.com/TEN_GITHUB/ten-repo

**Ví dụ (tiếng Anh):**

> Graduation Project — AI-powered university admission & major counseling app (Flutter, Firebase, Explainable Rule-based AI)  
> Source: https://github.com/TEN_GITHUB/ten-repo

---

## Tùy chọn — Chỉ dùng GitHub (bỏ GitLab làm mặc định)

```powershell
git remote rename origin gitlab
git remote add origin https://github.com/TEN_GITHUB/ten-repo.git
git push -u origin main
```

---

## Làm README đẹp cho người xem CV

- Đã có `README.md` — nên có: mô tả 2–3 dòng, stack công nghệ, ảnh demo (screenshot trong `docs/`), hướng dẫn clone + `flutter pub get` + cấu hình Firebase local.
- Thêm topic trên GitHub: `flutter`, `firebase`, `artificial-intelligence`, `education`

---

## Checklist

- [ ] Đã xóa/rotate API key Gemini nếu từng lộ
- [ ] `firebase_options.dart` không còn trong git (`git ls-files lib/firebase_options.dart` → trống)
- [ ] Push thành công lên GitHub
- [ ] Mở link repo bằng trình duyệt ẩn danh — thấy README, không thấy key
