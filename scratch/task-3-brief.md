# Task 3 Brief: 升级 SettingsView 语言切换交互并消除硬编码

**Files:**
- Modify: `Floreboard/Features/Settings/SettingsView.swift`
- Modify: `Floreboard/Features/Settings/SettingsViewModel.swift`

**Requirements:**
1. 语言切换卡片升级为原生 Menu Row：
   - SectionHeader 保持地球图标与 `localizationManager.t("settings.language")`。
   - 内容为一个优雅的水平条目：左侧为 `localizationManager.t("settings.currentLanguage")`（“当前语言 / Current Language”），右侧为一个原生 `Menu` 触发器，展示当前语言名称（如“简体中文”）、`chevron.up.chevron.down` 图标、圆角边框胶囊。
   - `Menu` 内部列出 `Language.allCases`，点击触发 `withAnimation(AppTheme.springDefault) { localizationManager.currentLanguage = lang }`，并在当前语言项显示对勾（`checkmark`）。
2. 全面消除设置页硬编码：
   - 将“会员与点数中心”卡片内的中文文本全部替换为 `localizationManager.t(...)`：
     - `"会员与点数中心"` -> `localizationManager.t("settings.credits.title")`
     - `"当前剩余点数"` -> `localizationManager.t("settings.credits.remaining")`
     - `"点"` -> `localizationManager.t("settings.credits.unit")`
     - `"PRO 专业版"` / `"免费体验"` -> `localizationManager.t("settings.credits.proBadge")` / `localizationManager.t("settings.credits.freeBadge")`
     - `"到期: ..."` -> `localizationManager.t("settings.credits.expires", ["date": ...])`
     - `"充值点数 / 升级会员"` -> `localizationManager.t("settings.credits.recharge")`
     - `"近期账单明细"` -> `localizationManager.t("settings.credits.history")`
     - 账单明细空状态 `"暂无账单明细"` -> `localizationManager.t("settings.credits.noHistory")`
   - 检查并确保其他卡片（账号、AI 服务、业务规则、退出登录）均已使用 `localizationManager.t(...)`。
3. 编译验证：
   - 运行: `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/DerivedData build`
   - 确保无任何语法错误或编译警告。
4. 提交更改：
   - `git add Floreboard/Features/Settings/SettingsView.swift Floreboard/Features/Settings/SettingsViewModel.swift`
   - `git commit -m "feat(settings): upgrade language switcher to Menu row and localize credits card"`
5. 输出报告至 `scratch/task-3-report.md`。
