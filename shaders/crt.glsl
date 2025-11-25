// Cool Retro Term Style CRT Shader for Ghostty
// Inspired by https://github.com/Swordfish90/cool-retro-term
// Licensed under GPL-3.0

// ============================================
// MONOCHROME / COLOR SETTINGS
// ============================================

// PHOSPHOR_COLOR - the color of the CRT phosphor
// Green: vec3(0.0, 1.0, 0.0)  Amber: vec3(1.0, 0.7, 0.0)  White: vec3(1.0)
const vec3 PHOSPHOR_COLOR = vec3(0.0, 1.0, 0.3);

// MONOCHROME - convert to single color (0.0 = full color, 1.0 = monochrome)
const float MONOCHROME = 0.0;

// SATURATION - color saturation (0.0 = grayscale, 1.0 = full color)
const float SATURATION = 1.0;

// ============================================
// BLOOM / GLOW SETTINGS
// ============================================

// BLOOM - glow around bright pixels (0.0 = none, 0.5 = moderate, 1.0 = heavy)
const float BLOOM = 0.4;

// BLOOM_RADIUS - size of the glow (1.0 = tight, 3.0 = diffuse)
const float BLOOM_RADIUS = 1.5;

// ============================================
// SCREEN SHAPE SETTINGS
// ============================================

// CURVATURE - barrel distortion (0.0 = flat, 0.3 = moderate, 0.5 = heavy)
const float CURVATURE = 0.12;

// VIGNETTE - darkening at edges (0.0 = none, 0.5 = moderate, 1.0 = heavy)
const float VIGNETTE = 0.4;

// ============================================
// SCANLINE SETTINGS
// ============================================

// SCANLINE_INTENSITY - darkness of scanlines (0.0 = none, 0.5 = visible, 1.0 = dark)
const float SCANLINE_INTENSITY = 0.3;

// SCANLINE_DENSITY - lines per pixel (0.5 = sparse, 1.0 = normal, 2.0 = dense)
const float SCANLINE_DENSITY = 1.0;

// ============================================
// NOISE & INTERFERENCE SETTINGS
// ============================================

// STATIC_NOISE - TV static grain (0.0 = none, 0.1 = subtle, 0.3 = noisy)
const float STATIC_NOISE = 0.05;

// FLICKER - brightness variation (0.0 = stable, 0.05 = subtle, 0.1 = noticeable)
const float FLICKER = 0.02;

// JITTER - horizontal pixel jitter (0.0 = none, 0.002 = subtle, 0.005 = visible)
const float JITTER = 0.001;

// HORIZONTAL_SYNC - VHS-style horizontal distortion (0.0 = none, 0.1 = subtle)
const float HORIZONTAL_SYNC = 0.0;

// ============================================
// CHROMATIC ABERRATION
// ============================================

// RGB_SHIFT - color channel separation (0.0 = none, 0.002 = subtle, 0.005 = visible)
const float RGB_SHIFT = 0.002;

// ============================================
// BRIGHTNESS / CONTRAST
// ============================================

// BRIGHTNESS - overall brightness (0.8 = darker, 1.0 = normal, 1.2 = brighter)
const float BRIGHTNESS = 1.0;

// CONTRAST - color contrast (0.8 = flat, 1.0 = normal, 1.2 = punchy)
const float CONTRAST = 1.0;

// AMBIENT_LIGHT - simulated room light reflection (0.0 = none, 0.2 = subtle)
const float AMBIENT_LIGHT = 0.05;

// ============================================
// SHADER CODE
// ============================================

// Attempt to pre-compute sample offsets for bloom
const vec2[12] bloomSamples = vec2[12](
    vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
    vec2(0.707, 0.707), vec2(-0.707, 0.707), vec2(0.707, -0.707), vec2(-0.707, -0.707),
    vec2(1.0, 0.5), vec2(-1.0, 0.5), vec2(0.5, 1.0), vec2(-0.5, 1.0)
);

