# Claude Code with Ollama

[Claude Code](https://claude.com/claude-code) is Anthropic's coding agent. **Claude models
themselves can't run locally.** Their weights aren't released, so Ollama can't download them.
What you *can* do is run the Claude Code **tool** and have it use a local Ollama model
instead of Anthropic's servers. Ollama 0.14+ speaks the Anthropic API, so this works directly.

The agent is the same, but the model is much weaker. Expect it to handle small, focused tasks
and struggle with large multi-file changes.

## 1. Install Claude Code

```powershell
irm https://claude.ai/install.ps1 | iex
```

Open a new PowerShell window afterwards and check with `claude --version`.

## 2. Launch it against Ollama

Easiest: let Ollama set everything up. Claude Code must be installed first (step 1);
`ollama launch` starts it and points it at Ollama but doesn't bundle it.

```powershell
ollama launch claude                    # pick a model from a menu
ollama launch claude --model qwen3:8b   # or name one
```

If you get "unknown command", update Ollama.

Or do it manually. These settings only last for the current PowerShell window:

```powershell
$env:ANTHROPIC_BASE_URL   = "http://localhost:11434"   # no /v1 on the end
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY    = ""
claude --model qwen3:8b
```

Run `claude` from inside the project folder you want it to work on.

To go back to real Claude, open a new PowerShell window (or clear those three variables).

## 3. Context length matters a lot

Claude Code sends a large system prompt plus tool definitions and file contents.
It's recommended to use **64k context or more**. With less, tool results and earlier
conversation get cut off and the agent gets confused.

On 12 GB of VRAM (see [hardware.md](hardware.md)), rough estimates for `qwen3:8b`:

| Context | Fits on GPU?                                                     |
|---------|------------------------------------------------------------------|
| 32k     | Yes, about 10 GB total                                           |
| 64k     | Not by default (~15 GB). Possible with a compressed KV cache, below |

To fit 64k, set these **user** environment variables, then quit Ollama from the tray and restart it:

| Variable                 | Value   | Effect                                          |
|--------------------------|---------|-------------------------------------------------|
| `OLLAMA_CONTEXT_LENGTH`  | `65536` | Default context length (or use the Settings slider) |
| `OLLAMA_FLASH_ATTENTION` | `1`     | Needed for KV cache compression                 |
| `OLLAMA_KV_CACHE_TYPE`   | `q8_0`  | Halves context memory, with minimal quality loss |

Then load the model and check `ollama ps` shows `100% GPU`. If it doesn't, drop to 32k.

## 4. Model choice

The model **must support tool calling** (run `scripts/test-model.ps1` — see
[testing-models.md](testing-models.md)). Candidates on 12 GB: `qwen3:8b` (best fit with a big
context) and `qwen3:14b` (smarter, but only with a small context). See [models.md](models.md).

## Sources

- [Ollama docs: Claude Code integration](https://docs.ollama.com/integrations/claude-code)
- [Run Claude Code on Windows with Ollama](https://clauder-navi.com/en/ollama-claude-windows)
