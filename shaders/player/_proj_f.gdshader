shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec3 camera_rot = vec3(0.0, 0.0, 0.0);
uniform vec3 camera_pos = vec3(0.0, 0.0, 19.2);
uniform vec2 proj_pos = vec2(0.5, 0.5);

void vertex() {
	vec3 view_dir = vec3(-sin(camera_rot.y) * cos(camera_rot.x), sin(camera_rot.x), -cos(camera_rot.y) * cos(camera_rot.x));
	vec3 right = normalize(cross(view_dir, vec3(0.0, 1.0, 0.0)));
	vec3 up = normalize(cross(right, view_dir));

	mat4 view_mat = mat4(
		vec4(right, 0.0),
		vec4(-up, 0.0),
		vec4(-view_dir, 0.0),
		vec4(-dot(right, camera_pos), dot(up, camera_pos), dot(view_dir, camera_pos), 1.0)
	);

	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	float f_len = camera_pos.z / 5.4;

	mat4 proj_mat = mat4(0.0);
	proj_mat[0][0] = f_len / aspect;
	proj_mat[1][1] = f_len;
	proj_mat[2][2] = -1.0;
	proj_mat[3][2] = -0.0001;
	proj_mat[2][3] = -1.0;
	proj_mat[2][0] = 1.0 - proj_pos.x * 2.0;
	proj_mat[2][1] = proj_pos.y * 2.0 - 1.0;

	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec4 view_pos = view_mat * world_pos;
	POSITION = proj_mat * view_pos;
}
