shader_type canvas_item;

uniform float size = 0.02;
uniform vec2 plot_size = vec2(5.0, 5.0);
uniform float rotation = 0.0;
uniform float aa = 1.5;

void fragment() {
	vec2 uv = UV - vec2(0.5, 0.5);
	mat2 rotation_matrix = mat2(vec2(cos(rotation), -sin(rotation)), vec2(sin(rotation), cos(rotation)));
	uv = uv * rotation_matrix + vec2(0.5, 0.5);
	vec2 grid = floor(uv * ( plot_size + 1.0 ));
	if ( grid.x <= 0.0 || grid.y <= 0.0 || grid.x >= plot_size.x || grid.y >= plot_size.y ) {
		discard;
	}
	vec2 center = ( grid + 0.5 ) / ( plot_size + 1.0 );
	float dist = distance(uv, center);
	float aaa = fwidth(dist) * aa;
	float alpha = 1.0 - smoothstep(size - aaa, size + aaa, dist);
	COLOR.a *= alpha;
}
