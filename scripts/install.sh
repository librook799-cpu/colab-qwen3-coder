#!/usr/bin/env bash
set -euo pipefail

REL=b11401
DEST=/content/llama
BIN="$DEST/llama-server"
: > /content/build.log
exec > >(tee -a /content/build.log) 2>&1
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"

if [ -x "$BIN" ] && "$BIN" --version >/dev/null 2>&1; then
  echo "llama-server 已安装，跳过下载"
  "$BIN" --version | head -2
  exit 0
fi

echo "[1/3] 下载官方预编译 llama-server b11401 (164MB，约 1 分钟)..."
curl -fL --retry 3 -o /tmp/llama.tar.gz \
  "https://github.com/ggml-org/llama.cpp/releases/download/$REL/llama-$REL-bin-ubuntu-cuda-12.8-x64.tar.gz"
mkdir -p "$DEST"
tar -xzf /tmp/llama.tar.gz -C "$DEST" --strip-components=1
chmod +x "$BIN"

if ! "$BIN" --version >/dev/null 2>&1; then
  echo "[2/3] 系统 CUDA 库不匹配，改用自带运行库版 (594MB)..."
  curl -fL --retry 3 -o /tmp/llama-cudart.tar.gz \
    "https://github.com/ggml-org/llama.cpp/releases/download/$REL/cudart-llama-$REL-bin-ubuntu-cuda-12.8-x64.tar.gz"
  tar -xzf /tmp/llama-cudart.tar.gz -C "$DEST" --strip-components=1
  chmod +x "$BIN"
fi

echo "[3/3] 校验："
"$BIN" --version
echo "安装完成"
