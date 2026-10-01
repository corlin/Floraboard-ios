// 运行方式：mkdir -p /tmp/sot && cp scripts/sync_outbox_test.swift /tmp/sot/main.swift && \
//   xcrun swiftc -o /tmp/sot/run /tmp/sot/main.swift Floreboard/Core/Utils/SyncOutboxState.swift && /tmp/sot/run
import Foundation
var failures = 0
func check(_ name: String, _ cond: Bool) { if cond { print("PASS  \(name)") } else { failures += 1; print("FAIL  \(name)") } }

let up = SyncOp(kind: .designUpsert, id: "d1")
let del = SyncOp(kind: .designDelete, id: "d1")
var s = OutboxState()
s.enqueue(up, now: 100)
s.enqueue(up, now: 101)
check("duplicate enqueue is merged", s.entries.count == 1)
s.enqueue(del, now: 102)
check("delete cancels pending upsert", s.entries.count == 1 && s.entries[0].op == del)
s.enqueue(up, now: 103)
check("upsert after delete cancels the delete", s.entries.count == 1 && s.entries[0].op == up)
s.enqueue(SyncOp(kind: .flowerUpsert, id: "d1"), now: 104)
check("same id on a different entity is independent", s.entries.count == 2)

check("backoff grows and caps", OutboxState.backoff(failures: 1) == 5 && OutboxState.backoff(failures: 2) == 10 && OutboxState.backoff(failures: 3) == 20 && OutboxState.backoff(failures: 99) == 300)

var t = OutboxState()
t.enqueue(up, now: 0)
t.fail(up, kind: .failure, now: 10, message: "500")
check("failure counts and delays", t.entries[0].failures == 1 && t.entries[0].nextAttemptAt == 15 && t.due(now: 14).isEmpty && t.due(now: 15).count == 1)
t.fail(up, kind: .network, now: 20, message: "offline")
check("network failure does not count", t.entries[0].failures == 1 && t.entries[0].nextAttemptAt == 35)
t.fail(up, kind: .deferred, now: 20, message: "no auth")
check("deferred does not count", t.entries[0].failures == 1 && t.entries[0].nextAttemptAt == 80)
t.releaseWaiting(now: 21)
check("release does not touch entries that keep failing", t.entries[0].nextAttemptAt == 80)
var u = OutboxState(); u.enqueue(up, now: 0); u.fail(up, kind: .network, now: 10, message: nil)
u.releaseWaiting(now: 12)
check("release makes network-waiting entries due", u.due(now: 12).count == 1)
u.enqueue(up, now: 50); u.fail(up, kind: .failure, now: 50, message: "x"); u.enqueue(up, now: 51)
check("new local change resets failures", u.entries[0].failures == 0 && u.entries[0].nextAttemptAt == 51)
u.complete(up)
check("complete removes", u.entries.isEmpty && u.nextWake(now: 0) == nil)
var v = OutboxState(); v.enqueue(up, now: 100); v.enqueue(SyncOp(kind: .flowerDelete, id: "f"), now: 100)
check("hasPending by entity", v.hasPending(designs: true) && v.hasPending(designs: false) && v.has(.designUpsert, id: "d1") && !v.has(.designDelete, id: "d1"))
let data = try! JSONEncoder().encode(v)
check("codable round trip", (try? JSONDecoder().decode(OutboxState.self, from: data)) == v)
print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
