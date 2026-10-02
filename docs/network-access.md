# Using Ollama from other computers on the network

Goal: run models on the Windows PC's GPU and use them from a laptop or other machine on the
same home network, with Claude Code, the `ollama` CLI, or any OpenAI-compatible tool.

## On the Windows PC (the server)

### 1. Expose Ollama

Ollama Settings → turn on **Expose Ollama to the network**. This makes it listen on all
network interfaces, not just `localhost`. (Same as setting `OLLAMA_HOST=0.0.0.0`.)

### 2. Find the PC's IP address

```powershell
ipconfig
```

Look for **IPv4 Address** under your active adapter (Ethernet or Wi-Fi).

**This PC: `192.168.4.24`**, reserved in the router, so it won't change. The examples below use it.

Tip: give the PC a fixed address with a **DHCP reservation** in your router's settings,
so the address doesn't change and break your other machines' config.

### 3. Make sure the network is "Private"

Settings → Network & internet → (your connection) → Properties → **Network profile type: Private**.
Windows is more locked down on "Public" networks.

### 4. Allow Ollama through Windows Firewall

Windows may prompt the first time; if you allowed it, you're done. Otherwise, in an
**Administrator** PowerShell:

```powershell
New-NetFirewallRule -DisplayName "Ollama" -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private
```

`-Profile Private` means it's only open on your home network, not on public Wi-Fi.

### 5. Keep the PC awake

If the PC sleeps, the other machines lose Ollama. Settings → System → Power → adjust
**sleep** timeouts as needed.

## On the other computer (the client)

All examples use the desktop's reserved IP, `192.168.4.24`.

### Test the connection

```bash
curl http://192.168.4.24:11434          # macOS / Linux -> "Ollama is running"
```
```powershell
Invoke-RestMethod http://192.168.4.24:11434   # Windows
```

A phone browser works too: open `http://192.168.4.24:11434`. Open
`http://192.168.4.24:11434/api/tags` to see the installed models.

If it times out: check the firewall rule, the network profile, and that both machines are
on the same network.

### Claude Code

macOS / Linux:

```bash
export ANTHROPIC_BASE_URL="http://192.168.4.24:11434"
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY=""
claude --model qwen3.5:9b
```

Windows PowerShell:

```powershell
$env:ANTHROPIC_BASE_URL   = "http://192.168.4.24:11434"
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY    = ""
claude --model qwen3.5:9b
```

The context length and other settings come from the **server** (the Windows PC), so set them
there. See [claude-code-ollama.md](claude-code-ollama.md).

### `ollama` CLI (if Ollama is installed on the client too)

```bash
OLLAMA_HOST=http://192.168.4.24:11434 ollama list
OLLAMA_HOST=http://192.168.4.24:11434 ollama run qwen3.5:9b
```

### Other tools (OpenAI-compatible)

Most tools (Open WebUI, Continue, Cline, Paperclip adapters, Python `openai` library, ...) accept:

| Setting  | Value                              |
|----------|------------------------------------|
| Base URL | `http://192.168.4.24:11434/v1`     |
| API key  | anything, e.g. `ollama` (it's ignored) |
| Model    | `qwen3.5:9b` (as shown by `ollama list`) |

Tools with a native Ollama option just need `http://192.168.4.24:11434`.

## Security

- **Ollama has no password.** Anyone who can reach port 11434 can use your GPU, run any
  downloaded model, and download or delete models.
- Only do this on a network you trust. Keep the firewall rule on the **Private** profile.
- **Never** port-forward 11434 on your router to the internet.
- To use it away from home, use a VPN such as Tailscale instead of opening ports.
- To stop sharing, turn the setting off (and optionally remove the rule:
  `Remove-NetFirewallRule -DisplayName "Ollama"`).
