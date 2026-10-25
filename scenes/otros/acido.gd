class_name Acido

## Efectos del ácido del zombi escupidor, con partículas generadas por código (sin texturas).
## El chorro es el del vomitador del proyecto YoelGame: gotas que salen de la boca hacia delante,
## caen en arco y se desvanecen. Los recursos se crean una vez y se comparten.

const COLOR_GOTA : Color = Color(0.78, 0.95, 0.25, 0.95)
const COLOR_MEDIO : Color = Color(0.5, 0.75, 0.12, 0.8)
const COLOR_FIN : Color = Color(0.3, 0.45, 0.08, 0.0)
#segundos que dura la salpicadura al caer
const VIDA_SALPICADURA : float = 0.6

static var _proceso_chorro : ParticleProcessMaterial
static var _proceso_estela : ParticleProcessMaterial
static var _proceso_salpicadura : ParticleProcessMaterial
static var _malla_gota : QuadMesh
static var _bola : SphereMesh
static var _tinte : StandardMaterial3D

#chorro de la boca (apagado): emite hacia su +Z, girarlo con look_at(destino, UP, true)
static func chorro() -> GPUParticles3D:
	_prepara()
	var p = _particulas(_proceso_chorro, 90, 0.75)
	p.name = "ChorroAcido"
	return p

#proyectil en vuelo: bola de ácido que va dejando una estela de gotas que caen
static func gota() -> Node3D:
	_prepara()
	var n = Node3D.new()
	var bola = MeshInstance3D.new()
	bola.mesh = _bola
	bola.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(bola)
	var estela = _particulas(_proceso_estela, 40, 0.5)
	estela.emitting = true
	n.add_child(estela)
	return n

#salpicadura al caer en el suelo; se libera sola
static func salpicadura(padre : Node, pos : Vector3) -> void:
	_prepara()
	var p = _particulas(_proceso_salpicadura, 36, VIDA_SALPICADURA)
	p.one_shot = true
	p.explosiveness = 0.9
	padre.add_child(p)
	p.global_position = pos + Vector3.UP * 0.2
	p.emitting = true
	p.get_tree().create_timer(VIDA_SALPICADURA + 0.2, false).timeout.connect(p.queue_free)

#capa verdosa sobre el modelo para distinguir al escupidor de los zombis normales
static func tinte() -> StandardMaterial3D:
	_prepara()
	return _tinte

static func _particulas(proceso : ParticleProcessMaterial, cantidad : int, vida : float) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.process_material = proceso
	p.draw_pass_1 = _malla_gota
	p.amount = cantidad
	p.lifetime = vida
	#las gotas no siguen al emisor: dejan el arco en el aire
	p.local_coords = false
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-7, -3, -7), Vector3(14, 6, 14))
	return p

static func _prepara() -> void:
	if _proceso_chorro != null:
		return
	var desvanece = GradientTexture1D.new()
	var g = Gradient.new()
	g.set_color(0, COLOR_GOTA)
	g.add_point(0.5, COLOR_MEDIO)
	g.set_color(g.get_point_count() - 1, COLOR_FIN)
	desvanece.gradient = g
	var crece = CurveTexture.new()
	var c = Curve.new()
	c.add_point(Vector2(0.0, 0.5))
	c.add_point(Vector2(1.0, 1.3))
	crece.curve = c

	_proceso_chorro = ParticleProcessMaterial.new()
	_proceso_chorro.direction = Vector3(0, -0.12, 1)
	_proceso_chorro.spread = 7.0
	_proceso_chorro.initial_velocity_min = 8.5
	_proceso_chorro.initial_velocity_max = 10.5
	_proceso_chorro.gravity = Vector3(0, -6.5, 0)
	_proceso_chorro.scale_min = 0.6
	_proceso_chorro.scale_max = 1.5
	_proceso_chorro.scale_curve = crece
	_proceso_chorro.color_ramp = desvanece

	_proceso_estela = ParticleProcessMaterial.new()
	_proceso_estela.direction = Vector3(0, -1, 0)
	_proceso_estela.spread = 40.0
	_proceso_estela.initial_velocity_min = 0.3
	_proceso_estela.initial_velocity_max = 1.0
	_proceso_estela.gravity = Vector3(0, -6.5, 0)
	_proceso_estela.scale_min = 0.5
	_proceso_estela.scale_max = 1.0
	_proceso_estela.color_ramp = desvanece

	_proceso_salpicadura = ParticleProcessMaterial.new()
	_proceso_salpicadura.direction = Vector3(0, 1, 0)
	_proceso_salpicadura.spread = 70.0
	_proceso_salpicadura.initial_velocity_min = 2.0
	_proceso_salpicadura.initial_velocity_max = 4.0
	_proceso_salpicadura.gravity = Vector3(0, -9.0, 0)
	_proceso_salpicadura.scale_min = 0.7
	_proceso_salpicadura.scale_max = 1.6
	_proceso_salpicadura.scale_curve = crece
	_proceso_salpicadura.color_ramp = desvanece

	#gota: quad con degradado radial suave, de cara a la cámara y coloreada por las partículas
	_malla_gota = QuadMesh.new()
	_malla_gota.size = Vector2(0.36, 0.36)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var mancha = GradientTexture2D.new()
	mancha.fill = GradientTexture2D.FILL_RADIAL
	mancha.fill_from = Vector2(0.5, 0.5)
	mancha.fill_to = Vector2(1.0, 0.5)
	var suave = Gradient.new()
	suave.set_color(0, Color(1, 1, 1, 1))
	suave.add_point(0.55, Color(1, 1, 1, 0.9))
	suave.set_color(suave.get_point_count() - 1, Color(1, 1, 1, 0))
	mancha.gradient = suave
	mat.albedo_texture = mancha
	_malla_gota.material = mat

	_bola = SphereMesh.new()
	_bola.radius = 0.22
	_bola.height = 0.44
	_bola.radial_segments = 12
	_bola.rings = 6
	var mat_bola = StandardMaterial3D.new()
	mat_bola.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_bola.albedo_color = Color(0.7, 0.95, 0.2)
	_bola.material = mat_bola

	_tinte = StandardMaterial3D.new()
	_tinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tinte.albedo_color = Color(0.55, 0.95, 0.1, 0.22)
