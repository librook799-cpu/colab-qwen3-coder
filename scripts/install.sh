#!/usr/bin/env bash
set -euo pipefail

pip install -q ninja
export CMAKE_ARGS="-DGGML_CUDA=on"
export FORCE_CMAKE=1

pip install -U "llama-cpp-python[server]" --no-cache-dir
