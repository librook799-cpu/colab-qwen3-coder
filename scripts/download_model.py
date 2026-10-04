#!/usr/bin/env python3
"""下载 GGUF 量化模型到本地（默认 /content/models，Colab 缓存盘）。"""
import argparse
import os

from huggingface_hub import hf_download

REPO = "mradermacher/Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated-i1-GGUF"
FILE_PREFIX = "Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated.i1-"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--quant", default="Q3_K_M", help="量化等级，如 Q3_K_M / Q3_K_S")
    parser.add_argument("--dest", default="/content/models", help="下载目录")
    args = parser.parse_args()

    os.makedirs(args.dest, exist_ok=True)
    filename = f"{FILE_PREFIX}{args.quant}.gguf"
    path = hf_download(
        repo_id=REPO,
        filename=filename,
        local_dir=args.dest,
    )
    print(f"MODEL_PATH={path}")


if __name__ == "__main__":
    main()
