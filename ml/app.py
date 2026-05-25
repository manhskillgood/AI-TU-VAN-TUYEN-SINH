from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
try:
	from sentence_transformers import SentenceTransformer
except Exception:
	# sentence-transformers not available or incompatible — use fallback later
	SentenceTransformer = None
import joblib
import numpy as np
from pathlib import Path
import json
import re
from typing import List, Dict, Any, Tuple, Optional
from datetime import datetime
import os

app = FastAPI()

# -----------------------------
# Configuration / constants
# -----------------------------
EMBEDDINGS_FILENAME = 'major_embeddings.npy'
MAJORS_FILENAME = 'majors_list.json'
EMBED_MODEL_NAME = 'all-MiniLM-L6-v2'


class RecommendRequest(BaseModel):
	profile_text: Optional[str] = None
	block: Optional[str] = None
	region: Optional[str] = None
	interests: Optional[List[str]] = None
	skills: Optional[List[str]] = None
	desired_careers: Optional[List[str]] = None
	include_advice: Optional[bool] = False


class AdviceRequest(BaseModel):
	major: str
	profile_text: str


class SelectMajorRequest(BaseModel):
	selected_major: str
	profile_text: Optional[str] = None
	user_id: Optional[str] = None


def _artifact_path(filename: str) -> Path:
	base = Path(__file__).resolve().parent
	return base.parent / 'ml_artifacts' / filename


def _resolve_majors_path() -> Path:
	"""Prefer full catalog in assets; fallback to ml_artifacts."""
	root = Path(__file__).resolve().parents[1]
	candidates = [
		root / 'assets' / 'data' / 'majors_catalog.json',
		root / 'assets' / 'data' / 'majors_list.json',
		_artifact_path(MAJORS_FILENAME),
	]
	for p in candidates:
		if p.exists():
			return p
	raise FileNotFoundError(f'No majors file found in {candidates}')


def _load_embeddings(path: Path) -> np.ndarray:
	if not path.exists():
		raise FileNotFoundError(f'Embeddings file not found: {path}')
	# joblib
	try:
		obj = joblib.load(path)
		arr = np.array(obj)
		if arr.ndim == 2:
			return arr
	except Exception:
		pass
	# numpy
	try:
		arr = np.load(path)
		if arr.ndim == 2:
			return arr
	except Exception:
		pass
	# json
	try:
		data = json.loads(path.read_text(encoding='utf-8'))
		arr = np.array(data)
		if arr.ndim == 2:
			return arr
	except Exception:
		pass
	raise ValueError(f'Unsupported embeddings format: {path}')


def _load_majors(path: Path) -> List[Dict[str, Any]]:
	if not path.exists():
		raise FileNotFoundError(f'Majors file not found: {path}')
	raw = None
	try:
		obj = joblib.load(path)
		if isinstance(obj, list):
			raw = obj
		elif isinstance(obj, dict):
			raw = obj.get('majors') or obj.get('majors_list') or obj.get('list')
	except Exception:
		pass
	if raw is None:
		try:
			parsed = json.loads(path.read_text(encoding='utf-8'))
			if isinstance(parsed, list):
				raw = parsed
			elif isinstance(parsed, dict):
				raw = parsed.get('majors') or parsed.get('majors_list') or parsed.get('list')
		except Exception:
			raw = []
	majors = []
	for i, item in enumerate(raw or []):
		if isinstance(item, dict):
			name = item.get('name') or item.get('title') or item.get('major') or f'Major {i}'
			desc = item.get('description') or ''
			kw = item.get('keywords') or item.get('tags') or []
			try:
				keywords = [str(x).lower() for x in kw]
			except Exception:
				keywords = []
		else:
			name = str(item)
			desc = ''
			keywords = []
		code = ''
		careers_list: List[str] = []
		if isinstance(item, dict):
			code = str(item.get('code') or '')
			raw_careers = item.get('careers') or []
			if isinstance(raw_careers, list):
				careers_list = [str(c) for c in raw_careers if c]
		majors.append({
			'id': i,
			'name': name,
			'description': desc,
			'keywords': keywords,
			'code': code,
			'careers': careers_list,
		})
	if not majors:
		raise ValueError('No majors found')
	return majors


def _load_guidance_rules(path: Path) -> List[Dict[str, Any]]:
	if not path.exists():
		return []
	try:
		data = json.loads(path.read_text(encoding='utf-8'))
	except Exception:
		return []
	rules = []
	for r in data:
		cond = r.get('conditions', {}) or {}
		interests = []
		if isinstance(cond.get('interest'), list):
			interests = [str(x).lower() for x in cond.get('interest')]
		rules.append({
			'id': r.get('id'),
			'major': str(r.get('major', '')).lower(),
			'score': float(r.get('score', 0.0)),
			'conditions': cond,
			'interest_terms': interests,
			'reason': r.get('reason', [])
		})
	return rules


