// 运行方式：mkdir -p /tmp/ept && cp scripts/execution_plan_test.swift /tmp/ept/main.swift && \
//   xcrun swiftc -o /tmp/ept/run /tmp/ept/main.swift Floreboard/Core/Utils/ExecutionPlan.swift Floreboard/Core/Utils/DesignPricing.swift && /tmp/ept/run
import Foundation
var failures = 0
func check(_ name: String, _ cond: Bool) { if cond { print("PASS  \(name)") } else { failures += 1; print("FAIL  \(name)") } }

let inv = [(id: "r", name: "红 玫瑰"), (id: "e", name: "Eucalyptus")]
let exp = ExecutionPlan.expectedDeductions(rows: [("红玫瑰", 5), ("eucalyptus", 3), ("红玫瑰", 2), ("幽灵花", 4), ("x", 0)], inventory: inv)
check("matches ignoring whitespace/case, sums duplicates, skips unknown/zero", exp == ["r": 7, "e": 3])
check("nil mapping uses server path", ExecutionPlan.matchesServer(mapped: nil, expected: exp))
check("identical mapping uses server path", ExecutionPlan.matchesServer(mapped: [("r", 7), ("e", 3)], expected: exp))
check("remapped unknown flower forces local path", !ExecutionPlan.matchesServer(mapped: [("r", 7), ("e", 3), ("z", 4)], expected: exp))
check("changed amount forces local path", !ExecutionPlan.matchesServer(mapped: [("r", 6), ("e", 3)], expected: exp))
check("split mapping of same flower still equals", ExecutionPlan.matchesServer(mapped: [("r", 5), ("r", 2), ("e", 3)], expected: exp))

check("budget is the price when set", DesignPricing.price(budget: 500, retail: 300) == 500)
check("retail is the price without budget", DesignPricing.price(budget: nil, retail: 300) == 300 && DesignPricing.price(budget: 0, retail: 300) == 300)
check("margin = profit / price, negative allowed", DesignPricing.margin(price: 200, profit: -50) == -0.25 && DesignPricing.margin(price: 0, profit: 5) == 0)
print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
