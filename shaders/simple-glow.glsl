// Simple Glow/Bloom Shader - based on working ghostty-shaders

// Pre-computed sample offsets (golden spiral pattern)
const vec3[12] samples = vec3[12](
    vec3(0.17, 0.99, 1.0),
    vec3(-1.33, 0.47, 0.71),
    vec3(-0.85, -1.51, 0.58),
    vec3(1.55, -1.26, 0.5),
    vec3(1.68, 1.47, 0.45),
    vec3(-1.28, 2.09, 0.41),
    vec3(-2.46, -0.98, 0.38),
    vec3(0.59, -2.77, 0.35),
    vec3(3.0, 0.12, 0.33),
    vec3(0.41, 3.14, 0.32),
    vec3(-3.17, 0.98, 0.30),
    vec3(-1.57, -3.09, 0.29)
);

float lum(vec4 c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    vec2 step = vec2(1.5) / iResolution.xy;

    for (int i = 0; i < 12; i++) {
        vec3 s = samples[i];
        vec4 c = texture(iChannel0, uv + s.xy * step);
        float l = lum(c);
        if (l > 0.1) {
            color += l * s.z * c * 0.15;
        }
    }

    fragColor = color;
}
