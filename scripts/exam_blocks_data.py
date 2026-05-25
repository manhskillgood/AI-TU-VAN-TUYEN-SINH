"""Định nghĩa khối thi THPT và quy tắc gán khối cho từng ngành (catalog build)."""

from __future__ import annotations

import re
import unicodedata

# Thứ tự hiển thị trên wizard (Flutter dùng cùng thứ tự trong exam_block_utils).
BLOCK_UI_ORDER: list[str] = [
    "A00",
    "A01",
    "A02",
    "B00",
    "B03",
    "H00",
    "C00",
    "C01",
    "C14",
    "C15",
    "D01",
    "D07",
    "D14",
    "D15",
    "K00",
    "K01",
]

BLOCK_SUBJECTS: dict[str, list[str]] = {
    "A00": ["Toán", "Vật lý", "Hóa học"],
    "A01": ["Toán", "Vật lý", "Tiếng Anh"],
    "A02": ["Toán", "Vật lý", "Sinh học"],
    "B00": ["Toán", "Hóa học", "Sinh học"],
    "B03": ["Toán", "Hóa học", "Tiếng Anh"],
    "C00": ["Ngữ văn", "Lịch sử", "Địa lý"],
    "C01": ["Ngữ văn", "Lịch sử", "Giáo dục công dân"],
    "C14": ["Ngữ văn", "Lịch sử", "Tiếng Anh"],
    "C15": ["Ngữ văn", "Địa lý", "Tiếng Anh"],
    "D01": ["Toán", "Ngữ văn", "Tiếng Anh"],
    "D07": ["Toán", "Hóa học", "Tiếng Anh"],
    "D14": ["Ngữ văn", "Lịch sử", "Tiếng Anh"],
    "D15": ["Ngữ văn", "Địa lý", "Tiếng Anh"],
    "H00": ["Hóa học", "Sinh học", "Tiếng Anh"],
    "K00": ["Ngữ văn", "Toán", "Vẽ (năng khiếu)"],
    "K01": ["Ngữ văn", "Vẽ (năng khiếu)", "Mỹ thuật"],
}

ALL_BLOCKS: frozenset[str] = frozenset(BLOCK_SUBJECTS.keys())

# Gợi ý nghề / domain trường theo khối (majors_by_block metadata).
BLOCK_CAREERS: dict[str, list[str]] = {
    "A00": ["Kỹ sư", "Lập trình viên", "Nhà khoa học"],
    "A01": ["Kỹ sư CNTT", "Chuyên viên quốc tế", "Kỹ sư điện tử"],
    "A02": ["Kỹ sư sinh học", "Kỹ sư môi trường", "Nhà nghiên cứu"],
    "B00": ["Bác sĩ", "Dược sĩ", "Kỹ sư nông nghiệp"],
    "B03": ["Dược sĩ", "Kỹ thuật viên y tế", "Chuyên viên phòng lab"],
    "C00": ["Nhà báo", "Luật sư", "Giáo viên", "Chuyên viên xã hội"],
    "C01": ["Giáo viên", "Cán bộ nhà nước", "Chuyên viên giáo dục"],
    "C14": ["Biên tập viên", "Phiên dịch viên", "Chuyên viên truyền thông"],
    "C15": ["Hướng dẫn viên du lịch", "Chuyên viên quan hệ quốc tế"],
    "D01": ["Chuyên viên kinh doanh", "Kế toán", "Giảng viên ngoại ngữ"],
    "D07": ["Chuyên viên tài chính", "Phân tích dữ liệu", "Marketing"],
    "D14": ["Nhà báo", "Luật sư", "Biên dịch viên"],
    "D15": ["Quản lý du lịch", "Chuyên viên logistics", "Marketing"],
    "H00": ["Dược sĩ", "Kỹ thuật viên y tế", "Chuyên viên phòng lab"],
    "K00": ["Kiến trúc sư", "Thiết kế đồ họa", "Designer sản phẩm"],
    "K01": ["Họa sĩ", "Nhà thiết kế", "Nghệ sĩ"],
}

