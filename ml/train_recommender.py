"""Train/demo script for recommender.

Usage examples:
  # If you have labeled CSV with a column 'chosen_major' (or 'major'):
  python train_recommender.py --data ../clean_students_data.csv --out model.joblib

  # If no labeled data, build and save major embeddings for fast inference:
  python train_recommender.py --build-index

This script attempts to be robust: if labeled data exists it will train
an XGBoost classifier combining SBERT text embeddings and numeric scores.
Otherwise it precomputes major embeddings used by the FastAPI recommender.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

import numpy as np

try:
    import pandas as pd
except Exception as e:
    print('pandas is required. Install with: pip install pandas')
    raise

from sentence_transformers import SentenceTransformer

MODEL_NAME = 'all-MiniLM-L6-v2'


def build_major_index(majors_path: Path, out_dir: Path):
    print('Building major embeddings index...')
    text = majors_path.read_text(encoding='utf-8')

    # Robust parse: file may contain a single JSON list/dict or multiple JSON documents.
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        decoder = json.JSONDecoder()
        parsed_objs = []
        idx = 0
        length = len(text)
        while idx < length:
            while idx < length and text[idx].isspace():
                idx += 1
            if idx >= length:
                break
            try:
                obj, end = decoder.raw_decode(text, idx)
                parsed_objs.append(obj)
                idx = end
            except json.JSONDecodeError:
                break

        # choose first list or dict with 'majors'
        parsed = None
        for obj in parsed_objs:
            if isinstance(obj, list):
                parsed = obj
                break
            if isinstance(obj, dict) and 'majors' in obj and isinstance(obj['majors'], list):
                parsed = obj['majors']
                break

    # Determine majors_list as list of dicts with name+description
    if isinstance(parsed, dict) and 'majors' in parsed and isinstance(parsed['majors'], list):
        majors_list = parsed['majors']
    elif isinstance(parsed, list):
        majors_list = parsed
    else:
        raise ValueError(f'Could not parse majors list from {majors_path}')

    # Normalize entries to objects with name and description
    normalized = []
    for i, item in enumerate(majors_list):
        if isinstance(item, dict):
            name = item.get('name') or item.get('title') or item.get('major') or f'Major {i}'
            desc = item.get('description') or item.get('job_trends') or ''
        else:
            name = str(item)
            desc = ''
        normalized.append({'name': name, 'description': desc})

    names = [m['name'] for m in normalized]
    texts = [(m['name'] + ' ' + m['description']).strip() for m in normalized]

    model = SentenceTransformer(MODEL_NAME)
    emb = model.encode(texts, convert_to_numpy=True, show_progress_bar=True)
    # normalize
    norms = np.linalg.norm(emb, axis=1, keepdims=True)
    norms[norms == 0] = 1.0
    emb = emb / norms

    out_dir.mkdir(parents=True, exist_ok=True)
    # Save embeddings and full majors metadata (joblib) so app can load them directly
    joblib_path_emb = out_dir / 'embeddings.pkl'
    joblib_path_maj = out_dir / 'majors.pkl'
    np.save(out_dir / 'major_embeddings.npy', emb)
    # joblib save for compatibility with app loader
    import joblib as _jl
    _jl.dump(emb, joblib_path_emb)
    _jl.dump(normalized, joblib_path_maj)

    # Also write human-readable JSON with full objects
    (out_dir / 'majors_list.json').write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Saved embeddings ({emb.shape}), {joblib_path_emb.name}, and majors metadata to {out_dir}')


def train_from_csv(data_path: Path, out_path: Path):
    print('Training classifier from CSV:', data_path)
    df = pd.read_csv(data_path)

    # Attempt to find label column
    label_cols = [c for c in df.columns if c.lower() in ('chosen_major', 'major', 'major_name', 'major_code')]
    if not label_cols:
        print('No label column found (searched for chosen_major/major/major_name/major_code). Aborting training.')
        return

    label_col = label_cols[0]
    print('Using label column:', label_col)

    # Text features: interests + strengths
    text_cols = [c for c in df.columns if c.lower() in ('interests', 'strengths', 'skills')]

    def make_text(row):
        parts = []
        for c in text_cols:
            v = row.get(c)
            if pd.isna(v):
                continue
            if isinstance(v, str):
                parts.append(v)
            elif isinstance(v, (list, tuple)):
                parts.append(' '.join(map(str, v)))
        return ' '.join(parts)

    texts = df.apply(make_text, axis=1).astype(str).tolist()

    # Numeric scores (if present)
    num_cols = [c for c in df.columns if c.lower() in ('math', 'toan', 'literature', 'van', 'english', 'anh')]
    X_num = None
    if num_cols:
        X_num = df[num_cols].fillna(0).to_numpy(dtype=float)

    # Encode text with SBERT
    model = SentenceTransformer(MODEL_NAME)
    X_text = model.encode(texts, convert_to_numpy=True, show_progress_bar=True)

    if X_num is not None:
        X = np.hstack([X_text, X_num])
    else:
        X = X_text

    # Labels
    y = df[label_col].astype(str)
    from sklearn.preprocessing import LabelEncoder
    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    try:
        import xgboost as xgb
    except Exception:
        print('xgboost is required to train classifier. Install with: pip install xgboost')
        raise

    clf = xgb.XGBClassifier(use_label_encoder=False, eval_metric='mlogloss')
    clf.fit(X, y_enc)

    # Save model and label encoder
    try:
        import joblib
    except Exception:
        print('joblib is required to save model. Install with: pip install joblib')
        raise

    out_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump({'model': clf, 'label_encoder': le, 'embed_model_name': MODEL_NAME}, out_path)
    print('Saved trained model to', out_path)


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=Path, help='Path to labeled CSV (clean_students_data.csv)')
    parser.add_argument('--out', type=Path, default=Path('model.joblib'), help='Output path for trained model')
    parser.add_argument('--build-index', action='store_true', help='Build major embeddings index (no labeled data needed)')
    # By default use merged_majors.json at repo root and write artifacts into ml/ml_artifacts
    parser.add_argument('--majors', type=Path, default=Path(__file__).resolve().parents[1] / 'merged_majors.json')
    parser.add_argument('--out-dir', type=Path, default=Path(__file__).resolve().parent / 'ml_artifacts')
    args = parser.parse_args(argv)

    if args.data and args.data.exists():
        train_from_csv(args.data, args.out)
        return

    if args.build_index:
        build_major_index(args.majors, args.out_dir)
        return

    print('No action taken. Provide --data <csv> to train or --build-index to precompute majors index.')


if __name__ == '__main__':
    main()
