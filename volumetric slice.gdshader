shader_type spatial;
render_mode cull_disabled, unshaded;

uniform sampler2D image: filter_nearest;

uniform int image_size = 16;

uniform mat3 rotation;

void fragment() {
	vec3 original_pos = vec3((UV - vec2(0.25)) * 2.0, NODE_POSITION_WORLD.z * 0.5 + 0.5);

	vec3 pos = ((original_pos - vec3(0.5)) * transpose(rotation)) + vec3(0.5);

	ALBEDO = texture(image, (pos.xy / vec2(1.0, float(image_size))) + vec2(0.0, floor(pos.z * float(image_size)) / float(image_size))).rgb;
	ALPHA = 0.125;

	if ((pos.x < 0.0 || pos.y < 0.0 || pos.z < 0.0) || (pos.x > 1.0 || pos.y > 1.0 || pos.z > 1.0)) {
		ALPHA = 0.0;
	}
}
