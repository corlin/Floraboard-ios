// 运行方式（含顶层代码的 Swift 文件必须叫 main.swift）：
//   mkdir -p /tmp/dmt && cp scripts/design_merge_test.swift /tmp/dmt/main.swift && \
//   xcrun swiftc -o /tmp/dmt/run /tmp/dmt/main.swift Floreboard/Core/Utils/DesignMerge.swift && /tmp/dmt/run
import Foundation
// 独立测试：只复制 DesignMerge 用到的字段，真实类型由整个 App 的编译保证一致。
enum ImageStatus: String { case pending = "PENDING", generating = "GENERATING", succeeded = "SUCCEEDED", failed = "FAILED" }
enum DesignStatus: String { case draft, completed }
struct DesignResult {
  var status: DesignStatus = .draft; var executedAt: Double? = nil
  var imageUrl: String? = nil; var imageStatus: ImageStatus? = nil; var imageError: String? = nil
  var imagePrompt: String? = nil; var referenceImageUrl: String? = nil
  var rating: Int? = nil; var feedback: String? = nil; var createdAt: Double = 0
  // 真实类型是 DesignRequestSnapshot / DesignFindings；合并逻辑只关心“有没有”
  var request: String? = nil; var findings: String? = nil
}
var failures = 0
func check(_ name: String, _ cond: Bool) { if cond { print("PASS  \(name)") } else { failures += 1; print("FAIL  \(name)") } }

check("remote url detection", DesignMerge.isRemoteImage("https://api.floreboard.com/x.jpg") && DesignMerge.isRemoteImage("HTTP://a/b"))
check("local filename / empty / nil are not remote", !DesignMerge.isRemoteImage("7DB37289-1358.jpg") && !DesignMerge.isRemoteImage("") && !DesignMerge.isRemoteImage(nil))
check("ms -> seconds, seconds untouched", DesignMerge.seconds(1_790_000_000_000) == 1_790_000_000 && DesignMerge.seconds(1_790_000_000) == 1_790_000_000)
var t = DesignResult(); t.createdAt = 1_790_000_000_000; t.executedAt = 1_790_000_005_000
let n = DesignMerge.normalizedTimestamps(t); check("normalizedTimestamps", n.createdAt == 1_790_000_000 && n.executedAt == 1_790_000_005)

// 云端旧副本（停在 PENDING、图片为本地文件名）vs 本地已完成
var cloud = DesignResult(); cloud.imageStatus = .pending; cloud.imageUrl = "ABC.jpg"
var local = DesignResult(); local.status = .completed; local.executedAt = 111; local.imageStatus = .succeeded
local.imageUrl = "https://api.floreboard.com/api/v1/storage/reference/t/a.jpg"; local.rating = 5; local.feedback = "好"; local.referenceImageUrl = "ref_1.jpg"
let m = DesignMerge.merge(local: local, cloud: cloud)
check("local completed beats cloud draft (and keeps executedAt)", m.status == .completed && m.executedAt == 111)
check("remote image URL beats local filename", m.imageUrl == local.imageUrl)
check("succeeded beats pending, error cleared", m.imageStatus == .succeeded && m.imageError == nil)
check("rating/feedback kept when cloud has none", m.rating == 5 && m.feedback == "好")
check("reference image stays local", m.referenceImageUrl == "ref_1.jpg")
check("merge differing from cloud => needs push", DesignMerge.needsPush(merged: m, cloud: cloud))

// 云端更靠前（别的设备执行/评分/出图成功）不被本地旧状态回退
var cloud2 = DesignResult(); cloud2.status = .completed; cloud2.executedAt = 222; cloud2.rating = 3
cloud2.imageStatus = .succeeded; cloud2.imageUrl = "https://x/y.jpg"
var local2 = DesignResult(); local2.imageStatus = .generating; local2.imageUrl = "old.jpg"
let m2 = DesignMerge.merge(local: local2, cloud: cloud2)
check("cloud ahead is never rolled back by an older local copy", m2.status == .completed && m2.executedAt == 222 && m2.rating == 3 && m2.imageUrl == "https://x/y.jpg" && m2.imageStatus == .succeeded)
check("identical state => no push", !DesignMerge.needsPush(merged: m2, cloud: cloud2))

// 本地失败不覆盖云端的成功；本地成功覆盖云端的失败
var c3 = DesignResult(); c3.imageStatus = .failed; c3.imageError = "boom"
var l3 = DesignResult(); l3.imageStatus = .succeeded
check("local success overrides cloud failure", DesignMerge.merge(local: l3, cloud: c3).imageStatus == .succeeded && DesignMerge.merge(local: l3, cloud: c3).imageError == nil)
check("local failure does not override cloud success", DesignMerge.merge(local: c3, cloud: l3).imageStatus == .succeeded)
check("empty local image never blanks a cloud image", { var c = DesignResult(); c.imageUrl = "https://x/y.jpg"; return DesignMerge.merge(local: DesignResult(), cloud: c).imageUrl == "https://x/y.jpg" }())
check("cloud copy without request/findings keeps the local ones", { var l = DesignResult(); l.request = "req"; l.findings = "fnd"; let m = DesignMerge.merge(local: l, cloud: DesignResult()); return m.request == "req" && m.findings == "fnd" }())
check("cloud request/findings win when present", { var l = DesignResult(); l.request = "old"; var c = DesignResult(); c.request = "new"; c.findings = "srv"; let m = DesignMerge.merge(local: l, cloud: c); return m.request == "new" && m.findings == "srv" }())

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
