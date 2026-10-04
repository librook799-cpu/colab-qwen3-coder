#!/usr/bin/env bash
set -uo pipefail

LOG=/content/build.log
pip install -q ninja
export CMAKE_ARGS="-DGGML_CUDA=on"
export FORCE_CMAKE=1

: > "$LOG"
START=$(date +%s)

heartbeat() {
  while :; do
    EL=$(( $(date +%s) - START ))
    PROG=$(tr '\r' '\n' < "$LOG" 2>/dev/null \
      | grep -aE '\[ *[0-9]+/[0-9]+\]|\[ *[0-9]+%|Building wheel' \
      | tail -n 1 | cut -c1-72)
    printf '  [编译 %02d:%02d] %s\n' $((EL/60)) $((EL%60)) "${PROG:-依赖下载/cmake 配置中...}"
    sleep 10
  done
}
heartbeat & HB=$!
trap 'kill "$HB" 2>/dev/null' EXIT

pip install -v -U "llama-cpp-python[server]" --no-cache-dir 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}

kill "$HB" 2>/dev/null
EL=$(( $(date +%s) - START ))
if [ "$RC" -eq 0 ]; then
  printf '安装完成，用时 %02d:%02d\n' $((EL/60)) $((EL%60))
else
  printf '安装失败 (exit=%d)，日志末尾：\n' "$RC"
  tail -n 30 "$LOG"
  exit "$RC"
fi
