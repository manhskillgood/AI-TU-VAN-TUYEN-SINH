#!/usr/bin/env python3
"""Validate guidance JSON assets. Run: python scripts/validate_guidance_data.py"""
from __future__ import annotations

import json
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data"


def norm(s: str) -> str:
    s = s.lower().strip()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return s


def main() -> None:
    catalog = json.loads((DATA / "majors_catalog.json").read_text(encoding="utf-8"))
    majors = catalog["majors"]
    issues: list[str] = []

    list_count = len(json.loads((DATA / "majors_list.json").read_text(encoding="utf-8")))
    if list_count != len(majors):
        issues.append(f"COUNT_MISMATCH: catalog={len(majors)} list={list_count}")

    names = {norm(m["name"]) for m in majors}
    display = {norm(m["name"]): m["name"] for m in majors}

    code_to_names: dict[str, list[str]] = {}
    for m in majors:
        c = (m.get("code") or "").strip()
        if c:
            code_to_names.setdefault(c, []).append(m["name"])
    for c, dup_list in code_to_names.items():
        if len(dup_list) > 1:
            issues.append(f"DUP_CODE: {c} -> {', '.join(dup_list)}")

    empty_wi = 0
    for m in majors:
        if not m.get("description"):
            issues.append(f"NO_DESC: {m['name']}")
        desc = m.get("description", "")
        if "đào tạo kiến thức chuyên môn và kỹ năng nghề nghiệp" in desc.lower():
            issues.append(f"GENERIC_DESC: {m['name']}")
        if not m.get("exam_blocks"):
            issues.append(f"NO_BLOCK: {m['name']}")
        if not m.get("universities"):
            issues.append(f"NO_UNI: {m['name']}")
        if not m.get("family"):
            issues.append(f"NO_FAMILY: {m['name']}")
        if not m.get("wizard_interests"):
            empty_wi += 1
        fam = m.get("family", "")
        kws = m.get("keywords") or []
        if fam == "tech_applied" and any(k in ("cntt", "lập trình") for k in kws):
            issues.append(f"BAD_KW_APPLIED_TECH: {m['name']} has IT keywords")
        if fam == "it" and norm(m["name"]) in {norm("Công nghệ thực phẩm"), norm("Công nghệ sinh học")}:
            issues.append(f"BAD_FAMILY_IT: {m['name']}")

    rules = json.loads((ROOT / "assets/guidance_rules.json").read_text(encoding="utf-8"))
    for r in rules:
        for maj in (r.get("boostMajors") or {}):
            if norm(maj) not in names:
                issues.append(f"RULE_BOOST_UNKNOWN: {r['id']} -> {maj}")

    opt = json.loads((ROOT / "assets/guidance_rules_optimized.json").read_text(encoding="utf-8"))
    for r in opt:
        maj = r.get("major", "")
        if maj and norm(maj) not in names:
            issues.append(f"OPT_RULE_UNKNOWN: {r['id']} -> {maj}")

    blocks = json.loads((ROOT / "assets/data/majors_by_block.json").read_text(encoding="utf-8"))
    for bid, entry in blocks.items():
        for maj in entry.get("majors", []):
            if norm(maj) not in names:
                issues.append(f"BLOCK_{bid}_UNKNOWN: {maj}")

    # exam_blocks trong catalog phải khớp majors_by_block
    catalog_by_block: dict[str, list[str]] = {}
    for m in majors:
        for bid in m.get("exam_blocks") or []:
            catalog_by_block.setdefault(str(bid).upper(), []).append(m["name"])
    for bid, names_in_block in catalog_by_block.items():
        block_entry = blocks.get(bid) or blocks.get(bid.upper())
        if not block_entry:
            issues.append(f"BLOCK_MISSING_IN_JSON: {bid}")
            continue
        block_set = {norm(x) for x in block_entry.get("majors", [])}
        for maj in names_in_block:
            if norm(maj) not in block_set:
                issues.append(f"BLOCK_SYNC: {bid} missing {maj}")

    exam_blocks_path = DATA / "exam_blocks.json"
    if exam_blocks_path.exists():
        meta = json.loads(exam_blocks_path.read_text(encoding="utf-8"))
        meta_ids = {str(b["id"]).upper() for b in meta.get("blocks", [])}
        if meta_ids != set(blocks.keys()):
            issues.append(f"EXAM_BLOCKS_META_MISMATCH: meta={sorted(meta_ids)} json={sorted(blocks.keys())}")
    else:
        issues.append("MISSING: exam_blocks.json")

    registry_path = DATA / "universities_registry.json"
    if registry_path.exists():
        reg = json.loads(registry_path.read_text(encoding="utf-8"))
        reg_unis = set((reg.get("universities") or {}).keys())
        for m in majors:
            for u in m.get("universities") or []:
                if u not in reg_unis:
                    issues.append(f"UNI_NOT_IN_REGISTRY: {m['name']} -> {u}")
    else:
        issues.append("MISSING: universities_registry.json")

    print(f"Majors in catalog: {len(majors)}")
    print(f"Without wizard_interests: {empty_wi}")
    print(f"Issues found: {len(issues)}")
    if len(issues) > 40:
        print(f"  ... and {len(issues) - 40} more")

    with_code = sum(1 for m in majors if m.get("code"))
    no_code = [m["name"] for m in majors if not m.get("code")]
    print(f"With ministry code: {with_code}/{len(majors)}")
    if no_code:
        issues.extend([f"NO_CODE: {n}" for n in no_code])

    report_path = ROOT / "scripts" / "data_validation_report.txt"
    report_path.write_text(
        f"Issues: {len(issues)}\n" + "\n".join(issues),
        encoding="utf-8",
    )
    print(f"Report written: {report_path}")


if __name__ == "__main__":
    main()
