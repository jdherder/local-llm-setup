# Models

Models tried or worth trying on the desktop PC (RTX 5070, 12 GB VRAM — see [hardware.md](hardware.md)).
Sizes are approximate for Ollama's default 4-bit quantization. Check
<https://ollama.com/library> for current versions and tags; new releases come out often.

## Tried

| Model      | Size   | Notes                         |
|------------|--------|-------------------------------|
| `llama3.2` | ~2 GB  | 3B. Works, fast. Good smoke test. |

## To try next: coding and harder tasks

| Model               | Size    | Why                                                                 |
|---------------------|---------|---------------------------------------------------------------------|
| `qwen2.5-coder:14b` | ~9 GB   | Widely recommended coder at the 12 GB limit. Good at writing and editing code. |
| `qwen3:14b`         | ~9.3 GB | Stronger general reasoning (has a "thinking" mode) and solid tool calling. Better pick for agents. |
| `qwen3:8b`          | ~5.2 GB | Same family, smaller: leaves VRAM for a much bigger context.        |
| `gpt-oss:20b`       | ~14 GB  | OpenAI's open-weight model, good at reasoning and tool use. Slightly over 12 GB, so part runs on CPU; it's a mixture-of-experts model so this hurts less than usual. |

Test each one on the same few real tasks and write the results in the journal.

## For agent tools (Paperclip, OpenCode, etc.)

Agent tools need more than chat:

1. **Tool calling.** The model must support it. On ollama.com, filter the library by the
   **Tools** tag.
2. **A big context.** Agents send long system prompts, tool definitions, and file contents.
   4k–8k is usually too small. Aim for **16k–32k**, which on 12 GB means a
   **~8B model**, or a 14B model with a tight fit. Check `ollama ps` for `100% GPU`.
3. **Realistic expectations.** Local 8–14B models are much weaker at multi-step agent
   work than frontier cloud models. Expect loops, bad tool calls, and giving up early.
   They do better on small, well-defined tasks.

### Paperclip

[Paperclip](https://github.com/paperclipai/paperclip) orchestrates teams of AI agents
(Node.js server + web UI; needs Node.js 24.11+). Install:

```powershell
npx paperclipai@latest onboard --yes
```

Ways to point it at Ollama (check the Paperclip docs for your version):

- A native `ollama_local` adapter, reported to call Ollama's `/api/chat` directly with tool calling.
  An [open issue](https://github.com/paperclipai/paperclip/issues/2979) still asks for native
  Ollama support, so confirm it's in your version.
- Or run agents through an adapter like **OpenCode**, configured to use Ollama.
- Ollama's OpenAI-compatible endpoint is `http://localhost:11434/v1` (any API key string works).

Models people have reported using with Paperclip + Ollama: `qwen2.5-coder:14b`, `gpt-oss:20b`
([ollama/ollama#15976](https://github.com/ollama/ollama/issues/15976)).

A sensible setup: local models for simple or private agent tasks, and a cloud model for
the hard ones. Paperclip can mix both.
