shader_type canvas_item;

uniform float sway_strength = 0.1;
uniform float sway_speed = 1.0;

void fragment() {
    // Flip UV.y so height = 0 at base, 1 at top
    float height = 2.0 - UV.y;

    // Sway value that changes over time
    float sway = sin(TIME * sway_speed) * sway_strength * 0.0066;

    // We shift higher pixels more than lower ones — base stays still
    vec2 offset = vec2(sway * height, 0.0);

    // We anchor the base by shifting everything back by full sway
    offset.x -= sway;

    COLOR = texture(TEXTURE, UV + offset);
}
