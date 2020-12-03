shader_type canvas_item;
uniform float cutoff;
uniform sampler2D transition_texture;
uniform vec4 color : hint_color;

void fragment() {
	vec4 c = texture(transition_texture, UV);
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	if (c.r > cutoff) {
		COLOR = screen;
	} else {
		COLOR = color;
	}
}