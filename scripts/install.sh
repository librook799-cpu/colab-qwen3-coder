#!/usr/bin/env bash
set -euo pipefail

pip install -q ninja
export CMAKE_ARGS="-DGGML_CUDA=on"
export FORCE_CMAKE=1

LOG=/content/build.log
START=$(date +%s)
: > "$LOG"

# -v 让 cmake 的构建进度（如 [ 45%] Building...）写入日志
pip install -v -U "llama-cpp-python[server]" --no-cache-dir >"$LOG" 2>&1 &
PID=$!

while kill -0 "$PID" 2>/dev/null; do
  EL=$(( $(date +%s) - START ))
  LAST=$(grep -aE '^\[ *[0-9]+%\]|Building wheel|error' "$LOG" | tail -n 1 | cut -c1-72)
  [ -z "$LAST" ] && LAST=$(tail -c 200 "$LOG" | tr '\r' '\n' | tail -n 1 | cut -c1-72)
  printf '\r  编译中 %02d:%02d | %-72s' $((EL/60)) $((EL%60)) "$LAST"
  sleep 5
done

if ! wait "$PID"; then
  echo
  echo "== 安装失败，日志末尾（完整日志: $LOG）=="
  tail -n 30 "$LOG"
  exit 1
fi

EL=$(( $(date +%s) - START ))
printf '\r  安装完成，用时 %02d:%02d %s\n' $((EL/60)) $((EL%60)) "$(printf '%*s' 60 '')"
