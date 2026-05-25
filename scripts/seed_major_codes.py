#!/usr/bin/env python3
"""
Gán mã ngành Bộ GDĐT (TT 09/2022) cho catalog bằng danh mục tham chiếu + khớp tên.
Chạy: python scripts/seed_major_codes.py && python scripts/build_majors_catalog.py
"""
from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
DATA = ASSETS / "data"
REF_OUT = DATA / "major_codes_tt09.json"


def norm(s: str) -> str:
    s = s.lower().strip()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s)
    return s


# Mã chuẩn đã xác minh (tên catalog -> mã 7 chữ số)
EXACT: dict[str, str] = {
    norm("Công nghệ thông tin"): "7480201",
    norm("An toàn thông tin"): "7480202",
    norm("Kỹ thuật phần mềm"): "7480103",
    norm("Khoa học máy tính"): "7480101",
    norm("Hệ thống thông tin"): "7480104",
    norm("Trí tuệ nhân tạo"): "7340110",
    norm("Khoa học dữ liệu"): "7340121",
    norm("Thống kê"): "7460102",
    norm("Y khoa"): "7720101",
    norm("Dược học"): "7720201",
    norm("Hóa dược"): "7720203",
    norm("Điều dưỡng"): "7720301",
    norm("Hộ sinh"): "7720302",
    norm("Quản trị kinh doanh"): "7340101",
    norm("Marketing"): "7340115",
    norm("Kinh tế học"): "7310101",
    norm("Kinh doanh quốc tế"): "7340204",
    norm("Tài chính ngân hàng"): "7340201",
    norm("Kế toán"): "7340301",
    norm("Luật"): "7380101",
    norm("Báo chí"): "7320101",
    norm("Quan hệ công chúng"): "7320104",
    norm("Tâm lý học"): "7310601",
    norm("Sư phạm Toán"): "7140209",
    norm("Sư phạm Văn"): "7140217",
    norm("Sư phạm Anh"): "7140231",
    norm("Sư phạm Tin học"): "7140210",
    norm("Giáo dục tiểu học"): "7140202",
    norm("Giáo dục mầm non"): "7140201",
    norm("Kiến trúc"): "7580101",
    norm("Thiết kế đồ họa"): "7210403",
    norm("Mỹ thuật"): "7210101",
    norm("Kỹ thuật điện"): "7520201",
    norm("Kỹ thuật cơ khí"): "7520101",
    norm("Kỹ thuật ô tô"): "7520114",
    norm("Hóa học"): "7440112",
    norm("Sinh học"): "7420101",
    norm("Vật lý học"): "7440101",
    norm("Toán học"): "7460101",
    norm("Du lịch"): "7810101",
    norm("Hướng dẫn du lịch"): "7810102",
    norm("Quản trị khách sạn"): "7810201",
    norm("Công nghệ nông nghiệp"): "7620101",
    norm("Thú y"): "7640101",
    norm("Kỹ thuật môi trường"): "7520801",
    norm("Logistics và quản lý chuỗi cung ứng"): "7840104",
    norm("Ngôn ngữ Anh"): "7220201",
    norm("Ngôn ngữ Trung Quốc"): "7220204",
    norm("Ngôn ngữ Nhật Bản"): "7220209",
    norm("Ngôn ngữ Hàn Quốc"): "7220210",
    norm("Robot và trí tuệ nhân tạo"): "7480107",
    norm("Thiết kế game"): "7480108",
    norm("Digital Marketing"): "7340115",
    norm("Việt Nam học"): "7310630",
    norm("Sư phạm Lịch sử"): "7140218",
    # 16 ngành catalog trước đây chưa khớp fuzzy
    norm("Lập trình nhúng và IoT"): "7520216",
    norm("Công nghệ đa phương tiện"): "7320106",
    norm("Kỹ thuật vật lý"): "7520401",
    norm("Quản lý tài nguyên môi trường"): "7850101",
    norm("Công nghệ xét nghiệm"): "7720601",
    norm("Răng hàm mặt"): "7720501",
    norm("Vật lý trị liệu"): "7720603",
    norm("Phân tích đầu tư tài chính"): "7310104",
    norm("Chứng khoán"): "7340201",
    norm("Quản trị logistics"): "7510605",
    norm("Thương mại quốc tế"): "7340121",
    norm("Dịch vụ hàng không"): "7810103",
    norm("Quảng cáo"): "7320105",
    norm("Quy hoạch đô thị"): "7580105",
    norm("Diễn viên sân khấu điện ảnh"): "7210234",
    norm("Phiên dịch biên dịch"): "7229040",
    norm("Biên - phiên dịch"): "7229040",
}

# Ghi đè thủ công (ưu tiên cao nhất khi seed)
MANUAL: dict[str, str] = {k: v for k, v in EXACT.items()}


def parse_reference_tables() -> dict[str, str]:
    """Parse | 1234567 | Tên ngành | từ file markdown đã lưu (nếu có)."""
    ref: dict[str, str] = {}
    agent_dir = Path.home() / ".cursor" / "projects" / "c-Users-Manh-DO-AN-TN" / "agent-tools"
    if not agent_dir.exists():
        return ref
    pattern = re.compile(r"^\|\s*(\d{7})\s*\|\s*(.+?)\s*\|")
    for path in agent_dir.glob("*.txt"):
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for line in text.splitlines():
            m = pattern.match(line.strip())
            if not m:
                continue
            code, name = m.group(1), m.group(2).strip()
            if len(name) < 4 or name.isupper() and len(name) < 12:
                continue
            ref[norm(name)] = code
    return ref


def fuzzy_pick(name: str, ref: dict[str, str]) -> str | None:
    n = norm(name)
    if n in MANUAL:
        return MANUAL[n]
    if n in ref:
        return ref[n]
    best_code = None
    best = 0
    for rn, code in ref.items():
        if n == rn:
            return code
        if n in rn or rn in n:
            score = len(set(n.split()) & set(rn.split()))
            if score > best:
                best = score
                best_code = code
    if best >= 2 or (best >= 1 and len(n.split()) <= 3):
        return best_code
    for rn, code in MANUAL.items():
        if n in rn or rn in n:
            return code
    return None


def main() -> None:
    ref = parse_reference_tables()
    ref.update(MANUAL)

    catalog_path = DATA / "majors_catalog.json"
    if catalog_path.exists():
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        names = [m["name"] for m in catalog["majors"]]
    else:
        names = [m["name"] for m in json.loads((DATA / "majors_list.json").read_text(encoding="utf-8"))]

    mapping: dict[str, str] = {}
    for name in names:
        code = fuzzy_pick(name, ref)
        if code:
            mapping[name] = code

    REF_OUT.write_text(json.dumps(mapping, ensure_ascii=False, indent=2), encoding="utf-8")
    missing = [n for n in names if n not in mapping]
    print(f"Mapped {len(mapping)}/{len(names)} majors -> {REF_OUT}")
    if missing:
        miss_path = DATA / "major_codes_missing.txt"
        miss_path.write_text("\n".join(missing), encoding="utf-8")
        print(f"Still missing ({len(missing)}): {miss_path}")

    rich_path = ASSETS / "majors.json"
    rich = json.loads(rich_path.read_text(encoding="utf-8"))
    for item in rich:
        c = mapping.get(item["name"]) or fuzzy_pick(item["name"], ref)
        if c:
            item["code"] = c
    rich_path.write_text(json.dumps(rich, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Updated codes in {rich_path}")


if __name__ == "__main__":
    main()
