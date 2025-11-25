#!/bin/bash
# Launch Ghostty with CRT shader generated from config.toml

set -e
cd "$(dirname "$0")"

# Generate shader from config.toml
SHADER_PATH=$(python3 generate.py)
echo "Generated: $SHADER_PATH"

# Launch Ghostty
open -na Ghostty.app --args --custom-shader="$SHADER_PATH" --custom-shader-animation=true
