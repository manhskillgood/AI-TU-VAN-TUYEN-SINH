#!/usr/bin/env python3
"""Check majors_by_block vs catalog exam_blocks alignment."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / "assets/data/majors_catalog.json").read_text(encoding="utf-8"))
blocks = json.loads((ROOT / "assets/data/majors_by_block.json").read_text(encoding="utf-8"))

by_name = {m["name"]: set(m.get("exam_blocks") or []) for m in catalog["majors"]}

for bid, entry in blocks.items():
    listed = entry.get("majors", [])
    not_in_catalog_blocks = []
    not_in_list = []
    for maj in listed:
        eb = by_name.get(maj, set())
        if bid not in eb and eb:
            not_in_catalog_blocks.append((maj, sorted(eb)))
        elif not eb:
            not_in_catalog_blocks.append((maj, []))
    for name, eb in by_name.items():
        if bid in eb and name not in listed:
            not_in_list.append(name)
    print(f"\n=== {bid} ===")
    print(f"  majors_by_block count: {len(listed)}")
    print(f"  catalog has block but not in list: {len(not_in_list)}")
    if not_in_list[:5]:
        print(f"    e.g. {not_in_list[:5]}")
    print(f"  in list but catalog blocks differ: {len(not_in_catalog_blocks)}")
    for item in not_in_catalog_blocks[:8]:
        print(f"    - {item[0]} catalog={item[1]}")
