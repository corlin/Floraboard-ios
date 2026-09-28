# Task 4 Brief: 全局界面硬编码清网与查漏补缺

**Target Files & Lines:**
1. `Floreboard/Features/Paywall/PaywallView.swift`
   - 替换所有硬编码文案为 `Tx.t("paywall.*")`：
     - 付费墙标题 `"升级会员与点数充值"` -> `Tx.t("paywall.title")`
     - `"当前剩余点数:"` -> `Tx.t("paywall.currentCredits")`
     - `"PRO 会员"` -> `Tx.t("paywall.proBadge")`
     - 特权描述 `"尊享大模型极速方案设计与 4K 商业效果图渲染"` -> `Tx.t("paywall.subtitle")`
     - 底部关闭按钮 `"稍后再说"` -> `Tx.t("paywall.later")`
     - `fallbackPlans` 数组中的标题、标签、描述等：
       - `pro_yearly`: `Tx.t("paywall.proYearly")`, `Tx.t("paywall.save25")`, `Tx.t("paywall.proYearlyDesc")`
       - `pro_monthly`: `Tx.t("paywall.proMonthly")`, `Tx.t("paywall.popular")`, `Tx.t("paywall.proMonthlyDesc")`
       - `credit_pack_100`: `Tx.t("paywall.pack100")`, `Tx.t("paywall.pack100Desc")`
       - `credit_pack_300`: `Tx.t("paywall.pack300")`, `Tx.t("paywall.bestValue")`, `Tx.t("paywall.pack300Desc")`
     - 计划项点数说明 `+\(plan.credits) 点数` -> `Tx.t("paywall.creditsBadge", ["count": "\(plan.credits)"])`

2. `Floreboard/Features/Home/HomeView.swift`
   - L336: `Text("枝在库")` -> `Text(Tx.t("home.stats.stockUnit"))`
   - L356: `Text("种紧缺")` -> `Text(Tx.t("home.stats.shortageUnit"))`
   - L376: `Text("总营收")` -> `Text(Tx.t("home.stats.revenueTitle"))`
   - L519: `Text("\(totalStems > 0 ? totalStems : design.flowerList.count) 枝精选")` -> `Text(Tx.t("home.stats.stemsSelected", ["count": "\(totalStems > 0 ? totalStems : design.flowerList.count)"]))`

3. `Floreboard/Features/Design/DesignMainView.swift`
   - L72: 生成按钮的点数角标 `(1点)` -> `Tx.t("design.costBadge", ["points": "1"])`

4. `Floreboard/Features/Analytics/InventoryAnalyticsSheetView.swift`
   - L147-149:
     - `"主花"` -> `Tx.t("inventory.category.primary")`
     - `"配花"` -> `Tx.t("inventory.category.secondary")`
     - `"叶材"` -> `Tx.t("inventory.category.foliage")`

5. `Floreboard/Features/Orders/FloristWorkbenchView.swift`
   - L134: `Text("原图")` -> `Text(Tx.t("order.originalImage"))`
   - L153: `Text(" · 定制花艺")` -> `Text(" · " + Tx.t("order.customFloral"))`

**Requirements:**
- 检查 `Localizable.xcstrings`，确保上述所有 key（如 `paywall.title`, `paywall.save25`, `home.stats.stockUnit`, `inventory.category.primary`, `order.originalImage` 等）在 5 国语言中均有对应译文；如果缺失，使用脚本或补齐至 xcstrings。
- 替换后运行 node 扫描脚本确认 `Floreboard/Features` 下硬编码中文字符串清零。
- 运行 `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/DerivedData build` 确保编译通过。
- 提交代码：`git commit -m "feat(i18n): eliminate hardcoded strings across Home, Paywall and Features"`
- 输出报告至 `scratch/task-4-report.md`。
