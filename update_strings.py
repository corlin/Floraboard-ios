import json

file_path = "/Users/corlin/2026/Floraboard-ios/Floreboard/Localizable.xcstrings"
with open(file_path, "r") as f:
    data = json.load(f)

new_keys = {
    "inventory.row.used": {"en": "Used", "zh-Hans": "已消耗"},
    "home.section.overview": {"en": "Overview", "zh-Hans": "概览"},
    "home.section.actions": {"en": "Actions", "zh-Hans": "快捷操作"},
    "home.section.recent_designs": {"en": "Recent Floral Designs", "zh-Hans": "最新花艺设计"},
    "home.section.gallery_subtitle": {"en": "A beautiful horizontal gallery", "zh-Hans": "设计作品全景画廊"},
    "home.stats.total_revenue": {"en": "Total Revenue", "zh-Hans": "总营收"},
    "home.card.designer_role": {"en": "Designer - Floral AI", "zh-Hans": "设计师 - 花艺 AI"},
    "home.card.orders": {"en": "Orders", "zh-Hans": "订单"},
    "home.card.stars": {"en": "Stars", "zh-Hans": "评分"},
    "home.card.likes": {"en": "Likes", "zh-Hans": "点赞"},
    "home.notifications.only_left": {"en": "Only {{count}} left", "zh-Hans": "仅剩 {{count}} 件"},
    "home.notifications.replenish": {"en": "Go to Inventory", "zh-Hans": "去补货"},
    "paywall.title": {"en": "Unlock Floreboard Pro", "zh-Hans": "解锁 Floreboard 专业版"},
    "paywall.subtitle": {"en": "Experience unlimited AI generation, premium visual muses, and priority processing.", "zh-Hans": "畅享无限 AI 生成、高级灵感库及优先处理服务。"},
    "paywall.feature1.title": {"en": "Unlimited AI Designs", "zh-Hans": "无限 AI 设计方案"},
    "paywall.feature1.subtitle": {"en": "Generate as many concepts as you need", "zh-Hans": "随心生成无限花艺创意灵感"},
    "paywall.feature2.title": {"en": "4K Resolution Export", "zh-Hans": "4K 高清分辨率导出"},
    "paywall.feature2.subtitle": {"en": "Crystal clear presentations for clients", "zh-Hans": "为客户呈现高清花艺展示方案"},
    "paywall.feature3.title": {"en": "Priority Processing", "zh-Hans": "专属优先处理通道"},
    "paywall.feature3.subtitle": {"en": "Skip the queue with dedicated servers", "zh-Hans": "无需排队，享受高速服务器运算"},
    "paywall.skip": {"en": "Maybe Later", "zh-Hans": "稍后再说"},
    "settings.subtitle": {"en": "Manage your store preferences", "zh-Hans": "管理您的花店偏好设置"},
    "settings.quota": {"en": "Account Quota", "zh-Hans": "账户配额"},
    "settings.quota_balance": {"en": "Credits Balance", "zh-Hans": "额度余额"},
    "settings.fetching_quota": {"en": "Fetching Quota...", "zh-Hans": "正在获取配额..."}
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

print("Successfully updated Localizable.xcstrings with all new keys.")
