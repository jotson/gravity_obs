shader_type canvas_item;

void fragment() {
	vec2 v = vec2(0,0);
	vec2 uv = SCREEN_UV;
	float factor = 0.0015;
	float t = (mod(TIME, 3.0) + 1.0) * 25.0;
	uv.y = clamp(uv.y + (sin(uv.y * 80.0 + t)) * factor, 0.0, 1.0);
	uv.x = clamp(uv.x + (cos(uv.x * 70.0 + t)) * factor, 0.0, 1.0);
	vec4 c = texture(SCREEN_TEXTURE, uv);
	COLOR.rgb = clamp(c.rgb, 0.0, 1.0);
	COLOR.a = texture(TEXTURE, UV).a;
}

void light() {
	LIGHT = vec4(0.0);
}