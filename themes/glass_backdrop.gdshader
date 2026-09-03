shader_type canvas_item;

uniform vec4 deep_colour : source_color = vec4(0.018, 0.027, 0.055, 1.0);
uniform vec4 aurora_colour : source_color = vec4(0.08, 0.30, 0.52, 1.0);
uniform vec4 violet_colour : source_color = vec4(0.24, 0.11, 0.42, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.28;
uniform float motion_speed : hint_range(0.0, 0.2) = 0.025;

float soft_circle(vec2 point, vec2 centre, float radius) {
	return 1.0 - smoothstep(radius * 0.18, radius, distance(point, centre));
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * motion_speed;
	vec4 base = deep_colour;
	float blue_glow = soft_circle(uv, vec2(0.15 + sin(time) * 0.05, 0.08 + cos(time) * 0.04), 0.62);
	float violet_glow = soft_circle(uv, vec2(0.90 + cos(time * 0.8) * 0.04, 0.86 + sin(time) * 0.05), 0.55);
	float vignette = smoothstep(1.16, 0.24, distance(uv, vec2(0.5)));
	base.rgb += aurora_colour.rgb * blue_glow * glow_strength;
	base.rgb += violet_colour.rgb * violet_glow * glow_strength * 0.55;
	base.rgb *= mix(0.76, 1.0, vignette);
	COLOR = base;
}