BLOCK_UNI_DOMAIN: dict[str, str] = {
    "A00": "tech",
    "A01": "tech",
    "A02": "engineering",
    "B00": "health",
    "B03": "health",
    "C00": "social",
    "C01": "social",
    "C14": "lang",
    "C15": "tourism",
    "D01": "econ",
    "D07": "econ",
    "D14": "social",
    "D15": "tourism",
    "H00": "health",
    "K00": "art",
    "K01": "art",
}

# Gán chính xác cho một số ngành (ưu tiên cao nhất).
EXAM_BLOCK_OVERRIDES_RAW: dict[str, list[str]] = {
    "Hệ thống thông tin": ["A00", "A01", "D07"],
    "Công nghệ thông tin": ["A00", "A01", "D07"],
    "Kỹ thuật phần mềm": ["A00", "A01"],
    "Khoa học máy tính": ["A00", "A01", "A02"],
    "Trí tuệ nhân tạo": ["A00", "A01", "D07"],
    "Khoa học dữ liệu": ["A00", "A01", "D07"],
    "An toàn thông tin": ["A00", "A01"],
    "Cơ điện tử": ["A00", "A01", "A02"],
    "Y khoa": ["B00", "B03", "H00"],
    "Dược học": ["B00", "B03", "H00"],
    "Điều dưỡng": ["B00", "B03", "H00"],
    "Răng học": ["B00", "B03"],
    "Hộ sinh": ["B00"],
    "Sinh học": ["B00", "A02"],
    "Sư phạm Toán": ["A00", "A01"],
    "Sư phạm Tin học": ["A00", "A01", "D01"],
    "Sư phạm Anh": ["D01", "C14", "D14"],
    "Sư phạm Văn": ["C00", "C01", "C14"],
    "Sư phạm Lịch sử": ["C00", "C01", "C14"],
    "Giáo dục tiểu học": ["C00", "C01", "D01"],
    "Giáo dục mầm non": ["C00", "C01"],
    "Luật": ["C00", "C14", "D14"],
    "Luật kinh tế": ["C00", "D01", "D14"],
    "Luật quốc tế": ["C00", "C14", "D14", "D01"],
    "Báo chí": ["C00", "C14", "D14"],
    "Truyền thông đa phương tiện": ["C00", "C14", "D01"],
    "Quảng cáo": ["C00", "D01", "C14"],
    "Digital Marketing": ["D01", "D07", "C14"],
    "Marketing": ["D01", "D07", "C14"],
    "Quản trị kinh doanh": ["D01", "D07"],
    "Kế toán": ["D01", "D07"],
    "Tài chính ngân hàng": ["D01", "D07"],
    "Thiết kế game": ["A00", "A01", "D01"],
    "Kiến trúc": ["A00", "K00", "D01"],
    "Thiết kế đồ họa": ["K00", "K01", "D01", "C15"],
    "Thiết kế thời trang": ["K00", "K01", "D01"],
    "Thiết kế nội thất": ["K00", "K01", "D01", "D15"],
    "Thiết kế công nghiệp": ["K00", "K01", "A00", "D01"],
    "Mỹ thuật ứng dụng": ["K01", "K00", "C00"],
    "Mỹ thuật": ["K01", "C00"],
    "Điện ảnh": ["C00", "C14", "K01"],
    "Âm nhạc": ["K01", "C14", "D01"],
    "Nhiếp ảnh": ["K01", "C00", "D01", "C15"],
    "Du lịch": ["C00", "C15", "D15"],
    "Hướng dẫn du lịch": ["C15", "D15", "C00"],
    "Quản trị khách sạn": ["D01", "C15", "D15"],
    "Quan hệ quốc tế": ["C00", "C14", "D14", "D01"],
    "Ngôn ngữ Anh": ["D01", "C14", "D14"],
    "Ngôn ngữ Trung Quốc": ["D01", "C14", "D14"],
    "Biên - Phiên dịch": ["D01", "C14", "D14"],
    "Kỹ thuật môi trường": ["A00", "A02", "B00"],
    "Quản lý tài nguyên môi trường": ["B00", "A02", "C00"],
    "Nông nghiệp": ["B00", "A02"],
    "Thú y": ["B00"],
    "Huấn luyện thể thao": ["C00", "B00"],
    "Dịch vụ hàng không": ["A00", "A01", "D01"],
    "Công nghệ thực phẩm": ["B00", "B03", "H00", "D07"],
    "Công nghệ sinh học": ["B00", "A02", "B03", "H00"],
    "Công nghệ nông nghiệp": ["B00", "A02", "B03"],
    "Công nghệ hóa học": ["A00", "B00", "B03", "D07"],
    "Công nghệ xét nghiệm": ["B00", "B03", "H00"],
    "Kỹ thuật xét nghiệm y học": ["B00", "B03", "H00"],
    "Công nghệ chế biến thực phẩm": ["B00", "B03", "H00", "D07"],
    "Xuất bản": ["C00", "C14"],
    "Quy hoạch đô thị": ["C00", "A00"],
    "Biên kịch": ["C00", "C14"],
    "Nhiếp ảnh": ["C00", "D01", "C15"],
    "Quản trị nhân lực": ["D01", "C00"],
    "Kiểm toán": ["D01", "D07"],
    "Bất động sản": ["D01", "C00"],
}


