shader_type canvas_item;

uniform vec4 color : source_color;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.r == 0.0) {
		c.rgb = color.rgb;
	}
	COLOR = c;	
}