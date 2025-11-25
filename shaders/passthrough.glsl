// Passthrough Shader - Template for Ghostty
//
// Available uniforms:
//   iChannel0    - terminal texture (sampler2D)
//   iTime        - elapsed seconds (float)
//   iTimeDelta   - delta time (float)
//   iResolution  - viewport size (vec3, use .xy)

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
}
