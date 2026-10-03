#!/usr/bin/env bash
# 运行 scripts/ 下的独立逻辑测试（不依赖 Xcode 工程的测试 target）。
# 每个测试只和它要测的源文件一起编译，失败时返回非 0。
#   用法：scripts/run_logic_tests.sh
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
failed=0

run() {
  local name="$1"; shift
  mkdir -p "$WORK/$name"
  cp "scripts/$name.swift" "$WORK/$name/main.swift"
  if ! xcrun swiftc -o "$WORK/$name/run" "$WORK/$name/main.swift" "$@"; then
    echo "✗ $name: compile failed"; failed=1; return
  fi
  if "$WORK/$name/run"; then
    echo "✓ $name"
  else
    echo "✗ $name"; failed=1
  fi
}

run design_review_test Floreboard/Core/Models/DesignReview.swift
run production_checks_test Floreboard/Core/Utils/ProductionChecks.swift
run design_merge_test Floreboard/Core/Utils/DesignMerge.swift
run execution_plan_test Floreboard/Core/Utils/ExecutionPlan.swift Floreboard/Core/Utils/DesignPricing.swift
run sync_outbox_test Floreboard/Core/Utils/SyncOutboxState.swift

exit $failed
