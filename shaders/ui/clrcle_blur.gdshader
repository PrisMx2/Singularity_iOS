shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float strength = 2.0;

void fragment() {
	if ( length(UV * 2.0 - vec2(1.0)) > 1.0 ) {
		discard;
	}
	vec4 color = textureLod(screen_texture, SCREEN_UV, strength);
	COLOR.rgb = mix(vec3(0.0), color.rgb, color.a);
}
