"""Mô tả ngành chuẩn — thay template chung, dùng trong build_majors_catalog."""
from __future__ import annotations

import re
import unicodedata

GENERIC_MARKERS = (
    "đào tạo kiến thức chuyên môn và kỹ năng nghề nghiệp phù hợp lĩnh vực",
    "đào tạo kiến thức chuyên môn",
)


def norm(s: str) -> str:
    s = s.lower().strip().replace("đ", "d").replace("Đ", "d")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\s+", " ", s)
    return s


def is_generic_description(text: str) -> bool:
    if not text or len(text.strip()) < 25:
        return True
    t = text.lower()
    return any(m in t for m in GENERIC_MARKERS)


def _has(nl: str, *phrases: str) -> bool:
    return any(norm(p) in nl for p in phrases)


# Mô tả theo tên chuẩn (norm). Bổ sung đủ 122 ngành trong catalog.
MAJOR_DESCRIPTIONS: dict[str, str] = {
    "cong nghe thong tin": "Nền tảng CNTT: lập trình, cơ sở dữ liệu, mạng và an toàn thông tin; mở đường cho kỹ sư phần mềm, devops và data.",
    "ky thuat phan mem": "Tập trung vòng đời phần mềm — phân tích yêu cầu, thiết kế, lập trình, kiểm thử và triển khai sản phẩm số.",
    "khoa hoc may tinh": "Lý thuyết máy tính, thuật toán và hệ thống; phù hợp người thích tư duy trừu tượng và nghiên cứu.",
    "tri tue nhan tao": "Học máy, học sâu và ứng dụng AI vào sản phẩm, tự động hóa và phân tích dữ liệu lớn.",
    "khoa hoc du lieu": "Thu thập, làm sạch, phân tích và trực quan hóa dữ liệu; nền cho data analyst và data engineer.",
    "an toan thong tin": "Bảo mật hệ thống, mã hóa, SOC và quản trị rủi ro an ninh mạng doanh nghiệp.",
    "he thong thong tin": "Quản trị hạ tầng CNTT, ERP, quy trình nghiệp vụ số và tích hợp hệ thống doanh nghiệp.",
    "mang may tinh va truyen thong du lieu": "Thiết kế mạng, truyền dẫn, cloud và vận hành hạ tầng viễn thông.",
    "ky thuat may tinh": "Phần cứng máy tính, nhúng và kiến trúc hệ thống; gần kỹ thuật điện–điện tử.",
    "lap trinh nhung va iot": "Lập trình firmware, cảm biến, IoT và hệ thống nhúng trong công nghiệp 4.0.",
    "thiet ke game": "Kết hợp lập trình game, đồ họa và thiết kế trải nghiệm người chơi.",
    "cong nghe da phuong tien": "Sản xuất nội dung số, đồ họa, âm thanh–hình ảnh và truyền thông đa phương tiện.",
    "thuong mai dien tu": "Vận hành sàn TMĐT, marketing số và logistics cho thương mại trực tuyến.",
    "toan hoc": "Toán thuần — đại số, giải tích, xác suất; nền cho nghiên cứu, tài chính định lượng và CNTT.",
    "toan ung dung": "Ứng dụng toán vào mô hình kinh tế, tối ưu, thống kê và khoa học dữ liệu.",
    "thong ke": "Thu thập dữ liệu, ước lượng và kiểm định giả thuyết; nền cho phân tích kinh tế–xã hội.",
    "khoa hoc du lieu thong ke": "Kết hợp thống kê hiện đại và khoa học dữ liệu cho quyết định dựa trên số liệu.",
    "vat ly hoc": "Nghiên cứu vật lý cơ bản; nền cho kỹ thuật, vật liệu và công nghệ cao.",
    "ky thuat vat ly": "Ứng dụng vật lý trong thiết bị, đo lường và công nghiệp chính xác.",
    "cong nghe vat lieu": "Phát triển và kiểm định vật liệu mới trong cơ khí, điện tử và xây dựng.",
    "co dien tu": "Tích hợp cơ khí, điện tử và điều khiển trong robot và dây chuyền sản xuất.",
    "ky thuat co khi": "Thiết kế, chế tạo và bảo trì máy móc, ô tô, năng lượng và sản xuất.",
    "ky thuat o to": "Kỹ thuật động cơ, khung gầm và hệ thống điện–điều khiển trên ô tô.",
    "ky thuat hang khong": "Thiết kế, bảo dưỡng và vận hành kết cấu, động cơ hàng không.",
    "ky thuat dien": "Hệ thống điện công nghiệp, năng lượng tái tạo và tự động hóa nhà máy.",
    "ky thuat dien tu vien thong": "Mạch điện tử, viễn thông, RF và thiết bị truyền thông.",
    "ky thuat dieu khien va tu dong hoa": "PLC, SCADA, robot công nghiệp và điều khiển tự động.",
    "robot va tri tue nhan tao": "Robot học, thị giác máy tính và AI cho tự động hóa thông minh.",
    "hoa hoc": "Hóa lý, hóa hữu cơ và phân tích; nền cho dược, vật liệu và môi trường.",
    "cong nghe hoa hoc": "Ứng dụng hóa học trong sản xuất công nghiệp, dược phẩm và năng lượng.",
    "cong nghe thuc pham": "Kiểm soát chất lượng, chế biến và an toàn vệ sinh thực phẩm — không phải lập trình CNTT.",
    "cong nghe sinh hoc": "Ứng dụng sinh học phân tử trong lab, dược và công nghiệp sinh học.",
    "ky thuat moi truong": "Xử lý nước thải, khí thải và công nghệ xanh trong sản xuất.",
    "quan ly tai nguyen moi truong": "Quy hoạch, giám sát tài nguyên và chính sách môi trường bền vững.",
    "sinh hoc": "Nghiên cứu sự sống ở tế bào–quần thể; nền cho y sinh, môi trường và R&D.",
    "cong nghe sinh hoc y duoc": "Sinh học phục vụ dược phẩm, xét nghiệm và sản xuất sinh phẩm y tế.",
    "cong nghe xet nghiem": "Kỹ thuật xét nghiệm lâm sàng, thiết bị lab và quy trình chẩn đoán.",
    "khoa hoc su song": "Tổng hợp sinh học, hóa sinh và phương pháp nghiên cứu đa ngành.",
    "y khoa": "Đào tạo bác sĩ — lâm sàng, chẩn đoán và điều trị; yêu cầu học tập dài hạn.",
    "rang ham mat": "Nha khoa lâm sàng, phục hình và điều trị răng–hàm–mặt.",
    "duoc hoc": "Dược lý, bào chế và tư vấn sử dụng thuốc an toàn.",
    "dieu duong": "Chăm sóc người bệnh, hỗ trợ điều trị và quản lý điều dưỡng lâm sàng.",
    "ky thuat xet nghiem y hoc": "Vận hành máy xét nghiệm và quy trình kiểm tra mẫu bệnh phẩm.",
    "ky thuat hinh anh y hoc": "Chụp X-quang, CT, MRI và kỹ thuật chẩn đoán hình ảnh.",
    "y te cong cong": "Epidemiology, phòng chống dịch và quản lý sức khỏe cộng đồng.",
    "dinh duong": "Tư vấn dinh dưỡng lâm sàng và chế độ ăn phòng bệnh.",
    "vat ly tri lieu": "Phục hồi chức năng vận động bằng vật lý trị liệu và kỹ thuật y sinh.",
    "ho sinh": "Hỗ trợ sinh sản an toàn trong đẻ và chăm sóc sơ sinh.",
    "luat": "Hệ thống pháp luật Việt Nam, tố tụng và tư vấn pháp lý.",
    "luat kinh te": "Pháp luật doanh nghiệp, hợp đồng thương mại và tranh chấp kinh tế.",
    "luat quoc te": "Luật quốc tế, thương mại xuyên biên giới và tổ chức quốc tế.",
    "kinh te hoc": "Lý thuyết kinh tế vĩ mô–vi mô và phân tích chính sách.",
    "kinh te quoc te": "Thương mại, FDI và kinh tế toàn cầu.",
    "kinh doanh quoc te": "Xuất nhập khẩu, logistics quốc tế và văn hóa kinh doanh.",
    "quan tri kinh doanh": "Chiến lược, vận hành và quản trị doanh nghiệp.",
    "quan tri nhan luc": "Tuyển dụng, đào tạo và phát triển nguồn nhân lực.",
    "marketing": "Nghiên cứu thị trường, thương hiệu và chiến dịch tiếp thị.",
    "digital marketing": "SEO, quảng cáo số, social media và phân tích hành vi khách hàng.",
    "tai chinh ngan hang": "Tín dụng, đầu tư và quản trị rủi ro tài chính.",
    "ke toan": "Ghi chép, báo cáo tài chính và tuân thủ kế toán–thuế.",
    "kiem toan": "Kiểm toán độc lập, nội bộ và đánh giá minh bạch tài chính.",
    "phan tich dau tu tai chinh": "Phân tích chứng khoán, danh mục và công cụ tài chính.",
    "chung khoan": "Môi giới, phân tích thị trường và dịch vụ chứng khoán.",
    "bao hiem": "Sản phẩm bảo hiểm, bồi thường và quản trị rủi ro.",
    "logistics va quan ly chuoi cung ung": "Vận tải, kho bãi và tối ưu chuỗi cung ứng.",
    "quan tri logistics": "Điều phối vận hành logistics và hợp đồng vận chuyển.",
    "thuong mai quoc te": "Xuất nhập khẩu, Incoterms và thương lượng hợp đồng.",
    "bat dong san": "Định giá, môi giới và phát triển dự án bất động sản.",
    "quan ly du an": "Lập kế hoạch, giám sát tiến độ và quản trị dự án.",
    "quan tri van phong": "Hành chính, thư ký điều hành và quy trình văn phòng.",
    "du lich": "Lữ hành, điểm đến và phát triển sản phẩm du lịch.",
    "quan tri khach san": "Vận hành khách sạn, lễ tân và trải nghiệm lưu trú.",
    "quan tri nha hang": "Ẩm thực, F&B và quản lý nhà hàng–dịch vụ ăn uống.",
    "huong dan du lich": "Thuyết minh, tour và dịch vụ hướng dẫn viên chuyên nghiệp.",
    "dich vu hang khong": "Tiếp viên, dịch vụ sân bay và vận hành hàng không thương mại.",
    "ngon ngu anh": "Tiếng Anh học thuật, giao tiếp và biên phiên dịch.",
    "ngon ngu trung": "Tiếng Trung thương mại và văn hóa Trung Hoa.",
    "ngon ngu nhat": "Tiếng Nhật cho doanh nghiệp và du học.",
    "ngon ngu han": "Tiếng Hàn cho giao tiếp và làm việc với doanh nghiệp Hàn Quốc.",
    "ngon ngu phap": "Tiếng Pháp và văn hóa Pháp ngữ.",
    "ngon ngu duc": "Tiếng Đức cho kỹ thuật, du học và dịch thuật.",
    "bien - phien dich": "Biên dịch văn bản và phiên dịch hội thoại đa lĩnh vực.",
    "bao chi": "Tìm tin, viết bài và sản xuất nội dung báo chí.",
    "truyen thong da phuong tien": "Sản xuất video, podcast và chiến dịch truyền thông số.",
    "quan he cong chung": "PR, quản trị khủng hoảng và hình ảnh thương hiệu.",
    "quang cao": "Sáng tạo quảng cáo, media planning và truyền thông thương hiệu.",
    "xuat ban": "Biên tập, xuất bản sách và quản lý bản quyền.",
    "thiet ke do hoa": "Nhận diện thương hiệu, layout và thiết kế truyền thông.",
    "thiet ke thoi trang": "Phác thảo, may mẫu và xu hướng thời trang.",
    "thiet ke noi that": "Không gian nội thất, vật liệu và trải nghiệm sống.",
    "thiet ke cong nghiep": "Thiết kế sản phẩm công nghiệp và ergonomics.",
    "my thuat ung dung": "Mỹ thuật ứng dụng trong in ấn, trang trí và sản phẩm.",
    "kien truc": "Thiết kế công trình, quy hoạch công trình và giám sát thi công.",
    "quy hoach do thi": "Quy hoạch đô thị, giao thông và phát triển bền vững.",
    "su pham toan": "Đào tạo giáo viên Toán THPT và phương pháp giảng dạy.",
    "su pham van": "Đào tạo giáo viên Ngữ văn và kỹ năng soạn giảng.",
    "su pham anh": "Đào tạo giáo viên Tiếng Anh và sư phạm ngoại ngữ.",
    "su pham tin hoc": "Đào tạo giáo viên Tin học và STEM trong nhà trường.",
    "giao duc tieu hoc": "Sư phạm tiểu học và tâm lý lứa tuổi.",
    "giao duc mam non": "Chăm sóc và giáo dục trẻ mầm non.",
    "tam ly hoc giao duc": "Tâm lý học đường và tư vấn học sinh.",
    "tam ly hoc": "Tư vấn tâm lý, đánh giá hành vi và nghiên cứu tâm lý.",
    "xa hoi hoc": "Nghiên cứu xã hội, khảo sát và chính sách cộng đồng.",
    "cong tac xa hoi": "Hỗ trợ nhóm yếu thế và can thiệp xã hội.",
    "quan he quoc te": "Ngoại giao, quan hệ quốc tế và tổ chức phi chính phủ.",
    "dong phuong hoc": "Văn hóa, lịch sử và ngôn ngữ các nước Đông Á.",
    "viet nam hoc": "Lịch sử, văn hóa và nghiên cứu Việt Nam.",
    "su pham lich su": "Đào tạo giáo viên Lịch sử và phương pháp dạy học.",
    "nong nghiep": "Sản xuất cây trồng, đất đai và quản lý trang trại.",
    "cong nghe nong nghiep": "Cơ giới hóa, IoT nông nghiệp và chế biến nông sản.",
    "thu y": "Thú y lâm sàng, dịch tễ và an toàn thực phẩm động vật.",
    "chan nuoi": "Chăn nuôi gia súc, thức ăn và quản lý trại.",
    "lam nghiep": "Lâm sinh, quản lý rừng và bảo tồn.",
    "nuoi trong thuy san": "Nuôi trồng thủy sản, chế biến và quản lý ao hồ–biển.",
    "the duc the thao": "Huấn luyện thể thao, quản lý thi đấu và giáo dục thể chất.",
    "huan luyen the thao": "Huấn luyện viên chuyên môn và khoa học thể thao.",
    "am nhac": "Thanh nhạc, nhạc cụ và biểu diễn âm nhạc.",
    "dien vien san khau dien anh": "Diễn xuất sân khấu, truyền hình và điện ảnh.",
    "dao dien": "Đạo diễn phim, truyền hình và sản xuất audiovisual.",
    "bien kich": "Viết kịch bản phim, phim truyền hình và sân khấu.",
    "nhiep anh": "Nhiếp ảnh nghệ thuật, thương mại và post-production.",
    "my thuat": "Hội họa, điêu khắc và triển lãm mỹ thuật.",
}

