shader_type spatial;
render_mode blend_mix, cull_back, unshaded, depth_test_disabled, depth_draw_never;

//global uniform float time;

varying flat float weight;
varying flat float alpha;

void vertex() {
	weight = clamp(INSTANCE_CUSTOM.r * 2.0, -1.0, 1.0);
	alpha = 1.0 - INSTANCE_CUSTOM.g;
	VERTEX.xy *= vec2(2.5, 0.06);
}

void fragment() {
	const vec3 early = vec3(0.0, 0.0, 1.0);
	const vec3 none = vec3(1.0, 1.0, 1.0);
	const vec3 late = vec3(1.0, 0.0, 0.0);
	ALBEDO = mix(mix(early, none, weight + 1.0), mix(none, late, weight), step(0.0, weight));
	ALPHA = alpha;
}
