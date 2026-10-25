# Simplifica las copas de árboles y arbustos del Stylized Nature MegaKit (Quaternius, CC0)
# para la GPU del móvil: las hojas son cientos de tarjetas con recorte alfa que se pintan
# unas encima de otras (CommonTree_1: 960 tarjetas, 1029 m² en un árbol de 4 m de ancho).
#
# Por cada modelo:
#  - agrupa las tarjetas de hojas (k-means) y crea por grupo un volumen opaco (envolvente
#    convexa encogida y simplificada) del color medio de las hojas: tapa todo lo de detrás;
#  - conserva solo las tarjetas exteriores, que dan el contorno frondoso;
#  - borra la corteza que queda oculta dentro del volumen.
# Exporta glTF que usan las texturas originales del proyecto (no las duplica).
#
# Uso:
#   blender -b --python tools/simplificar_copas.py -- /mnt/D2T/GodotRecursos/models3d/nature/glTF assets/naturaleza_simple [modelo ...]

import bpy, bmesh, sys, os, json
import numpy as np
from mathutils import Vector

#escala de la envolvente de los centros de las tarjetas respecto al centro del grupo
#(las tarjetas exteriores quedan medio fuera del volumen)
ESCALA_VOLUMEN = 0.95
#fracción de tarjetas que se conserva en cada grupo: las más alejadas del centro
FRACCION_EXTERIOR = 0.45
#tarjetas por grupo (define cuántos volúmenes tiene cada copa)
TARJETAS_POR_GRUPO = 140
#triángulos por volumen
TRIS_VOLUMEN = 80
#oscurece el volumen (es el interior de la copa)
OSCURECER = 0.75
#ruta de las texturas originales relativa a la carpeta de salida
TEXTURAS = "../externos/Nature/"

MODELOS = ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4",
	"Bush_Common", "Bush_Common_Flowers", "Pine_1", "Pine_2", "Pine_3"]

def es_hoja(nombre_mat):
	return nombre_mat.lower().startswith("lea")

def islas(bm, caras):
	resto = set(caras)
	grupos = []
	while resto:
		f = resto.pop()
		pila = [f]; isla = [f]
		while pila:
			g = pila.pop()
			for e in g.edges:
				for h in e.link_faces:
					if h in resto:
						resto.remove(h); pila.append(h); isla.append(h)
		grupos.append(isla)
	return grupos

def kmeans(puntos, k, iteraciones=30):
	rng = np.random.default_rng(1)
	centros = puntos[rng.choice(len(puntos), k, replace=False)]
	for _ in range(iteraciones):
		d = ((puntos[:, None, :] - centros[None, :, :]) ** 2).sum(-1)
		asignado = d.argmin(1)
		for i in range(k):
			if (asignado == i).any():
				centros[i] = puntos[asignado == i].mean(0)
	return asignado, centros

def color_medio(mat):
	#color medio (lineal) de los píxeles opacos de la textura base
	for n in mat.node_tree.nodes:
		if n.type == 'TEX_IMAGE' and n.image:
			p = np.array(n.image.pixels[:]).reshape(-1, 4)
			p = p[p[:, 3] > 0.5][:, :3]
			c = p.mean(0)
			return [float(x) for x in np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)]
	return [0.2, 0.4, 0.1]

