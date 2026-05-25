import json
from pathlib import Path
from typing import List, Dict

import numpy as np
from sentence_transformers import SentenceTransformer


class Recommender:
    def __init__(self, majors_path: Path | str):
        self.majors_path = Path(majors_path)
        self.majors = self._load_majors()
        # Use a compact SBERT model for speed.
        self.model = SentenceTransformer('all-MiniLM-L6-v2')
        self._build_index()

    def _load_majors(self) -> List[Dict]:
        text = self.majors_path.read_text(encoding='utf-8')

        # Try to load JSON normally; if file contains multiple JSON documents
        # (e.g. an array then an object), attempt to parse multiple values and
        # pick the first list found.
        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            decoder = json.JSONDecoder()
            objs = []
            idx = 0
            length = len(text)
            while idx < length:
                # skip whitespace
                while idx < length and text[idx].isspace():
                    idx += 1
                if idx >= length:
                    break
                try:
                    obj, end = decoder.raw_decode(text, idx)
                    objs.append(obj)
                    idx = end
                except json.JSONDecodeError:
                    break

            # Find first list among parsed JSON values or dict with key 'majors'.
            data = None
            for obj in objs:
                if isinstance(obj, list):
                    data = obj
                    break
                if isinstance(obj, dict) and 'majors' in obj and isinstance(obj['majors'], list):
                    data = obj['majors']
                    break

            if data is None:
                raise ValueError(f'Could not parse majors from {self.majors_path}')

        # Expecting a list of objects containing at least 'name' and 'description'.
        if isinstance(data, dict) and 'majors' in data:
            data_list = data['majors']
        elif isinstance(data, list):
            data_list = data
        else:
            raise ValueError(f'Unexpected JSON structure in {self.majors_path}')

        majors = []
        for i, item in enumerate(data_list):
            if not isinstance(item, dict):
                continue
            name = item.get('name') or item.get('major') or item.get('title') or f'Major {i}'
            desc = item.get('description') or item.get('summary') or ''
            majors.append({'id': i, 'name': name, 'description': desc})

        return majors

    def _build_index(self):
        texts = [(m['name'] + ' ' + m['description']).strip() for m in self.majors]
        # Encode into numpy array
        self.majors_embeddings = self.model.encode(texts, convert_to_numpy=True, show_progress_bar=False)
        # Normalize for cosine similarity
        norms = np.linalg.norm(self.majors_embeddings, axis=1, keepdims=True)
        norms[norms == 0] = 1.0
        self.majors_embeddings = self.majors_embeddings / norms

    def recommend(self, profile_text: str, top_k: int = 5) -> List[Dict]:
        q_emb = self.model.encode([profile_text], convert_to_numpy=True)
        q_emb = q_emb / (np.linalg.norm(q_emb, axis=1, keepdims=True) + 1e-9)
        sims = (self.majors_embeddings @ q_emb.T).squeeze()
        idx = np.argsort(-sims)[:top_k]
        results = []
        for i in idx:
            results.append({'name': self.majors[i]['name'], 'score': float(sims[i])})
        return results


if __name__ == '__main__':
    # Simple local test
    repo_root = Path(__file__).resolve().parents[1]
    majors_file = repo_root / 'assets' / 'majors.json'
    r = Recommender(majors_file)
    profile = 'interests: programming, math; strengths: problem solving; math:8.0; english:6.5'
    print(r.recommend(profile))
