#!/usr/bin/env python3
"""
Build / refresh master majors catalog and sync derived JSON assets.
Run from repo root: python scripts/build_majors_catalog.py
"""
from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

_SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(_SCRIPTS_DIR))
from major_descriptions import describe_major, is_generic_description
from exam_blocks_data import (  # noqa: E402
    ALL_BLOCKS,
    BLOCK_CAREERS,
    BLOCK_SUBJECTS,
    BLOCK_UI_ORDER,
    BLOCK_UNI_DOMAIN,
    EXAM_BLOCK_OVERRIDES,
    empty_majors_by_block,
    filter_known_blocks,
    infer_blocks_for_major,
    infer_major_family,
    is_applied_tech_major,
    is_it_major_name,
)
from universities_vn_data import (  # noqa: E402
    MAX_UNIVERSITIES_PER_MAJOR,
    MIN_UNIVERSITIES_PER_MAJOR,
    UNIVERSITIES_REGISTRY,
    flatten_domain,
    write_registry_json,
)

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
DATA = ASSETS / "data"
ML_ARTIFACTS = ROOT / "ml_artifacts"

# Canonical alias: rule/legacy name -> catalog name (sentence case)
ALIASES: dict[str, str] = {
    "công nghệ thông tin": "Công nghệ thông tin",
    "cong nghe thong tin": "Công nghệ thông tin",
    "kỹ thuật phần mềm": "Kỹ thuật phần mềm",
    "khoa học máy tính": "Khoa học máy tính",
    "khoa học dữ liệu": "Khoa học dữ liệu",
    "trí tuệ nhân tạo": "Trí tuệ nhân tạo",
    "quản lý kinh doanh": "Quản trị kinh doanh",
    "quản trị kinh doanh": "Quản trị kinh doanh",
    "y khoa": "Y khoa",
    "dược": "Dược học",
    "dược học": "Dược học",
    "thiết kế đồ họa": "Thiết kế đồ họa",
    "mỹ thuật": "Mỹ thuật",
    "sư phạm": "Sư phạm Toán",
    "sư phạm ngữ văn": "Sư phạm Văn",
    "khoa học môi trường": "Kỹ thuật môi trường",
    "an toàn thông tin": "An toàn thông tin",
    "kỹ thuật điện tử": "Kỹ thuật điện tử viễn thông",
    "kỹ thuật cơ khí": "Kỹ thuật cơ khí",
    "kỹ thuật điện": "Kỹ thuật điện",
    "tự động hóa": "Kỹ thuật điều khiển và tự động hóa",
    "kinh tế": "Kinh tế học",
    "kinh tế/thương mại quốc tế": "Kinh doanh quốc tế",
    "tài chính - ngân hàng": "Tài chính ngân hàng",
    "logistics và quản lý chuỗi cung ứng": "Logistics và quản lý chuỗi cung ứng",
    "hóa học": "Hóa học",
    "sinh học": "Sinh học",
    "truyền thông - báo chí": "Báo chí",
    "xây dựng/kiến trúc": "Kiến trúc",
    "phát triển ứng dụng/ứng dụng di động": "Kỹ thuật phần mềm",
    "thiết kế game/đồ họa máy tính": "Thiết kế game",
    "nông nghiệp/công nghệ nông nghiệp": "Công nghệ nông nghiệp",
    "vật lý trị liệu/phục hồi chức năng": "Vật lý trị liệu",
    "quản trị nhà hàng - khách sạn": "Quản trị khách sạn",
    "nghiên cứu khoa học": "Khoa học sự sống",
    "công tác xã hội/pháp luật": "Công tác xã hội",
    "du lịch - quản lý du lịch sinh thái": "Du lịch",
    "an toàn lao động/kỹ thuật an toàn": "Kỹ thuật môi trường",
    "toán học/giảng dạy toán": "Sư phạm Toán",
    "thiết kế web/ux": "Thiết kế đồ họa",
    "cơ khí - robot": "Robot và trí tuệ nhân tạo",
    "kỹ thuật điện tử ứng dụng": "Kỹ thuật điện tử viễn thông",
    "quản trị nhân sự": "Quản trị nhân lực",
    "kỹ thuật ô tô": "Kỹ thuật ô tô",
    "thiết kế công nghiệp": "Thiết kế công nghiệp",
    "kỹ thuật điện tử ứng dụng": "Kỹ thuật điện tử viễn thông",
    "nghiên cứu khoa học": "Khoa học sự sống",
    "tự động hóa": "Kỹ thuật điều khiển và tự động hóa",
    "hóa học": "Hóa học",
    "sinh học": "Sinh học",
    "sư phạm": "Sư phạm Toán",
    "mỹ thuật": "Mỹ thuật",
    "thống kê": "Thống kê",
    "marketing": "Marketing",
    "luật": "Luật",
    "tâm lý học": "Tâm lý học",
    "báo chí": "Báo chí",
    "truyền thông - báo chí": "Báo chí",
    "kinh tế": "Kinh tế học",
    "kinh doanh quốc tế": "Kinh doanh quốc tế",
    "tài chính - ngân hàng": "Tài chính ngân hàng",
    "logistics và quản lý chuỗi cung ứng": "Logistics và quản lý chuỗi cung ứng",
    "kỹ thuật cơ khí": "Kỹ thuật cơ khí",
    "kỹ thuật điện": "Kỹ thuật điện",
    "kỹ thuật ô tô": "Kỹ thuật ô tô",
    "an toàn thông tin": "An toàn thông tin",
    "khoa học môi trường": "Kỹ thuật môi trường",
    "khoa học dữ liệu": "Khoa học dữ liệu",
    "quản lý kinh doanh": "Quản trị kinh doanh",
    "sư phạm ngữ văn": "Sư phạm Văn",
    "sư phạm lịch sử": "Sư phạm Lịch sử",
    "tài chính - ngân hàng": "Tài chính ngân hàng",
    "an toàn lao động/kỹ thuật an toàn": "Kỹ thuật môi trường",
    "thiết kế web/ux": "Thiết kế đồ họa",
    "cơ khí - robot": "Robot và trí tuệ nhân tạo",
    "quản trị nhân sự": "Quản trị nhân lực",
    "phát triển ứng dụng/ứng dụng di động": "Kỹ thuật phần mềm",
    "phiên dịch biên dịch": "Biên - phiên dịch",
    "phien dich bien dich": "Biên - phiên dịch",
}

