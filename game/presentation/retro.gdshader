shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 raster_size = vec2(480.0, 270.0);
uniform float color_steps = 32.0;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.012;
uniform float chroma_pixels : hint_range(0.0, 2.0) = 0.3;

void fragment() {
	vec2 uv = (floor(SCREEN_UV * raster_size) + 0.5) / raster_size;
	vec2 offset = vec2(chroma_pixels / raster_size.x, 0.0);
	vec3 color = texture(screen_texture, uv).rgb;
	color.r = texture(screen_texture, uv + offset).r;
	color.b = texture(screen_texture, uv - offset).b;
	float noise = fract(sin(dot(floor(uv * raster_size), vec2(12.9898, 78.233)) + floor(TIME * 12.0)) * 43758.5453);
	color = floor(clamp(color + (noise - 0.5) * grain_strength, vec3(0.0), vec3(1.0)) * color_steps + 0.5) / color_steps;
	COLOR = vec4(color, 1.0);
}