# -----------------------------
# Startup: load artifacts
# -----------------------------
try:
	EMB_PATH = _artifact_path(EMBEDDINGS_FILENAME)
	MAJ_PATH = _resolve_majors_path()
	RULES_PATH = Path(__file__).resolve().parents[1] / 'assets' / 'guidance_rules_optimized.json'

	majors = _load_majors(MAJ_PATH)
	guidance_rules = _load_guidance_rules(RULES_PATH)

	majors_embeddings = None
	if EMB_PATH.exists():
		try:
			emb = _load_embeddings(EMB_PATH)
			if emb.ndim == 2 and emb.shape[0] == len(majors):
				norms = np.linalg.norm(emb, axis=1, keepdims=True)
				norms[norms == 0] = 1.0
				majors_embeddings = emb / norms
			else:
				print(f'Embeddings shape {emb.shape} mismatch majors {len(majors)} — keyword mode')
		except Exception as ex:
			print(f'Embeddings load failed, using keyword mode: {ex}')
	if majors_embeddings is None:
		majors_embeddings = np.zeros((len(majors), 1), dtype=float)

	# Load major -> universities mapping (optional)
	MAJOR_UNIS_PATH = Path(__file__).resolve().parents[1] / 'assets' / 'major_universities.json'
	major_unis = {}
	try:
		if MAJOR_UNIS_PATH.exists():
			_mu = json.loads(MAJOR_UNIS_PATH.read_text(encoding='utf-8'))
			# normalize keys to lowercase for matching
			major_unis = {k.strip().lower(): v for k, v in (_mu or {}).items()}
	except Exception:
		major_unis = {}

	# Load majors-by-block mapping (optional) — used to restrict suggestions to the selected exam block
	MAJORS_BY_BLOCK_PATH = Path(__file__).resolve().parents[1] / 'assets' / 'data' / 'majors_by_block.json'
	majors_by_block = {}
	try:
		if MAJORS_BY_BLOCK_PATH.exists():
			_mb = json.loads(MAJORS_BY_BLOCK_PATH.read_text(encoding='utf-8'))
			majors_by_block = {str(k).upper(): v for k, v in (_mb or {}).items()}
	except Exception:
		majors_by_block = {}

	UNI_REGISTRY_PATH = Path(__file__).resolve().parents[1] / 'assets' / 'data' / 'universities_registry.json'
	uni_region_map: Dict[str, List[str]] = {}
	try:
		if UNI_REGISTRY_PATH.exists():
			_reg = json.loads(UNI_REGISTRY_PATH.read_text(encoding='utf-8'))
			uni_region_map = {k: list(v) for k, v in (_reg.get('universities') or {}).items()}
	except Exception:
		uni_region_map = {}

	# Map major name lowercase -> index
	name_to_idx = {m['name'].lower(): i for i, m in enumerate(majors)}
	for rule in guidance_rules:
		target = rule.get('major', '').lower()
		if target in name_to_idx:
			idx = name_to_idx[target]
			kws = rule.get('interest_terms', [])
			existing = majors[idx].get('keywords') or []
			merged = list(dict.fromkeys(existing + [k for k in kws if k not in existing]))
			majors[idx]['keywords'] = merged

except Exception as e:
	raise RuntimeError(f'Failed to load artifacts: {e}')


# Encoder used at runtime for incoming profile text. If SentenceTransformer
# is not available (import failure or binary incompatibility), set to None
# and compute_similarity will use a lightweight keyword overlap fallback.
embed_model = None
if SentenceTransformer is not None:
	try:
		embed_model = SentenceTransformer(EMBED_MODEL_NAME)
	except Exception as e:
		embed_model = None
		print(f"SentenceTransformer unavailable — falling back to keyword matcher: {e}")


def preprocess(profile_text: str) -> Tuple[str, Dict[str, float]]:
	"""Clean text and extract numeric subject scores if present.

	Returns normalized lowercase text and a dict of numeric scores found.
	"""
	txt = (profile_text or '').strip()
	txt_low = txt.lower()
	# extract numeric scores for common keys (math, literature, english, biology, chemistry, creativity, language, science)
	scores = {}
	for key in ['math', 'literature', 'english', 'biology', 'chemistry', 'creativity', 'language', 'science']:
		m = re.search(rf"{key}[:\s]*([0-9]+\.?[0-9]*)", txt_low)
		if m:
			try:
				scores[key] = float(m.group(1))
			except Exception:
				pass
	return txt_low, scores


