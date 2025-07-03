shader_type canvas_item;

uniform float speed = 0.1;
uniform float strength = 2.0;
uniform float frequency = 20.0;
uniform float noise_scale = 60.0;
uniform float noise_strength = 0.02;

float random(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Soft ripple motion
    float wave = sin(UV.y * frequency + TIME * speed) * (strength / 100.0);
    vec2 ripple = vec2(wave, 0.0);

    // Procedural white noise pattern
    float noise = random(floor(UV * noise_scale));
    float white_ripples = step(0.95, noise); // tweak 0.95 for density

    // Distort UV slightly for movement
    vec2 distorted_uv = UV + ripple;

    // Texture base
    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // Add shimmer / ripple texture
    tex_color.rgb += white_ripples * 0.07; // subtle white shimmer

    COLOR = tex_color;
}
