"""Prepara los arcos del "3D Fantasy Bows Pack" (CC0) y la flecha de KayKit Skeletons (CC0).

Para cada arco: lo orienta y escala igual que el arco al que sustituye (eje largo, lado de la
cuerda y tamaño), renderiza la imagen de la tienda con el modelo completo y exporta una versión
ligera para el móvil (malla reducida y texturas pequeñas).

Uso (Blender 5):
  blender -b --python tools/preparar_armas.py -- <carpeta con los .glb del pack> <carpeta de renders> <Skeleton_Arrow.gltf>

<carpeta de renders>/viejos/ debe tener los arcoN.glb y arrow.glb anteriores (de git), que sirven de
referencia de orientación y tamaño. Escribe assets/weapons/arcoN.glb y assets/weapons/arrow.glb. Los renders salen sin contorno: el contorno dorado lo añade
ImageMagick (ver docs/arcos.md).
"""
import bpy, sys, os, math, mathutils, numpy

PROYECTO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#arco del juego -> (modelo del pack, imagen de la tienda o None)
ARCOS = {
	"arco1": ("06_Ranger_s_Yew_Longbow.glb", None),
	"arco2": ("18_Paladin_s_Sun_Bow.glb", "sunfire"),
	"arco3": ("19_Thorn_Bramble_Bow.glb", "thorn"),
	"arco4": ("07_Dragon-Rib_Greatbow.glb", "dragon"),
	"arco5": ("10_Frost_Ice_Bow.glb", "storm"),
}
TRIANGULOS = 4000
TEX_COLOR = 512
TEX_RESTO = 256
RENDER = 512
#grados que se inclina el arco en la imagen de la tienda
INCLINACION = -25
#grosor de la flecha respecto a escalarla igual en todos los ejes
GROSOR_FLECHA = 0.6

def limpiar():
	bpy.ops.wm.read_factory_settings(use_empty=True)

def importar(ruta):
	bpy.ops.import_scene.gltf(filepath=ruta)
	mallas = [o for o in bpy.context.scene.objects if o.type == 'MESH']
	bpy.ops.object.select_all(action='DESELECT')
	for o in mallas:
		o.select_set(True)
	bpy.context.view_layer.objects.active = mallas[0]
	if len(mallas) > 1:
		bpy.ops.object.join()
	obj = bpy.context.view_layer.objects.active
	#sin padres ni transformaciones: los vértices quedan en coordenadas del mundo
	bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	for o in list(bpy.context.scene.objects):
		if o != obj:
			bpy.data.objects.remove(o)
	return obj

def analizar(obj):
	"""Marco del arco: eje de punta a punta (L), grosor (T) y curvatura (C, hacia la empuñadura).

	Los modelos del pack vienen en diagonal dentro de su caja, así que el eje no es X, Y ni Z.
	Devuelve (matriz 3x3 con filas C, T, L; largo de punta a punta; posición de la empuñadura)."""
	P = numpy.array([v.co[:] for v in obj.data.vertices])
	centro = P.mean(axis=0)
	#puntas: el vértice más lejano del centro y el más lejano de ese
	p1 = P[numpy.argmax(((P - centro) ** 2).sum(axis=1))]
	p2 = P[numpy.argmax(((P - p1) ** 2).sum(axis=1))]
	L = (p2 - p1) / numpy.linalg.norm(p2 - p1)
	#grosor: la dirección de menor varianza, perpendicular al eje
	_, vecs = numpy.linalg.eigh(numpy.cov((P - centro).T))
	T = vecs[:, 0] - L * vecs[:, 0].dot(L)
	T /= numpy.linalg.norm(T)
	C = numpy.cross(T, L)
	medio = (p1 + p2) / 2
	largo = numpy.linalg.norm(p2 - p1)
	cerca = P[numpy.abs((P - medio) @ L) < 0.05 * largo]
	#en el corte central, la cuerda y la empuñadura son dos grupos separados por un hueco:
	#la cuerda es el de menos vértices. Si no hay hueco (la cuerda es una línea sin vértices en
	#el centro, como en los arcos viejos), las palas y la empuñadura quedan del lado de la media.
	#No basta con la media siempre: con las puntas muy curvadas hacia delante sale al revés.
	c = numpy.sort((cerca - medio) @ C)
	huecos = numpy.diff(c)
	i = huecos.argmax()
	if huecos[i] > 0.03 * largo:
		cuerda_detras = i + 1 < len(c) - i - 1
		if not cuerda_detras:
			C, T = -C, -T
	elif ((P - medio) @ C).mean() < 0:
		C, T = -C, -T
	empuñadura = cerca[numpy.argmax((cerca - medio) @ C)]
	return numpy.array([C, T, L]), largo, empuñadura

def preparar(nombre, origen, viejo):
	#referencia: el arco viejo
	limpiar()
	ref = importar(viejo)
	r_marco, r_largo, r_empuñadura = analizar(ref)
	limpiar()
	obj = importar(origen)
	marco, largo, empuñadura = analizar(obj)
	#R lleva el marco del nuevo al del viejo: R = r_marco^T @ marco
	R = r_marco.T @ marco
	if numpy.linalg.det(R) < 0:
		raise RuntimeError("marco con reflexión")
	escala = r_largo / largo
	M = mathutils.Matrix([list(f) for f in (R * escala)]).to_4x4()
	obj.data.transform(M)
	destino = mathutils.Vector(r_empuñadura) - M @ mathutils.Vector(empuñadura)
	obj.data.transform(mathutils.Matrix.Translation(destino))
	obj.data.update()
	return obj

