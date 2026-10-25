shader_type spatial;
//marca en el suelo donde caerá un proyectil: borde fijo y un relleno que crece hasta el impacto.
//Parámetros por instancia: todas las marcas comparten material (una sola compilación).
//Mezcla alfa: en el renderer Mobile la multiplicativa oscurece de más.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float progreso = 0.0;
instance uniform vec4 color : source_color = vec4(1.0, 0.3, 0.05, 1.0);
//0 = círculo, 1 = rectángulo (un carril entero)
instance uniform float rectangular = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = mix(length(p), max(abs(p.x), abs(p.y)), rectangular);
	if (d > 1.0) {
		discard;
	}
	float borde = smoothstep(0.8, 0.92, d);
	//el relleno late un poco para llamar la atención
	float relleno = step(d, progreso) * (0.4 + 0.1 * sin(TIME * 18.0));
	ALBEDO = color.rgb;
	ALPHA = clamp(max(borde * 0.9, relleno) + 0.12, 0.0, 1.0) * color.a;
}
