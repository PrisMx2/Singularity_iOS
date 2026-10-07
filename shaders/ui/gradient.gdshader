shader_type canvas_item;

uniform vec2 begin = vec2(0.0, 0.0);
uniform vec2 end = vec2(1.0, 1.0);
uniform vec4 color_a = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_b = vec4(1.0, 1.0, 1.0, 1.0);
uniform float angle = 0.0;

void fragment() {
	vec2 b = min(begin, end);
	vec2 e = max(begin, end);
	if (UV.x > b.x && UV.y > b.y && UV.x < e.x && UV.y < e.y) {
		vec2 local_uv = (UV - b) / max(e - b, vec2(0.0001));
		float rad = radians(angle);
		mat2 rotation_matrix = mat2(vec2(cos(rad), -sin(rad)), vec2(sin(rad), cos(rad)));
		vec2 uv = (local_uv - 0.5) * rotation_matrix + 0.5;
		COLOR *= mix(color_a, color_b, uv.y);
	}
}
