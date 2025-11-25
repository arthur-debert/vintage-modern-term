// CRT Monitor Effect - based on working ghostty-shaders examples

float warp = 0.25;       // curvature amount
float scan = 0.50;       // scanline darkness

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 dc = abs(0.5 - uv);
    dc *= dc;

    // warp the fragment coordinates for CRT curvature
    uv.x -= 0.5; uv.x *= 1.0 + (dc.y * (0.3 * warp)); uv.x += 0.5;
    uv.y -= 0.5; uv.y *= 1.0 + (dc.x * (0.4 * warp)); uv.y += 0.5;

    // scanline effect
    float apply = abs(sin(fragCoord.y) * 0.25 * scan);

    // chromatic aberration
    float shift = 0.002;
    float r = texture(iChannel0, uv + vec2(shift, 0.0)).r;
    float g = texture(iChannel0, uv).g;
    float b = texture(iChannel0, uv - vec2(shift, 0.0)).b;

    vec3 color = vec3(r, g, b);

    // vignette
    float vig = 1.0 - dot(dc * 4.0, dc * 4.0);
    color *= vig;

    // apply scanlines
    fragColor = vec4(mix(color, vec3(0.0), apply), 1.0);
}
