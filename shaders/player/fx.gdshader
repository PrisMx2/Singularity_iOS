shader_type canvas_item;

global uniform float time;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap, repeat_disable;

uniform float glitch_frequency = 48.0;
uniform float glitch_density = 16.0;
uniform float glitch_percent = 0.85;
uniform float glitch_strength = 0.007;

uniform float zoomblur_strength = 0.2;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	//float strip = floor(uv.y * density) * 2.2360679;
	//float unit = floor(time * frequency / 1000.0) * 1.7320508;
	//float apply = step(percent, hash(vec2(strip + 0.517, unit + 0.293))) * strength;
//
	//float r_seed = hash(vec2(strip + 11.317, unit + 7.131));
	//float g_seed = hash(vec2(strip + 23.719, unit + 19.373));
	//float b_seed = hash(vec2(strip + 41.173, unit + 31.797));
//
	//float r_offset = (r_seed - 0.5) * apply;
	//float g_offset = (g_seed - 0.5) * apply;
	//float b_offset = (b_seed - 0.5) * apply;
//
	//float r = texture(screen_texture, uv + vec2(r_offset, 0.0)).r;
	//float g = texture(screen_texture, uv + vec2(g_offset, 0.0)).g;
	//float b = texture(screen_texture, uv + vec2(b_offset, 0.0)).b;
//
	//COLOR = vec4(r, g, b, 1.0);

	vec2 duv = uv - 0.5;
	vec2 apply = duv * dot(duv, duv) * -zoomblur_strength;

	vec2 r_offset = apply * 1.0;
	vec2 g_offset = apply * 1.2;
	vec2 b_offset = apply * 1.4;

	float z_blur = clamp(length(apply) * 32.0 - 0.5, 0.0, 4.0);

	float r = textureLod(screen_texture, uv + r_offset, z_blur).r;
	float g = textureLod(screen_texture, uv + g_offset, z_blur).g;
	float b = textureLod(screen_texture, uv + b_offset, z_blur).b;

	COLOR = vec4(r, g, b, 1.0);
}
