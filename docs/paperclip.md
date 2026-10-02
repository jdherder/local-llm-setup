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

**On Linux/macOS or WSL**, `localhost` means *that* machine, not the Windows PC. Use
`http://192.168.4.24:11434/v1` unless Ollama is installed on the same machine. (WSL in its
default NAT networking mode can't reach Windows via `localhost` either.)

Check that OpenCode sees the models, then try one run by hand:

```powershell
opencode models                      # should list ollama/qwen3.5:9b
opencode run --print-logs --model ollama/qwen3.5:9b "Say hello and list the files in this folder"
```

If that works, OpenCode itself is fine. Anything that breaks after this is on the Paperclip side.

### Create the agent in Paperclip

**Don't use the UI's new-agent screen for this.** In current Paperclip, that screen always
attaches an **OpenRouter "AI connection"** to OpenCode agents, and that connection only accepts
`openrouter/...` models. With `ollama/qwen3.5:9b` it shows *"This connection does not support
the current harness and model"* and won't save. Once an agent has a connection attached,
editing can't remove it.

(From the source: `NewAgentSetup.tsx` defaults OpenCode agents to an OpenRouter binding, and
`isAiConnectionCompatible` requires OpenRouter bindings to use `openrouter/` models.)

**Workaround:** create the agent through Paperclip's API *without* an AI connection. It then
uses the machine's own OpenCode config, which has the `ollama` provider. Run these on the
machine running Paperclip:

```bash
# 1. Find your company ID
curl -s http://localhost:3100/api/companies

# 2. Create the agent (replace COMPANY_ID, and the cwd path if you like)
curl -s -X POST http://localhost:3100/api/companies/COMPANY_ID/agents \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Local Engineer",
    "role": "engineer",
    "title": "Engineer (local Qwen)",
    "adapterType": "opencode_local",
    "adapterConfig": {
      "model": "ollama/qwen3.5:9b",
      "cwd": "/home/jdherder/paperclip-work"
    }
  }'
```

The agent appears in the UI. Its AI connection section shows a notice offering to "adopt"
connections. **Leave it alone**, since adopting would attach OpenRouter again.

If the API returns 401/403, Paperclip is in authenticated mode rather than local trusted
mode. Copy the session cookie from the browser's dev tools and add `-H 'Cookie: ...'`.

Alternative to the config file: put the `provider` block into the agent's `adapterConfig.env`
as `PAPERCLIP_OPENCODE_PROVIDERS` (a JSON string of just the part inside
`"provider": { ... }`). Paperclip merges it into OpenCode's config at run time.

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

## "Missing issue disposition"

Paperclip expects an agent to **update the issue's status** when it finishes: mark it done,
blocked, send it for review, or hand it off. The agent does this by calling Paperclip's API
during the run. If a run succeeds but the status isn't changed, Paperclip posts
*"Missing issue disposition"* and wakes the agent once more to fix it. If that also fails, it
escalates: *"Missing disposition recovery blocked … board decision required"*.

Small local models often do the work but skip this step. Options:

- **Close it yourself:** open the issue and set its status (e.g. Done). That's the "board
  decision".
- **Spell it out in the task:** end task descriptions with *"When finished, mark this issue as
  done using the Paperclip API."*
- **Use a stronger model** for agents that need to manage their own issues, and keep local
  models on simple, well-scoped work.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| UI says *"This connection does not support the current harness and model"* | New-agent screen forces OpenRouter. Create the agent via the API (see above) |
| *Missing issue disposition* / *recovery blocked* | Agent didn't update the issue status. See above |
| `Model not found` | Model ID typo, or model missing from the `models` map in `opencode.json` |
| Connection refused / `Cannot connect to API` | Wrong base URL, Ollama not running, or firewall (remote setup). Test with `curl <baseURL>/models` |
| `opencode run` sits at `> build · model` forever | It's silently retrying a failed connection. Re-run with `--print-logs` to see the error |
| Agent loops / forgets instructions | Context too small. Raise Ollama's context length |
| Very slow | Model or context spilled to CPU. Check `ollama ps` |
| Tool calls fail / garbage output | Model weak at tool use. Try a different model |