def norm(s: str) -> str:
    s = s.lower().strip().replace("đ", "d").replace("Đ", "d")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s)
    return s


EXAM_BLOCK_OVERRIDES: dict[str, list[str]] = {
    norm(k): [b.upper() for b in v if b.upper() in ALL_BLOCKS]
    for k, v in EXAM_BLOCK_OVERRIDES_RAW.items()
}


def _has(nl: str, *phrases: str) -> bool:
    return any(norm(p) in nl for p in phrases)


def is_it_major_name(nl: str) -> bool:
    """CNTT / phần mềm / AI — không gồm Công nghệ thực phẩm, sinh học, ..."""
    if _has(
        nl,
        "thuc pham",
        "sinh hoc",
        "nong nghiep",
        "moi truong",
        "xet nghiem",
        "che bien",
        "dinh duong",
    ):
        return False
    return _has(
        nl,
        "thong tin",
        "phan mem",
        "may tinh",
        "tri tue nhan tao",
        "an toan thong tin",
        "he thong thong tin",
        "khoa hoc du lieu",
        "khoa hoc may tinh",
        "ky thuat may tinh",
        "lap trinh",
        "iot",
        "nhung",
        "game",
        "mang may tinh",
    )


def is_applied_tech_major(nl: str) -> bool:
    return _has(nl, "cong nghe") and not is_it_major_name(nl)


def infer_major_family(nl: str) -> str:
    """Nhãn chuẩn cho catalog + ML + wizard."""
    if is_it_major_name(nl):
        return "it"
    if is_applied_tech_major(nl):
        return "tech_applied"
    if _has(nl, "y khoa", "duoc", "dieu duong", "rang ham", "rang hoc", "ho sinh", "vet nghiem y", "hinh anh y", "vat ly tri lieu"):
        return "health"
    if _has(nl, "luat"):
        return "law"
    if _has(nl, "bao chi", "truyen thong", "quan he cong chung", "quang cao"):
        return "media"
    if _has(nl, "ngon ngu", "phien dich", "bien phien"):
        return "lang"
    if _has(nl, "thiet ke", "kien truc", "my thuat", "dien anh", "nhiep anh", "bien kich", "am nhac"):
        return "art"
    if _has(nl, "du lich", "khach san", "nha hang", "huong dan du lich"):
        return "tourism"
    if _has(nl, "the duc", "the thao", "huan luyen the thao"):
        return "sport"
    if _has(nl, "hang khong", "dich vu hang khong"):
        return "aviation"
    if _has(nl, "nong nghiep", "lam nghiep", "thuy san", "chan nuoi", "thu y"):
        return "agri"
    if _has(nl, "moi truong", "tai nguyen"):
        return "environment"
    if _has(nl, "ky thuat", "co khi", "dien", "oto", "tu dong", "robot", "co dien", "xay dung", "dien tu"):
        return "engineering"
    if _has(nl, "kinh te", "kinh doanh", "tai chinh", "ke toan", "marketing", "logistics", "quan tri", "thuong mai"):
        return "econ"
    if _has(nl, "su pham", "giao duc", "viet nam hoc", "dong phuong"):
        return "education"
    if _has(nl, "tam ly", "xa hoi", "nhan van", "cong tac xa hoi"):
        return "social"
    if _has(nl, "sinh hoc", "vat ly hoc", "hoa hoc", "toan hoc", "thong ke", "khoa hoc su song"):
        if not is_applied_tech_major(nl):
            return "science"
    return "econ"