DESCRIPTION_TEMPLATES: list[tuple[tuple[str, ...], str]] = [
    (("thuc pham",), "Ứng dụng khoa học vào sản xuất, bảo quản, kiểm định an toàn thực phẩm."),
    (("sinh hoc", "cong nghe sinh"), "Nghiên cứu và ứng dụng sinh học trong y dược, môi trường và công nghiệp."),
    (("nong nghiep", "cong nghe nong"), "Ứng dụng kỹ thuật hiện đại trong sản xuất nông nghiệp và chế biến."),
    (("cong nghe thong tin", "phan mem", "may tinh", "lap trinh"), "Ngành đào tạo nền tảng CNTT: lập trình, hệ thống và ứng dụng phần mềm."),
    (("tri tue nhan tao", "du lieu", "thong ke"), "Phân tích dữ liệu, mô hình học máy và ứng dụng AI trong thực tiễn."),
    (("y khoa", "duoc", "dieu duong", "y te"), "Chăm sóc sức khỏe, điều trị và nghiên cứu y sinh; yêu cầu cam kết học tập lâu dài."),
    (("luat",), "Nghiên cứu pháp luật, tố tụng và chính sách; phù hợp người thích lập luận."),
    (("bao chi", "truyen thong", "quang cao", "marketing"), "Sáng tạo nội dung, truyền thông và chiến lược tiếp thị."),
    (("kinh te", "kinh doanh", "tai chinh", "ke toan"), "Phân tích thị trường, quản trị doanh nghiệp và tài chính."),
    (("ngon ngu", "phien dich"), "Sử dụng ngoại ngữ trong giao tiếp, biên phiên dịch và giảng dạy."),
    (("su pham", "giao duc"), "Đào tạo giáo viên và phương pháp giảng dạy các bộ môn."),
    (("kien truc", "thiet ke", "my thuat"), "Thiết kế không gian, sản phẩm và sáng tạo thẩm mỹ."),
    (("ky thuat", "co khi", "dien", "oto", "hang khong"), "Ứng dụng khoa học kỹ thuật vào chế tạo, vận hành hệ thống."),
    (("du lich", "khach san", "nha hang"), "Dịch vụ du lịch, lữ hành và quản trị nhà hàng khách sạn."),
    (("moi truong", "nong nghiep", "lam", "thuy san"), "Bảo vệ môi trường và phát triển nông nghiệp bền vững."),
    (("tam ly", "xa hoi"), "Nghiên cứu hành vi con người và hỗ trợ cộng đồng."),
    (("the duc", "am nhac", "dien anh"), "Đào tạo năng khiệng nghệ thuật và thể thao."),
]

