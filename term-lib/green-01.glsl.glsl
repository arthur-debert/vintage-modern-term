// Cool Retro Term Style CRT Shader for Ghostty
// Generated from config.toml
// Licensed under GPL-3.0

// ============================================
// CONFIGURATION (generated from TOML)
// ============================================

const vec3 PHOSPHOR_COLOR = vec3(0.0, 0.9, 0.1);
const float MONOCHROME = 1.0;
const float SATURATION = 0.7;

const float BLOOM = 0.7;
const float BLOOM_SIZE = 0.9;

const float CURVATURE = 0.1;
const float VIGNETTE = 0.3;

const float SCANLINES = 0.2;
const float SCANLINE_SIZE = 0.33;

const float NOISE = 0.3;
const float FLICKER = 0.2;
const float JITTER = 0.1;
const float HSYNC = 0.1;

const float CHROMA = 0.1;

const float BRIGHTNESS = 0.7;
const float CONTRAST = 0.9;
const float AMBIENT = 0.0;

// ============================================
// PARAMETER MAPPING (0-1 to actual values)
// ============================================

const float BLOOM_RADIUS_RAW = mix(1.0, 3.0, BLOOM_SIZE);
const float CURVATURE_RAW = CURVATURE * 0.5;
const float VIGNETTE_RAW = VIGNETTE * 1.5;
const float SCANLINE_INTENSITY_RAW = SCANLINES;
const float SCANLINE_DENSITY_RAW = mix(0.5, 2.0, SCANLINE_SIZE);
const float STATIC_NOISE_RAW = NOISE * 0.3;
const float FLICKER_RAW = FLICKER * 0.1;
const float JITTER_RAW = JITTER * 0.005;
const float HSYNC_RAW = HSYNC * 0.15;
const float RGB_SHIFT_RAW = CHROMA * 0.01;
const float BRIGHTNESS_RAW = mix(0.4, 1.6, BRIGHTNESS);  // 0.0=dark, 0.5=normal, 1.0=bright
const float CONTRAST_RAW = mix(0.5, 1.5, CONTRAST);      // 0.0=flat, 0.5=normal, 1.0=punchy
const float AMBIENT_RAW = AMBIENT * 0.2;

// ============================================
// SHADER CODE
// ============================================

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

    // === BARREL DISTORTION (CURVATURE) ===
    vec2 curved_uv = uv;
    if (CURVATURE_RAW > 0.0) {
        float distortion = dot(cc, cc) * CURVATURE_RAW;
        curved_uv = uv + cc * distortion;
    }

    // Check bounds - render black outside screen area
    if (isInScreen(curved_uv) < 0.5) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // === HORIZONTAL SYNC DISTORTION ===
    vec2 sample_uv = curved_uv;
    if (HSYNC_RAW > 0.0) {
        float sync_noise = hash(vec2(floor(curved_uv.y * 100.0), iTime));
        if (sync_noise > 0.99) {
            sample_uv.x += (hash(vec2(iTime, curved_uv.y)) - 0.5) * HSYNC_RAW;
        }
    }

    // === JITTER ===
    if (JITTER_RAW > 0.0) {
        float jitter_noise = hash(sample_uv * 100.0 + iTime);
        sample_uv.x += (jitter_noise - 0.5) * JITTER_RAW;
    }

    // Clamp UV to prevent edge bleeding
    sample_uv = clamp(sample_uv, 0.001, 0.999);

    // === CHROMATIC ABERRATION ===
    vec3 color;
    if (RGB_SHIFT_RAW > 0.0) {
        vec2 r_uv = clamp(sample_uv + vec2(RGB_SHIFT_RAW, 0.0), 0.0, 1.0);
        vec2 b_uv = clamp(sample_uv - vec2(RGB_SHIFT_RAW, 0.0), 0.0, 1.0);
        float r = texture(iChannel0, r_uv).r;
        float g = texture(iChannel0, sample_uv).g;
        float b = texture(iChannel0, b_uv).b;
        color = vec3(r, g, b);
    } else {
        color = texture(iChannel0, sample_uv).rgb;
    }

    // === BLOOM / GLOW ===
    float original_lum = luminance(color);
    if (BLOOM > 0.0) {
        vec3 glow = vec3(0.0);
        vec2 blur_size = BLOOM_RADIUS_RAW / iResolution.xy;

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
        // Only apply bloom where there's already some brightness (preserves dark bg)
        float bloom_mix = smoothstep(0.0, 0.15, original_lum);
        color += glow * BLOOM * bloom_mix;
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
    color = (color - 0.5) * CONTRAST_RAW + 0.5;

    // === SCANLINES ===
    if (SCANLINE_INTENSITY_RAW > 0.0) {
        float scanline = sin(fragCoord.y * SCANLINE_DENSITY_RAW * 3.14159) * 0.5 + 0.5;
        color *= 1.0 - (scanline * SCANLINE_INTENSITY_RAW * 0.5);
    }

    // === STATIC NOISE ===
    if (STATIC_NOISE_RAW > 0.0) {
        float noise = hash(uv * iResolution.xy + iTime * 1000.0);
        color += (noise - 0.5) * STATIC_NOISE_RAW;
    }

    // === VIGNETTE ===
    if (VIGNETTE_RAW > 0.0) {
        float vig = 1.0 - dot(cc * VIGNETTE_RAW * 2.0, cc * VIGNETTE_RAW * 2.0);
        vig = clamp(vig, 0.0, 1.0);
        color *= vig;
    }

    // === FLICKER ===
    if (FLICKER_RAW > 0.0) {
        float flick = 1.0 - FLICKER_RAW * sin(iTime * 15.0) * hash(vec2(iTime, 0.0));
        color *= flick;
    }

    // === BRIGHTNESS ===
    color *= BRIGHTNESS_RAW;

    // === AMBIENT LIGHT ===
    if (AMBIENT_RAW > 0.0) {
        // Only apply to pixels with content (preserves dark bg)
        float ambient_mix = smoothstep(0.0, 0.1, original_lum);
        color += vec3(AMBIENT_RAW) * (1.0 - dist) * ambient_mix;
    }

    // Clamp final color
    color = clamp(color, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
