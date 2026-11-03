class_name PanelSkills extends Node3D

#dos mejoras distintas al azar de Balance.PUERTAS (texto, stat, incremento)
#el pilar central es una cuña en la capa de los muros: obliga a ir a un lado u otro
var left_rnd : int
var right_rnd : int
#solo se puede coger una de las dos (las dos áreas pueden avisar en el mismo frame)
var cogido : bool = false
@onready var left_mesh : MeshInstance3D = $left_mesh
@onready var right_mesh : MeshInstance3D = $right_mesh

#color del panel según la mejora (solo visual)
const COLORES = {
	"f_daño": Color(0.93, 0.26, 0.24),
	"p_attack_speed": Color(1.0, 0.6, 0.1),
	"f_cantidad": Color(0.25, 0.5, 1.0),
	"f_max_distancia": Color(0.1, 0.78, 0.85),
	"p_side_speed": Color(0.65, 0.35, 0.95),
	"p_vida": Color(0.25, 0.8, 0.35),
}
#ancho máximo del texto (m), centrado en el panel: no debe pisar su borde
const ANCHO_TEXTO = 4.2
#duración de la animación al coger una puerta
const ANIM_COGER = 0.35

func _ready() -> void:
	var n = Balance.PUERTAS.size()
	left_rnd = randi_range(0, n - 1)
	right_rnd = randi_range(0, n - 1)
	while left_rnd == right_rnd:
		right_rnd = randi_range(0, n - 1)
	_pinta(left_mesh, $left_mesh/left_titulo, $left_mesh/left_label, left_rnd)
	_pinta(right_mesh, $right_mesh/right_titulo, $right_mesh/right_label, right_rnd)

#el texto de PUERTAS es "Nombre\nValor": nombre pequeño arriba, valor grande abajo
func _pinta(mesh : MeshInstance3D, titulo : Label3D, valor : Label3D, i : int) -> void:
	var partes = Balance.PUERTAS[i][0].split("\n")
	titulo.text = partes[0].to_upper()
	valor.text = partes[1] if partes.size() > 1 else ""
	_encaja(titulo)
	_encaja(valor)
	mesh.set_instance_shader_parameter("color", COLORES.get(Balance.PUERTAS[i][1], Color.WHITE))

#reduce el texto si es más ancho que ANCHO_TEXTO
func _encaja(l : Label3D) -> void:
	var ancho = l.font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.font_size).x * l.pixel_size
	if ancho > ANCHO_TEXTO:
		l.pixel_size *= ANCHO_TEXTO / ancho

func _on_left_area_body_entered(body: Node3D) -> void:
	if body is Player:
		upgrade_skill_player(body, left_rnd, left_mesh, right_mesh)

func _on_right_area_body_entered(body: Node3D) -> void:
	if body is Player:
		upgrade_skill_player(body, right_rnd, right_mesh, left_mesh)

func upgrade_skill_player(body : Node3D, valor : int, elegido : MeshInstance3D, otro : MeshInstance3D) -> void:
	if cogido:
		return
	cogido = true
	Sonidos.toca("puerta")
	body.mejora(Balance.PUERTAS[valor][1], Balance.PUERTAS[valor][2])
	Logros.puerta(body)
	_anima_coger(elegido, otro)

#el panel elegido destella y crece; el otro se apaga; después se borra la puerta
func _anima_coger(elegido : MeshInstance3D, otro : MeshInstance3D) -> void:
	#al salir de pantalla (queda detrás de la cámara) el enabler desactivaría el nodo y su tween
	$VisibleOnScreenEnabler3D.queue_free()
	var t = create_tween().set_parallel()
	t.tween_method(func(v): elegido.set_instance_shader_parameter("destello", v), 1.0, 0.0, ANIM_COGER)
	t.tween_property(elegido, "scale", Vector3(1.25, 1.25, 1.0), ANIM_COGER).set_ease(Tween.EASE_OUT)
	for m in [elegido, otro]:
		t.tween_method(func(v): m.set_instance_shader_parameter("opacidad", v), 1.0, 0.0, ANIM_COGER)
		for l in m.get_children():
			if l is Label3D:
				t.tween_property(l, "modulate:a", 0.0, ANIM_COGER)
				t.tween_property(l, "outline_modulate:a", 0.0, ANIM_COGER)
	t.chain().tween_callback(queue_free)