# Gán trường cụ thể (ưu tiên); thiếu sẽ bổ sung từ flatten_domain.
MAJOR_UNIVERSITY_OVERRIDES: dict[str, list[str]] = {
    "Lập trình nhúng và IoT": flatten_domain("tech"),
    "Giáo dục tiểu học": flatten_domain("social"),
    "Giáo dục mầm non": flatten_domain("social"),
    "Tâm lý học giáo dục": flatten_domain("social"),
    "Sư phạm Toán": flatten_domain("social"),
    "Sư phạm Tin học": flatten_domain("tech") + flatten_domain("social"),
    "Sư phạm Văn": flatten_domain("social"),
    "Sư phạm Lịch sử": flatten_domain("social"),
    "Sư phạm Anh": flatten_domain("lang"),
    "Báo chí": flatten_domain("social"),
    "Truyền thông đa phương tiện": flatten_domain("social"),
    "Quảng cáo": flatten_domain("social"),
    "Digital Marketing": flatten_domain("econ"),
    "Marketing": flatten_domain("econ"),
    "Thiết kế game": flatten_domain("tech"),
    "Y khoa": flatten_domain("health"),
    "Dược học": flatten_domain("health"),
    "Điều dưỡng": flatten_domain("health"),
    "Luật": flatten_domain("law"),
    "Luật kinh tế": flatten_domain("law"),
    "Luật quốc tế": flatten_domain("law"),
    "Huấn luyện thể thao": flatten_domain("sport"),
    "Dịch vụ hàng không": flatten_domain("aviation"),
}


def _dedupe_preserve(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for x in items:
        if x not in seen:
            out.append(x)
            seen.add(x)
    return out


def _only_registered(unis: list[str]) -> list[str]:
    return [u for u in unis if u in UNIVERSITIES_REGISTRY]


def _ensure_min_universities(unis: list[str], domain: str) -> list[str]:
    base = _only_registered(_dedupe_preserve(unis))
    if len(base) >= MIN_UNIVERSITIES_PER_MAJOR:
        return base[:MAX_UNIVERSITIES_PER_MAJOR]
    extra = _only_registered(flatten_domain(domain, MAX_UNIVERSITIES_PER_MAJOR))
    merged = _dedupe_preserve(base + extra)
    if len(merged) < MIN_UNIVERSITIES_PER_MAJOR:
        for alt in ("engineering", "tech", "econ", "social"):
            if alt == domain:
                continue
            merged = _dedupe_preserve(
                merged + _only_registered(flatten_domain(alt, MAX_UNIVERSITIES_PER_MAJOR))
            )
            if len(merged) >= MIN_UNIVERSITIES_PER_MAJOR:
                break
    return merged[:MAX_UNIVERSITIES_PER_MAJOR]


DOMAIN_JOB_TRENDS: dict[str, str] = {
    "science": "Tăng",
    "tech_applied": "Cao",
    "tech": "Rất cao",
    "engineering": "Cao",
    "health": "Cao",
    "econ": "Cao",
    "aviation": "Cao",
    "art": "Tăng",
    "social": "Tăng",
    "education": "Tăng",
    "law": "Tăng",
    "lang": "Tăng",
    "tourism": "Tăng",
    "agri": "Trung bình",
    "sport": "Trung bình",
}

DOMAIN_REF_BASE: dict[str, float] = {
    "science": 20.5,
    "tech_applied": 21.0,
    "tech": 22.5,
    "engineering": 21.5,
    "health": 24.0,
    "econ": 20.5,
    "art": 19.0,
    "education": 19.5,
    "social": 20.0,
    "law": 21.0,
    "lang": 20.0,
    "tourism": 19.5,
    "agri": 18.0,
    "sport": 18.5,
    "aviation": 21.5,
}


def infer_job_trends(name: str, existing: str = "") -> str:
    if existing and str(existing).strip():
        return str(existing).strip()
    domain = infer_domain_for_major(norm(name))
    return DOMAIN_JOB_TRENDS.get(domain, "Trung bình")


def infer_reference_score(name: str, existing) -> float:
    if existing is not None and existing != "":
        try:
            v = float(existing)
            if v > 0:
                return round(v, 1)
        except (TypeError, ValueError):
            pass
    domain = infer_domain_for_major(norm(name))
    base = DOMAIN_REF_BASE.get(domain, 20.0)
    jitter = (hash(name) % 7) * 0.15 - 0.45
    return round(max(16.0, min(27.0, base + jitter)), 1)


FAMILY_TO_DOMAIN: dict[str, str] = {
    "it": "tech",
    "science": "engineering",
    "tech_applied": "health",
    "engineering": "engineering",
    "health": "health",
    "econ": "econ",
    "education": "education",
    "social": "social",
    "law": "law",
    "lang": "lang",
    "art": "art",
    "tourism": "tourism",
    "agri": "agri",
    "environment": "agri",
    "sport": "sport",
    "aviation": "aviation",
    "media": "social",
}


def infer_domain_for_major(nl: str) -> str:
    family = infer_major_family(nl)
    if family == "tech_applied" and has_any(nl, "moi truong", "tai nguyen"):
        return "agri"
    return FAMILY_TO_DOMAIN.get(family, "econ")


def norm(s: str) -> str:
    s = s.lower().strip().replace("đ", "d").replace("Đ", "d")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s)
    return s


