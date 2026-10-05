# colab-qwen3-coder

在 Google Colab（免费 T4 GPU）上运行无审查编程模型 **Qwen3-Coder-30B-A3B-Instruct-abliterated**，并提供 OpenAI 兼容 API。

## 模型

- 模型：`huihui-ai/Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated`（Qwen3-Coder 底座，abliterated 去除拒答）
- GGUF 量化：`mradermacher/Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated-i1-GGUF`
- 默认量化 `Q3_K_M`（约 14.7GB，适配 T4 16GB 显存）；OOM 时改 `Q3_K_S`（13.3GB）
- 30B 总参 / 3B 激活（MoE），推理速度快

## 使用步骤

### 1. 推送到 GitHub

```bash
cd colab-qwen3-coder
git remote add origin https://github.com/librook799-cpu/colab-qwen3-coder.git
git push -u origin main
```

### 2. 在 Colab 中运行

打开：

```
https://colab.research.google.com/github/librook799-cpu/colab-qwen3-coder/blob/main/colab.ipynb
```

按顺序运行 notebook 单元格：

1. **配置**：填 `REPO_URL`，可改 `QUANT` / `CTX`
2. **克隆代码**：从 GitHub 拉取本仓库
3. **安装依赖**：下载官方预编译 `llama-server`（约 1–2 分钟，零编译）
4. **下载模型**：从 HuggingFace 下载 GGUF（约 14GB，只下一次，之后会缓存）
5. **启动 API 服务**：后台运行 `llama-server`（OpenAI 兼容）
6. **测试请求**：curl `/v1/chat/completions`
7. **（可选）公网隧道**：cloudflared 暴露给外部访问

### 3. 调用 API

```bash
curl http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"local","messages":[{"role":"user","content":"hello"}]}'
```

OpenAI SDK：

```python
from openai import OpenAI
client = OpenAI(base_url="http://127.0.0.1:8000/v1", api_key="none")
resp = client.chat.completions.create(
    model="local",
    messages=[{"role": "user", "content": "write a python quicksort"}],
)
```

## 注意事项

- 启动后立即请求会返回 503 `Loading model`：模型加载需要 30–60 秒，稍后重试
- 首次生成请求因 CUDA 预热偏慢（预填可能 <1 t/s），第二次起正常，预期生成 40–80 t/s
- 验证 GPU：`nvidia-smi` 应显示约 14GB 占用；若为 0，查看 `/content/server.log` 启动段
- Colab 免费版会话最长约 12 小时，空闲会断开；模型和 llama-server 在 `/content` 缓存中，同一账号重开会话通常可复用
- 显存不足（CUDA out of memory）：把 notebook 里 `QUANT` 改成 `Q3_K_S` 或把 `CTX` 降到 4096
- 仅限合法用途

## 目录结构

```
colab.ipynb          # Colab notebook（入口）
scripts/
  install.sh         # 下载官方预编译 llama-server (CUDA)
  download_model.py  # 下载 GGUF 量化模型
  serve.sh           # 启动 OpenAI 兼容 API
```
