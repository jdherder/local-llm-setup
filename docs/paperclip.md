# Paperclip with local Ollama

[Paperclip](https://github.com/paperclipai/paperclip) orchestrates a "company" of AI agents.
Each agent uses an **adapter**, which is the agent program Paperclip runs on each heartbeat.

Based on reading Paperclip's source (main branch, 2026-10-01): **there is no built-in Ollama
adapter.** (A native one has been requested: [issue #2979](https://github.com/paperclipai/paperclip/issues/2979).)
Instead, use one of the agent CLIs it supports and point that CLI at Ollama:

| Option | Adapter | How it reaches Ollama |
|--------|---------|-----------------------|
| **A (tested, working)** | OpenCode (`opencode_local`) | OpenCode custom provider → Ollama's OpenAI-compatible `/v1` API |
| B | Claude Code (`claude_local`) | `ANTHROPIC_BASE_URL` env var → Ollama's Anthropic-compatible API |
| **C (untested, likely easiest)** | Pi (`pi_local`) | Pi custom provider → Ollama's `/v1` API. No AI-connection blocker, so it can be set up in the UI |

**Why not point Paperclip straight at Ollama's `/v1` endpoint?** Paperclip doesn't talk to models
directly. Every agent runs an *agent program* (a "harness") that loops: ask the model, run the
tools it asks for (read files, run commands, call Paperclip's API), and repeat. Ollama's `/v1` is
only the model. The `http` adapter doesn't help either: it POSTs a webhook to an external agent
*service*, not a chat API. So some harness (OpenCode, Pi, Codex, Claude Code…) is always needed.

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

### Installing Paperclip permanently (instead of `npx` every time)

There's **no Homebrew formula** for Paperclip. The closest equivalent is Paperclip's own managed
install, which puts a `paperclipai` command in `~/.local/bin` and pins it to the Node that ran
the install. On macOS, pairing it with Homebrew's Node keeps it independent of fnm/nvm:

```bash
brew install node
/opt/homebrew/bin/node --version                     # must be 24.11 or newer
PATH="/opt/homebrew/bin:$PATH" npx paperclipai@latest install --yes
```

Then open a new terminal and use:

```bash
cd ~ && paperclipai run
paperclipai update            # instead of @latest; backs up the database first
```

Known issue ([paperclipai/paperclip#14553](https://github.com/paperclipai/paperclip/issues/14553)):
the command is pinned to the exact Homebrew Node version, so after `brew upgrade node` it breaks.
Re-pin by re-running the install line above.

### Always start Paperclip from the same folder

Paperclip picks its config (and so its database) by looking for a `.paperclip/config.json` in
the **current folder and its parents**, and only falls back to the default instance in
`~/.paperclip/` if none is found. Starting it from inside a project that has its own
`.paperclip/` folder gives you a different, empty org. Your data isn't gone; it's in the
other instance.

Safest: always start it from your home folder, or pin the config explicitly:

```bash
cd ~ && npx paperclipai@latest run
# or
PAPERCLIP_CONFIG=~/.paperclip/instances/default/config.json npx paperclipai@latest run
```

### Use the same Paperclip version every time

`npx paperclipai run` can reuse an **older cached copy** from `~/.npm/_npx/`, while
`npx paperclipai@latest …` fetches the newest. If a newer version has already upgraded the
database, an older version then crashes with errors like:

```
ERROR: GET /api/companies 500 — ... column companies.attachment_max_bytes does not exist
```

(That column is *removed* by a recent migration, so the database is newer than the code.) The UI
then looks empty or broken. Fix: always run the latest, and never point an older version at an
upgraded database:

```bash
cd ~
npx paperclipai@latest run
# optional, in a second terminal while it's running:
npx paperclipai@latest db:backup
```

`db:backup` needs Paperclip's built-in database to be running, which only happens while
Paperclip itself is running. Otherwise it fails with `connect ECONNREFUSED 127.0.0.1:54329`.

### Stop Paperclip

- In the terminal running it: **Ctrl+C**.
- If that terminal is gone, find and stop the process:

  ```bash
  ss -ltnp | grep 3100        # shows the process using port 3100
  pkill -f paperclipai        # stop it
  ```

- Then free the PC's GPU/RAM: `ollama stop <model>` on the Windows PC (or wait 5 minutes).

Agents only run while Paperclip is running. Start again with `npx paperclipai run`.

## 2a. Option A: OpenCode (recommended)

### Install OpenCode

On the machine running Paperclip:

```powershell
npm install -g opencode-ai
opencode --version
```

(Other install methods: <https://opencode.ai>.)

### Tell OpenCode about Ollama

Create OpenCode's global config file at `~/.config/opencode/opencode.json` on Linux/macOS
(`%USERPROFILE%\.config\opencode\opencode.json` on Windows). This is the working config on the
Linux machine:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (desktop)",
      "options": {
        "baseURL": "http://192.168.4.24:11434/v1"
      },
      "models": {
        "qwen3.5:9b":  { "name": "Qwen 3.5 9B" },
        "qwen3.5:35b": { "name": "Qwen 3.5 35B" }
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

Only use `http://localhost:11434/v1` if OpenCode runs on the Windows PC itself.
**On Linux/macOS or WSL**, `localhost` means *that* machine, not the Windows PC, so use the PC's IP
as above. (WSL in its
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

### Add a new model

1. Pull it on the Windows PC: `ollama pull <model>`.
2. Add it to the `models` map in `opencode.json` (the key must match the Ollama name exactly).
3. Check: `opencode models | grep ollama`, then
   `opencode run --print-logs --model ollama/<model> "Say hello"`. The first run of a big model is
   slow while it loads.
4. Point agents at it (below), or create new ones with `"model": "ollama/<model>"`.

To remove a model: `ollama rm <model>` on the PC, delete its line from `opencode.json`, and
move any agents using it to another model.

### Change an existing agent's model

`PATCH` merges into the existing `adapterConfig`, so you only need to send the field you're
changing. Add the new model to `opencode.json`'s `models` map first.

```bash
COMPANY=3071a70b-4e5a-4de8-9357-e979b35cda95

# List agents with their IDs and current models
curl -s http://localhost:3100/api/companies/$COMPANY/agents \
  | jq -r '.[] | "\(.id)  \(.name)  \(.adapterType)  \(.adapterConfig.model)"'

# Update one agent
curl -s -X PATCH http://localhost:3100/api/agents/AGENT_ID \
  -H 'Content-Type: application/json' \
  -d '{"adapterConfig": {"model": "ollama/qwen3.5:35b"}}'

# Or update every OpenCode agent at once
for id in $(curl -s http://localhost:3100/api/companies/$COMPANY/agents \
            | jq -r '.[] | select(.adapterType=="opencode_local") | .id'); do
  curl -s -X PATCH http://localhost:3100/api/agents/$id \
    -H 'Content-Type: application/json' \
    -d '{"adapterConfig": {"model": "ollama/qwen3.5:35b"}}' > /dev/null && echo "updated $id"
done
```

`COMPANY` must be set in the same terminal session. If it's empty, the URL becomes
`/companies//agents`, the API returns an error object instead of a list, and `jq` fails with
*"Cannot index string with string"*. Check with `echo $COMPANY`.

(`jq` formats JSON: `sudo apt install jq` if missing. Without it, use Python to list agents:)

```bash
curl -s http://localhost:3100/api/companies/$COMPANY/agents | python3 -c '
import json, sys
for a in json.load(sys.stdin):
    print(a["id"], a["name"], a["adapterType"], a["adapterConfig"].get("model"), sep="  ")'
```

### Move an existing Claude Code agent to a local model

Agents created in the UI (or hired by other agents) default to the **Claude Code** adapter
(`claude_local`) with no model set, which means they use Claude via your Anthropic login.
A `PATCH` can switch the adapter. Paperclip keeps the agent's `cwd`, `env`, and instructions
files when the adapter type changes.

```bash
# Switch one agent to OpenCode + local model
curl -s -X PATCH http://localhost:3100/api/agents/AGENT_ID \
  -H 'Content-Type: application/json' \
  -d '{"adapterType": "opencode_local", "adapterConfig": {"model": "ollama/qwen3.5:35b"}}'

# Switch it back to Claude Code (no model = Paperclip's default Claude model)
curl -s -X PATCH http://localhost:3100/api/agents/AGENT_ID \
  -H 'Content-Type: application/json' \
  -d '{"adapterType": "claude_local", "adapterConfig": {}}'
```

If the switch fails with *"Select an AI connection compatible with the new harness and model"*,
the agent has a managed AI connection attached that can't be removed. Create a new OpenCode
agent via the API instead (above) and copy its instructions over.

Move one agent at a time and compare results. Keep coordinating roles (CEO, Chief of Staff)
on Claude. Local models struggle most with Paperclip's task management.

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

## 2c. Option C: Pi (no AI-connection blocker)

[Pi](https://github.com/badlogic/pi-mono) is a small coding agent. In Paperclip's source, `pi_local`
has **no AI-connection mapping**, so the new-agent screen doesn't force OpenRouter on it the
way it does for OpenCode. You should be able to create Pi agents in the UI normally.

Install it on the machine running Paperclip.

**macOS: use Homebrew (recommended).** It installs `pi` with its own Node, independent of
whichever Node version fnm/nvm has active, so switching Node versions can't break it:

```bash
brew install pi-coding-agent
which pi        # /opt/homebrew/bin/pi on Apple Silicon
pi --version
```

**Otherwise, use npm** (this is the package Paperclip itself installs). Note that it's tied to the
Node version that's active when you install it:

```bash
npm install -g @earendil-works/pi-coding-agent
pi --version
```

Tell Pi about Ollama in `~/.pi/agent/models.json` (format from Pi's docs, so verify against
your installed version):

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://192.168.4.24:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        { "id": "qwen3.5:9b" },
        { "id": "qwen3.5:35b" }
      ]
    }
  }
}
```

Check:

```bash
pi --list-models | grep ollama
pi --provider ollama --model qwen3.5:9b -p "Say hello"
```

Then in Paperclip's UI, create an agent with **Adapter: Pi**, **Model: `ollama/qwen3.5:9b`**.

**If the UI's Run test fails immediately with "command not found in path: pi":** Paperclip's
server process can't see `pi` on its `PATH`. This is common when Node comes from nvm, because
npm's global bin folder is only on your interactive shell's `PATH`. Fix by linking it into
a standard location, then restart Paperclip:

```bash
sudo ln -sf "$(which pi)" /usr/local/bin/pi
sudo ln -sf "$(which node)" /usr/local/bin/node   # pi is a Node script; make sure node is findable too
```

(Alternatively, create the agent via the API with `"command": "<output of which pi>"` in
`adapterConfig`.)

**Switched Node versions?** Global npm packages are installed *per Node version*. If you
installed Pi under one version (e.g. Node 22) and then switched to another to run Paperclip
(it needs 24.11+), `pi` doesn't exist for the new version. Reinstall it while the new version
is active: `npm install -g @earendil-works/pi-coding-agent`.

**fnm users (macOS):** `which pi` returns a *temporary* per-terminal path
(`~/Library/Caches/fnm_multishells/<random>/bin/pi`) that disappears when the terminal closes,
so a symlink to it breaks after restarting the terminal. Link to fnm's stable `default` alias
instead:

```bash
FNM_DEFAULT="$HOME/Library/Application Support/fnm/aliases/default/bin"
fnm default 26                                     # make the version Paperclip uses the default
ls "$FNM_DEFAULT/pi" "$FNM_DEFAULT/node"          # both should exist
sudo mkdir -p /usr/local/bin
sudo ln -sf "$FNM_DEFAULT/pi"   /usr/local/bin/pi
sudo ln -sf "$FNM_DEFAULT/node" /usr/local/bin/node
```

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
| Pi hello probe: *Connection error* | Can't reach Ollama. Check `curl http://192.168.4.24:11434/api/tags` from the same machine (PC asleep? Ollama quit? network exposure off?). On **macOS**, also check System Settings → Privacy & Security → **Local Network** for the app that started Paperclip (Terminal, iTerm, VS Code…). Without it, LAN connections from that app fail |
| Very slow | Model or context spilled to CPU. Check `ollama ps` |
| Tool calls fail / garbage output | Model weak at tool use. Try a different model |
