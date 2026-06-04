import json

file_path = "/Users/corlin/2026/Floraboard-ios/Floreboard/Localizable.xcstrings"
with open(file_path, "r") as f:
    data = json.load(f)

new_keys = {
    "inventory.row.used": {"en": "Used", "zh-Hans": "已消耗"}
}

for key, values in new_keys.items():
    data["strings"][key] = {
        "extractionState": "manual",
        "localizations": {
            "en": {
                "stringUnit": {
                    "state": "translated",
                    "value": values["en"]
                }
            },
            "zh-Hans": {
                "stringUnit": {
                    "state": "translated",
                    "value": values["zh-Hans"]
                }
            }
        }
    }

with open(file_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Updated Localizable.xcstrings")
