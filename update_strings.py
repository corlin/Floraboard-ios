import json

file_path = "/Users/corlin/2026/Floraboard-ios/Floreboard/Localizable.xcstrings"
with open(file_path, "r") as f:
    data = json.load(f)

new_keys = {
    "design.execution.header": {"en": "Deduction Confirmation", "zh-Hans": "花材扣减确认"},
    "design.execution.desc": {"en": "Review and match AI generated flowers to your actual inventory.", "zh-Hans": "请核对 AI 建议花材并关联到您的实际库存。"},
    "design.execution.match": {"en": "Match Inventory", "zh-Hans": "匹配库存"},
    "design.execution.skip": {"en": "Skip / Don't Deduct", "zh-Hans": "跳过 (不扣减)"},
    "design.execution.deduct": {"en": "Amount to Deduct", "zh-Hans": "扣减数量"}
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