def infer_domain_for_blocks(nl: str) -> str:
    """Domain đơn giản (đồng bộ với build_majors_catalog.infer_domain_for_major)."""
    if _has(nl, "y khoa", "duoc", "dieu duong", "y te", "rang ham", "rang hoc", "ho sinh", "vet nghiem y", "hinh anh y", "vat ly tri lieu"):
        return "health"
    if _has(nl, "luat"):
        return "law"
    if _has(nl, "bao chi", "truyen thong", "quan he cong chung", "quang cao"):
        return "social"
    if _has(nl, "ngon ngu", "phien dich", "bien phien"):
        return "lang"
    if _has(nl, "thiet ke", "kien truc", "my thuat", "dien anh", "nhiep anh", "bien kich", "am nhac"):
        return "art"
    if _has(nl, "du lich", "khach san", "nha hang", "huong dan du lich"):
        return "tourism"
    if _has(nl, "the duc", "the thao", "huan luyen the thao"):
        return "sport"
    if _has(nl, "hang khong", "dich vu hang khong"):
        return "aviation"
    if _has(nl, "nong nghiep", "lam nghiep", "thuy san", "chan nuoi", "thu y", "moi truong", "tai nguyen"):
        return "agri"
    if is_it_major_name(nl):
        return "tech"
    if is_applied_tech_major(nl):
        return "health" if _has(nl, "thuc pham", "dinh duong", "xet nghiem") else "agri"
    if _has(nl, "ky thuat", "co khi", "dien", "oto", "tu dong", "robot", "co dien", "xay dung", "dien tu"):
        return "engineering"
    if _has(nl, "kinh te", "kinh doanh", "tai chinh", "ke toan", "marketing", "logistics", "quan tri", "thuong mai"):
        return "econ"
    if _has(nl, "su pham", "giao duc", "tam ly", "xa hoi", "viet nam hoc", "dong phuong"):
        return "social"
    return "econ"


DOMAIN_TO_BLOCKS: dict[str, list[str]] = {
    "tech": ["A00", "A01", "A02", "D07"],
    "tech_applied": ["B00", "B03", "H00", "D07"],
    "engineering": ["A00", "A01", "A02"],
    "health": ["B00", "B03", "H00"],
    "econ": ["D01", "D07"],
    "social": ["C00", "C01", "C14", "D14"],
    "law": ["C00", "C14", "D01", "D14"],
    "lang": ["D01", "C14", "D14", "D15"],
    "art": ["K00", "K01", "D01", "C15", "D15"],
    "agri": ["B00", "A02", "B03"],
    "tourism": ["C00", "C15", "D15", "D01"],
    "sport": ["C00", "B00"],
    "aviation": ["A00", "A01", "D01"],
}


