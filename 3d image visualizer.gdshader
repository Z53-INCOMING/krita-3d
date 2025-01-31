shader_type canvas_item;

uniform sampler2D image: filter_nearest;

uniform int z_width = 16;

uniform float z_offset : hint_range(0.0, 1.0) = 0.0;

uniform mat3 rotation;

uniform float display_size = 0.5;

uniform vec3 mouse_position;

uniform vec4 modulate = vec4(1.0);

void fragment() {
	vec2 cropped_UV = UV * (vec2(16.0, 9.0) / 9.0);
	cropped_UV *= vec2(1.0 / display_size);
	cropped_UV -= vec2(16.0 / 9.0 * (1.0 / (display_size * 2.0)), (1.0 / (display_size * 2.0)));
	cropped_UV += vec2(1.0, 0.5);
	
	vec3 pixel_pos = vec3(cropped_UV, z_offset);
	
	pixel_pos = ((pixel_pos - vec3(0.5)) * rotation) + vec3(0.5);
	
	if (pixel_pos.x < 0.0 || pixel_pos.x > 1.0 || pixel_pos.y < 0.0 || pixel_pos.y > 1.0 || pixel_pos.z < 0.0 || pixel_pos.z > 1.0) {
		COLOR = vec4(0.0);
	} else {
		float float_z_width = float(z_width);
		
		vec2 scaled_2d_pos = pixel_pos.xy / vec2(1.0, float_z_width);
		float offset_from_z_axis = floor(pixel_pos.z * float_z_width) / float_z_width;
		
		COLOR = texture(image, scaled_2d_pos + vec2(0.0, offset_from_z_axis)) * modulate;
		if (floor(mouse_position * float_z_width) / float_z_width == floor(pixel_pos * float_z_width) / float_z_width) {
			COLOR = vec4(1.0);
		}
	}
}
