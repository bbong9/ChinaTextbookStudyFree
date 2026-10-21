#!/usr/bin/env bash
# sim-test.sh — 全机排队的模拟器测试入口（所有 Codex 任务都必须用它跑 xcodebuild test）
#
# 这台 Mac 同一时间只允许一个模拟器跑测试：脚本先拿全机唯一的锁，拿不到就排队等。
# 只用三台共用模拟器（iOS 18.6），缺了自动按同名创建；不准新建带卡号前缀的模拟器。
#
# 用法（在 worktree 根目录运行）：
#   scripts/redesign/sim-test.sh iphone16 [xcodebuild 额外参数...]
#   scripts/redesign/sim-test.sh se   -only-testing:ChinaTextbookStudyUITests/FooTests
#   scripts/redesign/sim-test.sh ipad -resultBundlePath /private/tmp/rd-03-ipad.xcresult
#
# 环境变量：
#   DERIVED_DATA   默认 /private/tmp/<当前分支名去掉 codex/>-derived
#   SIM_TEST_DRY_RUN=1  只打印将要执行的命令，不拿锁、不启动模拟器
set -euo pipefail

LOCK=/tmp/cstf-sim-test.lock
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-18-6

case "${1:-}" in
  iphone16) NAME="iPhone 16";            TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16 ;;
  se)       NAME="iPhone SE (3rd gen)";  TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation ;;
  ipad)     NAME="iPad (A16)";           TYPE=com.apple.CoreSimulator.SimDeviceType.iPad-A16 ;;
  *) echo "用法: $0 iphone16|se|ipad [xcodebuild 额外参数...]" >&2; exit 2 ;;
esac
shift

ROOT="$(git rev-parse --show-toplevel)"
BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
SLUG="${BRANCH#codex/}"; SLUG="${SLUG//\//-}"
DERIVED_DATA="${DERIVED_DATA:-/private/tmp/${SLUG}-derived}"

# 只认 iOS 18.6 下名字完全相同的那台。
device_id() {
  xcrun simctl list devices -j | python3 -c '
import json, sys
name, runtime = sys.argv[1], sys.argv[2]
for d in json.load(sys.stdin)["devices"].get(runtime, []):
    if d["name"] == name and d.get("isAvailable", True):
        print(d["udid"]); break
' "$NAME" "$RUNTIME"
}

CMD=(xcodebuild test
  -project "$ROOT/apps/mobile/ChinaTextbookStudy.xcodeproj"
  -scheme ChinaTextbookStudy
  -derivedDataPath "$DERIVED_DATA"
  -parallel-testing-enabled NO
  -disable-concurrent-destination-testing
  CODE_SIGNING_ALLOWED=NO
  "$@")

if [ "${SIM_TEST_DRY_RUN:-}" = "1" ]; then
  echo "设备: ${NAME}（$(device_id || true)）"
  echo "锁:   $LOCK"
  printf '命令:'; printf ' %q' "${CMD[@]}" -destination "platform=iOS Simulator,id=DEVICE"; echo
  exit 0
fi

# ---- 全机锁：mkdir 是原子操作；持锁进程已死则视为过期锁 ----
waited=0
until mkdir "$LOCK" 2>/dev/null; do
  holder="$(cat "$LOCK/owner" 2>/dev/null || true)"
  pid="${holder%% *}"
  if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
    echo "清理过期的测试锁（持有者 $holder 已退出）"
    rm -rf "$LOCK"; continue
  fi
  if [ $((waited % 60)) -eq 0 ]; then
    echo "⏳ 有别的任务在跑模拟器测试（${holder:-未知}），排队等待中… 已等 ${waited}s"
  fi
  sleep 5; waited=$((waited + 5))
done
echo "$$ $SLUG $(date '+%H:%M:%S')" > "$LOCK/owner"

ID=""
cleanup() {
  [ -n "$ID" ] && xcrun simctl shutdown "$ID" >/dev/null 2>&1 || true
  rm -rf "$LOCK"
}
trap cleanup EXIT
# 收到中断必须真正退出（EXIT 里统一释放锁），不能清了锁还继续往下跑。
trap 'exit 130' INT TERM

ID="$(device_id)"
if [ -z "$ID" ]; then
  echo "没有「${NAME}」，按共用名创建一台"
  ID="$(xcrun simctl create "$NAME" "$TYPE" "$RUNTIME")"
fi

# 本项目其他开着的模拟器（三台共用名或 RD- 前缀）：
#   - 还有 xcodebuild 在用（没走本脚本的旧任务）→ 排队等它跑完；
#   - 开着没人用 → 直接关掉。
# 别的项目的模拟器一概不动。
others() {
  xcrun simctl list devices booted -j | python3 -c '
import json, subprocess, sys
keep = sys.argv[1]
ours = {"iPhone 16", "iPhone SE (3rd gen)", "iPad (A16)"}
procs = subprocess.run(["ps", "-axo", "command"], capture_output=True, text=True).stdout
builds = [l for l in procs.splitlines() if "xcodebuild" in l and (" test" in l or "build" in l)]
for devs in json.load(sys.stdin)["devices"].values():
    for d in devs:
        if d["udid"] == keep or not (d["name"] in ours or d["name"].startswith("RD-")):
            continue
        busy = any(d["udid"] in l or ("name=" + d["name"]) in l for l in builds)
        print(("busy" if busy else "idle") + " " + d["udid"] + " " + d["name"])
' "$ID"
}
waited=0
while :; do
  list="$(others)"
  echo "$list" | awk '$1=="idle"{print $2}' | while read -r idle; do
    [ -n "$idle" ] && xcrun simctl shutdown "$idle" >/dev/null 2>&1 || true
  done
  busy="$(echo "$list" | awk '$1=="busy"{$1="";$2="";sub(/^ +/,"");s=s (s?"、":"") $0} END{print s}')"
  [ -z "$busy" ] && break
  if [ $((waited % 60)) -eq 0 ]; then
    echo "⏳ 还有旧任务在用模拟器（${busy}），等它跑完… 已等 ${waited}s"
  fi
  sleep 10; waited=$((waited + 10))
done

echo "▶ ${NAME} 开始测试（${SLUG}）"
"${CMD[@]}" -destination "platform=iOS Simulator,id=$ID"
