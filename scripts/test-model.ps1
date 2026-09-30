<#
.SYNOPSIS
  Quick check of an Ollama model: GPU fit, speed, and tool calling.

.EXAMPLE
  .\scripts\test-model.ps1 -Model qwen3:8b
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Model,
    [string]$OllamaUrl = "http://localhost:11434"
)

$ErrorActionPreference = "Stop"

function Invoke-Ollama($Path, $Body) {
    $json = $Body | ConvertTo-Json -Depth 10
    Invoke-RestMethod "$OllamaUrl$Path" -Method Post -Body $json -ContentType "application/json"
}

Write-Host "`n== 1. Speed ($Model) ==" -ForegroundColor Cyan
$r = Invoke-Ollama "/api/generate" @{
    model   = $Model
    prompt  = "Write a Python function that checks whether a string is a palindrome, ignoring case and punctuation. Include two example calls."
    stream  = $false
    options = @{ num_predict = 400 }
}
$tokensPerSec = [math]::Round($r.eval_count / ($r.eval_duration / 1e9), 1)
$loadSec = [math]::Round($r.load_duration / 1e9, 1)
Write-Host "Generated $($r.eval_count) tokens at $tokensPerSec tokens/s (model load: $loadSec s)"

Write-Host "`n== 2. GPU fit ==" -ForegroundColor Cyan
ollama ps

Write-Host "`n== 3. Tool calling ==" -ForegroundColor Cyan
try {
    $r = Invoke-Ollama "/api/chat" @{
        model    = $Model
        stream   = $false
        messages = @(@{ role = "user"; content = "What's the weather in Denver right now?" })
        tools    = @(@{
            type     = "function"
            function = @{
                name        = "get_weather"
                description = "Get the current weather for a city"
                parameters  = @{
                    type       = "object"
                    properties = @{ city = @{ type = "string"; description = "City name" } }
                    required   = @("city")
                }
            }
        })
    }
    if ($r.message.tool_calls) {
        $call = $r.message.tool_calls[0].function
        Write-Host "PASS: called $($call.name) with $($call.arguments | ConvertTo-Json -Compress)" -ForegroundColor Green
    } else {
        Write-Host "FAIL: no tool call. Model replied: $($r.message.content)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message) (model may not support tools)" -ForegroundColor Yellow
}

Write-Host "`nRecord the results in docs/models.md." -ForegroundColor Cyan
