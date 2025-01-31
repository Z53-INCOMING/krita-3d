shader_type spatial;
render_mode cull_disabled;

uniform sampler2D image: filter_nearest;

uniform int image_size = 16;

void fragment() {
	vec2 scaled_uv = UV / vec2(1.0, float(image_size));
	
	ALBEDO = texture(image, (scaled_uv) + vec2(0.0, floor((NODE_POSITION_WORLD.z * 0.5 + 0.5) * float(image_size)) / float(image_size))).rgb;
	ALPHA = 0.0625;
}
