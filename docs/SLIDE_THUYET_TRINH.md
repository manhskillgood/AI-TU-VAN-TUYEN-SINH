# THUYẾT TRÌNH ĐỒ ÁN — BẢN TỐI ƯU (13 SLIDE + LỜI NÓI)

> **Đề tài:** Ứng dụng AI trong hệ thống hỗ trợ tuyển sinh và tư vấn ngành học  
> **Thời gian:** ~12–15 phút (nói chậm, rõ, nhìn hội đồng — không đọc slide word-by-word)  
> **Trên slide:** ít chữ · **Dưới đây:** lời nói đầy đủ để luyện tập

---

## Cấu trúc tổng

| Slide | Nội dung | Thời gian |
|-------|----------|----------|
| 1 | Bìa | ~20s |
| 2 | Mục lục | ~30s |
| 3 | Vấn đề + Mục tiêu + Phạm vi | ~1,5 phút |
| 4 | Kiến trúc | ~1 phút |
| 5–6 | AI Engine (2 slide) | ~2,5 phút |
| 7–8 | Demo ứng dụng (2 slide) | ~2 phút |
| 9 | Chatbot + Admin | ~1 phút |
| 10 | Công nghệ + Kiểm thử | ~1 phút |
| 11 | Ưu / Nhược | ~1 phút |
| 12 | Kết luận | ~45s |
| 13 | Q&A | — |

---

## Slide 1 — Trang bìa

**Trên slide:**
```
ĐỒ ÁN TỐT NGHIỆP
ỨNG DỤNG AI TRONG HỆ THỐNG
HỖ TRỢ TUYỂN SINH VÀ TƯ VẤN NGÀNH HỌC
Sinh viên: Lê Đức Mạnh
GVHD: [Tên GVHD]
Năm: 2026
```

### Lời trình bày (~20 giây)

> Kính chào thầy cô trong Hội đồng, em là **Lê Đức Mạnh**, sinh viên thực hiện đồ án tốt nghiệp với đề tài **"Ứng dụng AI trong hệ thống hỗ trợ tuyển sinh và tư vấn ngành học"**, dưới sự hướng dẫn của thầy/cô **[Tên GVHD]**.  
> Em xin phép trình bày trong khoảng **12 đến 15 phút**, sau đó em sẵn sàng trả lời câu hỏi của Hội đồng. Em xin phép bắt đầu.

---

## Slide 2 — Mục lục

**Trên slide:**
1. Vấn đề & Mục tiêu  
2. Kiến trúc hệ thống  
3. AI Engine (Rule-based, giải thích được)  
4. Demo ứng dụng  
5. Chatbot & Quản trị  
6. Công nghệ & Kiểm thử  
7. Ưu / Nhược & Kết luận  

### Lời trình bày (~30 giây)

> Nội dung trình bày gồm **7 phần** như slide.  
> Em đi từ **bối cảnh và mục tiêu**, sau đó **kiến trúc**, phần trọng tâm là **AI Engine** và **demo ứng dụng**, rồi **chatbot, quản trị**, **công nghệ và kiểm thử**, cuối cùng **ưu nhược điểm và kết luận**.  
> Em xin chuyển sang phần đặt vấn đề.

---

## Slide 3 — Vấn đề & Mục tiêu & Phạm vi

**Trên slide:**
- Vấn đề: chọn ngành thiếu cơ sở; tư vấn thủ công
- Mục tiêu: Flutter + AI rule-based giải thích được + Firebase + Chatbot
- Phạm vi: hỗ trợ quyết định, không thay thế con người

### Lời trình bày (~1,5 phút)

