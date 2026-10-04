#!/usr/bin/env bash
set -uo pipefail

pip install -q ninja
export CMAKE_ARGS="-DGGML_CUDA=on"
export FORCE_CMAKE=1

pip install -v -U "llama-cpp-python[server]" --no-cache-dir 2>&1 | tee /content/build.log
exit "${PIPESTATUS[0]}"
