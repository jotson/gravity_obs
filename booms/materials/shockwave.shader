shader_type canvas_item;

uniform float radius = 0.0;
uniform float shockwave_width = 0.05;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0; // converts 0..1 to -1.0..1.0
	
	vec2 uv_normalized = normalize(uv);
	float uv_radius = length(uv);
	float delta_radius = abs(radius - uv_radius);
	if (delta_radius > shockwave_width) {
		delta_radius = 0.0;
	}
	
	vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV + uv_normalized * delta_radius);
	COLOR = c;
}
