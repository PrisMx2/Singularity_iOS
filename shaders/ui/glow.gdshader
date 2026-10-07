shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float blur = 5.0;
uniform float bright = 0.5;

void fragment() {
	vec4 normal = texture(screen_texture, SCREEN_UV);
	vec4 blured = textureLod(screen_texture, SCREEN_UV, blur);
	COLOR.rgb = min(normal + blured * bright, vec4(1.0)).rgb;
}
