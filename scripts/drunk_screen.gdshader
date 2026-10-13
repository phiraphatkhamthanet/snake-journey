shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float t = 0.0;

// หมุนสีรอบแกนเทา (hue shift)
vec3 hue_rotate(vec3 c, float a) {
	vec3 k = vec3(0.57735);
	float ca = cos(a);
	float sa = sin(a);
	return c * ca + cross(k, c) * sa + k * dot(k, c) * (1.0 - ca);
}

void fragment() {
	float k = intensity;
	vec2 uv = SCREEN_UV;

	// ภาพโยกเป็นคลื่น
	uv += vec2(sin(uv.y * 12.0 + t * 3.0), cos(uv.x * 10.0 + t * 2.5)) * 0.015 * k;

	// ซูมเข้าออกเป็นจังหวะ
	uv = (uv - 0.5) * (1.0 - 0.05 * k * sin(t * 2.0)) + 0.5;

	// สีแยกช่อง (chromatic aberration)
	float ca = 0.012 * k;
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(ca, 0.0)).b;

	// ภาพซ้อน
	vec3 ghost = texture(screen_tex, uv + vec2(sin(t * 1.7), cos(t * 1.3)) * 0.03 * k).rgb;
	col = mix(col, ghost, 0.35 * k);

	// สีวนเป็นรุ้ง + แสงสีฟุ้ง
	col = mix(col, hue_rotate(col, t * 2.0), k);
	col += 0.12 * k * vec3(
		sin(t + uv.x * 6.0),
		sin(t * 1.3 + uv.y * 6.0 + 2.0),
		sin(t * 0.7 + (uv.x + uv.y) * 5.0 + 4.0)
	);

	COLOR = vec4(col, 1.0);
}