> **Về vấn đề:** Hiện nay nhiều học sinh THPT chọn ngành học chủ yếu theo **cảm tính**, theo **xu hướng** hoặc theo **ý kiến gia đình**, chưa dựa đủ trên **năng lực học tập**, **sở thích** và **nhu cầu nghề nghiệp**. Hệ quả là tỷ lệ **chuyển ngành**, **bỏ học** hoặc **chán nản** ở năm nhất vẫn đáng quan tâm.  
> Công tác tư vấn tuyển sinh ở trường phổ thông và một số đơn vị đại học phần lớn vẫn **thủ công** — qua hội thảo, tờ rơi, tư vấn trực tiếp — nên **thiếu tính cá nhân hóa** và khó xử lý khi số lượng học sinh lớn.
>
> **Về hướng giải quyết:** Trí tuệ nhân tạo, đặc biệt hướng **AI giải thích được** — Explainable AI — có thể giúp phân tích hồ sơ học sinh và **gợi ý ngành có cơ sở**, đồng thời **nêu rõ lý do**, thay vì chỉ đưa ra một danh sách như mô hình “hộp đen” khó kiểm chứng.
>
> **Mục tiêu đồ án** của em là xây dựng **ứng dụng Flutter** tích hợp **AI Engine dạng rule-based** trong `GuidanceService`, kết nối **Firebase** để lưu trữ và đồng bộ dữ liệu, và tích hợp **chatbot** hỗ trợ hỏi đáp. Kết quả mong đợi: học sinh nhập hồ sơ, nhận **gợi ý ngành phù hợp** kèm **giải thích**.
>
> **Phạm vi:** Em tập trung **gợi ý ngành đại học** trong phạm vi demo đồ án, dữ liệu ngành–trường tham chiếu thực tế và mô phỏng. Em nhấn mạnh: hệ thống **hỗ trợ ra quyết định**, **không thay thế** vai trò phụ huynh, giáo viên hay tư vấn viên chuyên môn.

---

## Slide 4 — Kiến trúc hệ thống

**Trên slide:** Chèn **hình kiến trúc bạn đã vẽ** (Flutter Client — Android, đủ 3 tầng + 3 dịch vụ ngoài) — **chiếm ~70% slide**, chữ tối thiểu.

**2 bullet (góc dưới, tùy chọn):**
- Client Flutter: Presentation → Provider → Service → Local data
- Kết nối: **Firebase** · **FastAPI+SBERT** · **Gemini**

> *Không dùng `Hinh_2_3_Kien_truc.drawio` nữa nếu hình này đã đầy đủ và khớp code thực tế.*

### Lời trình bày (~1 phút) — khớp đúng hình trên

> Slide này là **kiến trúc tổng thể** ứng dụng **Flutter phía client Android**, em chia **ba tầng logic** và **ba kênh kết nối ra ngoài**.
>
> **Tầng Presentation** — giao diện: Home, Wizard nhập liệu, màn Kết quả, Chat, Forum, và khu vực Admin.  
> **Tầng State Management** — em dùng **Provider**: `AuthProvider` quản lý đăng nhập, `ThemeProvider` giao diện sáng/tối, `CareerGuidanceProvider` trạng thái luồng tư vấn ngành.  
> **Tầng Business / Service** — xử lý nghiệp vụ: `GuidanceService` là **AI rule-based**; `RecommendationMergeService` gộp kết quả rule với gợi ý ML; `AIService` gọi chatbot; `UserService`, `ForumLocalService` phục vụ người dùng và diễn đàn.
>
> **Dữ liệu cục bộ:** JSON assets như `majors_catalog`, **SQLite** `edu_guidance_forum.db`, **SharedPreferences** — theme, chat local, rule — giúp app **chạy offline** một phần.
>
> **Ba dịch vụ bên ngoài:**  
> — **Firebase** qua HTTPS: Authentication và Firestore — users, rules, forum, chat trên cloud.  
> — **FastAPI + SBERT** qua HTTP cổng 8000: endpoint `POST /recommend`, dùng `major_embeddings.npy` — **bổ trợ** gợi ý semantic, không thay lõi rule.  
> — **Google Gemini** qua HTTPS API: **chatbot tư vấn** generative.
>
> Như vậy kiến trúc là **client–cloud hybrid**: lõi gợi ý và giải thích trên app; Firebase lưu trữ; ML và LLM là **tầng bổ trợ**. Phân quyền admin qua **Firestore Rules** và email whitelist.  
> Em xin chuyển sang **phần lõi — AI Engine**.

