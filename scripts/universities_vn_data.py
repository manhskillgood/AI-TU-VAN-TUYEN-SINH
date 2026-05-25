# -*- coding: utf-8 -*-
"""Danh mục trường ĐH Việt Nam + nhóm ngành — nguồn cho build_majors_catalog.py"""

from __future__ import annotations

# name -> list of region codes: north | south | central | tay_nguyen
UNIVERSITIES_REGISTRY: dict[str, list[str]] = {
    # --- Miền Bắc ---
    "Đại học Bách Khoa Hà Nội": ["north"],
    "Đại học Công Nghệ - ĐHQG HN": ["north"],
    "Đại học FPT": ["north", "south"],
    "Đại học Kinh Tế Quốc Dân": ["north"],
    "Đại học Ngoại Thương": ["north"],
    "Đại học Hà Nội": ["north"],
    "Đại học Sư phạm Hà Nội": ["north"],
    "Học viện Báo chí và Tuyên truyền": ["north"],
    "Đại học Luật Hà Nội": ["north"],
    "Đại học Văn hóa Hà Nội": ["north"],
    "Đại học Y Hà Nội": ["north"],
    "Đại học Mỹ Thuật Việt Nam": ["north"],
    "Đại học Kiến Trúc Hà Nội": ["north"],
    "Đại học Mỹ Thuật Công Nghiệp": ["north"],
    "Đại học Thủy lợi": ["north"],
    "Đại học Nông nghiệp Hà Nội": ["north"],
    "Học viện Ngân hàng": ["north"],
    "Đại học Thương mại": ["north"],
    "Học viện Tài chính": ["north"],
    "Đại học Lao động - Xã hội": ["north"],
    "Đại học Giao thông Vận tải": ["north"],
    "Đại học Xây dựng Hà Nội": ["north"],
    "Học viện Công nghệ Bưu chính Viễn thông": ["north"],
    "Đại học Điện lực": ["north"],
    "Đại học Mỏ - Địa chất": ["north"],
    "Học viện Nông nghiệp Việt Nam": ["north"],
    "Đại học Tài chính - Kế toán": ["north"],
    "Đại học Phenikaa": ["north"],
    "Đại học Thăng Long": ["north"],
    "Đại học Hà Nội - Khoa học Tự nhiên": ["north"],
    "Đại học Hà Nội - Khoa học Xã hội và Nhân văn": ["north"],
    "Học viện Quân y": ["north"],
    "Học viện Cảnh sát nhân dân": ["north"],
    "Đại học Công nghiệp Hà Nội": ["north"],
    "Đại học Công nghiệp Dệt may Hà Nội": ["north"],
    "Đại học Sân khấu - Điện ảnh Hà Nội": ["north"],
    "Đại học Mở Hà Nội": ["north"],
    "Đại học Đại Nam": ["north"],
    # --- Miền Nam ---
    "Đại học Bách Khoa TP.HCM": ["south"],
    "Đại học Kinh Tế TP.HCM": ["south"],
    "Đại học Y Dược TP.HCM": ["south"],
    "Đại học KHXH&NV TP.HCM": ["south"],
    "Đại học Sư phạm TP.HCM": ["south"],
    "Đại học Công nghệ TP.HCM": ["south"],
    "Đại học Tôn Đức Thắng": ["south"],
    "Đại học Kinh tế - Luật TP.HCM": ["south"],
    "Đại học Cần Thơ": ["south"],
    "Đại học An Giang": ["south"],
    "Đại học Quốc tế Hồng Bàng": ["south"],
    "Đại học Nguyễn Tất Thành": ["south"],
    "Đại học Hoa Sen": ["south"],
    "Đại học Văn Lang": ["south"],
    "Đại học Tài chính - Marketing TP.HCM": ["south"],
    "Đại học Luật TP.HCM": ["south"],
    "Đại học Sư phạm Kỹ thuật TP.HCM": ["south"],
    "Đại học Nông Lâm TP.HCM": ["south"],
    "Đại học Kiến trúc TP.HCM": ["south"],
    "Đại học Mỹ thuật TP.HCM": ["south"],
    "Đại học Y khoa Phạm Ngọc Thạch": ["south"],
    "Đại học RMIT Việt Nam": ["south"],
    "Đại học Quốc tế TP.HCM": ["south"],
    "Đại học Công Thương TP.HCM": ["south"],
    "Đại học Công nghệ Thông tin TP.HCM": ["south"],
    "Đại học Hutech": ["south"],
    "Đại học Gia Định": ["south"],
    "Đại học Đồng Nai": ["south"],
    "Đại học Tây Đô": ["south"],
    "Đại học Võ Trường Toán": ["south"],
    "Đại học Hùng Vương TP.HCM": ["south"],
    "Đại học Sư phạm Thể dục thể thao TP.HCM": ["south"],
    "Học viện Hàng không Việt Nam": ["south"],
    # --- Miền Trung ---
    "Đại học Bách khoa Đà Nẵng": ["central"],
    "Đại học Đà Nẵng": ["central"],
    "Đại học Kinh tế Đà Nẵng": ["central"],
    "Đại học Sư phạm Đà Nẵng": ["central"],
    "Đại học Y Dược - Đại học Huế": ["central"],
    "Đại học Huế": ["central"],
    "Đại học Nha Trang": ["central"],
    "Đại học Duy Tân": ["central"],
    "Đại học Đông Á": ["central"],
    "Đại học Vinh": ["central"],
    "Đại học Quy Nhơn": ["central"],
    "Đại học Phan Châu Trinh": ["central"],
    "Đại học Kinh tế Huế": ["central"],
    "Đại học FPT Đà Nẵng": ["central"],
    "Đại học Công nghệ thông tin - ĐH Đà Nẵng": ["central"],
    "Đại học Kỹ thuật Xây dựng Miền Trung": ["central"],
    "Đại học Hà Tĩnh": ["central"],
    # --- Tây Nguyên ---
    "Đại học Tây Nguyên": ["tay_nguyen"],
    "Đại học Đà Lạt": ["tay_nguyen"],
}

