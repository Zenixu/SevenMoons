shader_type canvas_item;

// Blur sederhana 9-tap untuk efek "membuka mata" saat bangun.
// blur_amount: 0.0 = tajam, ~1.0 = sangat kabur (piksel tekstur).
uniform float blur_amount : hint_range(0.0, 8.0) = 4.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * blur_amount;
	vec4 acc = vec4(0.0);
	// kotak 3x3
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			acc += texture(TEXTURE, UV + vec2(float(x), float(y)) * px);
		}
	}
	vec4 col = acc / 9.0;

	// Vignette gelap di tepi (mata masih berat)
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.30, 0.72, length(d));
	col.rgb = mix(col.rgb, vec3(0.0), v * vignette_strength);

	COLOR = col;
}
