# Models

Models tried or worth trying on the desktop PC (RTX 5070, 12 GB VRAM — see [hardware.md](hardware.md)).
Sizes are approximate for Ollama's default 4-bit quantization. Check
<https://ollama.com/library> for current versions and tags; new releases come out often.

## Tried

| Model      | Params | Quant  | Size    | Max context | Capabilities              | Notes |
|------------|--------|--------|---------|-------------|---------------------------|-------|
| `llama3.2` | 3.2B   | Q4_K_M | 2.0 GB  | 128k        | completion, tools         | Works, fast. Good smoke test. |
| `qwen3:8b` | 8.2B   | Q4_K_M | 5.2 GB  | **40k**     | completion, tools, thinking | Downloaded; test pending. |

Capabilities and max context come from `http://192.168.4.24:11434/api/tags` (or
`ollama show <model>`). **Max context** is the most the model supports. Setting Ollama's
context length higher than that doesn't help.

## To try next: coding and harder tasks

Newer generations (Qwen 3.5, Gemma 4) replace most of the older picks. Both support tool calling
and long context (up to 256k), which fixes `qwen3:8b`'s 40k limit.

| Model          | Size    | Why                                                                     |
|----------------|---------|-------------------------------------------------------------------------|
| `qwen3.5:9b`   | ~6.6 GB | **Next to try.** Direct upgrade to `qwen3:8b`: smarter, tools + thinking, 256k max context. Leaves ~4 GB for context on 12 GB. |
| `gemma4:12b`   | ~8–9 GB? | Google's dense 12B, said to fit 12 GB. Tools + thinking, 256k max context. Less room for context. |
| `gemma4:26b`   | ~17 GB  | Mixture-of-experts (only ~4B active per token). Doesn't fit 12 GB, but MoE models run tolerably when partly on CPU. Experiment. |
| `gpt-oss:20b`  | ~14 GB  | OpenAI's open-weight model. Same idea: slightly too big, MoE, worth an experiment. |

Older picks, superseded but still fine: `qwen2.5-coder:14b` (~9 GB, coding), `qwen3:14b` (~9.3 GB).

Ollama defaults some models (e.g. Gemma 4) to a small context. Set the context length
yourself (see [ollama-windows.md](ollama-windows.md#context-length)).

Test each one on the same few real tasks ([testing-models.md](testing-models.md)) and record
the results in the table above.

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

See [paperclip.md](paperclip.md) for setup with local Ollama.
