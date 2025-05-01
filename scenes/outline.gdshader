shader_type canvas_item;

uniform float outline_size = 2.0;
uniform vec4 outline_color = vec4(0.0, 0.0, 0.0, 1.0) : color;




void fragment() {
    vec4 base = texture(TEXTURE, UV);
    float alpha = base.a;

    if (alpha < 0.1) {
        for (float x = -outline_size; x <= outline_size; x++) {
            for (float y = -outline_size; y <= outline_size; y++) {
                vec2 offset = vec2(x, y) / TEXTURE_PIXEL_SIZE;
                alpha = max(alpha, texture(TEXTURE, UV + offset).a);
            }
        }

        if (alpha > 0.1) {
            COLOR = outline_color;
            return;
        }
    }

    COLOR = base;
}
