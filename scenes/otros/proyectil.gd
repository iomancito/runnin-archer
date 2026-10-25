class_name Proyectil extends Node3D

## Bola de fuego (o de magia, de ácido o una piedra) que vuela hasta un punto del suelo marcado de antemano.
## La marca aparece al lanzarla y se va rellenando hasta el impacto: el player ve dónde caerá
## y cuánto le queda para apartarse. Al llegar daña al player si está dentro.
## La usan los bosses (Boss) y los enemigos que disparan (Lanzador).

enum Estilo {FUEGO, FUEGO_OSCURO, ALMAS, MAGIA, ACIDO, PIEDRA}
enum Forma {CIRCULO, CARRIL}

const GRUPO : StringName = &"proyectiles"
#cargados por código: también están en export_files del preset Android
const VFX : PackedScene = preload("res://assets/BinbunVFX_Vol2/ElementalMagicFX/effects/projectile/vfx_fire_projectile_01.tscn")
#piedra del troll (la misma que lleva en la mano)
const PIEDRA : PackedScene = preload("res://assets/externos/Nature/Pebble_Square_3.gltf")
const ESCALA_PIEDRA : float = 1.6
const SHADER_AVISO : Shader = preload("res://scenes/otros/aviso.gdshader")
#colores de cada estilo: [primario, secundario, terciario, marca del suelo]
const ESTILOS = {
	Estilo.FUEGO: [Color(1, 0.71, 0.31), Color(1, 0.4, 0.1), Color(0.51, 0.08, 0.04), Color(1.0, 0.3, 0.05)],
	Estilo.FUEGO_OSCURO: [Color(0.85, 0.5, 1.0), Color(0.55, 0.12, 0.95), Color(0.16, 0.02, 0.28), Color(0.75, 0.2, 1.0)],
	Estilo.ALMAS: [Color(0.7, 1.0, 0.95), Color(0.15, 0.75, 1.0), Color(0.02, 0.1, 0.3), Color(0.25, 0.95, 1.0)],
	Estilo.MAGIA: [Color(0.6, 1.0, 0.45), Color(0.2, 0.8, 0.25), Color(0.04, 0.2, 0.05), Color(0.45, 1.0, 0.3)],
	#el ácido no usa el efecto de fuego (ver Acido): solo cuenta el color de la marca
	Estilo.ACIDO: [Color(0.78, 0.95, 0.25), Color(0.5, 0.75, 0.12), Color(0.2, 0.35, 0.05), Color(0.75, 1.0, 0.1)],
	Estilo.PIEDRA: [Color.WHITE, Color.WHITE, Color.WHITE, Color(1.0, 0.75, 0.35)],
}
#al caer, la marca crece y se desvanece en este tiempo (s)
const DESTELLO : float = 0.3
#tamaño del efecto respecto al original
const ESCALA_VFX : float = 1.1
#largo (z) de la marca de un carril
const LARGO_CARRIL : float = 2.4
#la marca va un poco por encima del suelo (su superficie está a y = 0,1 en los mapas)
const ALTO_MARCA : float = 0.15

static var _material_marca : ShaderMaterial

var desde : Vector3
var hasta : Vector3
var tiempo : float = 1.0
var arco : float = 2.0
var daño : int = 0
var forma : int = Forma.CIRCULO
#radio del círculo o mitad del ancho del carril
var radio : float = 1.0
var estilo : int = Estilo.FUEGO
var escala : float = 1.0
var _t : float = 0.0
var _vfx : Node3D
var _marca : MeshInstance3D

## Lanza un proyectil de "desde" a "hasta" (en el suelo) que tarda "tiempo" segundos en llegar.
## arco: metros que sube sobre la línea recta a mitad de camino.
static func lanzar(padre : Node, de : Vector3, a : Vector3, t : float, d : int, est : int = Estilo.FUEGO,
		f : int = Forma.CIRCULO, r : float = 1.0, alto_arco : float = 2.0, esc : float = 1.0) -> Proyectil:
	var p = Proyectil.new()
	p.desde = de
	p.hasta = Vector3(a.x, 0.0, a.z)
	p.tiempo = max(t, 0.05)
	p.daño = d
	p.estilo = est
	p.forma = f
	p.radio = r
	p.arco = alto_arco
	p.escala = esc
	padre.add_child(p)
	return p

func _ready() -> void:
	add_to_group(GRUPO)
	top_level = true
	global_position = Vector3.ZERO
	var e = ESTILOS[estilo]
	if estilo == Estilo.ACIDO:
		_vfx = Acido.gota()
		add_child(_vfx)
	elif estilo == Estilo.PIEDRA:
		_vfx = Node3D.new()
		var piedra = PIEDRA.instantiate()
		piedra.scale = Vector3.ONE * ESCALA_PIEDRA
		_vfx.add_child(piedra)
		add_child(_vfx)
	else:
		_vfx = VFX.instantiate()
		_vfx.set("autoplay", false)
		#cada luz dinámica cuesta en el móvil
		for luz in _vfx.find_children("*", "Light3D", true, false):
			luz.visible = false
		add_child(_vfx)
		#los materiales del efecto son compartidos: el color se pone en cada lanzamiento
		_vfx.set("primary_color", e[0])
		_vfx.set("secondary_color", e[1])
		_vfx.set("tertiary_color", e[2])
		_vfx.set("emitting", true)
	_vfx.scale = Vector3.ONE * ESCALA_VFX * escala
	_vfx.global_position = desde
	_marca = _crea_marca(e[3])
	add_child(_marca)
	_marca.global_position = hasta + Vector3.UP * ALTO_MARCA

