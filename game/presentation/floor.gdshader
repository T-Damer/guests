shader_type spatial;
render_mode diffuse_lambert;

uniform vec3 tile_a : source_color = vec3(0.20, 0.24, 0.22);
uniform vec3 tile_b : source_color = vec3(0.28, 0.29, 0.25);
uniform float tile_count = 24.0;

void fragment() {
	vec2 cell = floor(UV * tile_count);
	float checker = mod(cell.x + cell.y, 2.0);
	vec2 local = fract(UV * tile_count);
	float seam = step(0.025, local.x) * step(0.025, local.y);
	ALBEDO = mix(tile_a, tile_b, checker) * mix(0.65, 1.0, seam);
	ROUGHNESS = 0.88;
}
