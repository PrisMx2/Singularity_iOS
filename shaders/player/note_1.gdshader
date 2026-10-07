shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_test_disabled, depth_draw_never;

const float frequency = 72.0;
const float density = 0.01;
const float percent = 0.9;
const float strength = 0.08;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

global uniform float time;
uniform vec4[2688] note_data;
uniform sampler2D contour: filter_linear, repeat_enable;
//uniform sampler2D mask: filter_linear, repeat_enable;

varying flat vec2 frame_border;
varying flat float inv_frame_x;
varying flat int note_complex;
varying flat float gold;
varying flat vec2 texture_vec;
varying flat float process_border;
varying flat float inv_border;
varying flat float skew;
varying flat float uv_zoom_x;

varying flat vec4 frame_color_a;
varying flat vec4 frame_color_b;
varying flat vec4 body_color_a;
varying flat vec4 body_color_b;

void vertex() {
	int index = int(INSTANCE_CUSTOM.r) * 7;
	frame_border = INSTANCE_CUSTOM.gb;
	inv_frame_x = 1.0 - frame_border.x * 2.0;

	vec4 data = note_data[index];
	vec3 camera_pos = data.rgb;
	note_complex = abs(int(data.a));
	gold = sign(data.a) * 0.5 + 1.5;

	data = note_data[index+1];
	vec2 proj_pos = data.rg;
	texture_vec = data.ba * time * 0.000075;

	data = note_data[index+2];
	process_border = data.r;
	inv_border = 0.5 - process_border;
	skew = data.g;
	float cone = data.b;
	uv_zoom_x = data.a;

	frame_color_a = note_data[index+3];
	frame_color_b = note_data[index+4];
	body_color_a = note_data[index+5];
	body_color_b = note_data[index+6];

	VERTEX.yz = VERTEX.zy;
	VERTEX.x *= -1.0;
	VERTEX.z -= 0.5;

	int note_type = note_complex / 10;
	if ( note_type == 5 ) {
		float strip = floor(VERTEX.z * density / frame_border.y) * 2.2360679;
		float unit = floor(time * frequency / 1000.0) * 1.7320508;
		float apply = step(percent, hash(vec2(strip + 0.517, unit + 0.293)));
		apply *= sign(hash(vec2(strip + 0.913, unit + 0.270)) - 0.5) * strength;
		VERTEX.x += apply;
	}

	VERTEX.xy *= 1.0 + VERTEX.z * cone;

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

	float dx = uv.y * skew / PI;
	uv.x = fract(uv.x + dx);
	uv.x = ( uv.x - 0.5 ) * uv_zoom_x + 0.5;
	uv.y *= 2.0;

	vec2 duv = 0.5 - uv;
	vec2 abs_duv = abs(duv);
	vec2 sign_duv = sign(duv);

	int note_type = note_complex / 10;
	int note_style = note_complex % 10;
	if ( note_style == 1 ) {
		if ( abs_duv.y > inv_border ) {
			vec2 pos = (sign_duv.y > 0.0) ? vec2(0.5, process_border) : vec2(0.5, 1.0 - process_border);
			float uv_scale_y = process_border * 2.0;
			uv -= pos;
			uv.y /= uv_scale_y;
			uv.y = length(uv) * -sign_duv.y;
			uv.y *= uv_scale_y;
			uv += pos;
		}
	} else if ( note_style == 2 ) {
		if ( abs_duv.y > inv_border ) {
			const float angle = PI / 4.0;
			const mat2 rotation_matrix = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
			vec2 pos = (sign_duv.y > 0.0) ? vec2(0.5, frame_border.y) : vec2(0.5, 1.0 - frame_border.y);
			float uv_scale_y = process_border * 2.0;
			uv -= pos;
			uv.y /= uv_scale_y;
			uv = (sign_duv.y * sign_duv.x > 0.0) ? uv = uv * rotation_matrix : uv = rotation_matrix * uv;
			uv.x *= 0.7071067812;
			uv.y *= uv_scale_y;
			uv += pos;
		}
	} else if ( note_style == 3 ) {
		if ( abs_duv.y > inv_border ) {
			const float angle = PI / 6.0;
			const mat2 rotation_matrix = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
			vec2 pos = (sign_duv.y > 0.0) ? vec2(0.5, frame_border.y) : vec2(0.5, 1.0 - frame_border.y);
			float uv_scale_y = process_border / ( 0.2886751346 + frame_border.x * 0.4226497308 );
			uv -= pos;
			uv.y /= uv_scale_y;
			uv = (sign_duv.y * sign_duv.x > 0.0) ? uv = uv * rotation_matrix : uv = rotation_matrix * uv;
			uv.x *= 0.8660254038;
			uv.y *= uv_scale_y;
			uv += pos;
		}
	} else {
		float corner_x = 1.0 - min(uv.x, 1.0 - uv.x) / frame_border.x;
		float corner_y = 1.0 - min(uv.y, 1.0 - uv.y) / frame_border.y;
		if ( corner_x > 0.0 && corner_y > 0.0 && corner_x * corner_x + corner_y * corner_y > 1.0) {
			discard;
		} else if ( note_type == 0 || note_type == 1 ) {
			if ( corner_y > 0.6 && corner_y - corner_x > 2.0 ) {
				discard;
			}
		}
	}
	abs_duv = abs(0.5 - uv);
	if ( abs_duv.x > 0.5 || abs_duv.y > 0.5 ) {
		discard;
	}
	if ( abs_duv.x < 0.5 - frame_border.x && abs_duv.y < 0.5 - frame_border.y ) {
		vec4 albedo = mix(body_color_a, body_color_b, UV.x / inv_frame_x + frame_border.x);
		ALPHA = albedo.a;
		ALBEDO = albedo.rgb * ( 1.0 - texture(contour, SCREEN_UV + texture_vec).a * 0.325 );
	} else {
		vec4 albedo = mix(frame_color_a, frame_color_b, UV.x);
		ALPHA = albedo.a;
		ALBEDO = albedo.rgb * gold;
	}
}
