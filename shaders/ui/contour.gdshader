shader_type canvas_item;

global uniform float time;
uniform sampler2D mask_texture: filter_linear, repeat_enable;
uniform vec3 mask_color = vec3(1.0, 1.0, 1.0);
uniform vec2 mask_speed = vec2(0.0, 0.0);
uniform float mask_zoom = 1.0;
uniform float mask_strength = 1.0;

void fragment() {
	float alpha = texture(mask_texture, SCREEN_UV * mask_zoom + mask_speed * time * 0.00001).a * 5.0;
	COLOR.a = alpha * mask_strength * COLOR.a;
	COLOR.rgb = mask_color;
}
