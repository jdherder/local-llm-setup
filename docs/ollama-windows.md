# Ollama on Windows 11

Step-by-step setup for [Ollama](https://ollama.com) on a Windows 11 PC.
Commands are for PowerShell unless noted.

## 1. Install

```powershell
irm https://ollama.com/install.ps1 | iex
```

`irm` (`Invoke-RestMethod`) downloads the script and `iex` (`Invoke-Expression`) runs it.
It installs Ollama for the current user and adds `ollama` to your `PATH`.

Alternative: download `OllamaSetup.exe` from <https://ollama.com/download/windows>.

> After installing, **open a new PowerShell window** so the updated `PATH` is picked up.

## 2. Verify the install

```powershell
ollama --version
```

Ollama runs a background server (you should see the llama icon in the system tray).
Check that it is answering on its default port, `11434`:

```powershell
Invoke-RestMethod http://localhost:11434
# -> "Ollama is running"
```

If it is not running, start it from the Start menu, or run the server in the foreground:

```powershell
ollama serve
```

## 3. Check the GPU (optional but recommended)

Models run far faster on a GPU. For NVIDIA cards:

```powershell
nvidia-smi
```

This shows the GPU model, driver version, and total VRAM. VRAM is the main constraint on
which model sizes run well. As a rough guide for 4-bit quantized models (Ollama's default):

| VRAM   | Comfortable model size |
|--------|------------------------|
| 6–8 GB | up to ~7–8B parameters |
| 12 GB  | up to ~12–14B          |
| 16 GB  | up to ~14–20B          |
| 24 GB  | up to ~30B+            |

Models larger than your VRAM still run, but spill over to CPU/RAM and get much slower.

## 4. Pull and run a first model

Browse available models at <https://ollama.com/library>. Start with something small to
confirm everything works, e.g.:

```powershell
ollama run llama3.2
```

`run` downloads the model on first use, then opens an interactive chat.
Type `/bye` to exit, `/?` for help.

Useful commands:

```powershell
ollama list          # models downloaded locally
ollama pull <model>  # download without running
ollama ps            # models currently loaded, and whether they're on GPU or CPU
ollama rm <model>    # delete a model
ollama show <model>  # model details (parameters, context length, quantization)
```

`ollama ps` is the quickest way to confirm the GPU is being used — the `PROCESSOR`
column should read `100% GPU`.

## 5. Use the local API

Ollama exposes an HTTP API on `http://localhost:11434`:

```powershell
Invoke-RestMethod http://localhost:11434/api/generate -Method Post -Body (@{
  model  = "llama3.2"
  prompt = "Why is the sky blue?"
  stream = $false
} | ConvertTo-Json) | Select-Object -ExpandProperty response
```

It also offers an OpenAI-compatible endpoint at `http://localhost:11434/v1`, so many
tools that speak the OpenAI API can point at it directly.

## Context length

The **context length** (Settings → Context length, or `OLLAMA_CONTEXT_LENGTH`) is how many
tokens the model can "see" at once: your messages, its replies, and any pasted text.
One token is roughly ¾ of a word, so 8k tokens ≈ 6,000 words.

- **Too small:** in long chats or with big pasted documents, the oldest text is dropped
  without any warning, and the model "forgets" it.
- **Too large:** the context's working memory (KV cache) takes VRAM. If model + context
  don't fit on the GPU, part of it runs on the CPU and everything gets much slower. It
  also uses more VRAM even when your chats are short.

Suggested starting points for 12 GB VRAM (see [hardware.md](hardware.md)):

| Model size | Context to start with |
|------------|-----------------------|
| 1–4B       | 16k–32k               |
| 7–9B       | 8k–16k                |
| 12–14B     | 4k–8k                 |

Raise it only when you need to (long documents, coding with large files). After changing
it, load a model and run `ollama ps`: `PROCESSOR` should still say `100% GPU`. If it
doesn't, lower the context length.

## Freeing the GPU (gaming, etc.)

Ollama only uses VRAM while a model is **loaded**. The background server on its own uses
almost nothing, so there's no need to uninstall or disable it to use the GPU for something else.

- A model is unloaded automatically after **5 minutes** without use (`OLLAMA_KEEP_ALIVE`).
- To free the VRAM right away:

  ```powershell
  ollama ps              # see what's loaded
  ollama stop llama3.2   # unload that model now
  ```

- To stop Ollama completely: right-click the llama tray icon → **Quit Ollama**.
  Start it again from the Start menu (or `ollama serve`) when you need it.
- Ollama starts automatically when you sign in. To turn that off:
  Task Manager → **Startup apps** → Ollama → Disable.

Verify with `nvidia-smi`: once the model is unloaded, the `ollama` process should no longer
be using gigabytes of GPU memory.

If you start a game while a model is still loaded, the game will probably still run, but it
has less VRAM and may stutter or show lower-quality textures. Loading a model *during* a game
works the other way: the model may partly fall back to CPU and run slowly.

## Where things live

| What              | Location                              |
|-------------------|---------------------------------------|
| Downloaded models | `%USERPROFILE%\.ollama\models`        |
| Logs              | `%LOCALAPPDATA%\Ollama` (`server.log`) |
| Program files     | `%LOCALAPPDATA%\Programs\Ollama`      |

Open the logs folder quickly with `explorer $env:LOCALAPPDATA\Ollama`.

## Configuration (environment variables)

Set these as **user** environment variables (Settings → search "environment variables"),
then quit Ollama from the tray icon and start it again.

| Variable        | Purpose                                                           |
|-----------------|-------------------------------------------------------------------|
| `OLLAMA_MODELS` | Store models somewhere else (e.g. a bigger drive: `D:\ollama\models`) |
| `OLLAMA_HOST`   | Listen address; `0.0.0.0` exposes it to your LAN (be careful)      |
| `OLLAMA_KEEP_ALIVE` | How long a model stays loaded in memory after use (default `5m`) |
| `OLLAMA_CONTEXT_LENGTH` | Default context length in tokens (same as the Settings slider) |
| `OLLAMA_FLASH_ATTENTION` | `1` enables flash attention (required for `OLLAMA_KV_CACHE_TYPE`) |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` roughly halves the VRAM used by the context |

Example from PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "D:\ollama\models", "User")
```

## Troubleshooting

- **`ollama` is not recognized** — open a new terminal; if it persists, check that
  `%LOCALAPPDATA%\Programs\Ollama` is on your user `PATH`.
- **Running slowly / `ollama ps` shows CPU** — model may be too big for VRAM, or GPU
  drivers are outdated. Try a smaller model and update drivers. Check `server.log`.
- **`Error: unexpected EOF` while pulling a model** — the download connection dropped.
  Run the same command again; Ollama keeps the parts already downloaded and continues from there.
  If it keeps failing: use `ollama pull <model>` and retry, pause VPNs or
  antivirus web filtering, check free disk space, and restart Ollama from the tray.
- **Port 11434 in use** — another Ollama instance is probably running; check the tray.

## Updating / uninstalling

- Update: Ollama notifies you from the tray icon; or re-run the install command.
- Uninstall: Settings → Apps → Installed apps → Ollama. Models in
  `%USERPROFILE%\.ollama` are not necessarily removed — delete that folder to reclaim space.
