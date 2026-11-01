
shader_type canvas_item;

uniform sampler2D my_tex;
uniform sampler2D my_tex2;


void vertex() {
	
}

void fragment() {
	vec2 uv = vec2(UV.x,1. -  UV.y);
	vec2 uv2 = vec2(UV.x,1. - UV.y);
	vec4 color = texture(my_tex, uv);
	vec4 color2 = texture(my_tex2,uv2);
	if (COLOR.r < 0.3){
		COLOR.rgb = vec3(0.,0.,0.);
	}
	COLOR.r += color.r;
	if (color2.r > color.r){
		COLOR.r = color2.r;
	}
		
	if (COLOR.r < 0.302){
		COLOR.rgb = vec3(0.,0.,0.);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
