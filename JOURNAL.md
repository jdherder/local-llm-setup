# Journal

Newest entries at the top. Record what was run, what happened, and anything surprising.

## 2026-10-02 — Paperclip setup research

- Read Paperclip's source: there's **no native Ollama adapter** (contrary to some blog posts).
  The supported path is the **OpenCode** adapter with an `ollama` custom provider pointing at
  `http://localhost:11434/v1`, and agent model `ollama/qwen3.5:9b`. Claude Code adapter +
  `ANTHROPIC_BASE_URL` is a fallback. Steps in [docs/paperclip.md](docs/paperclip.md).
- Installed OpenCode on the Linux machine. `opencode run` hung at `> build · qwen3.5:9b`
  with no output. `--print-logs` showed `Cannot connect to API`: the config had
  `localhost`, but Ollama is on the Windows PC. Fix: `baseURL` → `http://192.168.4.24:11434/v1`.
  ✅ Works: OpenCode on Linux → Ollama on the Windows PC's GPU.
- Lesson: `localhost` always means "the machine I'm running on". Any tool on another machine
  needs the PC's IP.
- Paperclip's new-agent screen blocked it: *"This connection does not support the current
  harness and model"*. It forces an OpenRouter AI connection on OpenCode agents, which only
  allows `openrouter/` models. Workaround: create the agent via the API with no AI connection.
  See [docs/paperclip.md](docs/paperclip.md#create-the-agent-in-paperclip).
- Created "Local Engineer" via the API (Paperclip is in local trusted mode, no auth needed).
- ✅ **First end-to-end run:** task JHF-2 "reply with Test complete" → agent replied
  "Test complete". Paperclip → OpenCode (Linux) → Ollama `qwen3.5:9b` (Windows GPU).
- But Paperclip flagged **"Missing issue disposition"**: the agent replied without updating
  the issue's status (done / blocked / needs review) through Paperclip's API. A corrective
  retry did the same, so it escalated to "board decision required". The 9B model doesn't
  reliably follow Paperclip's work protocol. Closed it by hand.
- Question: can a bigger model fit if slow is OK? Yes, via GPU + system RAM offload.
  Best bet: MoE models (`qwen3.5:35b` 24 GB (the 35B-A3B MoE), ~20 tok/s reported on 12 GB cards).
  Depends on system RAM (TODO: check). See [docs/models.md](docs/models.md).

## 2026-10-01 — Network access works

- Opened `http://192.168.4.24:11434` in my phone's browser → **"Ollama is running"**. ✅
  Exposing Ollama to the network works; the firewall is letting it through.
- `http://192.168.4.24:11434/api/tags` lists the installed models (handy quick check).
  It showed: `qwen3:8b` (8.2B, Q4_K_M, 5.2 GB, **max context 40k**, tools + thinking) and
  `llama3.2` (3.2B, Q4_K_M, 2.0 GB, max context 128k, tools).
- Learned: `qwen3:8b` can't do the 64k context recommended for Claude Code. Its max is 40k.
  Use 32k–40k with it. Updated [docs/claude-code-ollama.md](docs/claude-code-ollama.md).
- Looked up newer models: Qwen 3.5 and Gemma 4 are out, both with tools and 256k context.
  Next to try: `qwen3.5:9b` (~6.6 GB), then `gemma4:12b`. Updated [docs/models.md](docs/models.md).

## 2026-09-30 — Installing Ollama on Windows 11

- Installed Ollama from PowerShell with the official install script:

  ```powershell
  irm https://ollama.com/install.ps1 | iex
  ```

- Ran `nvidia-smi`: **RTX 5070, 12 GB VRAM**, driver 610.88 (CUDA 13.3).
  ~1.1 GB already in use by Windows/desktop apps at idle → ~11 GB available for models.
  Sweet spot is 7–9B models; 12–14B fit if context is kept modest.
  Details in [docs/hardware.md](docs/hardware.md).
- Note: the PowerShell prompt was `C:\WINDOWS\system32`, i.e. an **Administrator** window.
  Not needed for Ollama — a normal PowerShell window is fine.
- `ollama run llama3.2` works. ✅
- Question: how to free the GPU for gaming? Answer: Ollama only holds VRAM while a model is
  loaded (auto-unloads after 5 min idle). `ollama stop <model>` frees it immediately; tray →
  Quit Ollama stops it completely. Added a section to
  [docs/ollama-windows.md](docs/ollama-windows.md#freeing-the-gpu-gaming-etc).
- Question: what context length to set? Bigger = model remembers more of the chat, but
  costs VRAM. Starting point on 12 GB: 16k–32k for small models, 8k–16k for 7–9B,
  4k–8k for 12–14B. Check `ollama ps` still says 100% GPU. See
  [docs/ollama-windows.md](docs/ollama-windows.md#context-length).
- Researched models for coding / harder tasks and for running Paperclip (agent orchestrator)
  against Ollama. Shortlist: `qwen2.5-coder:14b`, `qwen3:14b`, `qwen3:8b`, `gpt-oss:20b`.
  Agents need tool calling and 16k–32k context, which is tight on 12 GB.
  See [docs/models.md](docs/models.md).
- `ollama run qwen3:8b` failed at 9% with `Error: unexpected EOF` (download dropped).
  Fix: re-run the command; it resumes. Added to troubleshooting.
- Re-ran the pull; `qwen3:8b` downloaded successfully.
- Added `scripts/test-model.ps1` and [docs/testing-models.md](docs/testing-models.md) for a
  repeatable test: speed (tokens/s), GPU fit, and tool calling (needed for Paperclip).
- Question: can I run Claude with Ollama? Claude models can't run locally, but the
  Claude Code agent can use an Ollama model (`ollama launch claude`, or set
  `ANTHROPIC_BASE_URL=http://localhost:11434`). Needs ~64k context, which is tight on 12 GB.
  See [docs/claude-code-ollama.md](docs/claude-code-ollama.md).
- Turned on **Expose Ollama to the network** in Settings, to use the PC's GPU from other
  machines. Steps (IP, firewall, client config, security) in
  [docs/network-access.md](docs/network-access.md).
- Desktop has a DHCP reservation in the router: **`192.168.4.24`** (on Wi-Fi, 5 GHz).
  Other machines use `http://192.168.4.24:11434`.
- Next: run the test on `qwen3:8b`, record results, then try `qwen3:14b` and Paperclip.
