# Task 1 Implementation Report: 扩展 Language 枚举与 LocalizationManager 级联回退机制

- **Status**: DONE
- **Commit Hash**: `6ef3891deee9c64fee83ae0398676e84033b89d2` (`6ef3891`)
- **Modified File**: `Floreboard/App/Localization.swift`

## 1. 变更详情
1. **扩展 `Language` 枚举**：
   - 支持 5 种语言：`.zh` ("zh", "简体中文", "zh-Hans"), `.en` ("en", "English", "en"), `.ja` ("ja", "日本語", "ja"), `.ko` ("ko", "한국어", "ko"), `.fr` ("fr", "Français", "fr")。
   - 保留 `Identifiable` 与 `CaseIterable`。

2. **`LocalizationManager` 级联与多语言 Bundle 缓存**：
   - 保持 `@MainActor class LocalizationManager: ObservableObject`。
   - 预缓存 `enBundle` 与 `zhBundle`，更新 `localizedBundle` 并在切换语言时同步。
   - 适配系统默认语言判定（前缀匹配 `zh`, `ja`, `ko`, `fr`，默认 `en`）。

3. **升级 `Tx.t(_ key:args:)` 级联回退与线程安全**：
   - 使用 `bundleLock`（`NSLock`）线程安全读取当前语言及各个 Bundle 引用。
   - 级联顺序：
     1. 当前语言 Bundle 查询（未命中返回 `__NOT_FOUND__`）；
     2. 若未找到且当前语言非英文，查询 `enBundle`；
     3. 若仍未找到且当前语言非中文，查询 `zhBundle`；
     4. 仍未找到则回退至 `key`。
   - 支持 `{{param}}` 参数动态插值替换。

## 2. 编译验证
- 验证命令：
  ```bash
  xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/DerivedData build
  ```
- 验证结果：
  ```
  ** BUILD SUCCEEDED **
  ```
  无任何编译错误或警告。
