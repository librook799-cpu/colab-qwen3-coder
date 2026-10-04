#!/usr/bin/env python3
"""下载 GGUF 量化模型到本地（默认 /content/models，Colab 缓存盘），带实时进度显示。"""
import argparse
import glob
import os
import threading
import time

from huggingface_hub import HfApi, hf_hub_download

REPO = "mradermacher/Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated-i1-GGUF"
FILE_PREFIX = "Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated.i1-"
FALLBACK_TOTAL = 15_000_000_000


def get_total(filename: str) -> int:
    try:
        info = HfApi().model_info(REPO, files_metadata=True)
        for s in info.siblings:
            if s.rfilename == filename and s.size:
                return s.size
    except Exception:
        pass
    return FALLBACK_TOTAL


def current_size(dest: str, filename: str) -> int:
    final = os.path.join(dest, filename)
    if os.path.exists(final):
        return os.path.getsize(final)
    total = 0
    patterns = ["**/*incomplete*", f"**/{filename}"]
    for root in (dest, os.path.expanduser("~/.cache/huggingface")):
        for pat in patterns:
            for f in glob.glob(os.path.join(root, pat), recursive=True):
                try:
                    if os.path.isfile(f):
                        total += os.path.getsize(f)
                except OSError:
                    pass
    return total


def monitor(dest: str, filename: str, total: int, stop: threading.Event) -> None:
    last_size = 0
    last_t = time.time()
    while not stop.is_set():
        size = current_size(dest, filename)
        now = time.time()
        dt = now - last_t
        speed = (size - last_size) / dt if dt > 0 and size >= last_size else 0.0
        last_size, last_t = size, now
        pct = min(size / total * 100, 100) if total else 0
        eta = (total - size) / speed if speed > 0 and size < total else 0
        eta_s = f"，剩余约 {int(eta // 60)}:{int(eta % 60):02d}" if eta else ""
        print(
            f"\r  下载中 {size / 1e9:.2f}/{total / 1e9:.2f} GB ({pct:5.1f}%)"
            f" · {speed / 1e6:6.1f} MB/s{eta_s}   ",
            end="",
            flush=True,
        )
        stop.wait(2)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--quant", default="Q3_K_M", help="量化等级，如 Q3_K_M / Q3_K_S")
    parser.add_argument("--dest", default="/content/models", help="下载目录")
    args = parser.parse_args()

    os.makedirs(args.dest, exist_ok=True)
    filename = f"{FILE_PREFIX}{args.quant}.gguf"

    total = get_total(filename)
    stop = threading.Event()
    t = threading.Thread(target=monitor, args=(args.dest, filename, total, stop), daemon=True)
    t.start()
    try:
        path = hf_hub_download(
            repo_id=REPO,
            filename=filename,
            local_dir=args.dest,
        )
    finally:
        stop.set()
        t.join(timeout=3)
        print()

    size = os.path.getsize(path)
    print(f"  下载完成 {size / 1e9:.2f} GB")
    print(f"MODEL_PATH={path}")


if __name__ == "__main__":
    main()