REGIONS_ORDER = ("north", "south", "central", "tay_nguyen")

# Trường theo nhóm ngành / miền (ưu tiên gợi ý)
UNIVERSITY_BY_DOMAIN: dict[str, dict[str, list[str]]] = {
    "tech": {
        "north": [
            "Đại học Bách Khoa Hà Nội", "Đại học Công Nghệ - ĐHQG HN", "Đại học FPT",
            "Học viện Công nghệ Bưu chính Viễn thông", "Đại học Phenikaa",
            "Đại học Công nghiệp Hà Nội",
        ],
        "south": [
            "Đại học Bách Khoa TP.HCM", "Đại học Công nghệ TP.HCM", "Đại học FPT",
            "Đại học Công nghệ Thông tin TP.HCM", "Đại học Hutech", "Đại học Tôn Đức Thắng",
        ],
        "central": [
            "Đại học Bách khoa Đà Nẵng", "Đại học Công nghệ thông tin - ĐH Đà Nẵng",
            "Đại học FPT Đà Nẵng", "Đại học Duy Tân",
        ],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "engineering": {
        "north": [
            "Đại học Bách Khoa Hà Nội", "Đại học Giao thông Vận tải", "Đại học Xây dựng Hà Nội",
            "Đại học Điện lực", "Đại học Mỏ - Địa chất", "Đại học Thủy lợi",
        ],
        "south": [
            "Đại học Bách Khoa TP.HCM", "Đại học Sư phạm Kỹ thuật TP.HCM",
            "Đại học Công Thương TP.HCM", "Đại học Kiến trúc TP.HCM",
        ],
        "central": [
            "Đại học Bách khoa Đà Nẵng", "Đại học Kỹ thuật Xây dựng Miền Trung",
        ],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "health": {
        "north": ["Đại học Y Hà Nội", "Học viện Quân y"],
        "south": [
            "Đại học Y Dược TP.HCM", "Đại học Y khoa Phạm Ngọc Thạch",
            "Đại học Cần Thơ", "Đại học An Giang",
        ],
        "central": ["Đại học Y Dược - Đại học Huế", "Đại học Huế", "Đại học Nha Trang"],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "econ": {
        "north": [
            "Đại học Kinh Tế Quốc Dân", "Đại học Ngoại Thương", "Học viện Ngân hàng",
            "Đại học Thương mại", "Học viện Tài chính", "Đại học Tài chính - Kế toán",
        ],
        "south": [
            "Đại học Kinh Tế TP.HCM", "Đại học Kinh tế - Luật TP.HCM",
            "Đại học Tài chính - Marketing TP.HCM", "Đại học Tôn Đức Thắng",
            "Đại học Cần Thơ", "Đại học Hoa Sen",
        ],
        "central": ["Đại học Kinh tế Đà Nẵng", "Đại học Kinh tế Huế", "Đại học Nha Trang"],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "social": {
        "north": [
            "Đại học Sư phạm Hà Nội", "Học viện Báo chí và Tuyên truyền",
            "Đại học Luật Hà Nội", "Đại học Văn hóa Hà Nội", "Đại học Lao động - Xã hội",
            "Đại học Hà Nội - Khoa học Xã hội và Nhân văn",
        ],
        "south": [
            "Đại học KHXH&NV TP.HCM", "Đại học Sư phạm TP.HCM", "Đại học Luật TP.HCM",
            "Đại học Văn Lang", "Đại học Hoa Sen",
        ],
        "central": ["Đại học Huế", "Đại học Sư phạm Đà Nẵng", "Đại học Đà Nẵng", "Đại học Vinh"],
        "tay_nguyen": ["Đại học Tây Nguyên", "Đại học Đà Lạt"],
    },
    "law": {
        "north": ["Đại học Luật Hà Nội", "Đại học Kinh Tế Quốc Dân"],
        "south": ["Đại học Luật TP.HCM", "Đại học Kinh tế - Luật TP.HCM"],
        "central": ["Đại học Huế", "Đại học Đà Nẵng"],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "lang": {
        "north": ["Đại học Hà Nội", "Đại học Ngoại Thương", "Đại học Thương mại"],
        "south": [
            "Đại học KHXH&NV TP.HCM", "Đại học Sư phạm TP.HCM",
            "Đại học Quốc tế TP.HCM", "Đại học Quốc tế Hồng Bàng",
        ],
        "central": ["Đại học Đà Nẵng", "Đại học Huế", "Đại học Nha Trang"],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "art": {
        "north": [
            "Đại học Mỹ Thuật Việt Nam", "Đại học Kiến Trúc Hà Nội",
            "Đại học Mỹ Thuật Công Nghiệp", "Đại học Sân khấu - Điện ảnh Hà Nội",
        ],
        "south": [
            "Đại học Mỹ thuật TP.HCM", "Đại học Kiến trúc TP.HCM",
            "Đại học KHXH&NV TP.HCM", "Đại học Hoa Sen",
        ],
        "central": ["Đại học Nha Trang", "Đại học Đông Á", "Đại học Duy Tân"],
        "tay_nguyen": ["Đại học Đà Lạt"],
    },
    "agri": {
        "north": [
            "Đại học Nông nghiệp Hà Nội", "Đại học Thủy lợi",
            "Học viện Nông nghiệp Việt Nam",
        ],
        "south": ["Đại học Cần Thơ", "Đại học An Giang", "Đại học Nông Lâm TP.HCM"],
        "central": ["Đại học Huế", "Đại học Nha Trang", "Đại học Quy Nhơn"],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "tourism": {
        "north": ["Đại học Văn hóa Hà Nội", "Đại học Ngoại Thương"],
        "south": ["Đại học KHXH&NV TP.HCM", "Đại học Hoa Sen", "Đại học Văn Lang"],
        "central": ["Đại học Nha Trang", "Đại học Đà Lạt", "Đại học Duy Tân"],
        "tay_nguyen": ["Đại học Đà Lạt", "Đại học Tây Nguyên"],
    },
    "sport": {
        "north": ["Đại học Sư phạm Hà Nội", "Đại học Văn hóa Hà Nội"],
        "south": ["Đại học Sư phạm Thể dục thể thao TP.HCM", "Đại học Sư phạm TP.HCM"],
        "central": ["Đại học Nha Trang"],
        "tay_nguyen": ["Đại học Tây Nguyên"],
    },
    "aviation": {
        "north": ["Học viện Hàng không Việt Nam"],
        "south": ["Học viện Hàng không Việt Nam", "Đại học Bách Khoa TP.HCM"],
        "central": ["Đại học Bách khoa Đà Nẵng"],
        "tay_nguyen": [],
    },
}

MIN_UNIVERSITIES_PER_MAJOR = 8
MAX_UNIVERSITIES_PER_MAJOR = 12


def flatten_domain(domain: str, max_total: int = MAX_UNIVERSITIES_PER_MAJOR) -> list[str]:
    pools = UNIVERSITY_BY_DOMAIN.get(domain, UNIVERSITY_BY_DOMAIN["econ"])
    out: list[str] = []
    seen: set[str] = set()
    for region in REGIONS_ORDER:
        for u in pools.get(region, []):
            if u not in seen:
                out.append(u)
                seen.add(u)
            if len(out) >= max_total:
                return out
    return out


def write_registry_json(path) -> None:
    import json
    doc = {
        "version": 2,
        "regions": list(REGIONS_ORDER),
        "universities": UNIVERSITIES_REGISTRY,
    }
    path.write_text(json.dumps(doc, ensure_ascii=False, indent=2), encoding="utf-8")
