from collections import Counter
from datasets import load_dataset
ds = load_dataset("projectsidewalk/sidewalk-validator-ai-dataset-surfaceproblem")
print(ds)
for s in ds:
    print(s, ds[s].features)
    break
for s in ds:
    for c, f in ds[s].features.items():
        if hasattr(f, "names") or "label" in c.lower():
            print(s, c, getattr(f, "names", None), Counter(ds[s][c]))
