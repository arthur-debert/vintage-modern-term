# Vintage Modern Terminal

Custom Ghostty shaders for a retro terminal aesthetic.

## Quick Start

```bash
# Run with CRT effect (default)
./run.sh

# Run with specific shader
./run.sh shaders/simple-glow.glsl
./run.sh shaders/passthrough.glsl
```

## Shaders

| Shader | Description |
|--------|-------------|
| `crt.glsl` | Full CRT monitor simulation with curvature, scanlines, vignette, and chromatic aberration |
| `simple-glow.glsl` | Subtle glow effect around text |
| `passthrough.glsl` | Template - does nothing, use as starting point |

## Creating Your Own Shader

1. Copy `passthrough.glsl` to a new file
2. Edit the `mainImage` function
3. Run with `./run.sh shaders/your-shader.glsl`

### Available Uniforms

```glsl
uniform sampler2D image;      // Terminal content texture
uniform float time;           // Elapsed seconds
uniform float time_delta;     // Delta time
uniform vec2 resolution;      // Viewport size
uniform vec4 cursor;          // Cursor position & size
uniform vec4 cursor_color;    // Cursor color
```

### Basic Structure

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / resolution;
    vec4 color = texture(image, uv);

    // Your effects here

    fragColor = color;
}
```

## Permanent Installation

Copy your preferred shader to Ghostty's config:

```bash
mkdir -p ~/.config/ghostty
cp shaders/crt.glsl ~/.config/ghostty/

# Add to ~/.config/ghostty/config:
# custom-shader = ~/.config/ghostty/crt.glsl
# custom-shader-animation = true
```