def compute_similarity(profile_text: str) -> np.ndarray:
	"""Encode profile_text and compute cosine similarity (using pre-normalized majors_embeddings)."""
	# If we have a real embed_model, use it. Otherwise use a simple
	# keyword-overlap heuristic to produce stable scores for demo/testing.
	if embed_model is not None and majors_embeddings.shape[1] > 1:
		user_emb = embed_model.encode([profile_text], convert_to_numpy=True)
		user_emb = user_emb / (np.linalg.norm(user_emb, axis=1, keepdims=True) + 1e-9)
		sims = (majors_embeddings @ user_emb.T).squeeze()
		return sims

	# Fallback: simple keyword overlap / name match scoring
	txt = (profile_text or '').lower()
	scores = np.zeros(len(majors), dtype=float)
	for i, m in enumerate(majors):
		name = str(m.get('name', '')).lower()
		kws = [str(x).lower() for x in (m.get('keywords') or [])]
		s = 0.0
		# exact name match strong
		if name and name in txt:
			s += 3.0
		# keyword matches
		for kw in kws:
			if kw and kw in txt:
				s += 1.5
		# token overlap (loose)
		txt_tokens = set(t for t in re.split(r"\W+", txt) if t)
		for token in txt_tokens:
			if token in name:
				s += 0.5
			else:
				for kw in kws:
					if token in kw:
						s += 0.3
						break
		scores[i] = s

	# Normalize into a vector similar to embedding similarity (0..1-ish)
	if scores.max() == 0:
		# avoid zero vector — return tiny uniform scores
		return np.ones_like(scores) * 1e-6
	# scale to 0..1 relative to max
	normed = scores / (scores.max() + 1e-9)
	return normed


def apply_boosting(profile_text: str, sims: np.ndarray, rules: List[Dict[str, Any]] = None) -> np.ndarray:
	"""Apply keyword boosting and rule-based adjustments. Returns boosted scores."""
	txt = (profile_text or '').lower()
	boosted = sims.copy()

	# keyword boost: if profile mentions major keywords
	for i, m in enumerate(majors):
		major_keywords = set(x.lower() for x in (m.get('keywords') or []))
		combined = (m.get('name', '') + ' ' + m.get('description', '')).lower()
		# exact keyword matches (strong)
		if any(kw and kw in txt for kw in major_keywords):
			boosted[i] = boosted[i] * 1.6
			continue
		# substring matches on name/description (medium)
		if any(term in combined for term in ['khoa học máy tính', 'công nghệ thông tin', 'kỹ thuật', 'marketing', 'y khoa', 'dữ liệu', 'thống kê', 'luật']):
			# if profile has generic IT terms, small boost
			it_terms = ['ai', 'máy học', 'lập trình', 'phần mềm', 'data', 'dữ liệu', 'thống kê']
			if any(t in txt for t in it_terms) and any(term in combined for term in ['khoa học máy tính', 'công nghệ thông tin', 'kỹ thuật phần mềm', 'khoa học dữ liệu']):
				boosted[i] = boosted[i] * 1.25

	# rule-based boosts: set floor score for matched rule targets
	try:
		if rules:
			for rule in rules:
				interests = rule.get('interest_terms', []) or []
				# interest match
				interest_match = any(term in txt for term in interests) if interests else True
				if not interest_match:
					continue
				# numeric condition check (permissive)
				conds = rule.get('conditions', {}) or {}
				violated = False
				for k, v in conds.items():
					if k == 'interest':
						continue
					m = re.search(rf"{k}[:\s]*([0-9]+\.?[0-9]*)", txt)
					if m:
						try:
							val = float(m.group(1))
							if isinstance(v, str) and v.startswith('>='):
								thresh = float(v[2:])
								if val < thresh:
									violated = True
									break
						except Exception:
							pass
				if violated:
					continue
				target = rule.get('major', '').lower()
				for i, m in enumerate(majors):
					if target == m.get('name', '').lower() or target in m.get('name', '').lower():
						rule_score = float(rule.get('score', 0.0))
						boosted[i] = max(boosted[i], rule_score)
						break
	except Exception:
		pass

	# small smoothing to stabilize ranks
	boosted = boosted * 0.999 + 1e-6
	return boosted