def _refine_blocks(nl: str, blocks: set[str]) -> set[str]:
    """Loại khối không phù hợp sau khi gán theo domain."""
    pure_health = _has(
        nl,
        "y khoa",
        "duoc",
        "dieu duong",
        "rang ham",
        "rang hoc",
        "ho sinh",
        "dinh duong",
        "vet nghiem y",
        "hinh anh y",
        "sinh hoc y duoc",
        "vat ly tri lieu",
    )
    pure_tech = _has(
        nl,
        "cong nghe thong tin",
        "phan mem",
        "may tinh",
        "lap trinh",
        "tri tue nhan tao",
        "khoa hoc du lieu",
        "an toan thong tin",
        "he thong thong tin",
        "iot",
        "game",
        "nhung",
    ) and not _has(nl, "su pham", "nong nghiep cong nghe")
    pure_engineering = _has(nl, "ky thuat", "co khi", "dien", "oto", "tu dong", "robot", "co dien") and not _has(
        nl, "moi truong", "nong nghiep"
    )
    humanities = _has(
        nl,
        "bao chi",
        "luat",
        "su pham van",
        "su pham lich",
        "su pham su",
        "tam ly",
        "cong tac xa hoi",
        "dong phuong",
        "viet nam hoc",
        "xa hoi hoc",
        "giao duc tieu hoc",
        "giao duc mam non",
    )
    lang_major = _has(nl, "ngon ngu", "phien dich", "bien phien", "su pham anh")
    su_pham_toan_tin = _has(nl, "su pham toan") or (_has(nl, "su pham") and _has(nl, "tin"))
    su_pham_van_lich = _has(nl, "su pham van") or _has(nl, "su pham lich") or _has(nl, "su pham su")

    pure_art = _has(
        nl,
        "thiet ke do hoa",
        "thiet ke thoi trang",
        "thiet ke noi that",
        "thiet ke cong nghiep",
        "my thuat",
        "kien truc",
        "dien anh",
        "nhiep anh",
        "bien kich",
        "am nhac",
    ) and not _has(nl, "thiet ke game", "game")
    if pure_health:
        blocks &= {"B00", "B03", "H00"}
        if _has(nl, "duoc", "dinh duong", "duoc ly"):
            blocks.add("H00")
    if pure_art:
        if _has(nl, "kien truc"):
            blocks = {"A00", "K00", "D01"}
        elif _has(nl, "am nhac"):
            blocks = {"K01", "C14", "D01"}
        else:
            blocks = {"K00", "K01", "D01", "C15", "D15"}
    if pure_tech or pure_engineering:
        blocks -= {"C00", "C01", "C14", "C15", "D14", "D15"}
        if pure_tech:
            blocks.update({"A00", "A01"})
    if humanities and not _has(nl, "marketing", "digital marketing", "tai chinh", "ke toan"):
        blocks -= {"A00", "A01", "A02", "B00", "B03", "D07"}
    if lang_major:
        blocks.update({"D01", "C14", "D14"})
        blocks -= {"A00", "A02", "B00"}
    if su_pham_toan_tin:
        blocks &= {"A00", "A01", "D01"}
    if su_pham_van_lich:
        blocks &= {"C00", "C01", "C14", "D14", "D01"}
    if _has(nl, "nong nghiep", "thuy san", "chan nuoi", "thu y", "lam nghiep"):
        blocks.update({"B00", "A02"})
        blocks -= {"C14", "D14"}
    if is_applied_tech_major(nl):
        blocks -= {"A00", "A01", "C00", "C14", "D14"}
        blocks.update({"B00", "B03", "H00", "D07"})
        if _has(nl, "thuc pham", "dinh duong"):
            blocks.update({"B00", "H00"})
    if _has(nl, "du lich", "khach san", "nha hang"):
        blocks.update({"C00", "C15", "D15", "D01"})
    if _has(nl, "marketing", "digital marketing", "quang cao"):
        blocks.update({"D01", "D07", "C14"})
    return blocks


def infer_blocks_for_major(name: str) -> list[str]:
    """Gán khối thi cho ngành (danh sách mã khối, đã lọc ALL_BLOCKS)."""
    nkey = norm(name)
    if nkey in EXAM_BLOCK_OVERRIDES:
        return list(EXAM_BLOCK_OVERRIDES[nkey])

    nl = nkey
    domain = infer_domain_for_blocks(nl)
    blocks: set[str] = set(DOMAIN_TO_BLOCKS.get(domain, ["D01"]))

    if _has(nl, "toan hoc", "toan ung dung", "thong ke"):
        blocks.update(["A00", "A01", "D07"])
    if _has(nl, "vat ly hoc", "hoa hoc"):
        blocks.update(["A00", "B00"])
    if _has(nl, "sinh hoc") and not _has(nl, "su pham"):
        blocks.update(["B00", "A02"])

    blocks = _refine_blocks(nl, blocks)
    if not blocks:
        blocks = {"D01"}
    return sorted(b for b in blocks if b in ALL_BLOCKS)


def filter_known_blocks(blocks: list[str]) -> list[str]:
    return sorted({str(b).upper() for b in blocks if str(b).upper() in ALL_BLOCKS})


def empty_majors_by_block() -> dict:
    return {
        bid: {
            "majors": [],
            "careers": list(BLOCK_CAREERS.get(bid, [])),
            "universities": [],
        }
        for bid in BLOCK_UI_ORDER
    }