// Hash function for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Convert RGB to grayscale
float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// Check if UV is within screen bounds
float isInScreen(vec2 v) {
    vec2 s = step(0.0, v) - step(1.0, v);
    return s.x * s.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Distance from center (for curvature and vignette)
    vec2 cc = uv - 0.5;
    float dist = length(cc);

    // === BARREL DISTORTION (CURVATURE) ===
    vec2 curved_uv = uv;
    if (CURVATURE > 0.0) {
        float distortion = dot(cc, cc) * CURVATURE;
        curved_uv = uv - cc * distortion;
    }

    // Check bounds - render black outside screen area
    if (isInScreen(curved_uv) < 0.5) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // === HORIZONTAL SYNC DISTORTION ===
    vec2 sample_uv = curved_uv;
    if (HORIZONTAL_SYNC > 0.0) {
        float sync_noise = hash(vec2(floor(curved_uv.y * 100.0), iTime));
        if (sync_noise > 0.99) {
            sample_uv.x += (hash(vec2(iTime, curved_uv.y)) - 0.5) * HORIZONTAL_SYNC;
        }
    }

    // === JITTER ===
    if (JITTER > 0.0) {
        float jitter_noise = hash(sample_uv * 100.0 + iTime);
        sample_uv.x += (jitter_noise - 0.5) * JITTER;
    }

    // Clamp UV to prevent edge bleeding
    sample_uv = clamp(sample_uv, 0.001, 0.999);

    // === CHROMATIC ABERRATION ===
    vec3 color;
    if (RGB_SHIFT > 0.0) {
        vec2 r_uv = clamp(sample_uv + vec2(RGB_SHIFT, 0.0), 0.0, 1.0);
        vec2 b_uv = clamp(sample_uv - vec2(RGB_SHIFT, 0.0), 0.0, 1.0);
        float r = texture(iChannel0, r_uv).r;
        float g = texture(iChannel0, sample_uv).g;
        float b = texture(iChannel0, b_uv).b;
        color = vec3(r, g, b);
    } else {
        color = texture(iChannel0, sample_uv).rgb;
    }

    // === BLOOM / GLOW ===
    if (BLOOM > 0.0) {
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
    }

    // === MONOCHROME / PHOSPHOR COLOR ===
    if (MONOCHROME > 0.0) {
        float gray = luminance(color);
        vec3 mono = PHOSPHOR_COLOR * gray;
        color = mix(color, mono, MONOCHROME);
    }

    // === SATURATION ===
    if (SATURATION < 1.0) {
        float gray = luminance(color);
        color = mix(vec3(gray), color, SATURATION);
    }

    // === CONTRAST ===
    color = (color - 0.5) * CONTRAST + 0.5;

    // === SCANLINES ===
    if (SCANLINE_INTENSITY > 0.0) {
        float scanline = sin(fragCoord.y * SCANLINE_DENSITY * 3.14159) * 0.5 + 0.5;
        color *= 1.0 - (scanline * SCANLINE_INTENSITY * 0.5);
    }

    // === STATIC NOISE ===
    if (STATIC_NOISE > 0.0) {
        float noise = hash(uv * iResolution.xy + iTime * 1000.0);
        color += (noise - 0.5) * STATIC_NOISE;
    }

    // === VIGNETTE ===
    if (VIGNETTE > 0.0) {
        float vig = 1.0 - dot(cc * VIGNETTE * 2.0, cc * VIGNETTE * 2.0);
        vig = clamp(vig, 0.0, 1.0);
        color *= vig;
    }

    // === FLICKER ===
    if (FLICKER > 0.0) {
        float flick = 1.0 - FLICKER * sin(iTime * 15.0) * hash(vec2(iTime, 0.0));
        color *= flick;
    }

    // === BRIGHTNESS ===
    color *= BRIGHTNESS;

    // === AMBIENT LIGHT ===
    if (AMBIENT_LIGHT > 0.0) {
        color += vec3(AMBIENT_LIGHT) * (1.0 - dist);
    }

    // Clamp final color
    color = clamp(color, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
