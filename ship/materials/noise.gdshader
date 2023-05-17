shader_type canvas_item;

uniform sampler2D noise;

void fragment() {
	vec2 uv = UV;
	
	uv.y += TIME * 0.2;
	
	vec4 c = texture(TEXTURE, UV);
	float alpha = c.a;
	vec4 n = texture(noise, uv);
	COLOR.rgb = c.rgb;
	COLOR.a = COLOR.a * alpha * n.r;
}
