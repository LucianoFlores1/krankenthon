// Full-screen "dirty paper" post-process. Put on a ColorRect (anchors full rect,
// mouse_filter = ignore) inside a CanvasLayer. Feed step_seed from StepClock so
// grain + jitter change only on beats (stop-motion), not every frame.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
// Optional: a scanned sheet of blank paper (tileable). White = no effect.
uniform sampler2D paper_tex : source_color, hint_default_white, repeat_enable, filter_linear_mipmap;
uniform float step_seed = 0.0;
uniform float paper_strength : hint_range(0.0, 1.0) = 0.6;
uniform float paper_scale = 1.5;
uniform float grain : hint_range(0.0, 0.5) = 0.07;
uniform float jitter_px : hint_range(0.0, 6.0) = 1.0; // whole-frame "camera bump" per beat
uniform float desaturate : hint_range(0.0, 1.0) = 0.75;
uniform float vignette : hint_range(0.0, 1.0) = 0.65;
uniform float contrast : hint_range(0.5, 2.0) = 1.15;
uniform vec3 tint : source_color = vec3(0.93, 0.89, 0.80);
uniform vec3 accent : source_color = vec3(0.75, 0.08, 0.06); // the one colour that survives (blood red)
uniform float accent_keep : hint_range(0.0, 1.0) = 0.8;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 seed = vec2(step_seed * 0.137, step_seed * 0.291);
	vec2 jitter = (vec2(hash(seed + 1.0), hash(seed + 2.0)) - 0.5) * jitter_px * SCREEN_PIXEL_SIZE;
	vec3 c = textureLod(screen_tex, SCREEN_UV + jitter, 0.0).rgb;

	// Desaturate everything except colours close to the accent.
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float accent_mask = accent_keep * (1.0 - smoothstep(0.15, 0.45, distance(normalize(c + 1e-4), normalize(accent))));
	c = mix(c, vec3(l), desaturate * (1.0 - accent_mask));
	c = (c - 0.5) * contrast + 0.5;

	// Paper multiplies like graphite on paper; offset per beat so the fibres "boil".
	vec2 paper_uv = SCREEN_UV * paper_scale * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0) + seed;
	c *= mix(vec3(1.0), texture(paper_tex, paper_uv).rgb, paper_strength);

	c += (hash(floor(FRAGCOORD.xy) + seed * 100.0) - 0.5) * grain;
	float v = smoothstep(0.85, 0.25, distance(SCREEN_UV, vec2(0.5)));
	c *= mix(1.0, v, vignette);

	COLOR = vec4(clamp(c * tint, 0.0, 1.0), 1.0);
}
