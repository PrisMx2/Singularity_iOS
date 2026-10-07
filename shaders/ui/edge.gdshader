shader_type canvas_item;

uniform float left = 1.0;
uniform float right = 1.0;
uniform float top = 1.0;
uniform float bottom = 1.0;

void fragment() {
	float x = sin(UV.x * PI);
	float y = sin(UV.y * PI);
	COLOR.a *= UV.x < 0.5 ? pow(x, left) : pow(x, right);
	COLOR.a *= UV.y < 0.5 ? pow(y, top) : pow(y, bottom);
}