def procesa(origen, salida, nombre):
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=os.path.join(origen, nombre + ".gltf"))
	obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
	ob = obs[0]
	me = ob.data
	mats = [m.name for m in me.materials]
	bm = bmesh.new(); bm.from_mesh(me)
	bm.faces.ensure_lookup_table()
	capa_color = bm.loops.layers.color.active or (bm.loops.layers.float_color.active if hasattr(bm.loops.layers, "float_color") else None)

	hojas = [f for f in bm.faces if es_hoja(mats[f.material_index])]
	tarjetas = islas(bm, hojas)
	centros_t = np.array([sum((f.calc_center_median() for f in t), Vector()) / len(t) for t in tarjetas])
	k = max(1, round(len(tarjetas) / TARJETAS_POR_GRUPO))
	asignado, centros = kmeans(centros_t, k)

	#color medio de vértice de las hojas (el material lo multiplica por la textura)
	col_vert = [1.0, 1.0, 1.0, 1.0]
	if capa_color:
		cs = np.array([list(l[capa_color]) for f in hojas for l in f.loops])
		col_vert = [float(x) for x in cs.mean(0)]

	borrar = []
	volumenes = []
	for g in range(k):
		ids = np.where(asignado == g)[0]
		if len(ids) == 0:
			continue
		c = Vector(centros[g])
		pts = [Vector(centros_t[i]) for i in ids]
		rs = [(p - c).length for p in pts]
		umbral = np.percentile(rs, 100 * (1 - FRACCION_EXTERIOR))
		for i, r in zip(ids, rs):
			if r < umbral:
				borrar.extend(tarjetas[i])
		if len(pts) >= 4:
			volumenes.append((c, pts))

	#envolventes: en un bmesh aparte, encogidas y simplificadas
	planos = []
	bm_vol = bmesh.new()
	for c, pts in volumenes:
		tmp = bmesh.new()
		vs = [tmp.verts.new(c + (p - c) * ESCALA_VOLUMEN) for p in pts]
		bmesh.ops.convex_hull(tmp, input=vs)
		for v in [v for v in tmp.verts if not v.link_faces]:
			tmp.verts.remove(v)
		malla = bpy.data.meshes.new("tmp"); tmp.to_mesh(malla); tmp.free()
		o = bpy.data.objects.new("tmp", malla); bpy.context.scene.collection.objects.link(o)
		mod = o.modifiers.new("dec", 'DECIMATE')
		mod.ratio = min(1.0, TRIS_VOLUMEN / max(1, len(malla.polygons)))
		dg = bpy.context.evaluated_depsgraph_get()
		ev = o.evaluated_get(dg).to_mesh()
		bm_vol.from_mesh(ev)
		o.evaluated_get(dg).to_mesh_clear()
		#planos de la envolvente para saber qué corteza queda dentro
		t2 = bmesh.new(); t2.from_mesh(malla)
		planos.append([(f.calc_center_median(), f.normal.copy()) for f in t2.faces]); t2.free()
		bpy.data.objects.remove(o)

	def dentro(p):
		return any(all((p - q).dot(n) < -0.05 for q, n in pl) for pl in planos)

	corteza = [f for f in bm.faces if not es_hoja(mats[f.material_index])]
	for f in corteza:
		if all(dentro(v.co) for v in f.verts):
			borrar.append(f)
	n_antes = len(bm.faces)
	bmesh.ops.delete(bm, geom=list(set(borrar)), context='FACES')

	#material del volumen
	hoja_mat = next(m for m in me.materials if es_hoja(m.name))
	base = color_medio(hoja_mat)
	vol_mat = bpy.data.materials.new("Copa_" + hoja_mat.name)
	vol_mat.use_nodes = True
	bsdf = vol_mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = [x * OSCURECER for x in base] + [1.0]
	bsdf.inputs["Roughness"].default_value = 1.0
	bsdf.inputs["Metallic"].default_value = 0.0
	me.materials.append(vol_mat)
	idx_vol = len(me.materials) - 1

	#juntar volúmenes al bmesh del modelo
	mv = bpy.data.meshes.new("vol"); bm_vol.to_mesh(mv); bm_vol.free()
	for p in mv.polygons:
		p.use_smooth = True
	bm.from_mesh(mv)
	bm.faces.ensure_lookup_table()
	#las caras recién añadidas son las últimas
	total_vol = len(mv.polygons)
	for f in bm.faces[len(bm.faces) - total_vol:]:
		f.material_index = idx_vol
		f.smooth = True
		if capa_color:
			for l in f.loops:
				l[capa_color] = col_vert
	n_despues = len(bm.faces)
	bm.to_mesh(me); bm.free()
	me.update()

	tris_hojas = sum(len(p.vertices) - 2 for p in me.polygons if es_hoja(me.materials[p.material_index].name))
	print("COPA %s: grupos=%d tarjetas %d -> %d, caras %d -> %d, color=%s" % (
		nombre, k, len(tarjetas), tris_hojas // 2, n_antes, n_despues, [round(x, 3) for x in base]))

	ruta = os.path.join(salida, nombre + ".gltf")
	bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLTF_SEPARATE', export_keep_originals=True,
		export_yup=True, export_apply=True)
	#las texturas apuntan a las originales del proyecto
	d = json.load(open(ruta))
	for im in d.get("images", []):
		im["uri"] = TEXTURAS + os.path.basename(im["uri"])
	json.dump(d, open(ruta, "w"), indent=1)

argv = sys.argv[sys.argv.index("--") + 1:]
origen, salida = argv[0], argv[1]
os.makedirs(salida, exist_ok=True)
for nombre in (argv[2:] or MODELOS):
	procesa(origen, salida, nombre)
