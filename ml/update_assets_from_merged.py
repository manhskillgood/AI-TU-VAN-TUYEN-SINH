#!/usr/bin/env python3
"""Merge new majors from ml/merged_majors.json (or ml_artifacts/majors_list.json)
into assets/majors.json. Creates a timestamped backup of assets/majors.json.

Usage:
  python update_assets_from_merged.py
"""
from pathlib import Path
import json
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
ML_MERGED = ROOT / 'merged_majors.json'
ML_ART = ROOT / 'ml_artifacts' / 'majors_list.json'
ASSETS = ROOT.parent / 'assets' / 'majors.json'


def load_json(p: Path):
    if not p.exists():
        return []
    try:
        return json.loads(p.read_text(encoding='utf-8'))
    except Exception:
        return []


def normalize_name(name):
    return ''.join(name.split()).lower()


def main():
    src = ML_MERGED if ML_MERGED.exists() else ML_ART
    print(f'Loading source majors from: {src}')
    src_list = load_json(src)
    assets_list = load_json(ASSETS)

    # Build lookup of existing names in assets
    existing = {normalize_name(a.get('name', '')): a for a in assets_list if isinstance(a, dict) and a.get('name')}

    added = []
    for item in src_list:
        # item may be dict with 'name' or 'title' or a string
        if isinstance(item, dict):
            name = item.get('name') or item.get('title') or item.get('major')
            desc = item.get('description') or item.get('job_trends') or ''
        else:
            name = str(item)
            desc = ''
        if not name:
            continue
        key = normalize_name(name)
        if key in existing:
            # enrich description if missing in assets
            a = existing[key]
            if not a.get('description') and desc:
                a['description'] = desc
        else:
            # create minimal asset entry
            new_obj = {
                'code': None,
                'name': name,
                'exam_blocks': [],
                'reference_score': None,
                'core_skills': [],
                'job_trends': '',
                'description': desc or ''
            }
            assets_list.append(new_obj)
            existing[key] = new_obj
            added.append(name)

    if not added:
        print('No new majors to add.')
        return

    # Backup existing assets file if present
    if ASSETS.exists():
        ts = datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
        backup = ASSETS.with_name(f'majors.json.bak.{ts}')
        backup.write_text(ASSETS.read_text(encoding='utf-8'), encoding='utf-8')
        print(f'Backup written to {backup}')

    # Write updated assets file
    ASSETS.write_text(json.dumps(assets_list, ensure_ascii=False, indent=2), encoding='utf-8')

    print(f'Added {len(added)} majors to {ASSETS}:')
    for n in added:
        print(' -', n)


if __name__ == '__main__':
    main()
