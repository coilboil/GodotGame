shader_type canvas_item;

uniform sampler2D my_tex;

void fragment() {
	vec2 uv = vec2(UV.x,1. -  UV.y);
	vec4 color = texture(my_tex,uv);
	if (color.r < 0.1){
		discard;
	}
	COLOR = color;
}
