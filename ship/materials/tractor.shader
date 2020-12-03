shader_type canvas_item;
render_mode blend_add;

uniform sampler2D lines;
uniform sampler2D noise;
uniform float speed = 0.0;
uniform float distortion = 0.0;

void fragment() {
	vec2 noise_uv = UV;
	noise_uv.y -= TIME * speed * 0.05;
	vec4 c_noise = texture(noise, noise_uv);
	
	vec2 distort_uv = UV;
	distort_uv.x += sin(UV.x * 233.0 + TIME * speed);
	distort_uv.x += sin(UV.x * 117.0 - TIME * speed);
	distort_uv.x *= distortion / 5000.0;
	//distort_uv.x = 0.0;
	distort_uv.y += sin(UV.y * 13.0 + TIME * speed + c_noise.r * 11.0);
	distort_uv.y += sin(UV.y * 11.0 + TIME * speed + c_noise.r * 13.0);
	distort_uv.y *= distortion / 5000.0;
	//distort_uv.y = 0.0;
	
	vec4 c = texture(TEXTURE, UV + distort_uv);
	
	// Using SCREEN_UV instead of UV to hide the texture pattern
	vec4 c_lines = texture(lines, SCREEN_UV * 3.0 + vec2(UV.x, UV.y + TIME * speed) + distort_uv + noise_uv * 3.0);
	c_lines *= c.a;
	
	COLOR = c + c_lines;
}