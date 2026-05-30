# Ảnh demo app (screenshot)

Đặt ảnh chụp từ điện thoại (Redmi / emulator) vào **thư mục này**, rồi `git add` + `git push`.

## Tên file gợi ý

| File | Màn hình |
|------|----------|
| `01_home.png` | Trang chủ |
| `02_wizard.png` | Wizard nhập liệu (khối, điểm, sở thích) |
| `03_ket_qua.png` | Kết quả gợi ý (% + lý do) |
| `04_chatbot.png` | Chatbot Gemini |
| `05_admin.png` | Admin dashboard (tùy chọn) |

- Định dạng: **PNG** hoặc **JPG**
- Nên crop thanh trạng thái nếu cần, ảnh dọc 1080×2400 hoặc nhỏ hơn (~400–600px chiều rộng trên README là đủ)

## Chụp trên Redmi

1. Mở app → màn cần chụp  
2. **Volume down + Power** (hoặc gesture chụp màn hình của máy)  
3. Copy ảnh vào PC → đổi tên theo bảng trên → paste vào `docs/images/demo/`

## Push lên GitHub

```powershell
cd C:\Users\Manh\DO_AN_TN
git add docs/images/demo/
git commit -m "docs: them anh demo app"
git push github main
```

Sau khi có ảnh, README gốc sẽ hiển thị gallery tự động (xem `README.md` mục Demo).
