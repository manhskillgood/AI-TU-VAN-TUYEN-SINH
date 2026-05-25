# Dữ liệu ngành — nguồn chuẩn

## Nguồn sự thật (single source of truth)

| File | Vai trò |
|------|---------|
| `assets/data/majors_list.json` | Danh sách 122 ngành gốc (tên + mô tả ngắn) |
| `scripts/build_majors_catalog.py` | **Tái sinh** toàn bộ file phụ thuộc |
| `scripts/major_descriptions.py` | Mô tả chi tiết từng ngành (thay template chung) |
| `assets/data/majors_catalog.json` | Master: mã TT09, khối thi, `family`, `wizard_interests`, trường |
| `assets/data/special_career_tracks.json` | Ngành đặc thù (CA, QĐ, An ninh, Hàng không) — schema riêng |

## Trường `family` (17 nhóm ngành đại học)

| family | Ý nghĩa | Ví dụ |
|--------|---------|-------|
| `it` | CNTT / phần mềm / AI | Công nghệ thông tin, KTPM |
| `tech_applied` | Công nghệ ứng dụng (không phải CNTT) | Công nghệ thực phẩm, sinh học |
| `engineering` | Kỹ thuật truyền thống | Cơ khí, Điện |
| `health` | Y dược | Y khoa, Dược, Điều dưỡng |
| `science` | Khoa học cơ bản | Sinh học, Toán, Vật lý |
| `econ` | Kinh tế / QTKD | Marketing, Tài chính |
| `law` | Luật | Luật, Luật kinh tế |
| `media` | Truyền thông | Báo chí, QHCC |
| `lang` | Ngoại ngữ | Ngôn ngữ Anh, Trung |
| `art` | Mỹ thuật / thiết kế | Thiết kế đồ họa |
| `education` | Sư phạm / GD | Sư phạm Toán |
| `social` | Xã hội học | Công tác xã hội |
| `tourism` | Du lịch / KS | Du lịch, QTKS |
| `aviation` | Hàng không (ĐH) | Dịch vụ hàng không |
| `agri` | Nông – Lâm – Thủy sản | Công nghệ nông nghiệp |
| `environment` | Môi trường | Kỹ thuật môi trường |
| `sport` | Thể thao | Thể dục thể thao |

Logic gán: `scripts/exam_blocks_data.py` → `infer_major_family`.

**Lưu ý:** Sở thích wizard **「Công nghệ」** chỉ map tới `family = it`, không gồm `tech_applied`.

## Sở thích wizard (12 nhãn UI)

Đồng bộ `GuidanceService.wizardInterests` ↔ `infer_wizard_interests()` trong `build_majors_catalog.py`:

`Công nghệ` · `Kỹ thuật` · `Nghệ thuật` · `Y tế` · `Giáo dục` · `Kinh tế` · `Môi trường` · `Luật & Xã hội` · `Du lịch` · `Truyền thông` · `Ngoại ngữ` · `Thể thao`

Mỗi ngành trong catalog có `wizard_interests` (0–n tag) để lọc gợi ý theo sở thích đã chọn.

## Khối thi & khu vực

- **16 khối** A00–K01: `assets/data/exam_blocks.json`, `majors_by_block.json`
- **Khu vực UI:** Miền Bắc / Trung / Nam / Tây Nguyên → mã `north` / `central` / `south` / `tay_nguyen` trong `universities_registry.json`

## Mã TT09

- File: `assets/data/major_codes_tt09.json`
- Sửa tay ưu tiên: `CODE_FIXES` trong `build_majors_catalog.py` (vd. Hướng dẫn du lịch = `7810102`, Du lịch = `7810101`)

## Cập nhật dữ liệu

```bash
python scripts/build_majors_catalog.py
python scripts/validate_guidance_data.py
```

Sau đó **hot restart (R)** app Flutter và restart server ML (`uvicorn`).

## File được đồng bộ tự động

- `assets/data/majors_by_block.json`
- `assets/data/exam_blocks.json`
- `assets/major_universities.json`
- `assets/majors.json`
- `assets/guidance_rules.json`
- `assets/guidance_rules_optimized.json`
- `ml_artifacts/majors_list.json`
