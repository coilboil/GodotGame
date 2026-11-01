shader_type spatial;

uniform sampler2D depth_cam_tex;
uniform sampler2D snow_tex: source_color;
uniform sampler2D normal_map: hint_normal;

void vertex() {
	vec2 uv = vec2(UV.x,UV.y);
	vec4 color = texture(depth_cam_tex,uv);
	VERTEX.y = 0.1 + ((VERTEX.y - color.r)*0.5);
}

void fragment() {
	vec2 uv = vec2(UV.x,1. - UV.y);
	vec2 uv2 = vec2(UV.x,UV.y);
	vec4 color = texture(snow_tex,uv);
	vec4 color2 = texture(normal_map,uv);
	vec4 color3 = texture(depth_cam_tex,uv2);
	ALBEDO = color.rgb;
	color2.y = 0.6 - (color3.r * 0.015);
	NORMAL_MAP = (color2.xyz)*0.8;
}
