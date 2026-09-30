# Journal

Newest entries at the top. Record what was run, what happened, and anything surprising.

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
- Next: verify the install, check GPU detection, pull a first model.
  See [docs/ollama-windows.md](docs/ollama-windows.md).