---

## Slide 5 — AI Engine (A) — Luồng xử lý

**Trên slide:** Chèn **sơ đồ Sequence** (User → UI Wizard → GuidanceService → FastAPI SBERT → MergeService → Hiển thị) — file `Hinh_2_4_Sequence.drawio` export PNG, **phóng to ~70% slide**.

**3 bullet (góc dưới, tùy chọn):**
- Lõi: `GuidanceService` — rule + **lý do** (Explainable)
- Bổ trợ: `POST /recommend` (SBERT) → `MergeService`
- **Fallback:** FastAPI lỗi/timeout → chỉ dùng kết quả local

### Lời trình bày (~1 phút 15 giây)

> Đây là **luồng xử lý gợi ý ngành** — sơ đồ **sequence** em thiết kế trong báo cáo (`Hinh 2.4`).
>
> **Bước 1:** Người dùng hoàn tất **wizard** — khối thi, điểm, sở thích.  
> **Bước 2:** `GuidanceService` gọi `computeSuitability()` kèm **tập luật** — trả về **điểm local** và **lý do** cho từng ngành. Đây là **lõi rule-based, giải thích được**.  
> **Bước 3:** App gửi `POST /recommend` tới **FastAPI + SBERT** — nhận `top_majors` từ embedding ngành (semantic).  
> **Bước 4:** `RecommendationMergeService` **gộp** kết quả ML và local → **Top 8 ngành**, có badge **ML / Rule** để minh bạch nguồn gợi ý.  
> **Bước 5:** UI **hiển thị kết quả** cho học sinh.
>
> Khối **`alt`** phía dưới: nếu **FastAPI lỗi hoặc timeout**, hệ thống **fallback** — chỉ dùng kết quả `GuidanceService`, app **vẫn chạy được** không phụ thuộc server ML.  
> Slide tiếp theo em minh họa **màn hình kết quả** trên app.

---

## Slide 6 — AI Engine (B) — Minh chứng

**Trên slide:** Screenshot kết quả (có % + lý do) HOẶC bảng 1 dòng CNTT 100%

### Lời trình bày (~1 phút 15 giây)

> Slide này là **minh chứng Explainable AI** — điểm khác biệt so với nhiều app chỉ hiện danh sách ngành.
>
> Ví dụ học sinh khối **A01**, **Toán cao**, chọn sở thích **Công nghệ**: hệ thống xếp **Công nghệ thông tin** đầu bảng, khoảng **100% phù hợp**, và hiển thị **lý do** — ví dụ: điểm Toán đạt ngưỡng, sở thích khớp nhóm CNTT, **rule** `tech_boost` được kích hoạt với hệ số tăng. Học sinh và phụ huynh **đọc được vì sao**, không chỉ thấy một con số.
>
> Mỗi rule trong tập luật có trường **`reason`** — câu giải thích bằng tiếng Việt — khi rule áp dụng, app đưa nội dung đó ra giao diện. Đó chính là **Explainable AI** em triển khai.
>
> Nếu thầy cô hỏi **“Sao không dùng Machine Learning làm chính?”** — em xin trả lời ngắn tại đây: trong tư vấn giáo dục cần **minh bạch**; dữ liệu huấn luyện quy mô lớn, chuẩn hóa ở Việt Nam còn hạn chế; rule do **admin chỉnh** được mà **không cần retrain**. ML và LLM em đặt vai trò **bổ trợ** — SBERT, Gemini — **không thay** lõi rule.  
> Em xin chuyển sang **demo giao diện ứng dụng**.

---

## Slide 7 — Demo (A) — Nhập liệu

**Trên slide:** Screenshot Wizard + 3 bullet (khối → điểm → sở thích → kỹ năng → khu vực)

### Lời trình bày (~1 phút)

