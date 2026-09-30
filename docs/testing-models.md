# Testing a model

What to check after pulling a new model. Record results in [models.md](models.md).

## 1. Automated check (speed, GPU fit, tool calling)

From the repo folder in PowerShell:

```powershell
.\scripts\test-model.ps1 -Model qwen3:8b
```

If Windows blocks the script ("running scripts is disabled"), allow it for this window only:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

What good looks like:

| Check        | Good                                         | Problem                                  |
|--------------|----------------------------------------------|------------------------------------------|
| Speed        | 7–9B on 12 GB GPU: roughly 40+ tokens/s      | Single digits → running on CPU           |
| GPU fit      | `ollama ps` → `PROCESSOR` = `100% GPU`       | CPU/GPU split → lower context or smaller model |
| Tool calling | `PASS: called get_weather with {"city":"Denver"}` | No tool call → not suitable for agents (Paperclip) |

Speed ranges are rough estimates; the point is to compare models on the same PC.

## 2. Manual prompts (quality)

Run `ollama run <model> --verbose` (`--verbose` prints tokens/s after each answer) and try
the same prompts on every model:

1. **Coding:** "Write a PowerShell script that lists the 10 largest files in a folder,
   with sizes in MB."
2. **Debugging:** paste a real error you hit, with the code, and ask what's wrong.
3. **Reasoning:** "I have 3 boxes. One has apples, one oranges, one both. All labels are
   wrong. I can take one fruit from one box. How do I label them correctly?"
4. **Following instructions:** "Summarize the following in exactly 3 bullet points,
   under 15 words each:" + a paragraph of text.
5. **Something from your real work.** This matters most.

Qwen3 models "think" before answering (shows a thinking section). In `ollama run`, type
`/set nothink` to turn it off for faster answers, `/set think` to turn it back on.
