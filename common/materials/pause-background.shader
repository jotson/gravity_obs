shader_type canvas_item;

uniform float pixel_size = 4.0;


void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 res = vec2(1.0/SCREEN_PIXEL_SIZE.x, 1.0/SCREEN_PIXEL_SIZE.y);
	
	uv -= mod(uv, vec2(pixel_size/res.x, pixel_size/res.y));
	
	COLOR.rgb = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb * 0.5;
	COLOR.a = 1.0;
}