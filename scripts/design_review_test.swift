// 运行方式：mkdir -p /tmp/drt && cp scripts/design_review_test.swift /tmp/drt/main.swift && xcrun swiftc -o /tmp/drt/run /tmp/drt/main.swift Floreboard/Core/Models/DesignReview.swift && /tmp/drt/run
import Foundation
enum OccasionType: String { case home }
enum RecipientType: String { case friend }
enum StyleType: String { case fresh }
struct DesignRequest { var occasion = OccasionType.home; var recipient = RecipientType.friend; var style = StyleType.fresh; var budget: Double? = nil; var school: String? = nil; var technique: String? = nil; var seasonality: String? = nil }
let json = #"{"v":"1","at":"x","items":[{"id":"tabooFour","level":"info","params":{"names":"玫瑰","n":4,"x":2.5},"flowers":["玫瑰"]},{"id":"a","level":"weird","params":{}}]}"#
let f = try! JSONDecoder().decode(DesignFindings.self, from: Data(json.utf8))
var bad = 0
func check(_ n: String, _ c: Bool) { print(c ? "PASS  \(n)" : "FAIL  \(n)"); if !c { bad += 1 } }
check("numbers become strings", f.items[0].params["n"] == "4" && f.items[0].params["x"] == "2.5" && f.items[0].params["names"] == "玫瑰")
check("unknown level degrades to info", f.items[1].level == .info)
check("counts", f.errorCount == 0 && f.warnCount == 0 && f.infoCount == 2 && f.badgeCount == 0)
let rt = try! JSONDecoder().decode(DesignFindings.self, from: JSONEncoder().encode(f))
check("round trip", rt == f)
exit(bad == 0 ? 0 : 1)
