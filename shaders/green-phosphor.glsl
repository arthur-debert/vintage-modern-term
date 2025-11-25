// Green Phosphor Monitor - Classic 80s terminal look
// All parameters use normalized 0.0 to 1.0 range

// ============================================
// CONFIGURATION - All values are 0.0 to 1.0
// ============================================

const vec3 PHOSPHOR_COLOR = vec3(0.0, 1.0, 0.0);

const float BLOOM = 0.5;         // 0.0 = none, 1.0 = heavy glow
const float BLOOM_SIZE = 0.5;    // 0.0 = tight, 1.0 = diffuse
const float CURVATURE = 0.3;     // 0.0 = flat, 1.0 = heavy curve
const float VIGNETTE = 0.5;      // 0.0 = none, 1.0 = heavy darkening
const float SCANLINES = 0.4;     // 0.0 = none, 1.0 = dark lines
const float SCANLINE_SIZE = 0.33;// 0.0 = sparse, 1.0 = dense
const float NOISE = 0.1;         // 0.0 = clean, 1.0 = heavy static
const float FLICKER = 0.2;       // 0.0 = stable, 1.0 = heavy flicker
const float BRIGHTNESS = 0.55;   // 0.0 = dark, 0.5 = normal, 1.0 = bright
const float CONTRAST = 0.55;     // 0.0 = flat, 0.5 = normal, 1.0 = punchy
const float AMBIENT = 0.1;       // 0.0 = none, 1.0 = heavy reflection

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
const float BRIGHTNESS_RAW = mix(0.8, 1.2, BRIGHTNESS);
const float CONTRAST_RAW = mix(0.8, 1.2, CONTRAST);
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

    // Barrel distortion
    vec2 curved_uv = uv;
    float distortion = dot(cc, cc) * CURVATURE_RAW;
    curved_uv = uv + cc * distortion;

    // Check bounds
    if (isInScreen(curved_uv) < 0.5) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 sample_uv = clamp(curved_uv, 0.001, 0.999);
    vec3 color = texture(iChannel0, sample_uv).rgb;

    // Bloom
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

    // Monochrome with phosphor color
    float gray = luminance(color);
    color = PHOSPHOR_COLOR * gray;

    // Contrast
    color = (color - 0.5) * CONTRAST_RAW + 0.5;

    // Scanlines
    if (SCANLINE_INTENSITY_RAW > 0.0) {
        float scanline = sin(fragCoord.y * SCANLINE_DENSITY_RAW * 3.14159) * 0.5 + 0.5;
        color *= 1.0 - (scanline * SCANLINE_INTENSITY_RAW * 0.5);
    }

    // Static noise
    if (STATIC_NOISE_RAW > 0.0) {
        float noise = hash(uv * iResolution.xy + iTime * 1000.0);
        color += (noise - 0.5) * STATIC_NOISE_RAW;
    }

    // Vignette
    if (VIGNETTE_RAW > 0.0) {
        float vig = 1.0 - dot(cc * VIGNETTE_RAW * 2.0, cc * VIGNETTE_RAW * 2.0);
        color *= clamp(vig, 0.0, 1.0);
    }

    // Flicker
    if (FLICKER_RAW > 0.0) {
        float flick = 1.0 - FLICKER_RAW * sin(iTime * 15.0) * hash(vec2(iTime, 0.0));
        color *= flick;
    }

    // Brightness and ambient
    color *= BRIGHTNESS_RAW;
    if (AMBIENT_RAW > 0.0) {
        color += vec3(AMBIENT_RAW) * (1.0 - dist);
    }

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
