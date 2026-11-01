shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : source_color, hint_depth_texture;

void vertex() {
 // POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
  vec2 uv = vec2(SCREEN_UV.x, SCREEN_UV.y);
  float depth = texture(depth_texture, SCREEN_UV).x;
  vec4 color = texture(depth_texture, uv);
  ALBEDO = color.rgb;
  // Visualize world coordinates
  //ALBEDO.rgb = fract(world_position).xyz;
}