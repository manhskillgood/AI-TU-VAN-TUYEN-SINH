#!/usr/bin/env python3
"""
Generate major_embeddings.npy from assets/data/majors_list.json (requires sentence-transformers).
Run: python scripts/build_embeddings.py
"""
from pathlib import Path
import json
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MAJORS_PATH = ROOT / "assets" / "data" / "majors_list.json"
OUT_PATH = ROOT / "ml_artifacts" / "major_embeddings.npy"


def main() -> None:
    try:
        from sentence_transformers import SentenceTransformer
    except ImportError as e:
        raise SystemExit(f"Install sentence-transformers: pip install sentence-transformers\n{e}")

    data = json.loads(MAJORS_PATH.read_text(encoding="utf-8"))
    texts = []
    for m in data:
        name = m.get("name", "")
        desc = m.get("description", "")
        kws = " ".join(m.get("keywords") or [])
        texts.append(f"{name}. {desc} {kws}".strip())

    model = SentenceTransformer("all-MiniLM-L6-v2")
    emb = model.encode(texts, convert_to_numpy=True, show_progress_bar=True)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    np.save(OUT_PATH, emb)
    print(f"Saved {emb.shape} -> {OUT_PATH}")


if __name__ == "__main__":
    main()
