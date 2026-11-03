shader_type spatial;
//panel de energía de las puertas de mejora: translúcido, borde claro y rayas diagonales
//que suben. Sin luz ni texturas (barato en la Mali); el color va por instancia
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

instance uniform vec4 color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
//0 = normal, 1 = blanco (al cogerla)
instance uniform float destello = 0.0;
//multiplica el alfa (para desvanecerla)
instance uniform float opacidad = 1.0;
//ancho / alto del quad (la UV va de 0 a 1 en los dos ejes)
uniform float aspecto = 2.5;

void fragment() {
	vec2 p = vec2(UV.x * aspecto, UV.y);
	//distancia al borde en unidades de alto
	float d = min(min(p.x, aspecto - p.x), min(p.y, 1.0 - p.y));
	float borde = 1.0 - smoothstep(0.045, 0.06, d);
	//halo interior junto al borde
	float halo = (1.0 - smoothstep(0.06, 0.22, d)) * (1.0 - borde);
	float s = fract((p.x * 0.6 + p.y) * 2.5 + TIME * 0.7);
	float rayas = smoothstep(0.0, 0.06, s) * (1.0 - smoothstep(0.42, 0.48, s));
	//más denso abajo, brillo arriba
	float alfa = mix(0.38, 0.62, UV.y) + rayas * 0.12 + halo * 0.35;
	vec3 col = color.rgb * (0.8 + rayas * 0.25 + halo * 0.4);
	col += (1.0 - smoothstep(0.0, 0.35, UV.y)) * 0.18;
	col = mix(col, mix(color.rgb, vec3(1.0), 0.75), borde);
	alfa = mix(alfa, 1.0, borde);
	col = mix(col, vec3(1.0), destello);
	ALBEDO = col;
	ALPHA = clamp(alfa + destello * 0.4, 0.0, 1.0) * opacidad;
}
