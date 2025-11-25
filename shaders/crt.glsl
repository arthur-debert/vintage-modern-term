// Cool Retro Term Style CRT Shader for Ghostty
// Inspired by https://github.com/Swordfish90/cool-retro-term
// Licensed under GPL-3.0
//
// All parameters below use a normalized 0.0 to 1.0 range:
//   0.0 = effect disabled / minimum
//   1.0 = effect at maximum intensity

// ============================================
// CONFIGURATION - All values are 0.0 to 1.0
// ============================================

// MONOCHROME / COLOR
const vec3 PHOSPHOR_COLOR = vec3(0.0, 1.0, 0.3);  // RGB color when monochrome
const float MONOCHROME = 0.0;    // 0.0 = full color, 1.0 = single phosphor color
const float SATURATION = 1.0;    // 0.0 = grayscale, 1.0 = full saturation

// BLOOM / GLOW
const float BLOOM = 0.4;         // 0.0 = none, 1.0 = heavy glow
const float BLOOM_SIZE = 0.25;   // 0.0 = tight glow, 1.0 = diffuse glow

// SCREEN SHAPE
const float CURVATURE = 0.24;    // 0.0 = flat, 1.0 = heavy barrel distortion
const float VIGNETTE = 0.4;      // 0.0 = none, 1.0 = heavy edge darkening

// SCANLINES
const float SCANLINES = 0.3;     // 0.0 = none, 1.0 = dark scanlines
const float SCANLINE_SIZE = 0.33;// 0.0 = sparse lines, 1.0 = dense lines

// NOISE & INTERFERENCE
const float NOISE = 0.17;        // 0.0 = clean, 1.0 = heavy static
const float FLICKER = 0.2;       // 0.0 = stable, 1.0 = heavy flicker
const float JITTER = 0.2;        // 0.0 = stable, 1.0 = heavy horizontal jitter
const float HSYNC = 0.0;         // 0.0 = none, 1.0 = heavy VHS-style distortion

// CHROMATIC ABERRATION
const float CHROMA = 0.2;        // 0.0 = none, 1.0 = heavy RGB separation

// BRIGHTNESS / CONTRAST
const float BRIGHTNESS = 0.5;    // 0.0 = darker, 0.5 = normal, 1.0 = brighter
const float CONTRAST = 0.5;      // 0.0 = flat, 0.5 = normal, 1.0 = punchy
const float AMBIENT = 0.25;      // 0.0 = none, 1.0 = heavy room light reflection

// ============================================
// PARAMETER MAPPING (0-1 to actual values)
// ============================================

// Bloom radius: 0.0 → 1.0, 1.0 → 3.0
const float BLOOM_RADIUS_RAW = mix(1.0, 3.0, BLOOM_SIZE);

// Curvature: 0.0 → 0.0, 1.0 → 0.5
const float CURVATURE_RAW = CURVATURE * 0.5;

// Vignette: 0.0 → 0.0, 1.0 → 1.5
const float VIGNETTE_RAW = VIGNETTE * 1.5;

// Scanline intensity: 0.0 → 0.0, 1.0 → 1.0 (already normalized)
const float SCANLINE_INTENSITY_RAW = SCANLINES;

// Scanline density: 0.0 → 0.5, 1.0 → 2.0
const float SCANLINE_DENSITY_RAW = mix(0.5, 2.0, SCANLINE_SIZE);

// Static noise: 0.0 → 0.0, 1.0 → 0.3
const float STATIC_NOISE_RAW = NOISE * 0.3;

// Flicker: 0.0 → 0.0, 1.0 → 0.1
const float FLICKER_RAW = FLICKER * 0.1;

// Jitter: 0.0 → 0.0, 1.0 → 0.005
const float JITTER_RAW = JITTER * 0.005;

// Horizontal sync: 0.0 → 0.0, 1.0 → 0.15
const float HSYNC_RAW = HSYNC * 0.15;

// RGB shift: 0.0 → 0.0, 1.0 → 0.01
const float RGB_SHIFT_RAW = CHROMA * 0.01;

// Brightness: 0.0 → 0.8, 1.0 → 1.2
const float BRIGHTNESS_RAW = mix(0.8, 1.2, BRIGHTNESS);

// Contrast: 0.0 → 0.8, 1.0 → 1.2
const float CONTRAST_RAW = mix(0.8, 1.2, CONTRAST);

// Ambient light: 0.0 → 0.0, 1.0 → 0.2
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
        color += vec3(AMBIENT_RAW) * (1.0 - dist);
    }

    // Clamp final color
    color = clamp(color, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