ALIASES_NORM: dict[str, str] = {norm(k): v for k, v in ALIASES.items()}


def has_any(nl: str, *phrases: str) -> bool:
    return any(norm(p) in nl for p in phrases)


def canonical_name(name: str, catalog_names: dict[str, str]) -> str:
    n = norm(name)
    if n in ALIASES_NORM:
        target = ALIASES_NORM[n]
        return catalog_names.get(norm(target), target)
    if n in catalog_names:
        return catalog_names[n]
    # fuzzy: find best catalog match
    best = None
    best_score = 0
    for cn, display in catalog_names.items():
        if n == cn:
            return display
        if n in cn or cn in n:
            score = len(set(n.split()) & set(cn.split()))
            if score > best_score:
                best_score = score
                best = display
    return best or name.strip()


def infer_description(name: str, existing: str, family: str = "", exam_blocks: list[str] | None = None) -> str:
    return describe_major(name, family=family, exam_blocks=exam_blocks, existing=existing or "")


CAREER_TEMPLATES: list[tuple[tuple[str, ...], list[str]]] = [
    (("thuc pham",), [
        "Kỹ sư công nghệ thực phẩm", "Chuyên viên QA thực phẩm", "Quản lý sản xuất chế biến",
    ]),
    (("sinh hoc",), [
        "Kỹ sư sinh học", "Chuyên viên R&D", "Kỹ thuật viên phòng lab",
    ]),
    (("cong nghe thong tin", "phan mem", "may tinh", "lap trinh", "tri tue", "du lieu"), [
        "Lập trình viên", "Kỹ sư phần mềm", "Kỹ sư hệ thống", "Chuyên viên dữ liệu",
    ]),
    (("ky thuat", "co khi", "dien", "oto", "tu dong", "robot"), [
        "Kỹ sư cơ khí", "Kỹ sư điện", "Kỹ sư tự động hóa",
    ]),
    (("y khoa", "duoc", "dieu duong", "y te", "rang ham", "ho sinh"), [
        "Bác sĩ", "Dược sĩ", "Điều dưỡng viên", "Kỹ thuật viên y tế",
    ]),
    (("bao chi", "truyen thong", "marketing", "quang cao"), [
        "Nhà báo", "Biên tập viên", "Chuyên viên Marketing", "Content creator",
    ]),
    (("kinh te", "kinh doanh", "tai chinh", "ke toan", "logistics"), [
        "Chuyên viên phân tích", "Nhân viên kinh doanh", "Kế toán viên", "Chuyên viên tài chính",
    ]),
    (("luat",), ["Luật sư", "Chuyên viên pháp chế", "Cán bộ tư pháp"]),
    (("su pham", "giao duc"), ["Giáo viên", "Giảng viên", "Chuyên viên giáo dục"]),
    (("du lich", "khach san", "nha hang"), [
        "Hướng dẫn viên du lịch", "Quản lý khách sạn", "Chuyên viên sự kiện",
    ]),
    (("kien truc", "thiet ke", "my thuat"), [
        "Kiến trúc sư", "Thiết kế đồ họa", "Designer sản phẩm",
    ]),
    (("ngon ngu", "phien dich", "bien phien"), [
        "Biên dịch viên", "Phiên dịch viên", "Giảng viên ngoại ngữ",
    ]),
    (("nong nghiep", "moi truong", "thuy san", "thu y"), [
        "Kỹ sư nông nghiệp", "Chuyên viên môi trường", "Quản lý trang trại",
    ]),
    (("tam ly", "xa hoi"), ["Tư vấn viên", "Chuyên viên công tác xã hội"]),
]