> Đây là **luồng người dùng** học sinh trên app. Sau đăng nhập, học sinh vào **wizard định hướng** — em thiết kế **nhiều bước** để tránh nhập một form dài gây nhầm lẫn.
>
> **Bước 1:** Chọn **khối thi** — A01, D01, C00… — hệ thống xác định **ba môn** tương ứng.  
> **Bước 2:** Nhập **điểm trung bình** từng môn, thang 0 đến 10.  
> **Bước 3:** Chọn **sở thích** — Công nghệ, Y tế, Kinh tế… — danh sách **lọc theo khối** để không gợi ý ngành ngoài tổ hợp.  
> **Bước 4:** Chọn **ưu điểm / kỹ năng** — logic, giao tiếp… — dùng cho hệ số boost.  
> **Bước 5:** Chọn **khu vực** — Bắc, Trung, Nam — ưu tiên gợi ý trường phù hợp.
>
> Nếu học sinh quan tâm **Công an, Quân đội**, app có thêm bước **thể chất** — chiều cao, cân nặng — theo module riêng.  
> Sau khi hoàn tất, người dùng bấm phân tích — em chiếu **màn kết quả** ở slide sau.

---

## Slide 8 — Demo (B) — Kết quả

**Trên slide:** Screenshot màn Kết quả (cùng case slide 7)

### Lời trình bày (~1 phút)

> Đây là **kết quả** cùng bộ dữ liệu em vừa nhập: khối A01, điểm Toán cao, sở thích Công nghệ.
>
> App hiển thị **danh sách ngành** xếp theo **mức phù hợp phần trăm**, kèm **gợi ý trường** theo khu vực, và quan trọng là **dòng giải thích** cho từng ngành — từ rule và từ thuật toán base score.  
> Học sinh có thể **lưu kết quả** lên Firestore để xem lại trong **lịch sử gợi ý** — chức năng F06 trong báo cáo.
>
> Như vậy luồng **nhập liệu → AI xử lý → kết quả giải thích được → lưu cloud** đã chạy **end-to-end** trên thiết bị Android em demo.  
> Em xin chuyển sang **chatbot và khu vực quản trị**.

---

## Slide 9 — Chatbot & Admin

**Trên slide:** 2 ảnh (Chat + Admin) · Phân quyền Firestore Rules

### Lời trình bày (~1 phút)

> **Chatbot:** Em tích hợp **Google Gemini API** để học sinh hỏi đáp tự nhiên — ngành học gì, học những môn nào, triển vọng việc làm… Chatbot **bổ sung** cho wizard, **không thay** kết quả gợi ý chính từ Rule Engine. App có **ghi chú** kết quả chatbot mang tính **tham khảo**.
>
> **Khu vực Admin** phục vụ cán bộ tuyển sinh hoặc quản trị: **A01** quản lý người dùng; **A02–A04** quản lý ngành, trường, dữ liệu tuyển sinh; **A05** dashboard thống kê. Đặc biệt admin có thể **thêm, sửa, bật tắt quy tắc AI** và **đồng bộ** với Firestore — không cần sửa code và build lại app.
>
> **Bảo mật:** Chỉ tài khoản **email nằm trong whitelist** mới thực hiện thao tác admin; người dùng thường chỉ đọc/ghi **dữ liệu của chính mình** — cấu hình trong `firestore.rules`.

---

## Slide 10 — Công nghệ & Kiểm thử

**Trên slide:** Flutter · Firebase · GuidanceService · Gemini · 19/19 test · <2s

### Lời trình bày (~1 phút)

> **Công nghệ:** Giao diện **Flutter/Dart** — một codebase triển khai Android, có thể mở rộng iOS và Web. Backend dữ liệu **Firebase Firestore** và **Firebase Authentication**. Lõi AI là **`GuidanceService`** viết bằng Dart — rule-based. Chatbot qua **Gemini API**. Dữ liệu offline: **SQLite**, **SharedPreferences**.
>
> **Kiểm thử:** Em viết **19 unit và widget test**, chạy `flutter test`, kết quả **pass 100%**. Các test bao gồm: logic gợi ý với điểm cao/thấp, lọc theo khối, xung đột rule, merge gợi ý ML, lọc trường theo miền, và smoke test màn splash.  
> Thời gian phản hồi AI engine em đo **dưới 2 giây** trên emulator và thiết bị thật. Giao diện hỗ trợ **sáng và tối** để dễ đọc.
>
> Em xin chuyển sang **đánh giá ưu, nhược điểm**.

