#!/usr/bin/env bash
set -euo pipefail

: "${MODEL_PATH:?缺少 MODEL_PATH}"
: "${PORT:=8000}"
: "${CTX:=8192}"

NV_LIBS=$(python3 -c "
import glob, os, sysconfig
ps = []
try:
    import nvidia
    ps += glob.glob(os.path.join(os.path.dirname(nvidia.__file__), '*', 'lib'))
except Exception:
    pass
try:
    ps += glob.glob(os.path.join(sysconfig.get_paths().get('purelib', ''), 'nvidia', '*', 'lib'))
except Exception:
    pass
ps += glob.glob('/usr/local/lib/python*/dist-packages/nvidia/*/lib')
print(':'.join(dict.fromkeys(os.path.abspath(p) for p in ps)))
")
export LD_LIBRARY_PATH="${NV_LIBS}:/usr/local/cuda/lib64:/usr/local/cuda-13.0/targets/x86_64-linux/lib:${LD_LIBRARY_PATH:-}"

exec /content/llama/llama-server \
  -m "$MODEL_PATH" \
  --host 0.0.0.0 --port "$PORT" \
  -c "$CTX" -ngl 99 --jinja
