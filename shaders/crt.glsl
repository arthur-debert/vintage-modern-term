// CRT Monitor Effect for Ghostty
// Tweak the constants below to customize the look

// ============================================
// CONFIGURATION - Adjust these values!
// ============================================

// CURVATURE - barrel distortion simulating curved CRT glass
// 0.0 = flat screen, 0.5 = moderate curve, 1.0 = heavy curve
const float CURVATURE = 0.25;

// SCANLINES - horizontal dark lines between pixel rows
// 0.0 = no scanlines, 0.5 = visible, 1.0 = very dark lines
const float SCANLINE_INTENSITY = 0.5;

// SCANLINE_DENSITY - how many scanlines per pixel
// 1.0 = normal, 2.0 = denser, 0.5 = sparser
const float SCANLINE_DENSITY = 1.0;

// VIGNETTE - darkening at screen edges
// 0.0 = no vignette, 1.0 = moderate, 2.0 = heavy darkening
const float VIGNETTE = 1.0;

// CHROMATIC_ABERRATION - RGB color fringing at edges
// 0.0 = none, 0.002 = subtle, 0.005 = noticeable, 0.01 = heavy
const float CHROMATIC_ABERRATION = 0.002;

// BRIGHTNESS - overall brightness adjustment
// 1.0 = normal, 1.2 = brighter, 0.8 = darker
const float BRIGHTNESS = 1.0;

// FLICKER - subtle brightness variation over time
// 0.0 = stable, 0.02 = subtle, 0.05 = noticeable
const float FLICKER = 0.0;

// ============================================
// SHADER CODE
// ============================================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Distance from center (squared)
    vec2 dc = abs(0.5 - uv);
    dc *= dc;

    // Apply barrel distortion for CRT curvature
    uv.x -= 0.5;
    uv.x *= 1.0 + (dc.y * (0.3 * CURVATURE));
    uv.x += 0.5;

    uv.y -= 0.5;
    uv.y *= 1.0 + (dc.x * (0.4 * CURVATURE));
    uv.y += 0.5;

    // Chromatic aberration - split RGB channels
    float r = texture(iChannel0, uv + vec2(CHROMATIC_ABERRATION, 0.0)).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - vec2(CHROMATIC_ABERRATION, 0.0)).b;
    vec3 color = vec3(r, g, b);

    // Scanline effect
    float scanline = abs(sin(fragCoord.y * SCANLINE_DENSITY) * 0.25 * SCANLINE_INTENSITY);
    color = mix(color, vec3(0.0), scanline);

    // Vignette - darken edges
    float vig = 1.0 - dot(dc * VIGNETTE * 4.0, dc * VIGNETTE * 4.0);
    vig = clamp(vig, 0.0, 1.0);
    color *= vig;

    // Brightness adjustment
    color *= BRIGHTNESS;

    // Flicker effect (time-based)
    if (FLICKER > 0.0) {
        float flick = 1.0 - FLICKER * sin(iTime * 10.0);
        color *= flick;
    }

    fragColor = vec4(color, 1.0);
}
