shader_type canvas_item;

global uniform float time;

uniform sampler2D area: filter_linear, repeat_disable;
uniform sampler2D distortion: filter_linear, repeat_enable;

uniform vec4 fill_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float edge_width = 1.0;

uniform vec2 distortion_vector = vec2(0.05, 0.05);
uniform float distortion_speed = 0.008;

uniform float pixel_scale = 128.0;

void fragment() {

	vec2 pixel = (floor(UV * pixel_scale) + 0.5) / pixel_scale;

	vec2 dir = distortion_vector;
	vec2 rdir = vec2(-dir.y, dir.x);
	float t = time * distortion_speed;
	float duv_a = texture(distortion, pixel + dir * t).a - 0.5;
	float duv_b = texture(distortion, pixel + rdir * t).a - 0.5;

	vec2 displace_vec = dir * duv_a + rdir * duv_b;

	vec2 final_uv = pixel + displace_vec;
	final_uv = (floor(final_uv * pixel_scale) + 0.5) / pixel_scale;

	float mask = texture(area, final_uv).a;

	vec2 duv = vec2(edge_width / pixel_scale);
	float border_l = texture(area, final_uv - vec2(duv.x, 0.0)).a;
	float border_r = texture(area, final_uv + vec2(duv.x, 0.0)).a;
	float border_u = texture(area, final_uv + vec2(0.0, duv.y)).a;
	float border_d = texture(area, final_uv - vec2(0.0, duv.y)).a;

	float m = min(min(border_l, border_r), min(border_u, border_d));
	float edge = smoothstep(0.0, 0.5, mask - m);

	COLOR = mix(fill_color * mask, edge_color, edge);
}