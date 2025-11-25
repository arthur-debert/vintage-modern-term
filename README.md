# Vintage Modern Terminal

Custom Ghostty shaders for retro CRT terminal aesthetics, inspired by [cool-retro-term](https://github.com/Swordfish90/cool-retro-term).

## Quick Start

```bash
./term-vintage              # Generate from config.toml and launch
./term-vintage --help       # See all options
```

## Usage

```bash
# 1. Edit config.toml to tweak effects
# 2. Preview your changes
./term-vintage

# 3. Happy with it? Save as a preset
./term-vintage --save amber

# 4. Load saved presets anytime
./term-vintage amber.glsl
```

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                         config.toml                             │
│  Human-friendly settings (all values normalized 0.0 to 1.0)     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        generate.py                              │
│  Reads TOML → Fills template → Writes shader with unique hash   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              /tmp/crt-term/crt-<hash>.glsl                      │
│  Generated GLSL fragment shader (kept for debugging history)    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Ghostty                                │
│  Renders terminal → Applies shader as post-processing filter    │
└─────────────────────────────────────────────────────────────────┘
```

## Shader Pipeline

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Terminal   │      │   Fragment   │      │    Final     │
│    Output    │ ───▶ │    Shader    │ ───▶ │    Image     │
│  (iChannel0) │      │  (per pixel) │      │              │
└──────────────┘      └──────────────┘      └──────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   ┌─────────┐         ┌─────────┐         ┌─────────┐
   │ Bloom   │         │Scanlines│         │ Noise   │
   │Curvature│         │Vignette │         │ Flicker │
   │ Chroma  │         │Phosphor │         │ Jitter  │
   └─────────┘         └─────────┘         └─────────┘
```

## Project Structure

```
vintage-modern-term/
├── config.toml                  # Edit this - all effect settings
├── generate.py                  # TOML → GLSL generator
├── term-vintage                 # CLI to generate and launch
└── templates/
    └── crt.template.glsl        # Shader template
```

## Configuration

All values in `config.toml` are normalized from **0.0** (disabled/minimum) to **1.0** (maximum).

| Section | Parameter | Description |
|---------|-----------|-------------|
| **color** | `phosphor_r/g/b` | RGB phosphor color for monochrome mode |
| | `monochrome` | Color → single phosphor color conversion |
| | `saturation` | Color intensity |
| **bloom** | `intensity` | Glow around bright pixels |
| | `size` | Glow spread radius |
| **screen** | `curvature` | Barrel distortion (CRT bulge) |
| | `vignette` | Edge darkening |
| **scanlines** | `intensity` | Horizontal line darkness |
| | `size` | Line density |
| **noise** | `static` | TV static grain |
| | `flicker` | Brightness variation over time |
| | `jitter` | Horizontal pixel displacement |
| | `hsync` | VHS-style tracking errors |
| **chromatic** | `aberration` | RGB channel separation |
| **levels** | `brightness` | Overall brightness |
| | `contrast` | Color contrast |
| | `ambient` | Simulated room light reflection |

## Permanent Installation

To use a shader permanently in Ghostty:

```bash
# Save your favorite config as a preset
./term-vintage --save my-crt

# Copy to Ghostty config directory
cp my-crt.glsl ~/.config/ghostty/
```

Then add to `~/.config/ghostty/config`:
```
custom-shader = ~/.config/ghostty/my-crt.glsl
custom-shader-animation = true
```

## Requirements

- Ghostty 1.2+
- Python 3.11+ (or Python 3.x with `pip install tomli`)

## Credits

- Inspired by [cool-retro-term](https://github.com/Swordfish90/cool-retro-term) by Filippo Scognamiglio
- Shader techniques from [ghostty-shaders](https://github.com/0xhckr/ghostty-shaders)

## License

GPL-3.0
