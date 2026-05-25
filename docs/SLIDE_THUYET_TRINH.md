# NỘI DUNG 15 SLIDE THUYẾT TRÌNH ĐỒ ÁN TỐT NGHIỆP

> **Đề tài:** Ứng dụng AI trong hệ thống hỗ trợ tuyển sinh và tư vấn ngành học
>
> Tạo PowerPoint từ nội dung bên dưới. Mỗi mục `## Slide X` = 1 slide.
> Hình minh họa: chụp từ app + sơ đồ trong `docs/thesis_diagrams/`.

---

## Slide 1 — Trang bìa

```
ĐỒ ÁN TỐT NGHIỆP

ỨNG DỤNG AI TRONG HỆ THỐNG
HỖ TRỢ TUYỂN SINH VÀ TƯ VẤN NGÀNH HỌC

Sinh viên: Hà Quỳnh Trang
GVHD: [Tên giảng viên]
Năm: 2026
```

---

## Slide 2 — Đặt vấn đề (WHY)

**Thực trạng:**
- 70% học sinh THPT chọn ngành theo cảm tính hoặc theo gia đình
- Tỷ lệ chuyển ngành / bỏ học năm nhất cao → lãng phí xã hội
- Công tác tư vấn hiện tại: thủ công (hội thảo, tờ rơi), thiếu cá nhân hóa

**Cơ hội:**
- AI có thể phân tích năng lực + sở thích → gợi ý có cơ sở
- Xu hướng Explainable AI: giải thích được lý do gợi ý (khác mô hình "hộp đen")

> *Ghi chú cho thuyết trình:* Đây là slide quan trọng nhất — hội đồng muốn biết "tại sao cần làm đề tài này". Nói thêm: "Em không nhằm thay thế con người, mà hỗ trợ ra quyết định có dữ liệu."

---

## Slide 3 — Mục tiêu đề tài

| # | Mục tiêu | Kết quả |
|---|----------|---------|
| 1 | Xây dựng CSDL tuyển sinh (ngành, trường, điểm chuẩn) | `majors_catalog.json`, `major_universities.json`, Firestore |
| 2 | Xây dựng AI Engine dựa trên tập luật (Rule-based) | `GuidanceService` — 14+ quy tắc, tính điểm phù hợp |
| 3 | Thiết kế cơ chế Explainable AI | Hiển thị lý do gợi ý cho từng ngành |
| 4 | Phát triển ứng dụng Flutter (Mobile) | App Android chạy thực tế |
| 5 | Đồng bộ dữ liệu cloud | Firebase Firestore + Authentication |
| 6 | Chatbot tư vấn tích hợp LLM | Google Generative AI (Gemini) |

---

## Slide 4 — Phạm vi & Đối tượng

**Phạm vi:**
- Gợi ý ngành học đại học (không thay thế quyết định con người)
- Dữ liệu: ngành/trường khu vực Việt Nam (mô phỏng + thực)
- Quy mô demo đồ án tốt nghiệp

**Đối tượng:**
- Người dùng chính: Học sinh THPT, sinh viên năm nhất
- Quản trị viên: Cán bộ tuyển sinh / giáo viên hướng nghiệp

**Phương pháp:**
- Lý thuyết: Hệ chuyên gia, Rule-based AI, Explainable AI, LLM
- Thực nghiệm: Xây dựng tập luật → kiểm thử hồ sơ giả lập → đánh giá

---

