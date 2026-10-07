shader_type spatial;
render_mode blend_mix, cull_back, unshaded, depth_test_disabled, depth_draw_never;

//global uniform float time;
uniform vec4[768] effect_data;

varying flat vec4 data_0;
varying flat vec4 data_1;
varying flat vec4 effect_color;

void vertex() {
	int index = int(INSTANCE_CUSTOM.r) * 3;

	data_0 = effect_data[index];
	vec3 camera_pos = data_0.rgb;
	float progress = data_0.a;

	data_1 = effect_data[index+1];
	vec2 proj_pos = data_1.rg;

	effect_color = effect_data[index+2];

	VERTEX.yz = VERTEX.zy;
	float width = 1.0 / length(VERTEX.xy);
	progress = pow(progress, 0.1);
	VERTEX.xy *= mix(1.0, width, progress);
	VERTEX.xy *= 0.3 + progress * 0.7;

	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float denom = camera_pos.z - p.z;
	vec2 clip_xy = (camera_pos.z * p.xy - camera_pos.xy * p.z) / 5.4;
	clip_xy *= vec2(1.0 / aspect, -1.0);
	vec2 offset = vec2(1.0 - proj_pos.x * 2.0, proj_pos.y * 2.0 - 1.0);
	POSITION = vec4(clip_xy - offset * denom, 0.5, denom);
}

void fragment() {
	float progress = data_0.a;
	ALBEDO = effect_color.rgb;
	ALPHA = 1.0 - progress * progress;
}
