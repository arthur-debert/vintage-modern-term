# Vintage Modern Terminal

Custom Ghostty shaders for retro CRT terminal aesthetics, inspired by [cool-retro-term](https://github.com/Swordfish90/cool-retro-term).

![Ghostty](https://img.shields.io/badge/Ghostty-1.2+-blue)
![License](https://img.shields.io/badge/License-GPL--3.0-green)

## Quick Start

```bash
# Run with CRT effect (default)
./run.sh

# Run with specific shader
./run.sh shaders/crt.glsl
./run.sh shaders/green-phosphor.glsl
./run.sh shaders/amber-phosphor.glsl
./run.sh shaders/vhs.glsl
```

## Available Shaders

| Shader | Description |
|--------|-------------|
| `crt.glsl` | Full CRT simulation with all effects configurable |
| `green-phosphor.glsl` | Classic 80s green monochrome monitor |
| `amber-phosphor.glsl` | Warm amber monochrome terminal |
| `vhs.glsl` | Glitchy VHS tape effect with tracking errors |
| `simple-glow.glsl` | Minimal bloom/glow effect |
| `monochrome.glsl` | Simple green monochrome conversion |
| `passthrough.glsl` | No effect (template for new shaders) |

## Effect Comparison

| Effect | `crt.glsl` | `green-phosphor.glsl` | `amber-phosphor.glsl` |
|--------|:----------:|:---------------------:|:---------------------:|
| **Phosphor Color** | Configurable | Green (fixed) | Amber (fixed) |
| **Monochrome** | Adjustable 0-1 | Always on | Always on |
| **Saturation** | Adjustable | - | - |
| **Bloom/Glow** | Yes | Yes | Yes |
| **Bloom Radius** | Adjustable | Fixed (2.0) | Fixed (2.0) |
| **Curvature** | Yes | Yes | Yes |
| **Vignette** | Yes | Yes | Yes |
| **Scanlines** | Yes | Yes | Yes |
| **Scanline Density** | Adjustable | Fixed (1.0) | Fixed (1.0) |
| **Static Noise** | Yes | Yes | Yes |
| **Flicker** | Yes | Yes | Yes |
| **Jitter** | Yes | - | - |
| **Horizontal Sync** | Yes | - | - |
| **RGB Shift (Chromatic)** | Yes | - | - |
| **Brightness** | Yes | Yes | Yes |
| **Contrast** | Yes | Yes | Yes |
| **Ambient Light** | Yes | Yes | Yes |

### Summary

- **`crt.glsl`** - The "kitchen sink" shader with everything configurable. Full color or monochrome with any phosphor color, all effects with adjustable parameters, VHS-style glitch effects, and chromatic aberration.

- **`green-phosphor.glsl`** / **`amber-phosphor.glsl`** - Simplified presets with fixed monochrome color and core CRT effects only (bloom, curvature, scanlines, noise, flicker, vignette). Fewer parameters to tweak.

- **`vhs.glsl`** - Analog video distortion with tracking errors, tape noise bands, heavy static, and horizontal sync glitches.

## Configuration

### crt.glsl Parameters

Edit the constants at the top of `shaders/crt.glsl` to customize:

#### Monochrome / Color

```glsl
// Phosphor color: Green, Amber, White, or any RGB
const vec3 PHOSPHOR_COLOR = vec3(0.0, 1.0, 0.3);  // Green
// const vec3 PHOSPHOR_COLOR = vec3(1.0, 0.7, 0.0);  // Amber
// const vec3 PHOSPHOR_COLOR = vec3(1.0);            // White

// 0.0 = full color, 1.0 = monochrome
const float MONOCHROME = 0.0;

// Color saturation (0.0 = grayscale, 1.0 = full color)
const float SATURATION = 1.0;
```

#### Bloom / Glow

```glsl
// Glow intensity (0.0 = none, 0.5 = moderate, 1.0 = heavy)
const float BLOOM = 0.4;

// Glow size (1.0 = tight, 3.0 = diffuse)
const float BLOOM_RADIUS = 1.5;
```

#### Screen Shape

```glsl
// Barrel distortion (0.0 = flat, 0.3 = moderate, 0.5 = heavy)
const float CURVATURE = 0.12;

// Edge darkening (0.0 = none, 0.5 = moderate, 1.0 = heavy)
const float VIGNETTE = 0.4;
```

#### Scanlines

```glsl
// Scanline darkness (0.0 = none, 0.5 = visible, 1.0 = dark)
const float SCANLINE_INTENSITY = 0.3;

// Lines per pixel (0.5 = sparse, 1.0 = normal, 2.0 = dense)
const float SCANLINE_DENSITY = 1.0;
```

#### Noise & Interference

```glsl
// TV static grain (0.0 = none, 0.1 = subtle, 0.3 = noisy)
const float STATIC_NOISE = 0.05;

// Brightness variation (0.0 = stable, 0.05 = subtle, 0.1 = noticeable)
const float FLICKER = 0.02;

// Horizontal pixel jitter (0.0 = none, 0.002 = subtle, 0.005 = visible)
const float JITTER = 0.001;

// VHS-style horizontal distortion (0.0 = none, 0.1 = subtle)
const float HORIZONTAL_SYNC = 0.0;
```

#### Chromatic Aberration

```glsl
// RGB channel separation (0.0 = none, 0.002 = subtle, 0.005 = visible)
const float RGB_SHIFT = 0.002;
```

#### Brightness / Contrast

```glsl
// Overall brightness (0.8 = darker, 1.0 = normal, 1.2 = brighter)
const float BRIGHTNESS = 1.0;

// Color contrast (0.8 = flat, 1.0 = normal, 1.2 = punchy)
const float CONTRAST = 1.0;

// Simulated room light reflection (0.0 = none, 0.2 = subtle)
const float AMBIENT_LIGHT = 0.05;
```

## Creating Your Own Shader

1. Copy `shaders/passthrough.glsl` to a new file
2. Edit the `mainImage` function
3. Run with `./run.sh shaders/your-shader.glsl`

### Available Uniforms

Ghostty provides these ShaderToy-compatible uniforms:

```glsl
uniform sampler2D iChannel0;  // Terminal content texture
uniform float iTime;          // Elapsed seconds
uniform float iTimeDelta;     // Delta time
uniform vec3 iResolution;     // Viewport size (use .xy)
```

### Basic Structure

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    // Your effects here

    fragColor = color;
}
```

## Permanent Installation

To use a shader permanently, add it to your Ghostty config:

```bash
# Copy shader to Ghostty config directory
mkdir -p ~/.config/ghostty
cp shaders/crt.glsl ~/.config/ghostty/
```

Add to `~/.config/ghostty/config`:

```
custom-shader = ~/.config/ghostty/crt.glsl
custom-shader-animation = true
```

## Validation

Use the included validation script to check shader syntax:

```bash
./validate.sh shaders/crt.glsl
```

Requires `glslang` (`brew install glslang` on macOS).

## Credits

- Inspired by [cool-retro-term](https://github.com/Swordfish90/cool-retro-term) by Filippo Scognamiglio
- Shader techniques from [ghostty-shaders](https://github.com/0xhckr/ghostty-shaders)

## License

GPL-3.0
