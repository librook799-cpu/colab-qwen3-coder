#!/usr/bin/env bash
set -euo pipefail

MODEL_PATH=${MODEL_PATH:-/content/models/Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated.i1-Q3_K_M.gguf}
CTX=${CTX:-8192}
PORT=${PORT:-8000}
HOST=${HOST:-127.0.0.1}

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "模型文件不存在: $MODEL_PATH" >&2
  exit 1
fi

exec python -m llama_cpp.server \
  --model "$MODEL_PATH" \
  --n_gpu_layers 99 \
  --n_ctx "$CTX" \
  --n_threads 4 \
  --host "$HOST" \
  --port "$PORT"
