#!/bin/bash
# Launch Ghostty with custom shaders on macOS

cd "$(dirname "$0")"

# Default shader
SHADER="${1:-shaders/crt.glsl}"

# Get absolute path
SHADER_PATH="$(pwd)/$SHADER"

echo "Launching Ghostty with shader: $SHADER_PATH"

# macOS requires using 'open' to launch GUI apps
open -na Ghostty.app --args --custom-shader="$SHADER_PATH" --custom-shader-animation=true
