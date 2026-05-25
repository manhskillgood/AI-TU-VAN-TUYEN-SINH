import pandas as pd
import random

# Danh sách ngành và cấu hình điểm đặc trưng
majors = {
    "Công nghệ thông tin": {
        "math": (7.5, 9.5),
        "physics": (7.0, 9.0),
        "chemistry": (6.0, 8.0),
        "english": (6.0, 8.5),
        "literature": (5.5, 8.0),
        "biology": (5.0, 7.5),
        "hobby": 0,  # Công nghệ
        "major_label": 0
    },
    "Quản trị kinh doanh": {
        "math": (6.0, 8.0),
        "physics": (5.0, 7.0),
        "chemistry": (5.0, 7.0),
        "english": (7.0, 9.5),
        "literature": (7.0, 9.0),
        "biology": (5.0, 7.0),
        "hobby": 1,  # Kinh doanh
        "major_label": 1
    },
    "Cơ khí": {
        "math": (8.0, 9.8),
        "physics": (8.0, 9.5),
        "chemistry": (7.0, 8.5),
        "english": (5.0, 7.0),
        "literature": (5.0, 7.0),
        "biology": (5.0, 7.0),
        "hobby": 2,  # Máy móc
        "major_label": 2
    },
    "Ngôn ngữ Anh": {
        "math": (5.0, 7.0),
        "physics": (4.0, 6.0),
        "chemistry": (4.0, 6.0),
        "english": (8.0, 10.0),
        "literature": (7.0, 9.5),
        "biology": (5.0, 7.0),
        "hobby": 3,  # Ngôn ngữ
        "major_label": 3
    },
    "Điều dưỡng": {
        "math": (5.5, 7.5),
        "physics": (4.0, 6.0),
        "chemistry": (6.5, 8.5),
        "english": (5.0, 7.5),
        "literature": (5.5, 7.5),
        "biology": (7.0, 9.5),
        "hobby": 4,  # Y tế
        "major_label": 4
    }
}

rows = []
for major, cfg in majors.items():
    # Số lượng mẫu khác nhau để phản ánh thực tế
    n_samples = random.randint(50, 70)
    for _ in range(n_samples):
        row = {
            "math": round(random.uniform(*cfg["math"]), 1),
            "physics": round(random.uniform(*cfg["physics"]), 1),
            "chemistry": round(random.uniform(*cfg["chemistry"]), 1),
            "english": round(random.uniform(*cfg["english"]), 1),
            "literature": round(random.uniform(*cfg["literature"]), 1),
            "biology": round(random.uniform(*cfg["biology"]), 1),
            "area": random.choice([0, 1, 2]),  # Bắc, Trung, Nam
            "hobby": cfg["hobby"],
            "major_label": cfg["major_label"]
        }
        rows.append(row)

df = pd.DataFrame(rows)
df = df.sample(frac=1).reset_index(drop=True)  # xáo trộn dữ liệu

df.to_csv("clean_students_data.csv", index=False, encoding="utf-8")
print(f"✅ Tạo thành công clean_students_data.csv ({df.shape[0]} mẫu)")
print(df.head())
