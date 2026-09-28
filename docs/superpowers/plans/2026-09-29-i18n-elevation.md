# iOS 国际化多语言体系优化与查漏补缺实施计划 (i18n Elevation Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 深度对齐 Web 端 5 国语言体系（简体中文、English、日本語、한국어、Français），构建级联回退与同构字典，消灭所有硬编码，升级设置页语言切换体验，并联动 AI 多语言生成。

**Architecture:** 
1. 语言核心层：扩展 `Language` 为 5 种语言，`LocalizationManager` 实现 `Target -> en -> zh-Hans -> key` 级联回退。
2. 资源层：从 Web 端 5 国语言包转换提取，合并构建支持 5 种语言的 `Localizable.xcstrings`。
3. 视图交互层：SettingsView 升级为原生 Menu Row；全面清网 `SettingsView`、`HomeView`、`PaywallView`、`LoginView` 硬编码。
4. 业务协同层：`AIProxyClient` 动态构造对应语言的系统提示词，端到端实现多语言方案生成。

**Tech Stack:** Swift 5.9+, SwiftUI, Xcode String Catalog (.xcstrings), iOS 17.0+

## Global Constraints
- 遵循 100% SwiftUI MVVM 架构。
- 所有颜色、字体、弹簧动画严格使用 `AppTheme.swift` 规范。
- 所有用户界面文案严禁硬编码，必须通过 `Tx.t(...)` 或 `loc.t(...)` 调用。
- 字典命名空间与 Web 端保持一致（`app.*`, `auth.*`, `home.*`, `inventory.*`, `design.*`, `settings.*`），iOS 专属功能按 `paywall.*`, `analytics.*`, `craft.*` 命名。

---

### Task 1: 扩展 Language 枚举与 LocalizationManager 级联回退机制

**Files:**
- Modify: `Floreboard/App/Localization.swift`
- Test: Build verification with `xcodebuild`

**Interfaces:**
- Consumes: `UserDefaults`
- Produces: `Language` (with `.zh`, `.en`, `.ja`, `.ko`, `.fr`), `LocalizationManager.shared.localizedBundle`, `Tx.t(_:args:)` cascading fallback

- [ ] **Step 1: 更新 `Language` 枚举支持 5 种语言**
  扩展支持 `zh` (zh-Hans), `en` (en), `ja` (ja), `ko` (ko), `fr` (fr)，并提供对应的 `displayName` 和 `lprojName`。
- [ ] **Step 2: 升级 `LocalizationManager` Bundle 加载与 `Tx.t` 级联回退**
  缓存 `enBundle` 与 `zhBundle`，当当前语言对应 bundle 找不到特定 key 时，自动按 `Target -> en -> zh-Hans -> key` 进行回退。
- [ ] **Step 3: 编译验证**
  运行: `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' build`
  确认编译无任何类型不匹配错误。
- [ ] **Step 4: Commit**
  ```bash
  git add Floreboard/App/Localization.swift
  git commit -m "feat(i18n): expand Language enum to 5 languages with cascading fallback"
  ```

---

### Task 2: 提取 Web 5 国语言包并构建 Localizable.xcstrings

**Files:**
- Create: `scratch/sync_i18n.js` (临时同步脚本)
- Modify: `Floreboard/Localizable.xcstrings`
- Source: `/Users/corlin/2026/floreboard-web/src/i18n/locales/*.json`

**Interfaces:**
- Consumes: Web JSON locales (`zh-CN.json`, `en-US.json`, `ja-JP.json`, `ko-KR.json`, `fr-FR.json`)
- Produces: 5-language entries in `Localizable.xcstrings` including `paywall.*`, `analytics.*`, `craft.*`, `settings.credits.*`

- [ ] **Step 1: 编写脚本合并 Web 字典与 iOS 专属词条**
  读取 Web 5 个 json 文件，展平所有嵌套键（如 `auth.loginTitle`），并为 iOS 特有键（`paywall.*`, `analytics.*`, `craft.*`, `settings.credits.*`）补充 5 种语言的标准翻译。
- [ ] **Step 2: 执行脚本生成并写回 `Localizable.xcstrings`**
  运行脚本，检查生成后的 `Localizable.xcstrings`，验证 5 个语言标识符（`zh-Hans`, `en`, `ja`, `ko`, `fr`）均已正确写入。
- [ ] **Step 3: 验证 String Catalog 格式与编译**
  运行: `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' build`
  确认 Xcode 成功识别并编译 5 种语言的 xcstrings。
- [ ] **Step 4: Commit**
  ```bash
  git add Floreboard/Localizable.xcstrings
  git commit -m "feat(i18n): sync 5 languages dictionaries from web into xcstrings"
  ```

---

### Task 3: 升级 SettingsView 语言切换交互并消除硬编码

**Files:**
- Modify: `Floreboard/Features/Settings/SettingsView.swift`
- Modify: `Floreboard/Features/Settings/SettingsViewModel.swift`