def infer_careers(name: str) -> list[str]:
    nl = norm(name)
    if is_it_major_name(nl):
        return [
            "Lập trình viên",
            "Kỹ sư phần mềm",
            "Kỹ sư hệ thống",
            "Chuyên viên dữ liệu",
        ][:6]
    if is_applied_tech_major(nl):
        for keys, careers in CAREER_TEMPLATES:
            if any(k in nl for k in keys):
                return careers[:6]
    for keys, careers in CAREER_TEMPLATES:
        if any(k in nl for k in keys):
            return careers[:6]
    return []


def _default_core_skills(family: str, name: str) -> list[str]:
    nl = norm(name)
    if family == "it":
        return ["lập trình", "tư duy logic", "phân tích"]
    if family == "tech_applied" and has_any(nl, "thuc pham"):
        return ["an toàn thực phẩm", "hóa học", "kiểm định"]
    if family == "health":
        return ["chăm sóc", "sinh học", "giao tiếp"]
    if family == "engineering":
        return ["tư duy logic", "kỹ thuật", "giải quyết vấn đề"]
    if family == "science":
        return ["phân tích", "nghiên cứu", "tư duy logic"]
    if family == "econ":
        return ["phân tích", "giao tiếp", "kinh doanh"]
    if family == "art":
        return ["sáng tạo", "thiết kế", "thẩm mỹ"]
    if family == "education":
        return ["giảng dạy", "giao tiếp", "kiên nhẫn"]
    return []


def infer_wizard_interests(name: str) -> list[str]:
    """Sở thích wizard — đồng bộ với GuidanceService.wizardInterests."""
    nl = norm(name)
    family = infer_major_family(nl)
    tags: list[str] = []

    if family == "it":
        tags.append("Công nghệ")
    if family == "engineering":
        tags.append("Kỹ thuật")
    if family == "health" or (
        family == "tech_applied"
        and has_any(
            nl,
            "y khoa",
            "duoc",
            "dieu duong",
            "rang",
            "vet nghiem",
            "vat ly tri lieu",
            "hinh anh y",
            "ho sinh",
        )
    ):
        tags.append("Y tế")
    if family in ("agri", "environment") or (
        family == "tech_applied"
        and has_any(nl, "nong nghiep", "moi truong", "thuy san", "chan nuoi", "thu y")
    ):
        tags.append("Môi trường")
    if family == "science" and has_any(
        nl, "sinh hoc", "khoa hoc su song", "vat ly hoc", "hoa hoc", "moi truong"
    ):
        tags.append("Môi trường")
    if family == "science" and has_any(nl, "toan", "thong ke", "du lieu"):
        tags.append("Công nghệ")
    if family == "art" or has_any(
        nl, "thiet ke", "my thuat", "kien truc", "dien anh", "nhiep anh", "am nhac"
    ):
        tags.append("Nghệ thuật")
    if family == "education" or has_any(nl, "su pham", "giao duc"):
        tags.append("Giáo dục")
    if family == "econ" or has_any(
        nl,
        "kinh te",
        "marketing",
        "tai chinh",
        "ke toan",
        "thuong mai",
        "logistics",
        "quan tri",
    ):
        tags.append("Kinh tế")
    if family == "media" or has_any(
        nl, "bao chi", "truyen thong", "quang cao", "quan he cong chung"
    ):
        tags.append("Truyền thông")
    if family in ("law", "social") or has_any(
        nl, "luat", "cong tac xa hoi", "tam ly", "nhan van", "viet nam hoc"
    ):
        tags.append("Luật & Xã hội")
    if family in ("tourism", "aviation") or has_any(
        nl, "du lich", "khach san", "nha hang", "hang khong"
    ):
        tags.append("Du lịch")
    if family == "lang" or has_any(nl, "ngon ngu", "phien dich", "bien phien"):
        tags.append("Ngoại ngữ")
    if family == "sport" or has_any(nl, "the duc", "the thao", "huan luyen"):
        tags.append("Thể thao")
    if family == "tech_applied" and not tags:
        if has_any(nl, "thuc pham", "dinh duong"):
            tags.append("Y tế")
        else:
            tags.append("Kỹ thuật")

    return list(dict.fromkeys(tags))