def generate_reason(profile_text: str, major: Dict[str, Any], score: float, rules: List[Dict[str, Any]]) -> str:
	"""Generate a Vietnamese natural-language reason why this major matches the profile.

	Thêm các insight dựa trên từ khoá (AI, lập trình, dữ liệu, marketing, y tế, luật, tài chính,...)
	để câu lý giải cảm giác tự nhiên hơn và có chiều sâu.
	"""
	txt = (profile_text or '').lower()
	parts = []
	# Mention matched keywords from major.keywords
	kws = [k for k in (major.get('keywords') or []) if k and k in txt]
	if kws:
		parts.append(f"Bạn đề cập đến {', '.join(kws)} — những từ khoá này liên quan trực tiếp tới ngành {major.get('name')}")
	# Mention if major name appears
	if major.get('name', '').lower() in txt:
		parts.append(f"Bạn đã nêu trực tiếp ngành {major.get('name')} trong hồ sơ")
	# Check guidance rules reasons
	matched_reasons = []
	for rule in (rules or []):
		target = rule.get('major', '').lower()
		if target == major.get('name', '').lower() or target in major.get('name', '').lower():
			if any(term in txt for term in (rule.get('interest_terms') or [])):
				matched_reasons += rule.get('reason', [])
	if matched_reasons:
		parts.append('Theo quy tắc hướng dẫn: ' + '; '.join(matched_reasons))

	# Add domain-specific insights
	if 'ai' in txt or 'máy học' in txt or 'machine learning' in txt:
		parts.append('Bạn thể hiện định hướng về AI/machine learning — đây là lĩnh vực đang tăng trưởng nhanh, cần nền tảng toán và lập trình.')
	if 'lập trình' in txt or 'python' in txt or 'java' in txt or 'code' in txt:
		parts.append('Bạn có quan tâm tới lập trình — ngành này sẽ phù hợp nếu bạn muốn làm phát triển phần mềm hoặc engineering.')
	if 'dữ liệu' in txt or 'data' in txt or 'thống kê' in txt:
		parts.append('Bạn quan tâm tới dữ liệu/thống kê — có thể phù hợp với chuyên ngành phân tích dữ liệu hoặc khoa học dữ liệu.')
	if 'marketing' in txt or 'quảng cáo' in txt or 'content' in txt:
		parts.append('Bạn có xu hướng sáng tạo và giao tiếp — marketing/digital có thể là lựa chọn thực tế với kỹ năng content và phân tích.')
	if 'y' in txt or 'y khoa' in txt or 'sinh học' in txt:
		parts.append('Bạn thể hiện sự quan tâm tới y tế/sinh học — ngành y và sức khoẻ đòi hỏi cam kết và kiến thức chuyên sâu.')
	if 'luật' in txt or 'pháp' in txt:
		parts.append('Bạn có xu hướng pháp luật — ngành Luật phù hợp nếu bạn thích lập luận và nghiên cứu chính sách.')
	if 'tài chính' in txt or 'ngân hàng' in txt or 'đầu tư' in txt:
		parts.append('Bạn quan tâm tài chính — ngành Tài chính/Ngân hàng phù hợp với người thích phân tích số liệu và mô hình thị trường.')

	# Fallback based on score components
	if not parts:
		if score >= 0.85:
			parts.append('Điểm tương đồng cao giữa hồ sơ của bạn và mô tả ngành.')
		elif score >= 0.6:
			parts.append('Có điểm tương đồng vừa phải; nên xem chi tiết môn học và nghề nghiệp.')
		else:
			parts.append('Kết quả không rõ ràng — hồ sơ cần thêm thông tin để gợi ý chính xác.')

	# Combine into a natural Vietnamese paragraph
	reason = ' '.join(parts)
	if not reason.endswith('.'):
		reason = reason + '.'
	return reason


def recommend_majors_for_text(profile_text: str, top_k: int = 5, include_advice: bool = False) -> Dict[str, Any]:
	"""End-to-end pipeline returning structured result with explanations and contact suggestion."""
	txt_low, numeric_scores = preprocess(profile_text)
	sims = compute_similarity(profile_text)
	boosted = apply_boosting(profile_text, sims, guidance_rules)
	final_scores = (boosted - boosted.min()) / (max(1e-9, boosted.max() - boosted.min()))

	# pick top_k indices (stable by tie-breaking with index)
	top_idx = np.argsort(final_scores)[::-1][:top_k]

	top_results = []
	for i in top_idx:
		m = majors[i]
		sc = float(final_scores[i])
		reason = generate_reason(profile_text, m, sc, guidance_rules)
		# include an advice snippet linked to the reason only if requested
		advice_text = generate_advice(m.get('name'), profile_text, reason) if include_advice else None
		confidence = round(sc, 2)
		# lookup suggested universities (case-insensitive)
		unis = []
		try:
			unis = major_unis.get(str(m.get('name', '')).strip().lower(), []) or []
		except Exception:
			unis = []
		region_code = _parse_user_region(_extract_region_from_profile(profile_text))
		unis = _filter_universities_by_region(unis, region_code)
		item = {
			'name': m.get('name'),
			'major': m.get('name'),
			'score': sc,
			'confidence': confidence,
			'description': m.get('description', ''),
			'reason': reason,
			'universities': unis,
			'career': list(m.get('careers') or []),
		}
		if m.get('code'):
			item['code'] = m.get('code')
		if include_advice and advice_text is not None:
			item['advice'] = advice_text
		top_results.append(item)

	# contact suggestion: if highest score < 0.6 or profile too short/ambiguous
	need_support = False
	message = ''
	max_score = float(final_scores.max()) if final_scores.size > 0 else 0.0
	# Improved vagueness detection: count unique tokens
	unique_tokens = len(set([t for t in txt_low.split() if t.strip()]))
	if max_score < 0.6 or unique_tokens < 5:
		need_support = True
		message = 'Bạn nên trao đổi thêm với tư vấn viên để có định hướng rõ hơn.'

	# top confidence (for frontend summary)
	top_confidence = round(float(max_score), 2)

	# contact label for frontend when support needed
	contact_label = 'Liên hệ tư vấn' if need_support else ''

	return {
		'top_majors': top_results,
		'top_confidence': top_confidence,
		'need_human_support': need_support,
		'support_message': message,
		'contact_label': contact_label
	}


