shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec3 camera_rot = vec3(0.0, 0.0, 0.0);
uniform vec3 camera_pos = vec3(0.0, 0.0, 19.2);
uniform vec2 proj_pos = vec2(0.5, 0.5);

void vertex() {
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float denom = camera_pos.z - p.z;
	vec2 clip_xy = (camera_pos.z * p.xy - camera_pos.xy * p.z) / 5.4;
	clip_xy *= vec2(1.0 / aspect, -1.0);
	vec2 offset = vec2(1.0 - proj_pos.x * 2.0, proj_pos.y * 2.0 - 1.0);
	POSITION = vec4(clip_xy - offset * denom, 0.5, denom);
}
