# local-llm-setup

Notes, steps, and lessons learned from running large language models locally.
The goal is a reproducible record: if I have to set this up again (new PC, reinstall,
different tool), I can follow these docs instead of re-discovering everything.

## Current setup

| Machine    | OS         | Runtime | Status      |
|------------|------------|---------|-------------|
| Desktop PC | Windows 11 | Ollama  | In progress |

## Guides

- [Ollama on Windows 11](docs/ollama-windows.md) — install, verify, pull and run a first model

## Journal

[JOURNAL.md](JOURNAL.md) is a dated log of what I actually did, what broke, and what I
learned. The guides are the clean "how to"; the journal is the messy "what happened".

## Possible future topics

- Hardware notes (GPU, VRAM, which model sizes fit)
- Model comparisons for different tasks
- Front ends (e.g. Open WebUI) on top of Ollama
- Using the local API from scripts and editors
- Other runtimes (LM Studio, llama.cpp)