def generate_advice(major: str, profile_text: str, reason: str = None) -> str:
    mname = major or 'Ngành này'
    mlow = mname.lower()
    txt = (profile_text or '').strip().lower()

    parts = []

    # 🎯 Tiêu đề
    parts.append(f"🎯 Ngành: {mname}")
    parts.append("")

    # 📌 Giải thích
    if reason:
        parts.append("📌 Vì sao phù hợp:")
        parts.append(f"- {reason}")
        parts.append("")

    # 📚 Học gì
    parts.append("📚 Bạn nên học:")
    
    if any(k in mlow for k in ['công nghệ', 'phần mềm', 'khoa học máy tính', 'trí tuệ nhân tạo', 'ai']):
        parts.extend([
            "- Ngôn ngữ lập trình (Python, Java, C++)",
            "- Cấu trúc dữ liệu & giải thuật",
            "- Hệ điều hành, mạng",
        ])
        parts.append("")
        parts.append("🛠️ Thực hành:")
        parts.extend([
            "- Làm project cá nhân / GitHub",
            "- Thực tập (internship)",
            "- Tìm hiểu AI / Machine Learning nếu thích"
        ])

    elif 'dữ liệu' in mlow or 'khoa học dữ liệu' in mlow:
        parts.extend([
            "- Thống kê, xác suất",
            "- Python / R, SQL",
            "- Data visualization"
        ])
        parts.append("")
        parts.append("🛠️ Thực hành:")
        parts.extend([
            "- Làm project phân tích dữ liệu",
            "- Tham gia Kaggle"
        ])

    elif 'marketing' in mlow:
        parts.extend([
            "- Digital marketing, SEO",
            "- Content, quảng cáo",
            "- Phân tích dữ liệu (analytics)"
        ])
        parts.append("")
        parts.append("🛠️ Thực hành:")
        parts.extend([
            "- Chạy ads thử nghiệm",
            "- Làm content page"
        ])

    elif 'y' in mlow or 'y khoa' in mlow:
        parts.extend([
            "- Sinh học, hoá học",
            "- Kiến thức y khoa cơ bản"
        ])
        parts.append("")
        parts.append("🛠️ Thực hành:")
        parts.extend([
            "- Thực tập bệnh viện",
            "- Tình nguyện y tế"
        ])

    else:
        parts.extend([
            "- Kiến thức nền tảng của ngành",
            "- Kỹ năng tư duy và thực hành"
        ])
        parts.append("")
        parts.append("🛠️ Thực hành:")
        parts.append("- Làm dự án / thực tập")

    parts.append("")

    # 💼 Nghề nghiệp
    parts.append("💼 Hướng nghề nghiệp:")
    if "công nghệ" in mlow or "ai" in mlow:
        parts.extend([
            "- Lập trình viên",
            "- Kỹ sư AI / Data",
            "- Backend / Mobile Dev"
        ])
    else:
        parts.append("- Tùy theo chuyên ngành cụ thể")

    parts.append("")

    # ⚠️ Gợi ý thêm
    if len(txt) < 30:
        parts.append("⚠️ Hồ sơ của bạn còn ít thông tin → nên bổ sung để hệ thống tư vấn chính xác hơn.")
    else:
        parts.append("🚀 Bạn có định hướng khá rõ → nên bắt đầu học và làm dự án sớm.")

    parts.append("")
    parts.append("📞 Nếu cần, bạn có thể liên hệ tư vấn viên để được hỗ trợ chi tiết hơn.")

    return "\n".join(parts)


def generate_reason_structured(block: str, interests: List[str], skills: List[str], desired_careers: List[str], major_name: str, score: float) -> str:
	parts = []
	mlow = major_name.lower()
	if block:
		parts.append(f"Bạn chọn tổ hợp {block} → hệ thống chỉ gợi ý các ngành phù hợp với khối này.")
	if interests:
		parts.append(f"Sở thích: {', '.join(interests)} phù hợp với ngành {major_name}.")
	if skills:
		parts.append(f"Kỹ năng: {', '.join(skills)} hỗ trợ học ngành này.")
	if desired_careers:
		parts.append(f"Bạn mong muốn nghề: {', '.join(desired_careers)} — ngành này có thể dẫn tới các nghề đó.")
	# Tailored hints
	if any(t in mlow for t in ['báo chí', 'truyền thông', 'quan hệ']):
		parts.append('Bạn phù hợp nhóm ngành xã hội, giao tiếp và sáng tạo.')
	if any(t in mlow for t in ['công nghệ', 'khoa học máy tính', 'phần mềm', 'trí tuệ']):
		parts.append('Ngành kỹ thuật/ CNTT yêu cầu toán và tư duy logic.')
	if any(t in mlow for t in ['y khoa', 'dược', 'điều dưỡng']):
		parts.append('Ngành y dược cần thích chăm sóc sức khỏe và cam kết học tập dài hạn.')
	if not parts:
		parts.append('Gợi ý dựa trên sở thích và kỹ năng bạn cung cấp.')
	reason = ' '.join(parts)
	if not reason.endswith('.'):
		reason = reason + '.'
	return reason


