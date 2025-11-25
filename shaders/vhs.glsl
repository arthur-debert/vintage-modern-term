// VHS / Glitchy Tape Effect
// Analog distortion and tracking errors

const float CURVATURE = 0.05;
const float VIGNETTE = 0.3;
const float SCANLINE_INTENSITY = 0.2;
const float STATIC_NOISE = 0.08;
const float FLICKER = 0.03;
const float JITTER = 0.003;
const float HORIZONTAL_SYNC = 0.15;
const float RGB_SHIFT = 0.004;
const float BRIGHTNESS = 0.95;
const float CONTRAST = 1.1;
const float SATURATION = 0.85;
const float BLOOM = 0.2;

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

    // Barrel distortion
    vec2 curved_uv = uv;
    float distortion = dot(cc, cc) * CURVATURE;
    curved_uv = uv - cc * distortion;

    // Check bounds
    if (isInScreen(curved_uv) < 0.5) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 sample_uv = curved_uv;

    // Horizontal sync - tracking errors
    float line_noise = hash(vec2(floor(curved_uv.y * 50.0), floor(iTime * 10.0)));
    if (line_noise > 0.97) {
        sample_uv.x += (hash(vec2(iTime * 100.0, curved_uv.y * 100.0)) - 0.5) * HORIZONTAL_SYNC;
    }

    // Occasional full-screen glitch
    float glitch_trigger = hash(vec2(floor(iTime * 2.0), 0.0));
    if (glitch_trigger > 0.98) {
        sample_uv.x += (hash(vec2(iTime, curved_uv.y)) - 0.5) * 0.1;
    }

    // Jitter
    float jitter_noise = hash(sample_uv * 100.0 + iTime * 50.0);
    sample_uv.x += (jitter_noise - 0.5) * JITTER;

    // Clamp to prevent edge bleeding
    sample_uv = clamp(sample_uv, 0.001, 0.999);

    // Chromatic aberration (stronger for VHS look)
    vec2 r_uv = clamp(sample_uv + vec2(RGB_SHIFT, 0.0), 0.0, 1.0);
    vec2 b_uv = clamp(sample_uv - vec2(RGB_SHIFT, 0.0), 0.0, 1.0);
    float r = texture(iChannel0, r_uv).r;
    float g = texture(iChannel0, sample_uv).g;
    float b = texture(iChannel0, b_uv).b;
    vec3 color = vec3(r, g, b);

    // Bloom
    vec3 glow = vec3(0.0);
    vec2 blur_size = 1.5 / iResolution.xy;
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

    // Desaturate slightly
    float gray = luminance(color);
    color = mix(vec3(gray), color, SATURATION);

    // Contrast
    color = (color - 0.5) * CONTRAST + 0.5;

    // Scanlines (subtle for VHS)
    float scanline = sin(fragCoord.y * 3.14159) * 0.5 + 0.5;
    color *= 1.0 - (scanline * SCANLINE_INTENSITY * 0.5);

    // Heavy static noise
    float noise = hash(uv * iResolution.xy + iTime * 1000.0);
    color += (noise - 0.5) * STATIC_NOISE;

    // Tape noise bands
    float band_y = fract(uv.y + iTime * 0.1);
    float band_noise = hash(vec2(floor(band_y * 20.0), floor(iTime * 5.0)));
    if (band_noise > 0.95) {
        color += vec3(0.1) * hash(vec2(uv.x * 100.0, band_y));
    }

    // Vignette
    float vig = 1.0 - dot(cc * VIGNETTE * 2.0, cc * VIGNETTE * 2.0);
    color *= clamp(vig, 0.0, 1.0);

    // Flicker
    float flick = 1.0 - FLICKER * sin(iTime * 8.0);
    color *= flick;

    // Brightness
    color *= BRIGHTNESS;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
