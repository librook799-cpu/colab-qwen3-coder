#!/usr/bin/env bash
set -euo pipefail

: "${MODEL_PATH:?缺少 MODEL_PATH}"
: "${PORT:=8000}"
: "${CTX:=8192}"

NV_LIBS=$(python3 -c "
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
")

LIBCUDA_DIR=$(find /usr/lib64-nvidia /usr/lib/x86_64-linux-gnu /usr/lib /lib \
  -maxdepth 3 -name 'libcuda.so.1*' -not -path '*stubs*' -not -path '*dist-packages*' 2>/dev/null | head -1 | xargs -r dirname)

export LD_LIBRARY_PATH="${LIBCUDA_DIR}:${NV_LIBS}:/usr/local/cuda/lib64:/usr/local/cuda-13.0/targets/x86_64-linux/lib:${LD_LIBRARY_PATH:-}"

exec /content/llama/llama-server \
  -m "$MODEL_PATH" \
  --host 0.0.0.0 --port "$PORT" \
  -c "$CTX" -ngl 99 --jinja