def _extract_region_from_profile(profile_text: str) -> Optional[str]:
	if not profile_text:
		return None
	for part in profile_text.split(';'):
		p = part.strip().lower()
		if p.startswith('khu vực:') or p.startswith('khu vuc:'):
			return part.split(':', 1)[-1].strip()
	return None


def _parse_user_region(region: Optional[str]) -> Optional[str]:
	if not region:
		return None
	r = re.sub(r'\s+', ' ', region.lower().strip())
	if 'tay nguyen' in r or 'tây nguyên' in r:
		return 'tay_nguyen'
	if 'mien trung' in r or 'miền trung' in r or 'trung mien' in r or 'trung miền' in r or r == 'trung':
		return 'central'
	if 'mien nam' in r or 'miền nam' in r or 'nam mien' in r or 'nam miền' in r:
		return 'south'
	if 'mien bac' in r or 'miền bắc' in r or 'bac mien' in r or 'bắc miền' in r:
		return 'north'
	if any(x in r for x in ['da nang', 'đà nẵng', 'hue', 'huế', 'nha trang']):
		return 'central'
	if any(x in r for x in ['ho chi minh', 'hồ chí minh', 'tp.hcm', 'hcm', 'can tho', 'cần thơ']):
		return 'south'
	if any(x in r for x in ['ha noi', 'hà nội', 'bac', 'bắc']):
		return 'north'
	return None


def _filter_universities_by_region(unis: List[str], region_code: Optional[str]) -> List[str]:
	if not region_code or not unis:
		return unis
	out = []
	for u in unis:
		regions = uni_region_map.get(u)
		if regions:
			if region_code in regions:
				out.append(u)
			continue
		lu = u.lower()
		south_markers = ['tp.hcm', 'tp hcm', 'hồ chí minh', 'ho chi minh', 'cần thơ', 'can tho', 'sài gòn', 'sai gon']
		central_markers = ['đà nẵng', 'da nang', 'huế', 'hue', 'nha trang']
		tn_markers = ['tây nguyên', 'tay nguyen', 'đà lạt', 'da lat']
		if region_code == 'north':
			if any(x in lu for x in south_markers + central_markers + tn_markers):
				continue
			if any(x in lu for x in ['hà nội', 'ha noi', 'quốc dân', 'ngoại thương', 'bách khoa hà nội', 'sư phạm hà nội', 'đhqg hn', 'phenikaa', 'thăng long', 'buu chinh', 'bưu chính', 'công nghiệp hà nội']):
				out.append(u)
		elif region_code == 'south':
			if any(x in lu for x in south_markers):
				out.append(u)
		elif region_code == 'central':
			if any(x in lu for x in central_markers):
				out.append(u)
		elif region_code == 'tay_nguyen':
			if any(x in lu for x in tn_markers):
				out.append(u)
	return out if out else []


def _norm_major_name(s: str) -> str:
	return re.sub(r'\s+', ' ', (s or '').lower().strip())


def _is_it_major(name: str) -> bool:
	m = _norm_major_name(name)
	excluded = (
		'thực phẩm', 'sinh học', 'nông nghiệp', 'môi trường',
		'xét nghiệm', 'hóa học', 'vật liệu', 'đa phương tiện',
	)
	if any(e in m for e in excluded):
		return False
	return any(
		t in m
		for t in (
			'thông tin', 'phần mềm', 'máy tính', 'trí tuệ nhân tạo',
			'an toàn thông tin', 'dữ liệu', 'lập trình', 'hệ thống thông tin',
			'khoa học máy tính', 'kỹ thuật máy tính',
		)
	)


def _tech_wizard_interest(interest: str) -> bool:
	it = _norm_major_name(interest)
	return it in ('công nghệ',) or 'cntt' in it or 'lập trình' in it or 'tin học' in it


def _interest_matches_major(interest: str, major: str) -> bool:
	it = _norm_major_name(interest)
	if _tech_wizard_interest(interest):
		return _is_it_major(major)
	return bool(it) and it in _norm_major_name(major)


