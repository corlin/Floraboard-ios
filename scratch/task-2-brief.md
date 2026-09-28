# Task 2 Brief: 提取 Web 5 国语言包并构建 Localizable.xcstrings

**Files:**
- Create: `scratch/sync_i18n.js`
- Modify: `Floreboard/Localizable.xcstrings`
- Sources:
  - `/Users/corlin/2026/floreboard-web/src/i18n/locales/zh-CN.json`
  - `/Users/corlin/2026/floreboard-web/src/i18n/locales/en-US.json`
  - `/Users/corlin/2026/floreboard-web/src/i18n/locales/ja-JP.json`
  - `/Users/corlin/2026/floreboard-web/src/i18n/locales/ko-KR.json`
  - `/Users/corlin/2026/floreboard-web/src/i18n/locales/fr-FR.json`

**Requirements:**
1. 编写 Node.js 脚本 `scratch/sync_i18n.js`：
   - 读取已有的 `Floreboard/Localizable.xcstrings`
   - 读取 Web 端的 5 个语言包（`zh-CN.json`, `en-US.json`, `ja-JP.json`, `ko-KR.json`, `fr-FR.json`）
   - 展平 Web 端所有多层嵌套 key（如 `auth.loginTitle`），映射到 5 种语言代号：
     - `zh-CN` -> `zh-Hans`
     - `en-US` -> `en`
     - `ja-JP` -> `ja`
     - `ko-KR` -> `ko`
     - `fr-FR` -> `fr`
   - 为 iOS 特有键与新增键补全 5 种语言翻译，包括：
     - `paywall.*`：充值与会员订阅墙文案
     - `settings.credits.*`：设置页点数与会员卡片文案
     - `settings.currentLanguage`：当前选择语言行标签
     - `home.stats.*`：首页在库/紧缺/营收/精选单位文案
     - `analytics.*`：经营看板文案
     - `design.pro.*` / `pro.school.*` / `pro.tech.*`：流派技法
   - 将现有 iOS xcstrings 中的有效词条与 Web 词条合并，为缺少日/韩/法文的条目基于中/英进行优雅补全。
   - 写回 `Floreboard/Localizable.xcstrings`，确保遵循 Apple String Catalog 1.0 JSON 格式。
2. 验证：
   - 检查 `Localizable.xcstrings` 中包含 5 个语言标识（`zh-Hans`, `en`, `ja`, `ko`, `fr`）。
   - 运行 `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/DerivedData build`，确保 Xcode 正确编译 String Catalog。
3. 提交：
   - `git add Floreboard/Localizable.xcstrings scratch/sync_i18n.js`
   - `git commit -m "feat(i18n): sync 5 languages dictionaries from web into xcstrings"`
4. 输出报告至 `scratch/task-2-report.md`。
