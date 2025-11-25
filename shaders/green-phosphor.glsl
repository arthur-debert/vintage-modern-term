// Green Phosphor Monitor - Classic 80s terminal look
// Based on cool-retro-term style

const vec3 PHOSPHOR_COLOR = vec3(0.0, 1.0, 0.0);
const float MONOCHROME = 1.0;
const float SATURATION = 1.0;
const float BLOOM = 0.5;
const float BLOOM_RADIUS = 2.0;
const float CURVATURE = 0.15;
const float VIGNETTE = 0.5;
const float SCANLINE_INTENSITY = 0.4;
const float SCANLINE_DENSITY = 1.0;
const float STATIC_NOISE = 0.03;
const float FLICKER = 0.02;
const float BRIGHTNESS = 1.1;
const float CONTRAST = 1.1;
const float AMBIENT_LIGHT = 0.02;

const vec2[12] bloomSamples = vec2[12](
    vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
    vec2(0.707, 0.707), vec2(-0.707, 0.707), vec2(0.707, -0.707), vec2(-0.707, -0.707),
    vec2(1.0, 0.5), vec2(-1.0, 0.5), vec2(0.5, 1.0), vec2(-0.5, 1.0)
);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float isInScreen(vec2 v) {
    vec2 s = step(0.0, v) - step(1.0, v);
    return s.x * s.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 cc = uv - 0.5;
    float dist = length(cc);

    // Barrel distortion
    vec2 curved_uv = uv;
    float distortion = dot(cc, cc) * CURVATURE;
    curved_uv = uv + cc * distortion;

    // Check bounds
    if (isInScreen(curved_uv) < 0.5) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 sample_uv = clamp(curved_uv, 0.001, 0.999);
    vec3 color = texture(iChannel0, sample_uv).rgb;

    // Bloom
    vec3 glow = vec3(0.0);
    vec2 blur_size = BLOOM_RADIUS / iResolution.xy;
    for (int i = 0; i < 12; i++) {
        vec2 offset = bloomSamples[i] * blur_size;
        vec2 bloom_uv = clamp(sample_uv + offset, 0.0, 1.0);
        vec3 sample_color = texture(iChannel0, bloom_uv).rgb;
        float lum = luminance(sample_color);
        if (lum > 0.1) {
            glow += sample_color * lum;
        }
    }
    glow /= 12.0;
    color += glow * BLOOM;

    // Monochrome with phosphor color
    float gray = luminance(color);
    color = PHOSPHOR_COLOR * gray;

    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;

    // Scanlines
    float scanline = sin(fragCoord.y * SCANLINE_DENSITY * 3.14159) * 0.5 + 0.5;
    color *= 1.0 - (scanline * SCANLINE_INTENSITY * 0.5);

    // Static noise
    float noise = hash(uv * iResolution.xy + iTime * 1000.0);
    color += (noise - 0.5) * STATIC_NOISE;

    // Vignette
    float vig = 1.0 - dot(cc * VIGNETTE * 2.0, cc * VIGNETTE * 2.0);
    color *= clamp(vig, 0.0, 1.0);

    // Flicker
    float flick = 1.0 - FLICKER * sin(iTime * 15.0) * hash(vec2(iTime, 0.0));
    color *= flick;

    // Brightness and ambient
    color *= BRIGHTNESS;
    color += vec3(AMBIENT_LIGHT) * (1.0 - dist);

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
