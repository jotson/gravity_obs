shader_type canvas_item;

uniform float scale = 0.0;
uniform float max_scale = 10.0;
uniform float intensity = 2.0;

void fragment() {
	vec2 offset = SCREEN_PIXEL_SIZE * scale;
	offset.y = 0.0;
	
	// Rotate the offset for larger scales
	// Turend this off because it felt like too much
	float angle = step(1.1, scale) * sin(TIME) * 3.141579 * 2.0;
	float s = sin(angle);
	float c = cos(angle);
	vec2 v = offset;
	offset.x = c * v.x - s * v.y;
	offset.y = s * v.x + c * v.y;
	
	float ratio = 0.5;

	// Offset the red channel
	vec4 red_channel = texture(SCREEN_TEXTURE, SCREEN_UV + offset);
	red_channel.r *= ratio;
	red_channel.g = 0.0;
	red_channel.b = 0.0;
	red_channel.a = ratio;

	// Offset the blue channel
	vec4 blue_channel = texture(SCREEN_TEXTURE, SCREEN_UV - offset);
	blue_channel.r = 0.0;
	blue_channel.g *= 0.0;
	blue_channel.b *= step(1.1, scale) * ratio;
	blue_channel.a = ratio;

	// Subtract red and blue from the base channel
	vec4 base = texture(SCREEN_TEXTURE, SCREEN_UV);
	base.r *= (1.0 - ratio);
	base.b *= (1.0 - step(1.1, scale) * ratio);
	base.a = 1.0 - ratio - step(1.1, scale) * ratio;
	//base.a += step(1.1, scale) * 2.0; // intensify colors when distorting
	base.a += smoothstep(1.1, max_scale, scale) * intensity;

	// Add em up
	COLOR = base + red_channel + blue_channel;
}