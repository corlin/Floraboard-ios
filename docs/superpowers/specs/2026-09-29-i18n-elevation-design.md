# iOS 国际化多语言体系优化与查漏补缺设计规范 (i18n Elevation Design)

- **Date**: 2026-09-29
- **Platform**: iOS (Floraboard-ios)
- **Reference**: Web (floreboard-web / src/i18n)
- **Status**: Approved by User

---

## 1. 目标与背景

当前 iOS 版本（`Floraboard-ios`）仅支持中/英两种语言，且在最近重构与新增业务（会员充值、StoreKit 2 付费墙、点数中心、专业花艺流派设计表单、经营看板）中存在部分硬编码文案。与此同时，Web 版本（`floreboard-web`）已构建了涵盖 5 国语言（简中、英、日、韩、法）且结构化规范的分模块国际化字典体系。

本设计的核心目标：
1. **全面看齐 Web 语言矩阵**：在 iOS 端完整支持 **简体中文 (zh-Hans)**、**英语 (en)**、**日语 (ja)**、**韩语 (ko)**、**法语 (fr)** 5 国语言。
2. **字典同构与全量同步**：从 Web 版本的 5 个语言包同步导入基础业务字典（`app.*`, `auth.*`, `home.*`, `inventory.*`, `design.*`, `settings.*`, `onboarding.*`），并同构扩展 iOS 独有业务字典（`paywall.*`, `analytics.*`, `craft.*`）。
3. **级联回退机制**：构建 `Target Locale -> English (en) -> Simplified Chinese (zh-Hans) -> Raw Key` 的容错级联回退机制。
4. **硬编码零遗漏清网**：重构 `SettingsView`、`HomeView`、`PaywallView`、`Design*`、`Inventory*`、`LoginView`，消灭所有硬编码中文字符串。
5. **设置页交互体验升级**：将原仅支持 2 项的分段器升级为高质感的原生下拉菜单行（Menu Row），即选即响应式刷新。
6. **AI 生成多语言联动**：用户切换语言后，动态向 AI 提示词注入对应语言指令约束，实现方案名、花语与制作步骤原生本地化输出。

---

## 2. 核心架构与设计

### 2.1 语言枚举与 Bundle 资源映射 (`Floreboard/App/Localization.swift`)

扩展 `Language` 枚举：
```swift
enum Language: String, CaseIterable, Identifiable {
  case zh = "zh"
  case en = "en"
  case ja = "ja"
  case ko = "ko"
  case fr = "fr"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .zh: return "简体中文"
    case .en: return "English"
    case .ja: return "日本語"
    case .ko: return "한국어"
    case .fr: return "Français"
    }
  }

  /// 对应 Xcode xcstrings 与 lproj 资源目录标识符
  var lprojName: String {
    switch self {
    case .zh: return "zh-Hans"
    case .en: return "en"
    case .ja: return "ja"
    case .ko: return "ko"
    case .fr: return "fr"
    }
  }
}
```

### 2.2 级联回退逻辑 (`LocalizationManager` & `Tx`)

```swift
struct Tx {
  static func t(_ key: String, _ args: [String: String] = [:]) -> String {
    // 1. 获取当前设置语言对应的 bundle
    let currentBundle = LocalizationManager.shared.localizedBundle
    var value = currentBundle.localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)
    
    // 2. 若未找到且当前不是 en，回退至 en
    if value == "__NOT_FOUND__" {
      if let enBundle = LocalizationManager.shared.enBundle {
        value = enBundle.localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)
      }
    }
    
    // 3. 若仍未找到且当前不是 zh-Hans，回退至 zh-Hans
    if value == "__NOT_FOUND__" {
      if let zhBundle = LocalizationManager.shared.zhBundle {
        value = zhBundle.localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)
      }
    }
    
    // 4. 若最终都未找到，回退至 key 本身
    if value == "__NOT_FOUND__" {
      value = key
    }

    // 插值变量替换: {{param}}
    for (k, v) in args {
      value = value.replacingOccurrences(of: "{{\(k)}}", with: v)
    }
    return value
  }
}
```

### 2.3 字典结构同构规范 (`Floreboard/Localizable.xcstrings`)

`Localizable.xcstrings` 覆盖 5 种语言 (`zh-Hans`, `en`, `ja`, `ko`, `fr`)，包含以下主要命名空间：

