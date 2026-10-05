#!/usr/bin/env bash
set -euo pipefail

REL=b11401
DEST=/content/llama
BIN="$DEST/llama-server"
: > /content/build.log
exec > >(tee -a /content/build.log) 2>&1

nv_lib_path() {
  python3 -c "
import glob, os
subs = ('cuda_runtime', 'cublas', 'nvjitlink')
ps = []
try:
    import nvidia
    base = os.path.dirname(nvidia.__file__)
    for s in subs:
        ps += glob.glob(os.path.join(base, s, 'lib'))
except Exception:
    pass
for s in subs:
    ps += glob.glob('/usr/local/lib/python*/dist-packages/nvidia/%s/lib' % s)
print(':'.join(dict.fromkeys(os.path.abspath(p) for p in ps)))
"
}

libcuda_dir() {
  local f
  f=$(find /usr/lib64-nvidia /usr/lib/x86_64-linux-gnu /usr/lib /lib \
        -maxdepth 3 -name 'libcuda.so.1*' \
        -not -path '*stubs*' -not -path '*dist-packages*' 2>/dev/null | head -1)
  if [ -n "$f" ]; then dirname "$f"; fi
}

export LD_LIBRARY_PATH="$(libcuda_dir):$(nv_lib_path):/usr/local/cuda/lib64:/usr/local/cuda-13.0/targets/x86_64-linux/lib:${LD_LIBRARY_PATH:-}"

if [ -x "$BIN" ] && "$BIN" --version >/dev/null 2>&1; then
  echo "llama-server 已存在，跳过下载"
else
  echo "[1/3] 下载官方预编译 llama-server b11401 (164MB，约 1 分钟)..."
  curl -fL --retry 3 -o /tmp/llama.tar.gz \
    "https://github.com/ggml-org/llama.cpp/releases/download/$REL/llama-$REL-bin-ubuntu-cuda-12.8-x64.tar.gz"
  mkdir -p "$DEST"
  tar -xzf /tmp/llama.tar.gz -C "$DEST" --strip-components=1
  chmod +x "$BIN"
fi

echo "[2/3] 安装 CUDA 12 运行库 (libcudart/libcublas/libnvjitlink，约 450MB)..."
pip install -q nvidia-cuda-runtime-cu12 nvidia-cublas-cu12 nvidia-nvjitlink-cu12
export LD_LIBRARY_PATH="$(libcuda_dir):$(nv_lib_path):/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"

echo "[3/3] 校验："
echo "libcuda 定位: $(ldd "$DEST/libggml-cuda.so" | grep libcuda || true)"
if ldd "$DEST/libggml-cuda.so" | grep 'not found'; then
  echo "错误：CUDA 库仍有缺失（见上）"
  exit 1
fi
"$BIN" --version
echo "安装完成，CUDA 库全部就绪"