## Slide 5 — Kiến trúc hệ thống (QUAN TRỌNG — hội đồng hay hỏi)

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│         Flutter (Dart)                  │
│   Wizard · Kết quả · Chat · Admin · …  │
├─────────────────────────────────────────┤
│       Application Logic Layer           │
│  GuidanceService (Rule-based AI Engine) │
│  SBERT/FastAPI (ML — tùy chọn)         │
│  Gemini API (Chatbot)                   │
├─────────────────────────────────────────┤
│        Local Data Layer                 │
│  SQLite · SharedPreferences             │
│  guidance_rules.json (offline)          │
├─────────────────────────────────────────┤
│         Cloud Data Layer                │
│  Firebase Firestore (users, majors,     │
│  admissions, guidance_rules, career_    │
│  guidance, forum_posts)                 │
│  Firebase Authentication                │
└─────────────────────────────────────────┘
```

> Dùng hình `Hinh_2_3_Kien_truc.drawio` xuất PNG chèn vào slide.

**Điểm nhấn khi trình bày:**
- Client–Cloud Architecture: không cần backend server riêng
- Offline-first: quy tắc lưu local, không cần internet để gợi ý
- Phân quyền: admin whitelist bằng email trong Firestore Rules

---

## Slide 6 — AI Engine: Cách hoạt động (SLIDE THEN CHỐT — hội đồng CHẮC CHẮN hỏi)

**Quy trình 5 bước:**

```
Hồ sơ học sinh → Chuẩn hóa điểm (0–1) → Tính base score theo nhóm ngành
     → Áp dụng tập luật (rule engine) → Sắp xếp → Top N ngành + giải thích
```

**Chi tiết thuật toán trong `GuidanceService.computeSuitability()`:**

1. **Normalize** điểm 0–10 → 0–1 (math, literature, english)
2. **Base score** theo nhóm ngành — trọng số khác nhau:
   - CNTT: `math×0.6 + english×0.25 + literature×0.15`
   - Kinh tế: `literature×0.45 + english×0.35 + math×0.2`
   - Y tế: `english×0.45 + literature×0.25 + math×0.3`
   - Kỹ thuật: `math×0.55 + literature×0.15 + english×0.3`
3. **Strength boost**: kỹ năng (logic, giao tiếp…) nhân hệ số
4. **Region boost**: ưu tiên nhẹ theo miền (Bắc/Nam)
5. **Rule engine**: duyệt 14+ luật, mỗi luật có `conditions` + `boostMajors` + `confidence`
6. **Normalize** kết quả: top = 100%, còn lại tỷ lệ theo

> *Chuẩn bị câu trả lời:*
> - "Tại sao dùng rule-based mà không dùng ML?" → Explainable AI, giải thích được, dễ kiểm soát trong giáo dục, không cần training data lớn
> - "Có bao nhiêu rule?" → 14+ rule, có thể thêm/xóa từ admin
> - "Độ chính xác bao nhiêu?" → Kiểm thử 19 test case, 100% pass (unit test)

---

## Slide 7 — Cấu trúc 1 Rule (ví dụ cụ thể)

```json
{
  "id": "tech_boost",
  "conditions": {
    "interest": "công nghệ",
    "math_min": 0.7,
    "block": "A01"
  },
  "boostMajors": {
    "Công nghệ thông tin": 1.5,
    "Kỹ thuật phần mềm": 1.4,
    "Khoa học dữ liệu": 1.3
  },
  "confidence": 0.85,
  "reason": "Học sinh có năng lực toán cao + sở thích công nghệ phù hợp nhóm CNTT",
  "enabled": true
}
```

**Giải thích cho hội đồng:**
- `conditions`: khi nào rule được kích hoạt (điểm, sở thích, khối thi)
- `boostMajors`: nhân hệ số vào base score (1.5 = tăng 50%)
- `confidence`: mức tin cậy của rule
- `reason`: **Explainable AI** — lý do hiển thị cho học sinh

---

## Slide 8 — Luồng nhập liệu Wizard (6 bước)

| Bước | Tên | Nội dung nhập |
|------|-----|---------------|
| 1 | Khối thi | Chọn tổ hợp (A01, D01, C00, …) → xác định 3 môn |
| 2 | Điểm số | Nhập điểm TB 0–10 cho 3 môn |
| 3 | Sở thích | Chọn 1–3 (Công nghệ, Y tế, Kinh tế, …) — lọc theo khối |
| 4 | Ưu điểm | Chọn 2–3 kỹ năng (logic, giao tiếp, …) |
| 5 | Khu vực | Miền Bắc / Trung / Nam |
| 6 | Kết quả | Top ngành + trường + giải thích + nút Lưu |

**Tùy chọn:** Nếu tick "Quan tâm Công an/Quân đội" → thêm bước **Thể chất** (chiều cao, cân nặng)

> Dùng hình `Hinh_3_3_Wizard_Nhap_Lieu.drawio` hoặc chụp màn hình app

---

## Slide 9 — Explainable AI: Kết quả gợi ý minh họa

**Ví dụ đầu vào:**
- Khối A01, Toán 8.5, Lý 7.5, Hóa 8.0
- Sở thích: Công nghệ | Ưu điểm: Tư duy logic
- Khu vực: Miền Bắc

**Kết quả AI trả về:**

| Ngành | Điểm phù hợp | Lý do (Explainable) |
|-------|-------------|---------------------|
| Công nghệ thông tin | 100% | Toán cao + sở thích Công nghệ + rule tech_boost (×1.5) |
| Khoa học máy tính | 92% | Toán cao + logic + khối A01 |
| Trí tuệ nhân tạo | 88% | Toán + Công nghệ + rule AI_boost |
| Kỹ thuật phần mềm | 85% | Toán + sở thích + region boost Bắc |
| Khoa học dữ liệu | 80% | Toán + Công nghệ + rule data_boost |

> *Chụp screenshot trang Kết quả trên app để chèn*

**Điểm nhấn:** Mỗi ngành có **lý do giải thích** (reason) — không phải "hộp đen"

---

## Slide 10 — Chatbot AI (Gemini)

**Tích hợp:** Google Generative AI API (Gemini)

**Khả năng:**
- Trả lời câu hỏi tự nhiên về ngành học, trường, học phí
- Giải thích kết quả gợi ý từ wizard
- Tư vấn lộ trình nghề nghiệp

**Ví dụ hội thoại:**
```
Học sinh: "Ngành CNTT học những gì?"
Chatbot:  "Ngành CNTT đào tạo lập trình, hệ thống phần mềm,
           trí tuệ nhân tạo, quản trị mạng. Cơ hội việc làm:
           lập trình viên, kỹ sư phần mềm, chuyên gia dữ liệu…"
