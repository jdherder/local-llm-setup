# local-llm-setup

Notes, steps, and lessons learned from running large language models locally.
The goal is a reproducible record: if I have to set this up again (new PC, reinstall,
different tool), I can follow these docs instead of re-discovering everything.

## Current setup

| Machine    | OS / GPU   | Runtime | Status      |
|------------|------------|---------|-------------|
| Desktop PC | Windows 11, RTX 5070 (12 GB VRAM) | Ollama + Paperclip (via OpenCode on Linux) | Working |
| Mac        | macOS (client)                    | Paperclip + Pi → desktop's Ollama | Working |

## How it fits together

```
Windows PC (192.168.4.24)              Linux machine
  RTX 5070, 12 GB VRAM                   Paperclip  (http://localhost:3100)
  Ollama  :11434  <---- LAN ----         └─ OpenCode agents
   ├─ qwen3.5:9b   (default)                  └─ ~/.config/opencode/opencode.json
   ├─ qwen3.5:35b  (big, slow, background)        → ollama/<model> @ 192.168.4.24
   └─ llama3.2     (smoke test)
```

## Guides

- [Ollama on Windows 11](docs/ollama-windows.md) — install, verify, pull and run a first model
- [Hardware](docs/hardware.md) — GPU specs and which model sizes fit
- [Testing a model](docs/testing-models.md) — speed, GPU fit, tool calling, and quality checks
- [Claude Code with Ollama](docs/claude-code-ollama.md) — run the Claude Code agent on a local model
- [Paperclip with local Ollama](docs/paperclip.md) — run Paperclip agents on local models via OpenCode
- [Network access](docs/network-access.md) — use the PC's Ollama from other computers on the LAN
- [Models](docs/models.md) — models tried, what to try next, and using them with agent tools like Paperclip

## Journal

[JOURNAL.md](JOURNAL.md) is a dated log of what I actually did, what broke, and what I
learned. The guides are the clean "how to"; the journal is the messy "what happened".

## Possible future topics

- Front ends (e.g. Open WebUI) on top of Ollama
- Using the local API from scripts and editors
- Other runtimes (LM Studio, llama.cpp)
