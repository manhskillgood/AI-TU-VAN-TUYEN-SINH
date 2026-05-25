Quick start — Recommender server

1) Create Python venv and install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate     # on Windows use `.venv\\Scripts\\activate`
pip install -r requirements.txt
```

2) Run the server (binds to 0.0.0.0:8000):

```bash
uvicorn app:app --host 0.0.0.0 --port 8000
```

3) From Android emulator use `http://10.0.2.2:8000/recommend` to call the endpoint.

Payload example (POST JSON):

```json
{
  "math": 8.0,
  "literature": 6.5,
  "english": 7.0,
  "interests": ["programming", "math"],
  "strengths": ["problem solving"]
}
```

Response example:

```json
{
  "top_majors": [
    {"name": "Computer Science", "score": 0.91},
    {"name": "Information Systems", "score": 0.76}
  ]
}
```

Notes:
- This is a lightweight embedding-based recommender (SBERT). It demonstrates AI usage
  (text embeddings + similarity) and is suitable for demo in a thesis.
- For production, consider hosting on a GPU-enabled server or using a smaller on-device
  model converted to TFLite for offline use.