func _crea_marca(color : Color) -> MeshInstance3D:
	if _material_marca == null:
		_material_marca = ShaderMaterial.new()
		_material_marca.shader = SHADER_AVISO
	var m = MeshInstance3D.new()
	var plano = PlaneMesh.new()
	plano.size = Vector2(radio * 2.0, LARGO_CARRIL if forma == Forma.CARRIL else radio * 2.0)
	m.mesh = plano
	m.material_override = _material_marca
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.set_instance_shader_parameter("color", color)
	m.set_instance_shader_parameter("rectangular", 1.0 if forma == Forma.CARRIL else 0.0)
	m.set_instance_shader_parameter("progreso", 0.0)
	return m

func _physics_process(delta : float) -> void:
	_t += delta
	var k = clampf(_t / tiempo, 0.0, 1.0)
	var antes = _vfx.global_position
	_vfx.global_position = desde.lerp(hasta, k) + Vector3.UP * arco * 4.0 * k * (1.0 - k)
	#el efecto avanza por su +X
	var dir = _vfx.global_position - antes
	if dir.length_squared() > 0.0001:
		dir = dir.normalized()
		var arriba = Vector3.UP if abs(dir.y) < 0.99 else Vector3.BACK
		var b = Basis.looking_at(dir, arriba) * Basis(Vector3.UP, PI * 0.5)
		_vfx.global_basis = b.scaled(Vector3.ONE * ESCALA_VFX * escala)
	_marca.set_instance_shader_parameter("progreso", k)
	if k >= 1.0:
		_impacto()

func _impacto() -> void:
	var p = Progreso.player
	if daño > 0 and is_instance_valid(p) and not p.is_dead and dentro(p.global_position):
		p.recibe_daño(daño)
		texto_daño(get_parent(), p.global_position, daño)
	efecto_impacto(get_parent(), hasta, estilo, radio)
	_marca.reparent(get_parent())
	_marca.set_instance_shader_parameter("progreso", 1.0)
	var color : Color = ESTILOS[estilo][3]
	var marca = _marca
	var tw = marca.create_tween().set_parallel()
	tw.tween_property(marca, "scale", Vector3(1.4, 1.0, 1.4), DESTELLO)
	tw.tween_method(func(a): marca.set_instance_shader_parameter("color", Color(color, a)), 1.0, 0.0, DESTELLO)
	tw.chain().tween_callback(marca.queue_free)
	queue_free()

#el player (su centro) está en la zona del impacto
func dentro(pos : Vector3) -> bool:
	var dx = abs(pos.x - hasta.x)
	var dz = abs(pos.z - hasta.z)
	if forma == Forma.CARRIL:
		return dx < radio + Balance.RADIO_PLAYER and dz < LARGO_CARRIL * 0.5 + Balance.RADIO_PLAYER
	return Vector2(dx, dz).length() < radio + Balance.RADIO_PLAYER

#la explosión del juego es naranja: solo con el fuego normal; el ácido salpica; los demás, solo
#el destello de la marca
static func efecto_impacto(padre : Node, pos : Vector3, est : int, r : float) -> void:
	if est == Estilo.FUEGO:
		ArcoEfectos.explosion(padre, pos, r * 0.8)
	elif est == Estilo.ACIDO:
		Acido.salpicadura(padre, pos)

#lo llama el boss al morir: lo que queda en el aire desaparece sin dañar
func cancelar() -> void:
	queue_free()

#"-N" rojo que sube sobre el player
static func texto_daño(padre : Node, pos : Vector3, d : int) -> void:
	var label = Label3D.new()
	label.text = "-%d" % d
	label.modulate = Color(1, 0.3, 0.25)
	label.outline_modulate = Color(0.1, 0.02, 0.02)
	label.font_size = 110
	label.outline_size = 26
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	padre.add_child(label)
	label.global_position = pos + Vector3.UP * 2.0
	var tw = label.create_tween().set_parallel()
	tw.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)

#muestra un proyectil inofensivo durante la carga para compilar sus shaders, y los efectos
#de su impacto ya, porque el precalentado dura menos de lo que tarda en caer
static func precalentar(padre : Node, pos : Vector3, est : int) -> void:
	lanzar(padre, pos + Vector3.UP * 2.0, pos, 0.4, 0, est, Forma.CIRCULO, 1.0, 1.0)
	lanzar(padre, pos + Vector3(2, 2, 0), pos + Vector3(2, 0, 0), 0.4, 0, est, Forma.CARRIL, 1.0, 1.0)
	efecto_impacto(padre, pos + Vector3(0, 0, -1.5), est, Balance.LANZADOR_RADIO)
	if est == Estilo.ACIDO:
		Acido.precalentar(padre, pos + Vector3(0, 1.2, -1.5))