def infer_keywords(name: str, core_skills: list) -> list[str]:
    kws = set()
    for s in core_skills or []:
        if s:
            kws.add(str(s).lower().strip())
    tokens = [t for t in re.split(r"\W+", name.lower()) if len(t) > 2]
    kws.update(tokens)
    nl = norm(name)
    family = infer_major_family(nl)
    if family == "it":
        kws.update(["lập trình", "công nghệ", "cntt", "phần mềm", "máy tính"])
    elif family == "science":
        if has_any(nl, "sinh hoc", "khoa hoc su song"):
            kws.update(["sinh học", "nghiên cứu", "lab"])
        elif has_any(nl, "toan", "thong ke", "du lieu"):
            kws.update(["toán", "thống kê", "phân tích"])
        elif has_any(nl, "vat ly", "hoa hoc"):
            kws.update(["vật lý", "hóa học", "thí nghiệm"])
        kws.discard("cntt")
        kws.discard("lập trình")
    elif family == "tech_applied":
        if has_any(nl, "thuc pham"):
            kws.update(["thực phẩm", "an toàn thực phẩm", "chế biến"])
        elif has_any(nl, "sinh hoc"):
            kws.update(["sinh học", "công nghệ sinh học", "lab"])
        else:
            kws.update(["công nghệ ứng dụng", "kỹ thuật"])
        kws.discard("cntt")
        kws.discard("lập trình")
    elif has_any(nl, "y khoa", "duoc"):
        kws.update(["y tế", "sức khỏe"])
    elif has_any(nl, "marketing"):
        kws.update(["marketing", "quảng cáo"])
    elif has_any(nl, "luat"):
        kws.update(["luật", "pháp luật"])
    elif has_any(nl, "su pham", "giao duc"):
        kws.update(["giáo dục", "giảng dạy"])
    return sorted(kws)


def infer_universities(name: str) -> list[str]:
    if name in MAJOR_UNIVERSITY_OVERRIDES:
        domain = infer_domain_for_major(norm(name))
        return _ensure_min_universities(list(MAJOR_UNIVERSITY_OVERRIDES[name]), domain)
    nkey = norm(name)
    for key, unis in MAJOR_UNIVERSITY_OVERRIDES.items():
        if norm(key) == nkey:
            domain = infer_domain_for_major(nkey)
            return _ensure_min_universities(list(unis), domain)

    nl = norm(name)
    domain = infer_domain_for_major(nl)
    return _ensure_min_universities(flatten_domain(domain), domain)


def build_block_reverse(majors_by_block: dict, catalog_names: dict[str, str]) -> dict[str, set[str]]:
    rev: dict[str, set[str]] = {}
    for block, entry in majors_by_block.items():
        for m in entry.get("majors", []):
            canon = canonical_name(str(m), catalog_names)
            key = norm(canon)
            rev.setdefault(key, set()).add(block.upper())
    return rev


