#!/usr/bin/env bash
set -euo pipefail

: "${MODEL_PATH:?缺少 MODEL_PATH}"
: "${PORT:=8000}"
: "${CTX:=8192}"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"

exec /content/llama/llama-server \
  -m "$MODEL_PATH" \
  --host 0.0.0.0 --port "$PORT" \
  -c "$CTX" -ngl 99 --jinja