---

## Slide 11 — Ưu & Nhược

**Trên slide:** Bảng 3 ưu / 3 nhược + 1 dòng hướng phát triển

### Lời trình bày (~1 phút)

> **Ưu điểm:** Thứ nhất, **giải thích được kết quả** — phù hợp yêu cầu minh bạch trong giáo dục. Thứ hai, **gợi ý offline** nhờ rule lưu local — học sinh vẫn dùng được khi mạng yếu. Thứ ba, **kiến trúc mở rộng** — Flutter một nguồn, admin quản rule và dữ liệu trên cloud.
>
> **Hạn chế:** Em nêu thẳng để Hội đồng đánh giá đúng. Thứ nhất, **chất lượng gợi ý phụ thuộc dữ liệu** ngành, trường, điểm chuẩn — cần **cập nhật hàng năm**. Thứ hai, **chưa khảo sát người dùng thật** quy mô lớn — mới kiểm thử kỹ thuật và vài profile mẫu. Thứ ba, **rule-based chưa phản ánh hết** yếu tố tâm lý, hoàn cảnh; chatbot LLM **phụ thuộc API** và có thể sai — em đã ghi trong báo cáo.
>
> **Hướng phát triển:** Kết hợp **ML/SBERT**, tích hợp **API Bộ GD&ĐT**, pilot tại trường, đưa lên **CH Play / App Store**.

---

## Slide 12 — Kết luận

**Trên slide:** Đã hoàn thành · Đóng góp · Cảm ơn & Q&A

### Lời trình bày (~45 giây)

> **Tóm lại**, em đã hoàn thành hệ thống **ứng dụng AI hỗ trợ tuyển sinh và tư vấn ngành học** với **AI rule-based giải thích được**, **ứng dụng Flutter** chạy thực tế, **Firebase** cho dữ liệu và xác thực, đủ chức năng **học sinh F01–F06** và **admin A01–A05**, tích hợp **chatbot Gemini**, **19 test pass**.
>
> **Đóng góp:** Đề xuất mô hình tư vấn **minh bạch** trong giáo dục; kiến trúc **client–cloud** có thể phát triển thành công cụ hướng nghiệp thực tế.
>
> Em xin **cảm ơn thầy cô và Hội đồng** đã lắng nghe. Em **sẵn sàng trả lời câu hỏi**.

---

## Slide 13 — Q&A

**Trên slide:** HỎI ĐÁP

### Lời trình bày

> (Không nói thêm — lắng nghe câu hỏi, trả lời theo phần **Ôn trước trưởng khoa** bên dưới.)

---

---

# ÔN TRƯỚC TRƯỞNG KHOA — CÂU HỎI GẮT & TRẢ LỜI (NÓI MIỆNG)

> Mỗi câu ~30–45 giây. Không đọc slide khi trả lời.

### 1. "AI của em là gì? Có phải machine learning không?"

**Trả lời:** "Dạ, lõi là **hệ chuyên gia rule-based**: tập luật + engine tính điểm phù hợp. Em chọn vì **giải thích được** từng gợi ý — phù hợp tư vấn giáo dục. ML (SBERT) và LLM (Gemini) em dùng **bổ trợ**, không thay lõi rule."

### 2. "Thuật toán tính điểm cụ thể?"

**Trả lời:** "Chuẩn hóa điểm 0–1 → base score theo nhóm ngành (VD CNTT: Toán 60%) → nhân boost kỹ năng, miền → duyệt 14+ rule, nếu khớp `conditions` thì nhân `boostMajors` → chuẩn hóa top = 100%. Code: `GuidanceService.computeSuitability()`, đã unit test."

### 3. "Tại sao không dùng ML làm chính?"

