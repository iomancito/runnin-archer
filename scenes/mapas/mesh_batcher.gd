class_name MeshBatcher

## Junta los MeshInstance3D estáticos que comparten malla en MultiMeshInstance3D,
## uno por malla y bloque de profundidad (z). Así cada bloque fuera de cámara se
## descarta entero y pasamos de miles de nodos/draw calls a unas decenas.

#mallas pequeñas que no proyectan sombra (ahorra la pasada de sombras en el móvil)
const SIN_SOMBRA : PackedStringArray = ["grass", "clover", "fern", "flower", "petal", "mushroom", "pebble", "bush", "plant"]
#materiales sólidos que el pack exporta con recorte alfa y doble cara sin necesitarlo:
#en GPUs Mali el recorte alfa desactiva la eliminación de superficies ocultas
const SOLIDOS : PackedStringArray = ["bark", "rock"]
#hojas: con la cámara detrás del player llenan media pantalla con varias capas de recorte alfa;
#sin recibir sombras ni especular cada píxel cuesta mucho menos (~4 ms en el móvil)
const HOJAS : PackedStringArray = ["leaves"]

static func batch(root : Node3D, block_size : float = 30.0) -> int:
	var grupos := {}
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skin != null or not mi.is_visible_in_tree():
			continue
		var materiales := []
		for s in mi.get_surface_override_material_count():
			materiales.append(mi.get_surface_override_material(s))
		var sombra = mi.cast_shadow
		var nombre = mi.mesh.resource_name.to_lower() + " " + String(mi.name).to_lower()
		for k in SIN_SOMBRA:
			if nombre.contains(k):
				sombra = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				break
		var bloque = int(floor(mi.global_position.z / block_size))
		var clave = [mi.mesh, mi.material_override, materiales, sombra, bloque]
		if not grupos.has(clave):
			grupos[clave] = []
		grupos[clave].append(mi)

	var inversa = root.global_transform.affine_inverse()
	for clave in grupos:
		var instancias : Array = grupos[clave]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _optimiza_materiales(_malla_con_materiales(clave[0], clave[2]))
		mm.instance_count = instancias.size()
		for i in instancias.size():
			mm.set_instance_transform(i, inversa * instancias[i].global_transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Batch_%s_%d" % [mm.mesh.resource_name, clave[4]]
		mmi.multimesh = mm
		mmi.material_override = clave[1]
		mmi.cast_shadow = clave[3]
		root.add_child(mmi)
		for mi in instancias:
			mi.queue_free()
	return grupos.size()

#copia la malla con los materiales sólidos opacos y de una cara y las hojas baratas (cacheado por malla)
static var _optimizadas := {}
static var _materiales := {}
static func _optimiza_materiales(mesh : Mesh) -> Mesh:
	if _optimizadas.has(mesh):
		return _optimizadas[mesh]
	var resultado = mesh
	for s in mesh.get_surface_count():
		var mat = mesh.surface_get_material(s)
		var opt = _material_solido(mat)
		if opt != mat:
			if resultado == mesh:
				resultado = mesh.duplicate()
			resultado.surface_set_material(s, opt)
	_optimizadas[mesh] = resultado
	return resultado

static func _material_solido(mat : Material) -> Material:
	if not mat is BaseMaterial3D:
		return mat
	var nombre = mat.resource_name.to_lower()
	var solido = Array(SOLIDOS).any(func(k): return nombre.contains(k))
	var hoja = Array(HOJAS).any(func(k): return nombre.contains(k))
	if not solido and not hoja:
		return mat
	if not _materiales.has(mat):
		var copia : BaseMaterial3D = mat.duplicate()
		if solido:
			copia.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			copia.cull_mode = BaseMaterial3D.CULL_BACK
		else:
			copia.disable_receive_shadows = true
			copia.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_materiales[mat] = copia
	return _materiales[mat]

#MultiMeshInstance3D no admite materiales por superficie: se copian a la malla
static func _malla_con_materiales(mesh : Mesh, materiales : Array) -> Mesh:
	if materiales.all(func(m): return m == null):
		return mesh
	var copia : Mesh = mesh.duplicate()
	for s in materiales.size():
		if materiales[s] != null:
			copia.surface_set_material(s, materiales[s])
	return copia
