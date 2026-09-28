# Task 1 Brief: 扩展 Language 枚举与 LocalizationManager 级联回退机制

**File:**
- Modify: `Floreboard/App/Localization.swift`

**Requirements:**
1. 扩展 `Language` 枚举支持 5 种语言：
   - `.zh` -> rawValue: "zh", displayName: "简体中文", lprojName: "zh-Hans"
   - `.en` -> rawValue: "en", displayName: "English", lprojName: "en"
   - `.ja` -> rawValue: "ja", displayName: "日本語", lprojName: "ja"
   - `.ko` -> rawValue: "ko", displayName: "한국어", lprojName: "ko"
   - `.fr` -> rawValue: "fr", displayName: "Français", lprojName: "fr"
2. 在 `LocalizationManager` 中：
   - 保持 `@MainActor class LocalizationManager: ObservableObject`
   - 初始化时预先/按需获取并缓存 `enBundle` 与 `zhBundle`
   - 当切换 `currentLanguage` 时，更新当前 `localizedBundle`
3. 升级 `Tx.t(_ key: String, _ args: [String: String] = [:]) -> String`：
   - 级联回退顺序：
     1. 从当前语言 Bundle 中查询 `localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)`
     2. 若返回 `__NOT_FOUND__` 且当前语言不是英文，尝试从 `en` Bundle 查询
     3. 若仍为 `__NOT_FOUND__` 且当前语言不是中文，尝试从 `zh-Hans` Bundle 查询
     4. 若仍未找到，直接使用 `key` 作为回退
   - 支持变量插值替换 `{{param}}`
4. 验证编译：
   - 运行 `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/DerivedData build`
   - 确保无编译报错
5. 完成后执行 git commit：
   - `git add Floreboard/App/Localization.swift`
   - `git commit -m "feat(i18n): expand Language enum to 5 languages with cascading fallback"`