**Interfaces:**
- Consumes: `LocalizationManager.shared.currentLanguage`, `Tx.t`
- Produces: Native Menu Row for language switching, fully localized Credits & Account cards

- [ ] **Step 1: 将 Segmented Picker 替换为精致原生 Menu Row**
  展示带有地球图标的语言选择行，显示当前语言与对勾，点击展开 5 种语言列表，支持平滑 spring 动画切换。
- [ ] **Step 2: 清除设置页所有硬编码文案**
  将会员与点数卡片（`当前剩余点数`、`点`、`到期`、`PRO 专业版`、`充值点数 / 升级会员`、`近期账单明细`、`保存成功`等）全部替换为 `loc.t("settings.credits.*")` / `loc.t("settings.*")`。
- [ ] **Step 3: 编译并验证**
  运行: `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' build`
  确认无编译错误。
- [ ] **Step 4: Commit**
  ```bash
  git add Floreboard/Features/Settings/SettingsView.swift Floreboard/Features/Settings/SettingsViewModel.swift
  git commit -m "feat(settings): upgrade language switcher to Menu row and localize credits card"
  ```

---

### Task 4: 全局界面硬编码清网与查漏补缺

**Files:**
- Modify: `Floreboard/Features/Home/HomeView.swift`
- Modify: `Floreboard/Features/Paywall/PaywallView.swift`
- Modify: `Floreboard/Features/Auth/LoginView.swift`
- Modify: `Floreboard/Features/Design/ProfessionalFormView.swift`
- Modify: `Floreboard/Features/Design/DesignExecutionSheet.swift`

**Interfaces:**
- Consumes: `Tx.t(key, args)`
- Produces: Zero hardcoded Chinese strings in views

- [ ] **Step 1: 清理 HomeView 硬编码**
  将统计指标单位（`枝在库`、`种紧缺`、`总营收`、`枝精选`等）替换为 `Tx.t("home.stats.*")`。
- [ ] **Step 2: 清理 PaywallView 硬编码**
  将付费墙标题、副标题、特权说明、点数包说明（`升级会员与点数充值`、`当前剩余点数:`、`稍后再说`、`+XX 点数`）全面替换为 `Tx.t("paywall.*")`。
- [ ] **Step 3: 清理 LoginView & DesignView 剩余硬编码**
  确保登录注册切换、流派工艺选择、出库确认弹窗全部使用 `Tx.t(...)`。
- [ ] **Step 4: 静态代码扫描检查**
  运行 grep 脚本检查 `Floreboard/Features`，确认无未本地化的文本展示。
- [ ] **Step 5: 编译并验证**
  运行: `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' build`
- [ ] **Step 6: Commit**
  ```bash
  git add Floreboard/Features/
  git commit -m "feat(i18n): eliminate hardcoded strings across Home, Paywall and Auth views"
  ```

---

### Task 5: AI 提示词多语言动态指令联动

**Files:**
- Modify: `Floreboard/Core/Services/AIProxyClient.swift`

**Interfaces:**
- Consumes: `Language`
- Produces: Dynamic system prompt with native language output constraints for `.zh`, `.en`, `.ja`, `.ko`, `.fr`

- [ ] **Step 1: 更新 `buildSystemPrompt` 注入 5 国语言指令**
  针对 5 种语言精确设定输出约束（花名、设计理念、步骤等），确保大模型严格按照用户选择的语言返回 JSON 数据。
- [ ] **Step 2: 编译验证**
  运行: `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' build`
- [ ] **Step 3: Commit**
  ```bash
  git add Floreboard/Core/Services/AIProxyClient.swift
  git commit -m "feat(ai): add 5-language dynamic prompt instructions for floral design generation"
  ```

---

### Task 6: 物理设备部署与全链路验证 (corlin17mx)

**Files:**
- Target: Device `00008150-0009599C3C43401C` (`corlin17mx`)

- [ ] **Step 1: 物理真机编译打包**
  运行: `xcodebuild -project Floreboard.xcodeproj -scheme Floreboard -destination 'generic/platform=iOS' -derivedDataPath ./build/DerivedData build`
- [ ] **Step 2: 安装到物理设备**
  运行: `/opt/homebrew/bin/ideviceinstaller -u 00008150-0009599C3C43401C install ./build/DerivedData/Build/Products/Debug-iphoneos/Floreboard.app`
- [ ] **Step 3: 运行验证与多语言切换测试**
  在设备端测试：
  1. 切换至 English，验证首页、设计、库存、设置、付费墙全部呈现 English。
  2. 切换至 日本語，验证菜单与文字全部转换为日文。
  3. 切换至 한국어 与 Français，验证完整无漏翻。
- [ ] **Step 4: 最终 Commit & Tag**
  ```bash
  git commit -m "release: i18n elevation complete with 5 languages on iOS and physical verification"
  ```