def recommend_from_structured(block: Optional[str], interests: Optional[List[str]], skills: Optional[List[str]], desired_careers: Optional[List[str]], region: Optional[str] = None, top_k: int = 5, include_advice: bool = False) -> Dict[str, Any]:
	"""Rule-based recommendation using explicit fields. Returns structured items as requested."""
	block_up = (block or '').upper() if block else ''

	# Candidate majors: restrict to block if provided and mapping exists
	if block_up and block_up in majors_by_block:
		candidates_strings = list(majors_by_block[block_up].get('majors', []))
		# map known majors (from majors metadata) to canonical names
		name_map = {m['name'].lower(): m['name'] for m in majors}
		def _norm_name(s: str) -> str:
			return re.sub(r"\s+", " ", (s or "").lower().strip())

		allowed_norm: set[str] = set()
		for cs in candidates_strings:
			cs_n = _norm_name(cs)
			allowed_norm.add(cs_n)
			if cs_n in name_map:
				allowed_norm.add(_norm_name(name_map[cs_n]))

		candidates = []
		for cs in candidates_strings:
			cs_lower = _norm_name(cs)
			# Chỉ khớp tên chính xác — tránh "Sư phạm Văn" (C00) kéo theo "Sư phạm Toán"
			if cs_lower in name_map:
				candidates.append(name_map[cs_lower])
			else:
				candidates.append(cs)
		seen: set[str] = set()
		unique_candidates = []
		for c in candidates:
			if _norm_name(c) not in allowed_norm:
				continue
			key = _norm_name(c)
			if key not in seen:
				unique_candidates.append(c)
				seen.add(key)
		candidates = unique_candidates
	else:
		candidates = [m['name'] for m in majors]

	# Map known majors to their metadata
	name_to_obj = {m['name'].lower(): m for m in majors}

	scores = []
	for maj in candidates:
		mlow = maj.lower()
		base = 0.0

		# Interest matches
		for it in (interests or []):
			it_s = it.lower().strip()
			if not it_s:
				continue
			# special-case education interests -> match sư phạm / giáo dục majors
			if any(sub in it_s for sub in ['giáo', 'sư phạm', 'giáo dục']):
				if 'giáo dục' in mlow:
					base += 2.0
					continue
				if 'sư phạm' in mlow or ('sư' in mlow and 'phạm' in mlow):
					# C00: ưu tiên sư phạm xã hội, không cộng điểm sư phạm toán/tin
					if block_up == 'C00' and any(
						t in mlow for t in ['toán', 'tin học', 'vật lý', 'hóa', 'sinh']
					):
						pass
					else:
						base += 2.0
					continue
			# "Công nghệ" wizard = CNTT only (not Công nghệ thực phẩm / sinh học)
			if _tech_wizard_interest(it_s):
				if _is_it_major(maj):
					base += 2.5
				continue
			# direct substring match (other interests)
			if it_s in mlow:
				base += 2.0
			else:
				# check tokens
				for t in it_s.split():
					if t and t in mlow:
						base += 0.6
						break
				# check major keywords from metadata
				mo = name_to_obj.get(mlow)
				if mo:
					for kw in (mo.get('keywords') or []):
						if kw and kw in it_s:
							base += 1.2
							break

		# Skills -> heuristic boosts
		for s in (skills or []):
			sk = s.lower()
			if any(k in sk for k in ['tư duy', 'logic', 'phân tích']):
				if _is_it_major(maj):
					base += 1.6
				elif any(term in mlow for term in ['kỹ thuật', 'điện', 'cơ khí', 'tự động hóa']):
					base += 1.0
			if 'sáng tạo' in sk or 'thiết kế' in sk:
				if any(term in mlow for term in ['báo chí', 'marketing', 'thiết kế', 'truyền thông', 'quảng cáo']):
					base += 1.4
			if 'giao tiếp' in sk or 'nói chuyện' in sk:
				if any(term in mlow for term in ['quan hệ', 'báo chí', 'truyền thông', 'marketing', 'sư phạm', 'du lịch']):
					base += 1.3
			if 'chăm sóc' in sk or 'y tế' in sk or 'sức khỏe' in sk:
				if any(term in mlow for term in ['y', 'dược', 'điều dưỡng', 'sức khỏe']):
					base += 1.5

		# Desired careers matching (if the major's block lists the career)
		if desired_careers and block_up and block_up in majors_by_block:
			block_entry = majors_by_block.get(block_up, {})
			block_careers = [c.lower() for c in block_entry.get('careers', [])]
			for dc in desired_careers:
				if dc and dc.lower() in block_careers:
					base += 2.0

		# Tech eligibility rules (do not boost/push technical majors unless explicit signals)
		is_tech = _is_it_major(maj)
		tech_signal = False
		for it in (interests or []):
			if any(t in it.lower() for t in ['lập trình', 'công nghệ', 'ai', 'máy học', 'dữ liệu', 'data', 'code', 'python', 'java']):
				tech_signal = True
				break
		for s in (skills or []):
			if any(t in s.lower() for t in ['tư duy logic', 'logic', 'phân tích']):
				tech_signal = True
				break

		if is_tech and block_up == 'C00':
			base *= 0.01
		elif is_tech and not tech_signal:
			base *= 0.05

		scores.append(base)

	arr = np.array(scores, dtype=float)
	if arr.size == 0:
		return {'top_majors': [], 'top_confidence': 0.0, 'need_human_support': True, 'support_message': 'Không có ngành phù hợp cho khối này.'}

	if arr.max() == 0:
		norm = np.ones_like(arr) * 1e-6
	else:
		norm = (arr - arr.min()) / (max(1e-9, arr.max() - arr.min()))

	top_idx = np.argsort(norm)[::-1][:top_k]

	top_results = []
	for i in top_idx:
		name = candidates[int(i)]
		mo = name_to_obj.get(name.lower(), {})
		sc = float(norm[i])
		conf = round(sc, 2)
		careers = list(mo.get('careers') or [])
		unis = major_unis.get(name.lower(), []) or []
		region_code = _parse_user_region(region)
		unis = _filter_universities_by_region(unis, region_code)
		if not unis and block_up and block_up in majors_by_block:
			block_unis = majors_by_block[block_up].get('universities', []) or []
			unis = _filter_universities_by_region(list(block_unis), region_code)
		code = str(mo.get('code') or '')

		reason = generate_reason_structured(block_up, interests or [], skills or [], desired_careers or [], name, sc)
		item = {
			'name': name,
			'major': name,
			'career': careers,
			'universities': unis,
			'reason': reason,
			'confidence': conf,
		}
		if code:
			item['code'] = code
		if include_advice:
			item['advice'] = generate_advice(name, '')
		top_results.append(item)

	# require human support if top confidence is low or user supplied no structured signals
	no_signals = (not (interests or []) and not (skills or []) and not (desired_careers or []))
	need_support = bool(norm.max() < 0.6 or no_signals)
	support_message = 'Bạn nên trao đổi với tư vấn viên để có định hướng chính xác hơn.' if need_support else ''

	return {
		'top_majors': top_results,
		'top_confidence': round(float(norm.max()), 2),
		'need_human_support': need_support,
		'support_message': support_message,
		'contact_label': 'Liên hệ tư vấn' if need_support else ''
	}


