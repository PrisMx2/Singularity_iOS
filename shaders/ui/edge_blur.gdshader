shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float strength = 2.0;

uniform float left = 1.0;
uniform float right = 1.0;
uniform float top = 1.0;
uniform float bottom = 1.0;

void fragment() {
	float s = strength;
	float x = sin(UV.x * PI);
	float y = sin(UV.y * PI);
	s *= UV.x < 0.5 ? pow(x, left) : pow(x, right);
	s *= UV.y < 0.5 ? pow(y, top) : pow(y, bottom);
	vec4 color = textureLod(screen_texture, SCREEN_UV, s);
	COLOR.rgb = mix(vec3(0.0), color.rgb, color.a);
}
