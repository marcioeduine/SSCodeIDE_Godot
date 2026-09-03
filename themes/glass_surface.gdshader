shader_type canvas_item;
render_mode unshaded;

// A restrained, panel-only glass sheen. The Theme still owns opacity, borders,
// corner radii and focus rings; this material only adds light to the surface.
uniform vec4 upper_tint : source_color = vec4(0.26, 0.62, 0.98, 1.0);
uniform vec4 lower_tint : source_color = vec4(0.45, 0.30, 0.88, 1.0);
uniform float sheen_strength : hint_range(0.0, 0.18) = 0.045;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float top_sheen = pow(1.0 - UV.y, 2.4);
	float bottom_glow = pow(UV.y, 3.0);
	float grain = fract(sin(dot(UV * 1024.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	vec3 glass_light = upper_tint.rgb * top_sheen + lower_tint.rgb * bottom_glow * 0.32;
	source.rgb += glass_light * sheen_strength * source.a;
	source.rgb += grain * 0.006 * source.a;
	COLOR = source;
}
