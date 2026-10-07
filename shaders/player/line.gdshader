shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_test_disabled, depth_draw_never;

global uniform float time;
uniform vec4[640] line_data;
//uniform sampler2D mask: filter_linear, repeat_enable;

varying flat float border;
varying flat vec4 data_2;
varying flat vec4 line_color_a;
varying flat vec4 line_color_b;

void vertex() {
	int index = int(INSTANCE_CUSTOM.r) * 5;

	vec4 data_0 = line_data[index];
	vec3 camera_pos = data_0.rgb;
	int line_style = abs(int(data_0.a));
	float line_terminal = step(0.0, data_0.a);

	vec4 data_1 = line_data[index+1];
	vec2 proj_pos = data_1.rg;
	vec2 bezier_pos = vec2(data_1.a, -data_1.b);

	data_2 = line_data[index+2];
	float line_length = data_2.r;
	float line_length_multiplier = data_2.g;
	float line_width = data_2.b;
	float line_circle_angle = data_2.a;

	line_color_a = line_data[index+3];
	line_color_b = line_data[index+4];

	VERTEX.x *= line_width;
	float progress = VERTEX.y + 0.5;
	if ( line_style == 1 ) {
		float width_angle = line_width / line_length;
		float half_length = line_length * 0.5;
		float radius = half_length + VERTEX.x;
		float full = line_circle_angle + width_angle * 2.0;
		float angle = progress * full - width_angle;

		float body = clamp(angle, 0.0, line_circle_angle);
		float ext = ( body - angle ) * half_length;

		float s = sin(body);
		float c = cos(body);
		VERTEX.xy = vec2(c * radius + s * ext, s * radius - c * ext);
		border = width_angle / full * line_terminal;
	} else if ( line_style == 2 ) {
		float half_width = line_width * 0.5;
		float full = line_length + line_width;

		float along = progress * full - half_width;
		progress = clamp(along / line_length, 0.0, 1.0);
		float ext = progress * line_length - along;

		float half_length = line_length * 0.5;
		vec2 p0 = vec2(0.0, -half_length);
		vec2 p1 = bezier_pos;
		vec2 p2 = vec2(0.0, half_length);

		float invert = 1.0 - progress;
		vec2 point = invert * invert * p0 + 2.0 * invert * progress * p1 + progress * progress * p2;
		vec2 v = normalize(2.0 * invert * (p1 - p0) + 2.0 * progress * (p2 - p1));
		vec2 ext_v = vec2(v.y, -v.x);

		vec2 center = point - v * ext;
		VERTEX.xy = center + ext_v * VERTEX.x;
		border = half_width / full * line_terminal;
	} else {
		line_length *= line_length_multiplier;
		line_length += line_width;
		VERTEX.y *= line_length;
		border = line_width / line_length / 2.0 * line_terminal;
	}
	VERTEX.xy = vec2(-VERTEX.y, VERTEX.x);

	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float denom = camera_pos.z - p.z;
	vec2 clip_xy = (camera_pos.z * p.xy - camera_pos.xy * p.z) / 5.4;
	clip_xy *= vec2(1.0 / aspect, -1.0);
	vec2 offset = vec2(1.0 - proj_pos.x * 2.0, proj_pos.y * 2.0 - 1.0);
	POSITION = vec4(clip_xy - offset * denom, 0.5, denom);
}

void fragment() {
	vec2 uv = UV;
	float corner_x = 1.0 - min(uv.x, 1.0 - uv.x) * 2.0;
	float corner_y = 1.0 - min(uv.y, 1.0 - uv.y) / border;
	if ( corner_x > 0.0 && corner_y > 0.0 && corner_x * corner_x + corner_y * corner_y > 1.0 ) {
		discard;
	}
	float line_length_multiplier = data_2.g;
	float uy = clamp(( UV.y - 0.5 ) * line_length_multiplier, -0.5, 0.5) + 0.5;
	vec4 gradient_color = mix(line_color_a, line_color_b, uy);
	ALBEDO = gradient_color.rgb;
	ALPHA = gradient_color.a;
}
