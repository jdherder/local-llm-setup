# Hardware

## Desktop PC (Windows 11)

| Component | Details                                   |
|-----------|-------------------------------------------|
| GPU       | NVIDIA GeForce RTX 5070                   |
| VRAM      | 12 GB (12227 MiB reported)                |
| Driver    | 610.88 (CUDA 13.3), WDDM mode             |
| RAM       | 32 GB                                     |
| Network   | Wi-Fi 5 GHz, reserved IP `192.168.4.24`   |

Captured with `nvidia-smi` on 2026-09-30.

### VRAM budget

At idle, Windows and desktop apps (Chrome, Edge WebView, Steam, Xbox, NVIDIA overlay, etc.)
were already using **~1.1 GB** of VRAM. That leaves roughly **11 GB** for models.

A model needs VRAM for its weights **plus** the context window (the KV cache), which grows
with context length. So leave 1–2 GB of headroom beyond the model file size.

### What fits (4-bit quantized, Ollama's default)

| Model size   | Approx. download | Fit on 12 GB                                   |
|--------------|------------------|------------------------------------------------|
| 1–4B         | 1–3 GB           | Easily; very fast                              |
| 7–9B         | 4.5–6 GB         | Comfortably, with room for longer context      |
| 12–14B       | 8–9.5 GB         | Fits, but tight; keep context modest           |
| 20B+         | 12 GB+           | Spills to CPU/RAM; works but much slower       |

Check the actual split with `ollama ps`. The `PROCESSOR` column should say `100% GPU`.
If it shows something like `30%/70% CPU/GPU`, the model (or its context) doesn't fit.

Tips to free VRAM for bigger models: close GPU-heavy apps (browsers with hardware
acceleration, games, overlays) before loading.
