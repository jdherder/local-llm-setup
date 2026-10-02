# Paperclip with local Ollama

[Paperclip](https://github.com/paperclipai/paperclip) orchestrates a "company" of AI agents.
Each agent uses an **adapter**, which is the agent program Paperclip runs on each heartbeat.

Based on reading Paperclip's source (main branch, 2026-10-01): **there is no built-in Ollama
adapter.** (A native one has been requested: [issue #2979](https://github.com/paperclipai/paperclip/issues/2979).)
Instead, use one of the agent CLIs it supports and point that CLI at Ollama:

| Option | Adapter | How it reaches Ollama |
|--------|---------|-----------------------|
| **A (recommended)** | OpenCode (`opencode_local`) | OpenCode custom provider → Ollama's OpenAI-compatible `/v1` API |
| B | Claude Code (`claude_local`) | `ANTHROPIC_BASE_URL` env var → Ollama's Anthropic-compatible API |

Option A is the better fit: OpenCode is built to work with many providers, and Paperclip's
OpenCode adapter has explicit support for custom providers.

## 0. Prerequisites

- Ollama running on the desktop with a tool-capable model, e.g. `qwen3.5:9b`
  (check with `scripts/test-model.ps1`).
- **Set the context length on the Ollama side** (Settings slider or `OLLAMA_CONTEXT_LENGTH`).
  OpenCode/Claude Code use the server default, and the 4k default is far too small for agents.
  Aim for 32k. See [ollama-windows.md](ollama-windows.md#context-length).
- Node.js **24.11+** (`node --version`). Install from <https://nodejs.org> if needed.

Which address to use for Ollama below:
- Paperclip on the **same PC** as Ollama → `http://localhost:11434`
- Paperclip on **another machine** → `http://192.168.4.24:11434` (see [network-access.md](network-access.md))

## 1. Install and start Paperclip

```powershell
npx paperclipai onboard --yes
```

This sets things up and starts the web UI at <http://localhost:3100>. Later, start it again with:

```powershell
npx paperclipai run
```

## 2a. Option A: OpenCode (recommended)

### Install OpenCode

On the machine running Paperclip:

```powershell
npm install -g opencode-ai
opencode --version
```

(Other install methods: <https://opencode.ai>.)

### Tell OpenCode about Ollama

Create OpenCode's global config file at `%USERPROFILE%\.config\opencode\opencode.json`
(`~/.config/opencode/opencode.json` on macOS/Linux):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (desktop)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3.5:9b": { "name": "Qwen 3.5 9B" },
        "qwen3:8b":   { "name": "Qwen 3 8B" }
      }
    }
  }
}
```

PowerShell one-liner to open it in Notepad (creates the folder first):

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\opencode" | Out-Null
notepad "$env:USERPROFILE\.config\opencode\opencode.json"
```

Check that OpenCode sees the models, then try one run by hand:

```powershell
opencode models                      # should list ollama/qwen3.5:9b
opencode run --model ollama/qwen3.5:9b "Say hello and list the files in this folder"
```

If that works, OpenCode itself is fine. Anything that breaks after this is on the Paperclip side.

### Create the agent in Paperclip

In the Paperclip UI, create (or edit) an agent and set:

| Field   | Value                                                  |
|---------|--------------------------------------------------------|
| Adapter | **OpenCode** (`opencode_local`)                        |
| Model   | `ollama/qwen3.5:9b` (format is `provider/model`)       |
| cwd     | A folder for the agent to work in, e.g. `C:\paperclip\work` |

Paperclip copies your global OpenCode config for each run and adds its own permission settings,
so the `ollama` provider above carries through.

Alternative to the config file: put the same `provider` block into the agent's **env** as
`PAPERCLIP_OPENCODE_PROVIDERS` (a JSON object, just the part inside `"provider": { ... }`).
Paperclip merges it into OpenCode's config at run time.

## 2b. Option B: Claude Code

Install Claude Code (see [claude-code-ollama.md](claude-code-ollama.md)), then create an agent with:

| Field   | Value                         |
|---------|-------------------------------|
| Adapter | **Claude Code** (`claude_local`) |
| Model   | `qwen3.5:9b`                  |
| env     | see below                     |

```
ANTHROPIC_BASE_URL=http://localhost:11434
ANTHROPIC_AUTH_TOKEN=ollama
ANTHROPIC_API_KEY=
ANTHROPIC_SMALL_FAST_MODEL=qwen3.5:9b
```

`ANTHROPIC_SMALL_FAST_MODEL` stops Claude Code from asking Ollama for a Claude "Haiku" model
for background tasks, which Ollama doesn't have.

Caveats: Paperclip's Claude adapter expects real Anthropic credentials, and Claude Code's
prompts are large (it recommends 64k context). Treat this as an experiment. If the agent fails
to start or errors on auth, use Option A.

## 3. Start small

- Begin with **one agent** and one small, concrete task (e.g. "create a README describing
  this folder"). Don't build a whole org chart on a local 9B model.
- Watch the PC: `ollama ps` should show the model at `100% GPU` while the agent runs.
- Agents run with permission prompts turned off by default (`dangerouslySkipPermissions`),
  so they can edit files and run commands without asking. Point `cwd` at a dedicated folder.
- Mix and match: use local models for simple agents, and a cloud model for the hard roles.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `Model not found` | Model ID typo, or model missing from the `models` map in `opencode.json` |
| Connection refused | Wrong base URL, Ollama not running, or firewall (remote setup) |
| Agent loops / forgets instructions | Context too small. Raise Ollama's context length |
| Very slow | Model or context spilled to CPU. Check `ollama ps` |
| Tool calls fail / garbage output | Model weak at tool use. Try a different model |