@app.post('/recommend')
def recommend(req: RecommendRequest):
	# If structured inputs are provided (block/interests/skills/desired_careers),
	# prefer rule-based structured recommender. Otherwise fall back to text pipeline.
	region = req.region or _extract_region_from_profile(req.profile_text or '')
	if req.block or req.interests or req.skills or req.desired_careers:
		res = recommend_from_structured(
			block=req.block,
			interests=req.interests,
			skills=req.skills,
			desired_careers=req.desired_careers,
			region=region,
			top_k=5,
			include_advice=bool(req.include_advice),
		)
		return res
	# backward-compatible fallback
	profile_text = req.profile_text or ''
	result = recommend_majors_for_text(
		profile_text,
		top_k=5,
		include_advice=bool(req.include_advice),
	)
	return result


@app.post('/advice')
def advice(req: AdviceRequest):
    major = (req.major or '').strip()
    profile_text = (req.profile_text or '').strip()

    def normalize_text(s: str) -> str:
        return re.sub(r'\s+', ' ', s.strip().lower())

    # 🔹 Precompute 1 lần
    sims = compute_similarity(profile_text)
    boosted = apply_boosting(profile_text, sims, guidance_rules)
    final_scores = (boosted - boosted.min()) / (max(1e-9, boosted.max() - boosted.min()))

    # 🔹 Try match major chính xác
    match_idx = None
    input_major = normalize_text(major)

    for i, m in enumerate(majors):
        if input_major == normalize_text(m.get('name', '')):
            match_idx = i
            break

    # 🔹 Nếu không match → lấy ngành top 1
    if match_idx is None:
        best_idx = int(np.argmax(final_scores))
        reason = generate_reason(profile_text, majors[best_idx], float(final_scores[best_idx]), guidance_rules)
        text = generate_advice(majors[best_idx]['name'], profile_text, reason)

        return {
            'major': majors[best_idx]['name'],
            'advice': text,
            'need_human_support': True
        }

    # 🔹 Match thành công → generate advice
    score = float(final_scores[match_idx])
    reason = generate_reason(profile_text, majors[match_idx], score, guidance_rules)
    text = generate_advice(majors[match_idx]['name'], profile_text, reason)

    return {
        'major': majors[match_idx]['name'],
        'advice': text,
        'need_human_support': score < 0.6
    }


@app.post('/select_major')
def select_major(req: SelectMajorRequest):
	"""Log user's selected major for later model improvement.

	Appends a JSON line to ml_logs/selection_log.jsonl with timestamp, user_id (optional),
	selected_major and profile_text.
	"""
	log_dir = Path(__file__).resolve().parents[1] / 'ml_logs'
	try:
		os.makedirs(log_dir, exist_ok=True)
		log_path = log_dir / 'selection_log.jsonl'
		entry = {
			'timestamp': datetime.utcnow().isoformat() + 'Z',
			'user_id': req.user_id,
			'selected_major': req.selected_major,
			'profile_text': req.profile_text
		}
		with open(log_path, 'a', encoding='utf-8') as f:
			f.write(json.dumps(entry, ensure_ascii=False) + '\n')
		return {'ok': True, 'message': 'Chọn ngành đã được ghi nhận. Cảm ơn bạn!'}
	except Exception as e:
		raise HTTPException(status_code=500, detail=f'Không thể ghi log: {e}')

