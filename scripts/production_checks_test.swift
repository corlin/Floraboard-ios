// 运行方式（含顶层代码的 Swift 文件必须叫 main.swift）：
//   mkdir -p /tmp/pct && cp scripts/production_checks_test.swift /tmp/pct/main.swift && \
//   xcrun swiftc -o /tmp/pct/run /tmp/pct/main.swift Floreboard/Core/Utils/ProductionChecks.swift && /tmp/pct/run
import Foundation
var failures = 0
func check(_ n: String, _ c: Bool) { if c { print("PASS  \(n)") } else { failures += 1; print("FAIL  \(n)") } }
func item(_ n: String, _ c: Int, _ r: StemRole, cost: Double = 5, retail: Double = 12, stock: Int? = 100) -> ProductionItem {
  ProductionItem(name: n, count: c, role: r, unitCost: cost, retailPrice: retail, stock: stock, colorHex: nil)
}
func ids(_ a: ProductionAnalysis) -> [String] { a.checks.map { $0.id } }

// 与网页端测试同一场景：缺货 + AI 凭空花材 + 超预算
let a = ProductionChecks.analyze(items: [
  item("红玫瑰", 12, .main, cost: 6, retail: 15, stock: 5),
  item("尤加利叶", 30, .foliage, cost: 2, retail: 5),
  item("幻觉花", 3, .filler, cost: 3, retail: 6, stock: nil),
], price: 100, executed: false)
check("totals: 45 stems, cost 141", a.stems == 45 && a.cost == 141)
check("stock shortfall detected with numbers", a.checks.contains { $0.id == "stockShort" && $0.params["short"] == "7" && $0.params["name"] == "红玫瑰" })
check("flower missing from inventory warns", ids(a).contains("notInInventory"))
check("cost over price is an error", a.checks.contains { $0.id == "budgetOver" && $0.level == .error })
check("over budget does not also report low margin", !ids(a).contains("lowMargin"))

let b = ProductionChecks.analyze(items: [item("红玫瑰", 3, .main, stock: 0)], price: 100, executed: true)
check("executed designs skip the stock check", !ids(b).contains("stockShort"))
check("cost far below price warns (under 30%)", ids(b).contains("budgetUnder"))

// 截图里的方案：成本 160 / 成交价 200 => 利润率 20% < 35%
let c = ProductionChecks.analyze(items: [
  item("牡丹", 4, .main, cost: 30, retail: 60), item("兰花", 2, .main, cost: 15, retail: 30), item("白玫瑰", 2, .main, cost: 5, retail: 12),
], price: 200, executed: false)
check("screenshot case: margin 20% -> lowMargin warn", c.cost == 160 && Int((c.margin * 100).rounded()) == 20 && c.checks.contains { $0.id == "lowMargin" && $0.params["margin"] == "20" })

check("no main flower warns", ids(ProductionChecks.analyze(items: [item("尤加利叶", 5, .foliage)], price: 100, executed: false)).contains("noMainFlower"))
check("foliage/filler heavy warns at >75% of >=8 stems", ids(ProductionChecks.analyze(items: [item("玫瑰", 2, .main), item("叶", 8, .foliage)], price: 0, executed: false)).contains("foliageHeavy"))
check("price <= 0 skips budget and margin checks", ProductionChecks.analyze(items: [item("玫瑰", 2, .main)], price: 0, executed: false).checks.isEmpty)
check("zero-count rows are ignored", ProductionChecks.analyze(items: [item("玫瑰", 0, .main)], price: 100, executed: false).rows.isEmpty)
check("healthy plan has no checks", ProductionChecks.analyze(items: [item("玫瑰", 6, .main, cost: 5), item("洋甘菊", 4, .filler, cost: 3), item("尤加利叶", 5, .foliage, cost: 2)], price: 100, executed: false).checks.isEmpty)

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED"); exit(failures == 0 ? 0 : 1)