def main() -> None:
    list_path = DATA / "majors_list.json"
    rich_path = ASSETS / "majors.json"
    block_path = DATA / "majors_by_block.json"
    rules_path = ASSETS / "guidance_rules.json"
    opt_rules_path = ASSETS / "guidance_rules_optimized.json"
    uni_path = ASSETS / "major_universities.json"

    majors_list: list[dict] = json.loads(list_path.read_text(encoding="utf-8"))
    rich_list: list[dict] = json.loads(rich_path.read_text(encoding="utf-8"))
    rich_by_norm = {norm(m["name"]): m for m in rich_list}
    # Sửa mã TT09 sai / trùng (ưu tiên hơn major_codes_tt09.json)
    CODE_FIXES: dict[str, str] = {
        "Hướng dẫn du lịch": "7810102",
    }

    codes_path = DATA / "major_codes_tt09.json"
    code_by_name: dict[str, str] = {}
    if codes_path.exists():
        raw_codes = json.loads(codes_path.read_text(encoding="utf-8"))
        if isinstance(raw_codes, dict):
            code_by_name = {str(k): str(v) for k, v in raw_codes.items() if v}
    code_by_name.update(CODE_FIXES)
    legacy_block: dict = json.loads(block_path.read_text(encoding="utf-8"))
    majors_by_block: dict = empty_majors_by_block()
    catalog_names: dict[str, str] = {norm(m["name"]): m["name"] for m in majors_list}
    block_rev = build_block_reverse(legacy_block, catalog_names)

    # Fix block typos
    for block_id, entry in majors_by_block.items():
        fixed = []
        for m in entry.get("majors", []):
            ms = str(m)
            if norm(ms) == norm("Sư phạm Ngữ văn"):
                ms = "Sư phạm Văn"
            if norm(ms) == norm("Kinh tế") and "Kinh tế học" in [x["name"] for x in majors_list]:
                ms = "Kinh tế học"
            fixed.append(ms)
        entry["majors"] = fixed

    # careers theo khối (áp dụng chung cho ngành trong khối)
    block_careers: dict[str, list[str]] = {
        bid: list(entry.get("careers") or []) for bid, entry in majors_by_block.items()
    }

    catalog: list[dict] = []
    for item in majors_list:
        name = item["name"].strip()
        n = norm(name)
        rich = rich_by_norm.get(n, {})
        if n in EXAM_BLOCK_OVERRIDES:
            blocks = set(EXAM_BLOCK_OVERRIDES[n])
        else:
            blocks = set(infer_blocks_for_major(name))
            if not blocks and rich.get("exam_blocks"):
                blocks |= set(filter_known_blocks([str(b) for b in rich["exam_blocks"]]))
            if not blocks:
                blocks |= {b for b in block_rev.get(n, set()) if b in ALL_BLOCKS}
        blocks = sorted(blocks)
        if not blocks:
            blocks = ["D01"]
        core = rich.get("core_skills") or []
        keywords = infer_keywords(name, core)
        unis = infer_universities(name)
        careers: list[str] = list(rich.get("careers") or [])
        if not careers:
            careers = infer_careers(name)
        if not careers and blocks:
            careers = list(block_careers.get(blocks[0], []))[:4]
        careers = list(dict.fromkeys(careers))[:8]
        code = CODE_FIXES.get(name) or rich.get("code") or code_by_name.get(name, "")
        ref_raw = rich.get("reference_score") if rich.get("reference_score") is not None else item.get("reference_score")
        trend_raw = rich.get("job_trends") or item.get("job_trends") or ""
        family = infer_major_family(n)
        desc = infer_description(
            name,
            item.get("description") or rich.get("description", ""),
            family=family,
            exam_blocks=blocks,
        )
        catalog.append({
            "code": code,
            "name": name,
            "family": family,
            "exam_blocks": blocks,
            "reference_score": infer_reference_score(name, ref_raw),
            "core_skills": core if core else _default_core_skills(family, name),
            "job_trends": infer_job_trends(name, trend_raw),
            "keywords": keywords,
            "description": desc,
            "careers": careers,
            "universities": unis,
            "wizard_interests": infer_wizard_interests(name),
        })

    # majors_list.json (slim, for ML / RecommenderService)
    slim_list = [
        {
            "name": m["name"],
            "description": m["description"],
            "keywords": m["keywords"],
            "code": m.get("code", ""),
            "careers": m.get("careers", []),
            "family": m.get("family", ""),
            "exam_blocks": m.get("exam_blocks", []),
        }
        for m in catalog
    ]

    # major_universities.json — keys = catalog names
    uni_map: dict[str, list[str]] = {}
    for m in catalog:
        if m["universities"]:
            uni_map[m["name"]] = m["universities"]

    # Normalize guidance_rules.json
    rules = json.loads(rules_path.read_text(encoding="utf-8"))
    for rule in rules:
        boosts = rule.get("boostMajors") or {}
        new_boosts = {}
        for k, v in boosts.items():
            canon = canonical_name(k, catalog_names)
            new_boosts[canon] = v
        rule["boostMajors"] = new_boosts

    # Normalize guidance_rules_optimized.json
    opt_rules = json.loads(opt_rules_path.read_text(encoding="utf-8"))
    orphan_rules: list[str] = []
    for rule in opt_rules:
        if rule.get("major"):
            before = rule["major"]
            rule["major"] = canonical_name(rule["major"], catalog_names)
            mn = norm(rule["major"])
            if mn in catalog_names:
                rule["family"] = infer_major_family(mn)
            if mn not in catalog_names:
                orphan_rules.append(f"{rule.get('id')}: {before} -> {rule['major']}")
    if orphan_rules:
        print(f"WARNING: {len(orphan_rules)} optimized rules with weak catalog match (see validate script)")

    for block_id in BLOCK_UI_ORDER:
        domain = BLOCK_UNI_DOMAIN.get(block_id, "econ")
        unis = _dedupe_preserve(flatten_domain(domain, 12))
        majors_by_block[block_id]["universities"] = unis[:8]
        majors_by_block[block_id]["careers"] = list(BLOCK_CAREERS.get(block_id, []))

    # majors_by_block: danh sách ngành theo từng khối từ catalog
    for block_id in BLOCK_UI_ORDER:
        majors_by_block[block_id]["majors"] = [
            m["name"] for m in catalog if block_id in (m.get("exam_blocks") or [])
        ]

    exam_blocks_meta = {
        "version": 1,
        "order": BLOCK_UI_ORDER,
        "blocks": [{"id": bid, "subjects": BLOCK_SUBJECTS[bid]} for bid in BLOCK_UI_ORDER],
    }
    (DATA / "exam_blocks.json").write_text(
        json.dumps(exam_blocks_meta, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    catalog_doc = {"version": 2, "updated": "auto", "majors": catalog}

    out_catalog = DATA / "majors_catalog.json"
    out_catalog.write_text(json.dumps(catalog_doc, ensure_ascii=False, indent=2), encoding="utf-8")
    list_path.write_text(json.dumps(slim_list, ensure_ascii=False, indent=2), encoding="utf-8")
    block_path.write_text(json.dumps(majors_by_block, ensure_ascii=False, indent=2), encoding="utf-8")
    rules_path.write_text(json.dumps(rules, ensure_ascii=False, indent=2), encoding="utf-8")
    opt_rules_path.write_text(json.dumps(opt_rules, ensure_ascii=False, indent=2), encoding="utf-8")
    uni_path.write_text(json.dumps(uni_map, ensure_ascii=False, indent=2), encoding="utf-8")

    ML_ARTIFACTS.mkdir(parents=True, exist_ok=True)
    (ML_ARTIFACTS / "majors_list.json").write_text(
        json.dumps(slim_list, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    # Cập nhật assets/majors.json — toàn bộ catalog (định dạng rich, dùng làm tham chiếu mở rộng)
    rich_export = [
        {
            "code": m.get("code") or "",
            "name": m["name"],
            "exam_blocks": m["exam_blocks"],
            "reference_score": m.get("reference_score"),
            "core_skills": m.get("core_skills") or [],
            "job_trends": m.get("job_trends") or "",
            "description": m["description"],
        }
        for m in catalog
    ]
    rich_path.write_text(json.dumps(rich_export, ensure_ascii=False, indent=2), encoding="utf-8")

    registry_path = DATA / "universities_registry.json"
    write_registry_json(registry_path)

    codes_out = {m["name"]: m["code"] for m in catalog if m.get("code")}
    codes_path.write_text(
        json.dumps(codes_out, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    with_desc = sum(1 for m in catalog if len(m.get("description", "")) > 25)
    with_blocks = sum(1 for m in catalog if m.get("exam_blocks"))
    uni_counts = [len(m.get("universities") or []) for m in catalog]
    print(f"Universities in registry: {len(UNIVERSITIES_REGISTRY)}")
    print(f"Catalog: {len(catalog)} majors")
    print(f"  universities per major: min={min(uni_counts)} avg={sum(uni_counts)/len(uni_counts):.1f} max={max(uni_counts)}")
    print(f"  with description: {with_desc}")
    print(f"  with exam_blocks: {with_blocks}")
    print(f"  universities keys: {len(uni_map)}")
    print(f"  rules normalized: {len(rules)}, optimized: {len(opt_rules)}")
    print("Written:", out_catalog, list_path, uni_path, ML_ARTIFACTS / "majors_list.json")


if __name__ == "__main__":
    main()
