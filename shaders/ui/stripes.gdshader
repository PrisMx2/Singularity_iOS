shader_type canvas_item;

global uniform float time;
uniform float speed = 0.015;

void fragment() {
	COLOR.a *= clamp( ceil( sin( ( UV.x * 19.2 + UV.y * 10.8 ) * 40.0 + time * speed ) - 0.65 ) * 0.35, 0.0, 1.0 );
}