def render(obj, salida):
	"""Arco en diagonal con la cuerda a la derecha, fondo transparente."""
	escena = bpy.context.scene
	escena.render.engine = 'BLENDER_WORKBENCH'
	escena.display.shading.light = 'STUDIO'
	escena.display.shading.color_type = 'TEXTURE'
	escena.render.film_transparent = True
	escena.render.resolution_x = RENDER
	escena.render.resolution_y = RENDER
	escena.view_settings.view_transform = 'Standard'
	#empuñadura a la izquierda (-X), eje de punta a punta en Z y luego inclinado
	marco, _, _ = analizar(obj)
	ejes = numpy.array([[-1, 0, 0], [0, -1, 0], [0, 0, 1]])
	R = mathutils.Matrix([list(f) for f in ejes.T @ marco]).to_4x4()
	obj.matrix_world = mathutils.Matrix.Rotation(math.radians(INCLINACION), 4, 'Y') @ R
	bpy.context.view_layer.update()
	vs = [obj.matrix_world @ v.co for v in obj.data.vertices]
	cx = (max(v.x for v in vs) + min(v.x for v in vs)) / 2
	cz = (max(v.z for v in vs) + min(v.z for v in vs)) / 2
	tam = max(max(v.x for v in vs) - min(v.x for v in vs), max(v.z for v in vs) - min(v.z for v in vs))
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	escena.collection.objects.link(cam)
	cam.data.type = 'ORTHO'
	cam.data.ortho_scale = tam * 1.12
	cam.location = (cx, -20, cz)
	cam.rotation_euler = (math.pi / 2, 0, 0)
	escena.camera = cam
	escena.render.filepath = salida
	bpy.ops.render.render(write_still=True)
	bpy.data.objects.remove(cam)
	obj.matrix_world = mathutils.Matrix.Identity(4)

def aligerar(obj):
	tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
	if tris > TRIANGULOS:
		mod = obj.modifiers.new("reducir", 'DECIMATE')
		mod.ratio = TRIANGULOS / tris
		bpy.context.view_layer.objects.active = obj
		bpy.ops.object.modifier_apply(modifier=mod.name)
	for img in bpy.data.images:
		if img.size[0] == 0:
			continue
		lado = TEX_COLOR if es_color(img) else TEX_RESTO
		if img.size[0] > lado:
			img.scale(lado, lado)
			img.pack()

def es_color(img):
	for m in bpy.data.materials:
		if not m.use_nodes:
			continue
		for n in m.node_tree.nodes:
			if n.type == 'BSDF_PRINCIPLED':
				for l in n.inputs['Base Color'].links:
					if getattr(l.from_node, "image", None) == img:
						return True
	return False

def flecha(origen, vieja):
	"""Flecha de KayKit con el largo y la orientación de la vieja (punta hacia -Y en Blender)."""
	limpiar()
	ref = importar(vieja)
	ys = [v.co.y for v in ref.data.vertices]
	limpiar()
	obj = importar(origen)
	#en KayKit la punta está en -Z: Z pasa a Y
	obj.data.transform(mathutils.Matrix.Rotation(math.radians(-90), 4, 'X'))
	zs = [v.co.y for v in obj.data.vertices]
	escala = (max(ys) - min(ys)) / (max(zs) - min(zs))
	#un poco más fina que a escala uniforme
	obj.data.transform(mathutils.Matrix.Diagonal((escala * GROSOR_FLECHA, escala, escala * GROSOR_FLECHA, 1)))
	zs = [v.co.y for v in obj.data.vertices]
	obj.data.transform(mathutils.Matrix.Translation((0, min(ys) - min(zs), 0)))
	#arrow.tscn retoca este nodo
	obj.name = "Arrow_Cube_020"
	bpy.ops.export_scene.gltf(filepath=os.path.join(PROYECTO, "assets", "weapons", "arrow.glb"),
		export_format='GLB', export_image_format='AUTO', export_animations=False)

def main():
	args = sys.argv[sys.argv.index("--") + 1:]
	pack, renders, flecha_kaykit = args[0], args[1], args[2]
	os.makedirs(renders, exist_ok=True)
	for nombre, (archivo, imagen) in ARCOS.items():
		destino = os.path.join(PROYECTO, "assets", "weapons", nombre + ".glb")
		#la referencia es el arco viejo (git: assets/weapons/arcoN.glb antes del cambio)
		viejo = os.path.join(renders, "viejos", nombre + ".glb")
		obj = preparar(nombre, os.path.join(pack, archivo), viejo)
		if imagen:
			render(obj, os.path.join(renders, imagen + ".png"))
		aligerar(obj)
		bpy.ops.export_scene.gltf(filepath=destino, export_format='GLB', use_selection=False,
			export_image_format='AUTO', export_animations=False)
		print("ARCO", nombre, "<-", archivo, "tris", sum(len(p.vertices) - 2 for p in obj.data.polygons))
	flecha(flecha_kaykit, os.path.join(renders, "viejos", "arrow.glb"))
	print("FLECHA lista")

main()
