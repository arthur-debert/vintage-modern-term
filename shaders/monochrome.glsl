// Monochrome shader - converts terminal to green phosphor look

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    // Convert to grayscale using luminance
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    // Output as green phosphor
    fragColor = vec4(0.0, gray, 0.0, color.a);
}