1. **`app.*`**：应用名称、主导航（看板、设计、库存、记录、设置）、全局通用操作（确认、取消、保存、返回、刷新、删除等）。
2. **`auth.*`**：登录/注册标题、店铺名称、邮箱输入、密码输入、切换注册/登录文案、错误提示。
3. **`home.*`**：经营概览指标（在库花材量、紧缺预警量、累计预估营收）、快速操作、近期创作作品列表、无数据提示。
4. **`inventory.*`**：花材管理列表、筛选分类、新增花材、编辑成本/售价/预警线、库存扣减与出入库。
5. **`design.*`**：AI 创作主界面、场景选择（商务会展、婚礼庆典、节日花礼等）、风格预算、专业流派与工艺（`design.pro.*`）、步骤执行（`design.execution.*`）。
6. **`settings.*`**：店铺设置、账户卡片、业务参数（低库存预警阈值、默认预算）、会员与点数（`settings.credits.*`）、语言切换。
7. **`paywall.*`**：会员充值墙（`paywall.title`, `paywall.pro_monthly`, `paywall.pro_yearly`, `paywall.credit_pack_100`, `paywall.credit_pack_300`, `paywall.benefits.*`）。
8. **`analytics.*`**：数据看板统计指标、图表分类、毛利率趋势。

### 2.4 UI 交互优化 (`SettingsView.swift`)

在设置页将原本紧凑局促的 2 段 Segmented Control 替换为精致的下拉菜单行（Menu Row）：
```swift
// 语言切换卡片
VStack(alignment: .leading, spacing: 16) {
  SectionHeader(title: localizationManager.t("settings.language"), icon: "globe")

  Menu {
    ForEach(Language.allCases) { lang in
      Button {
        withAnimation(AppTheme.springDefault) {
          localizationManager.currentLanguage = lang
        }
      } label: {
        HStack {
          Text(lang.displayName)
          if localizationManager.currentLanguage == lang {
            Image(systemName: "checkmark")
          }
        }
      }
    }
  } label: {
    HStack {
      Text(localizationManager.t("settings.currentLanguage"))
        .font(AppTheme.bodySmall)
        .foregroundColor(AppTheme.foreground)
      Spacer()
      HStack(spacing: 6) {
        Text(localizationManager.currentLanguage.displayName)
          .font(AppTheme.sansFont(size: 15, weight: .medium))
          .foregroundColor(AppTheme.primary)
        Image(systemName: "chevron.up.chevron.down")
          .font(.system(size: 12))
          .foregroundColor(AppTheme.mutedText)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(AppTheme.surfaceElevated)
      .cornerRadius(AppTheme.controlRadius)
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.controlRadius)
          .stroke(AppTheme.hairline, lineWidth: 1)
      )
    }
  }
}
.padding(20)
.glassmorphic()
.padding(.horizontal, 24)
```

### 2.5 AI Prompt 动态语言输出指令 (`Floreboard/Core/Services/AIProxyClient.swift`)

在 `buildSystemPrompt` 中根据所选语言注入精准指令：
```swift
let langInstruction: String
switch language {
case .zh:
  langInstruction = "必须全部使用简体中文输出所有文本（包括花名、设计理念、步骤等）。"
case .en:
  langInstruction = "You must output all text in English (including flower names, design rationale, steps, etc.)."
case .ja:
  langInstruction = "花の名前、デザインコンセプト、制作手順などのすべてのテキストを必ず日本語で出力してください。"
case .ko:
  langInstruction = "꽃 이름, 디자인 컨셉, 제작 단계 등 모든 텍스트를 반드시 한국어로 출력하십시오."
case .fr:
  langInstruction = "Vous devez rédiger tous les textes en français (noms de fleurs, concept de design, étapes, etc.)."
}
```

---

## 3. 验收标准与验证方案

1. **编译与构建验证**：
   - 更新 `Localizable.xcstrings` 与代码后，`xcodebuild` 针对物理机 `corlin17mx` 编译无任何报错或丢失警告。
2. **多语言即时生效验证**：
   - 在设置中分别切换为 简中、English、日本語、한국어、Français：
     - 主导航 Tab、主页统计、设置卡片即时刷新为对应语言。
     - 付费墙弹窗（`PaywallView`）完整展示 5 国语言的会员价格与点数权益文案。
3. **零漏翻/零硬编码检验**：
   - 全局静态代码扫描，验证 `Floreboard/Features/` 中无裸露的硬编码中文提示。
4. **AI 生成多语言验证**：
   - 切换至日语/英语时触发一次 AI 设计生成，验证返回的方案标题与制作步骤与目标语言一致。
