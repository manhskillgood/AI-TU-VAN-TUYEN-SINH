#!/usr/bin/env python3
"""Merge majors from ml_artifacts/majors_list.json and assets/majors.json

Produces a deduplicated merged JSON list at ml/merged_majors.json
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ML_ART = ROOT / 'ml_artifacts' / 'majors_list.json'
ASSETS = ROOT.parent / 'assets' / 'majors.json'
OUT = ROOT / 'merged_majors.json'


def load_json(path: Path):
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception:
        return []


def normalize_item(item):
    if isinstance(item, dict):
        name = item.get('name') or item.get('title') or item.get('major')
        desc = item.get('description') or item.get('job_trends') or ''
        keywords = item.get('keywords') or item.get('core_skills') or []
        code = item.get('code') or item.get('major_code') or None
    else:
        name = str(item)
        desc = ''
        keywords = []
        code = None
    return {
        'name': name.strip() if name else None,
        'description': desc or '',
        'keywords': list(dict.fromkeys([str(k).lower() for k in (keywords or []) if k])),
        'code': code,
    }


def main():
    ml_list = load_json(ML_ART)
    assets = load_json(ASSETS)

    merged = {}

    for item in ml_list:
        norm = normalize_item(item)
        if not norm['name']:
            continue
        merged[norm['name'].lower()] = norm

    for item in assets:
        norm = normalize_item(item)
        if not norm['name']:
            continue
        key = norm['name'].lower()
        if key in merged:
            # prefer richer fields from assets
            existing = merged[key]
            if norm.get('description'):
                existing['description'] = norm['description']
            # merge keywords
            existing['keywords'] = list(dict.fromkeys(existing.get('keywords', []) + norm.get('keywords', [])))
            if norm.get('code'):
                existing['code'] = norm['code']
            merged[key] = existing
        else:
            merged[key] = norm

    out_list = list(merged.values())
    OUT.write_text(json.dumps(out_list, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Wrote {len(out_list)} merged majors to {OUT}')


if __name__ == '__main__':
    main()
