shader_type canvas_item;

void fragment() {
	vec2 normalized_uv = SCREEN_UV / vec2(SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y, 1.0);
	ivec2 pixel = ivec2(floor(normalized_uv * vec2(64.0)));
	if ((pixel.x + pixel.y) % 2 == 0) {
		COLOR = vec4(vec3(0.075), 1.0);
	} else {
		COLOR = vec4(vec3(0.15), 1.0);
	}
}
