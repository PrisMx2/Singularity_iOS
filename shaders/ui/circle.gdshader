shader_type canvas_item;

void fragment() {
	if ( length(UV * 2.0 - vec2(1.0)) > 1.0 ) {
		discard;
	}
}