FAMILY_DESCRIPTIONS: dict[str, str] = {
    "it": "{name}: đào tạo chuyên sâu CNTT — phần mềm, hệ thống, dữ liệu và AI.",
    "tech_applied": "{name}: ứng dụng khoa học vào sản xuất và kiểm định (không phải lập trình CNTT).",
    "engineering": "{name}: kỹ thuật ứng dụng — thiết kế, vận hành và bảo trì hệ thống kỹ thuật.",
    "health": "{name}: chăm sóc sức khỏe, y sinh và dịch vụ y tế chuyên nghiệp.",
    "science": "{name}: khoa học cơ bản và nghiên cứu — nền cho y sinh, môi trường và R&D.",
    "econ": "{name}: kinh tế, quản trị và tài chính trong doanh nghiệp.",
    "law": "{name}: pháp luật, tố tụng và tư vấn pháp lý.",
    "lang": "{name}: ngoại ngữ, biên phiên dịch và giao tiếp quốc tế.",
    "media": "{name}: truyền thông, báo chí và quan hệ công chúng.",
    "art": "{name}: thiết kế, mỹ thuật và sáng tạo thẩm mỹ.",
    "education": "{name}: sư phạm và phương pháp giảng dạy.",
    "social": "{name}: khoa học xã hội, tâm lý và công tác cộng đồng.",
    "tourism": "{name}: du lịch, khách sạn và dịch vụ lưu trú.",
    "agri": "{name}: nông–lâm–thủy sản và phát triển nông nghiệp bền vững.",
    "environment": "{name}: bảo vệ môi trường và quản lý tài nguyên.",
    "sport": "{name}: thể thao, huấn luyện và quản lý thi đấu.",
    "aviation": "{name}: dịch vụ hàng không và vận hành sân bay.",
}


def describe_major(
    name: str,
    family: str = "",
    exam_blocks: list[str] | None = None,
    existing: str = "",
) -> str:
    if existing and not is_generic_description(existing):
        return existing.strip()

    nl = norm(name)
    if nl in MAJOR_DESCRIPTIONS:
        return MAJOR_DESCRIPTIONS[nl]

    for keys, desc in _TOKEN_TEMPLATES:
        if any(k in nl for k in keys):
            return desc.format(name=name) if "{name}" in desc else desc

    fam = family or "econ"
    tpl = FAMILY_DESCRIPTIONS.get(fam, FAMILY_DESCRIPTIONS["econ"])
    base = tpl.format(name=name)
    if exam_blocks:
        blk = ", ".join(exam_blocks[:3])
        return f"{base} Khối thi thường: {blk}."
    return base


# Bổ sung khi norm không khớp dict chính xác
_TOKEN_TEMPLATES: list[tuple[tuple[str, ...], str]] = [
    (("su pham",), "{name}: đào tạo giáo viên và kỹ năng sư phạm theo môn."),
    (("giao duc",), "{name}: giáo dục học đường và phát triển người học."),
]
