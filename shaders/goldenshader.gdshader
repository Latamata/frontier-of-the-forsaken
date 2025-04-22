shader_type canvas_item;

uniform vec4 target_color : source_color; // The color you want to replace
uniform vec4 new_color : source_color;    // The color to replace it with
uniform float tolerance = 0.1;            // How close it has to be to count
uniform bool toggle_gold = false;            // How close it has to be to count

void fragment() {
	if (toggle_gold){
		
    vec4 tex_color = texture(TEXTURE, UV);
    
    float diff = distance(tex_color.rgb, target_color.rgb);
    
    if (diff < tolerance) {
        COLOR = vec4(new_color.rgb, tex_color.a);
    } else {
        COLOR = tex_color;
    }
	}
}