```

> *Chụp screenshot màn hình Chatbot*

---

## Slide 11 — Hệ thống Admin (A01–A05)

| Chức năng | Mô tả | Màn hình |
|-----------|-------|----------|
| A01 — Người dùng | Xem, phân quyền admin, xóa tài khoản | AdminUsersScreen |
| A02 — Ngành học | CRUD ngành, nhập từ assets/cloud | AdminMajorsScreen |
| A03 — Trường ĐH | CRUD trường đại học | AdminUniversitiesScreen |
| A04 — Tuyển sinh | CRUD dữ liệu điểm chuẩn | AdminAdmissionsScreen |
| A05 — Thống kê | Dashboard: số rule, user, phiên gợi ý | AdminDashboardScreen |

**Thêm:**
- Quản lý quy tắc AI: thêm/xóa/bật/tắt rule, đồng bộ Firestore ↔ thiết bị
- Kiểm duyệt diễn đàn: xem/xóa bài viết

> *Chụp 1-2 screenshot Admin Dashboard + quản lý quy tắc*

---

## Slide 12 — Công nghệ sử dụng

| Thành phần | Công nghệ | Vai trò |
|------------|-----------|---------|
| Frontend | **Flutter 3.x** (Dart) | UI đa nền tảng |
| Cloud DB | **Firebase Firestore** | NoSQL document database |
| Auth | **Firebase Authentication** | Đăng nhập email/password |
| AI Engine | **GuidanceService** (Rule-based) | Suy luận + Explainable |
| ML (tùy chọn) | **SBERT + FastAPI** | Embedding similarity |
| Chatbot | **Google Gemini API** | Hỏi đáp tự nhiên |
| Local DB | **SQLite + SharedPreferences** | Cache offline |
| Charts | **fl_chart** | Biểu đồ xu hướng |
| Testing | **flutter_test** | 19 unit test |

---

## Slide 13 — Kết quả kiểm thử

| Tiêu chí | Kết quả |
|----------|---------|
| Unit test | **19/19 passed** (guidance, merge, region, widget) |
| Thời gian phản hồi AI | < 2 giây (local rule engine) |
| Giao diện | Hỗ trợ Light + Dark mode |
| Bảo mật | Firestore Rules + Admin email whitelist |
| Chạy thực tế | Android emulator + thiết bị thật |

**Bảng đánh giá nhanh:**

| Hồ sơ đầu vào | Ngành gợi ý | Phù hợp? |
|----------------|-------------|----------|
| Toán 8.5, Anh 7, sở thích lập trình | Công nghệ thông tin (100%) | ✅ Chính xác |
| Toán 7, Văn 8, sở thích kinh doanh | Quản trị kinh doanh (82%) | ✅ Chính xác |
| Khối C00, Văn 9, sở thích giáo dục | Sư phạm Văn (95%) | ✅ Chính xác |

---

## Slide 14 — Ưu / Nhược điểm & Hướng phát triển

**Ưu điểm:**
- ✅ Explainable AI: giải thích lý do gợi ý (khác hộp đen)
- ✅ Offline-first: chạy không cần internet (rule local)
- ✅ Mã nguồn Flutter 1 codebase → Android + iOS + Web
- ✅ Admin quản trị rule linh hoạt, đồng bộ cloud
- ✅ 19 test case pass 100%

**Nhược điểm:**
- ⚠️ Phụ thuộc chất lượng dữ liệu (điểm chuẩn cần cập nhật hàng năm)
- ⚠️ Chưa mô phỏng yếu tố tâm lý, hoàn cảnh cá nhân
- ⚠️ Quy mô demo, chưa triển khai production

**Hướng phát triển:**
- 🔄 Kết hợp ML (SBERT đã sẵn sàng) để nâng cao gợi ý
- 🔄 Tích hợp API Bộ GD&ĐT cập nhật điểm chuẩn tự động
- 🔄 Đưa lên Google Play / App Store
- 🔄 Mở rộng: tư vấn nghề nghiệp, dự đoán tỷ lệ đỗ

---

## Slide 15 — Kết luận & Q&A

**Tóm tắt:**
- Đã xây dựng hệ thống **AI Rule-based + Explainable** hỗ trợ tư vấn ngành học
- Ứng dụng Flutter chạy thực tế trên Android
- 6 chức năng người dùng (F01–F06) + 5 chức năng admin (A01–A05)
- 14+ quy tắc AI, 19 test case, chatbot Gemini tích hợp

**Đóng góp:**
- Mô hình AI giải thích được — minh bạch trong giáo dục
- Kiến trúc Client–Cloud linh hoạt, dễ mở rộng
- Nền tảng có thể phát triển thành công cụ tư vấn hướng nghiệp thực tế

```
CẢM ƠN HỘI ĐỒNG ĐÃ LẮNG NGHE
Em sẵn sàng trả lời câu hỏi.
```

---

---

# PHỤ LỤC: CÂU HỎI HỘI ĐỒNG THƯỜNG HỎI & GỢI Ý TRẢ LỜI

## 1. "Tại sao dùng Rule-based mà không dùng Machine Learning?"

> "Dạ thưa thầy/cô, em chọn Rule-based vì 3 lý do:
> 1. **Explainable AI**: trong giáo dục, học sinh và phụ huynh cần hiểu TẠI SAO được gợi ý ngành đó — rule-based giải thích được từng bước, ML thì là hộp đen.
> 2. **Không cần training data lớn**: hệ thống tuyển sinh VN chưa có bộ dữ liệu huấn luyện đủ lớn và chuẩn.
> 3. **Kiểm soát được**: admin thêm/xóa/sửa rule trực tiếp, không cần retrain model.
>
> Tuy nhiên, hệ thống đã chuẩn bị sẵn module SBERT/FastAPI để kết hợp ML trong tương lai — đây là hướng phát triển."

## 2. "Thuật toán tính điểm phù hợp cụ thể như thế nào?"

> "Dạ, thuật toán gồm 6 bước:
> 1. Chuẩn hóa điểm 0–10 → 0–1
> 2. Tính base score theo nhóm ngành với trọng số khác nhau (VD: CNTT ưu tiên Toán 60%)
> 3. Nhân strength boost (kỹ năng logic → ×1.1 cho CNTT)
> 4. Nhân region boost (miền Bắc → ×1.03 cho ngành Công nghệ)
> 5. Duyệt 14+ rule: nếu conditions khớp → nhân boostMajors vào score
> 6. Normalize: ngành cao nhất = 100%, còn lại tỷ lệ theo
>
> Code nằm trong `GuidanceService.computeSuitability()`, ~180 dòng, đã unit test."

## 3. "Firestore Rules bảo mật thế nào?"

> "Dạ, em thiết kế theo principle of least privilege:
> - `users/{userId}`: chỉ đọc/sửa hồ sơ của mình; admin mới list được tất cả
> - `guidance_rules`: authenticated users đọc (load rule); chỉ admin email whitelist mới ghi
> - `forum_posts`: public đọc, chỉ tác giả/admin sửa/xóa
> - Admin xác định bằng custom claim HOẶC email whitelist trong rules
> - File: `firestore.rules`, ~240 dòng với validation chặt chẽ"

## 4. "Tại sao dùng Flutter chứ không dùng React Native / native?"

> "Flutter cho phép 1 codebase chạy Android + iOS + Web, tiết kiệm thời gian phát triển cho đồ án. Dart có null safety, hot reload nhanh, và Firebase SDK tích hợp tốt. Giao diện em custom bằng theme_colors + Material 3, hỗ trợ cả light/dark mode."

## 5. "19 test case gồm những gì?"

> "Gồm 4 file test:
> - `guidance_service_test.dart`: 8 test (IT high score, Marketing medium, low score, block filtering, conflict rules...)
> - `recommendation_merge_test.dart`: 6 test (merge ML + local, region filtering)
> - `region_label_utils_test.dart`: 1 test (normalize legacy labels)
> - `university_region_test.dart`: 2 test (Bắc only, Nam excludes Hà Nội)
> - `widget_test.dart`: 1 test (splash branding)
>
> Tất cả pass 100%, chạy bằng `flutter test`."

## 6. "Dữ liệu ngành/trường lấy từ đâu?"

> "Em xây dựng từ nhiều nguồn:
> - `majors_catalog.json`: 50+ ngành, có mã ngành theo TT09
> - `major_universities.json`: mapping ngành → trường
> - `majors_by_block.json`: mapping khối thi → ngành + trường
> - Dữ liệu tham khảo từ website tuyển sinh các trường ĐH
> - Admin có thể nhập/cập nhật thêm từ Firebase (A02–A04)"

## 7. "Chatbot Gemini có giới hạn gì không?"

> "Có ạ:
> - Phụ thuộc API key + quota Google (miễn phí có giới hạn request/phút)
> - Không có memory dài hạn giữa các phiên chat
> - Câu trả lời có thể không chính xác 100% (hạn chế chung của LLM)
> - Em đã thêm disclaimer trong app: kết quả chỉ mang tính tham khảo"

## 8. "Đề tài có gì mới so với các hệ thống tư vấn hiện có?"

> "Dạ, 3 điểm mới:
> 1. **Explainable AI**: giải thích lý do gợi ý — các hệ thống hiện tại chỉ hiện danh sách
> 2. **Kiến trúc hybrid**: Rule-based (chính) + SBERT (ML tùy chọn) + Gemini (chatbot) — 3 tầng AI
> 3. **Admin quản trị rule**: cán bộ tuyển sinh tự thêm/sửa rule không cần lập trình viên"
