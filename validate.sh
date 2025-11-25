#!/bin/bash
# Validate Ghostty shaders using glslangValidator

SHADER="${1:-shaders/crt.glsl}"

# Create a temp file with Ghostty's uniforms prepended
TEMP_FILE=$(mktemp /tmp/shader_validate.XXXXXX.frag)

cat > "$TEMP_FILE" << 'HEADER'
#version 330
// Ghostty-provided uniforms
uniform sampler2D iChannel0;
uniform float iTime;
uniform float iTimeDelta;
uniform vec3 iResolution;
uniform vec4 iMouse;
uniform int iFrame;

out vec4 outputColor;

HEADER

cat "$SHADER" >> "$TEMP_FILE"

# Add a main() wrapper if the shader uses mainImage
cat >> "$TEMP_FILE" << 'FOOTER'

void main() {
    mainImage(outputColor, gl_FragCoord.xy);
}
FOOTER

echo "Validating: $SHADER"
echo "---"
glslangValidator "$TEMP_FILE" 2>&1

rm "$TEMP_FILE"