**Trả lời:** "Thiếu dataset huấn luyện chuẩn quy mô lớn; kết quả ML khó giải thích cho phụ huynh; rule do admin sửa được không cần retrain. Hướng sau: kết hợp SBERT."

### 4. "Explainable AI em làm thế nào?"

**Trả lời:** "Mỗi rule có field `reason`; khi rule kích hoạt, app hiển thị lý do trên màn kết quả. Học sinh thấy vì sao CNTT cao điểm — không chỉ một con số."

### 5. "Bảo mật Firebase? Admin lấy data người khác thế nào?"

**Trả lời:** "Firestore Rules: user chỉ đọc/sửa document của mình; **chỉ email admin** trong whitelist mới list users, ghi `guidance_rules`. Auth Firebase + `ensureFirestoreSession` trước thao tác nhạy cảm."

### 6. "Dữ liệu ngành/trường từ đâu? Tin được không?"

**Trả lời:** "Từ catalog JSON (mã TT09), mapping khối–ngành–trường; tham khảo website tuyển sinh. Đây là **demo đồ án** — production cần API Bộ GD&ĐT hoặc cập nhật định kỳ qua admin."

### 7. "Chatbot Gemini sai thì sao?"

**Trả lời:** "Chatbot chỉ **hỏi đáp tham khảo**; gợi ý chính từ Rule Engine. App có disclaimer; không lưu memory dài giữa phiên; phụ thuộc quota API."

### 8. "Em kiểm thử ra sao? Có số liệu không?"

**Trả lời:** "19 test `flutter test` pass 100%: logic gợi ý (khối, điểm cao/thấp, conflict rule), merge ML, region trường, widget splash. Thử tay: Toán cao + IT → CNTT đầu; Văn cao + kinh doanh → QTKD."

### 9. "Đóng góp khoa học / thực tiễn?"

**Trả lời:** "Khoa học: rule-based + explainable vào tư vấn hướng nghiệp. Thực tiễn: app chạy được, admin quản rule/dữ liệu, học sinh có công cụ tham khảo trước khi chọn ngành."

### 10. "Hạn chế lớn nhất? Em có che không?"

**Trả lời:** "Dạ không ạ: phụ thuộc dữ liệu đầu vào; chưa khảo sát người dùng thật quy mô lớn; rule chưa phủ hết yếu tố tâm lý. Em ghi rõ trong báo cáo."

### 11. "Flutter tại sao không React Native?"

**Trả lời:** "Một codebase Android/iOS/Web; Firebase SDK tốt; phù hợp thời gian đồ án; UI Material 3, light/dark."

### 12. "Triển khai thật cho trường, em làm gì tiếp?"

**Trả lời:** "Cập nhật dữ liệu tuyển sinh tự động; giám sát vận hành; pilot học sinh THPT; tích hợp ML sau khi có phản hồi thực tế."

---

## CHECKLIST TRƯỚC KHI VÀO PHÒNG

- [ ] In hoặc mở file này trên điện thoại — luyện **1 lần đầy đủ** (~15 phút)
- [ ] Slide 4: hình **Kiến trúc Flutter Client** (3 tầng + Firebase/SBERT/Gemini) **đủ lớn**
- [ ] Slide 6, 7, 8: có **ảnh app** đủ lớn
- [ ] Slide 6 + 8: **cùng 1 case** demo (A01 + Công nghệ)
- [ ] Nhớ số **19/19 test**, **14+ rule**, **< 2 giây**
- [ ] App mở sẵn trên điện thoại (backup nếu máy chiếu lỗi)
- [ ] Khi trả lời: **dừng 1 giây** trước câu quan trọng — tự tin, không đọc slide

---

## GỢI Ý ĐIỀN FORM

**Số chương:** 3 · **Tổng số trang:** [điền theo Word/PDF]

**Thành công:** App Flutter + Firebase; AI rule-based Explainable; F01–F06, A01–A05; chatbot; 19/19 test.

**Hạn chế:** Dữ liệu cần cập nhật; chưa khảo sát user rộng; rule/LLM còn giới hạn.
