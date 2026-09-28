import os
import re

features_dir = "/Users/corlin/2026/Floraboard-ios/Floreboard/Features"
results = {}

for root, _, files in os.walk(features_dir):
    for f in sorted(files):
        if not f.endswith(".swift"):
            continue
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, "/Users/corlin/2026/Floraboard-ios")
        with open(full_path, "r", encoding="utf-8") as fp:
            for idx, line in enumerate(fp):
                stripped = line.strip()
                if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
                    continue
                matches = re.findall(r'"([^"\n]*[\u4e00-\u9fa5]+[^"\n]*)"', line)
                if matches:
                    if rel_path not in results:
                        results[rel_path] = []
                    for m in matches:
                        results[rel_path].append((idx + 1, m))

for path, items in results.items():
    print(f"FILE: {path} ({len(items)} strings)")
    for l, txt in items[:6]:
        print(f"  L{l}: {txt}")
    if len(items) > 6:
        print(f"  ... (+{len(items)-6} more)")
