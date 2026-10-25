# Monta scenes/enemies/map2/black_dragon/black_dragon.glb a partir del dragón negro de 3DHaupt
# (Dragon_Baked_Actions.blend). El original no se modifica.
#  - Deja solo el esqueleto y la malla; las texturas del .blend se perdieron: se vuelven a poner
#    (color y normales con el UV "UV_NO_mirror", reducidas a TEX_MAX px) y los ojos pasan a emisivos.
#  - Conserva el reposo (Idel_New → "idle") y crea los ataques, que el original no trae, girando
#    huesos sobre la pose de reposo: "spit" (escupe una bola), "breath" (barrera de fuego) y "death".
#    Ejes medidos con renders: X+ en el cuello levanta la cabeza, en "breast" alza el tronco y en
#    "Bone" (mandíbula) abre la boca; Z gira el cuello a un lado.
#  - Escala a ALTO m y mira a -Y (en Godot, +Z).
#
# Uso:
#   blender -b --python tools/dragon_negro.py [-- --render DIR]   (con --render, fotogramas en vez de exportar)

import bpy, sys, os, math
from mathutils import Vector, Matrix

ORIGEN = "/mnt/D300/revisar/desktop2026/Assets3D/dragones/black_dragon"
PROYECTO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SALIDA = PROYECTO + "/scenes/enemies/map2/black_dragon/black_dragon.glb"
TEX_MAX = 1024
ALTO = 5.0
FPS = 24
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

CUELLO = ["ACT_neck_4", "ACT_neck_3", "ACT_neck_2", "ACT_neck_1"]

#cada animación: duración (s) y poses clave [tiempo, {hueso: (eje, grados)}]; entre claves, curva suave.
#Los giros de la lista CUELLO se reparten igual entre sus cuatro huesos (clave "cuello").
ANIMS = {
	#se echa atrás, lanza la cabeza y abre la boca a los 0,55 s (Boss lanza la bola entonces)
	"spit": (1.3, [
		[0.0, {}],
		[0.4, {"breast": ("X", 10), "cuello": ("X", 40), "Bone": ("X", 5)}],
		[0.55, {"breast": ("X", -6), "cuello": ("X", -30), "Bone": ("X", 34)}],
		[0.85, {"breast": ("X", -4), "cuello": ("X", -22), "Bone": ("X", 30)}],
		[1.3, {}],
	]),
	#se alza más, baja la cabeza con la boca abierta a los 0,85 s y barre de lado a lado
	"breath": (2.6, [
		[0.0, {}],
		[0.65, {"breast": ("X", 16), "cuello": ("X", 50), "Bone": ("X", 8)}],
		[0.85, {"breast": ("X", -6), "cuello": ("X", -26), "Bone": ("X", 38)}],
		[1.3, {"breast": ("X", -6), "cuello": [("X", -24), ("Z", 22)], "Bone": ("X", 38)}],
		[1.9, {"breast": ("X", -6), "cuello": [("X", -24), ("Z", -22)], "Bone": ("X", 38)}],
		[2.2, {"breast": ("X", -4), "cuello": ("X", -12), "Bone": ("X", 16)}],
		[2.6, {}],
	]),
	#se desploma hacia delante
	"death": (2.0, [
		[0.0, {}],
		[0.4, {"breast": ("X", 14), "cuello": ("X", 40), "Bone": ("X", 30)}],
		[1.4, {"breast": ("X", -30), "cuello": ("X", -50), "Bone": ("X", 20)}],
		[2.0, {"breast": ("X", -32), "cuello": ("X", -56), "Bone": ("X", 14)}],
	]),
}


def log(*a):
	print("DRAGON", *a, flush=True)


bpy.ops.wm.open_mainfile(filepath=ORIGEN + "/Dragon_Baked_Actions.blend")
sc = bpy.context.scene
sc.render.fps = FPS
rig = bpy.data.objects["Armature"]
malla = bpy.data.objects["Dragon_Mesh"]
for o in list(bpy.data.objects):
	if o not in (rig, malla):
		bpy.data.objects.remove(o)

#--- materiales ---
def imagen(nombre, color):
	img = bpy.data.images.load(ORIGEN + "/textures/" + nombre)
	if not color:
		img.colorspace_settings.name = "Non-Color"
	w, h = img.size
	if max(w, h) > TEX_MAX:
		img.scale(TEX_MAX, TEX_MAX)
	img.pack()
	return img

col = imagen("Dragon_ground_color.jpg", True)
nor = imagen("Dragon_Nor.jpg", False)

def material_piel(nombre):
	m = bpy.data.materials.new(nombre)
	m.use_nodes = True
	nt = m.node_tree
	bsdf = nt.nodes["Principled BSDF"]
	bsdf.inputs["Roughness"].default_value = 0.6
	t = nt.nodes.new("ShaderNodeTexImage"); t.image = col
	n = nt.nodes.new("ShaderNodeTexImage"); n.image = nor
	nm = nt.nodes.new("ShaderNodeNormalMap")
	nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
	nt.links.new(n.outputs["Color"], nm.inputs["Color"])
	nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
	return m

def material_ojos():
	m = bpy.data.materials.new("ojos")
	m.use_nodes = True
	bsdf = m.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (0.9, 0.25, 0.05, 1)
	bsdf.inputs["Emission Color"].default_value = (1.0, 0.35, 0.05, 1)
	bsdf.inputs["Emission Strength"].default_value = 2.0
	return m

piel = material_piel("piel")
ojos = material_ojos()
me = malla.data
nuevos = []
for i, m in enumerate(me.materials):
	nuevos.append(ojos if m and m.name.startswith("EYES") else piel)
#una sola ranura por material distinto
unicos = list(dict.fromkeys(nuevos))
indice = [unicos.index(m) for m in nuevos]
for p in me.polygons:
	p.material_index = indice[p.material_index]
me.materials.clear()
for m in unicos:
	me.materials.append(m)
#solo el UV de las texturas que se usan
for uv in list(me.uv_layers):
	if uv.name != "UV_NO_mirror":
		me.uv_layers.remove(uv)

#--- animaciones ---
idle = bpy.data.actions["Idel_New"]
for a in list(bpy.data.actions):
	if a != idle:
		bpy.data.actions.remove(a)
idle.name = "idle"
rig.animation_data.action = idle
sc.frame_set(int(idle.frame_range[0]))
base = {pb.name: pb.matrix_basis.copy() for pb in rig.pose.bones}

def suave(x):
	return x * x * (3.0 - 2.0 * x)

def giros(pose):
	#{hueso: [(eje, grados)]} con "cuello" repartido
	r = {}
	for k, v in pose.items():
		lista = v if isinstance(v, list) else [v]
		if k == "cuello":
			for h in CUELLO:
				r.setdefault(h, []).extend([(e, g / len(CUELLO)) for e, g in lista])
		else:
			r.setdefault(k, []).extend(lista)
	return r

def angulo(claves, hueso, eje, t):
	for i in range(len(claves) - 1):
		t0, p0 = claves[i]
		t1, p1 = claves[i + 1]
		if t0 <= t <= t1:
			a0 = sum(g for e, g in giros(p0).get(hueso, []) if e == eje)
			a1 = sum(g for e, g in giros(p1).get(hueso, []) if e == eje)
			return a0 + (a1 - a0) * suave((t - t0) / max(t1 - t0, 1e-6))
	return 0.0

for nombre, (dur, claves) in ANIMS.items():
	act = bpy.data.actions.new(nombre)
	rig.animation_data.action = act
	huesos = set()
	for _, p in claves:
		huesos |= set(giros(p))
	frames = int(round(dur * FPS))
	for f in range(frames + 1):
		t = f / FPS
		for pb in rig.pose.bones:
			pb.matrix_basis = base[pb.name]
		for h in huesos:
			pb = rig.pose.bones[h]
			m = pb.matrix_basis
			for eje in ("X", "Y", "Z"):
				g = angulo(claves, h, eje, t)
				if g != 0.0:
					m = m @ Matrix.Rotation(math.radians(g), 4, eje)
			pb.matrix_basis = m
		for pb in rig.pose.bones:
			pb.keyframe_insert("rotation_quaternion", frame=f)
			pb.keyframe_insert("location", frame=f)
	log("anim", nombre, "%.2f s" % dur)

#--- escala ---
rig.animation_data.action = idle
sc.frame_set(int(idle.frame_range[0]))
bpy.context.view_layer.update()
zs = [(malla.matrix_world @ Vector(c)).z for c in malla.bound_box]
factor = ALTO / (max(zs) - min(zs))
rig.scale *= factor
rig.location *= factor
log("escala", factor)

if "--render" in ARGS:
	carpeta = ARGS[ARGS.index("--render") + 1]
	os.makedirs(carpeta, exist_ok=True)
	sc.render.engine = 'BLENDER_WORKBENCH'
	sc.display.shading.color_type = 'TEXTURE'
	sc.render.resolution_x = 320; sc.render.resolution_y = 240; sc.render.resolution_percentage = 100
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
	cam.data.clip_end = 500
	centro = Vector((0, -1.0, ALTO * 0.5))
	cam.location = centro + Vector((ALTO * 2.6, -ALTO * 1.2, ALTO * 0.3))
	cam.rotation_euler = (centro - cam.location).to_track_quat('-Z', 'Y').to_euler()
	for i, nombre in enumerate(ANIMS):
		rig.animation_data.action = bpy.data.actions[nombre]
		frames = int(round(ANIMS[nombre][0] * FPS))
		for k in range(6):
			sc.frame_set(int(frames * k / 5))
			sc.render.filepath = "%s/bd_%02d_%d.png" % (carpeta, i, k)
			bpy.ops.render.render(write_still=True)
else:
	os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
	bpy.ops.object.select_all(action='DESELECT')
	rig.select_set(True); malla.select_set(True)
	bpy.ops.export_scene.gltf(filepath=SALIDA, export_format='GLB', use_selection=True,
		export_animation_mode='ACTIONS', export_force_sampling=True, export_frame_step=2,
		export_optimize_animation_size=True, export_image_format='JPEG')
	log("exportado", SALIDA, "%.1f MB" % (os.path.getsize(SALIDA) / 1e6))
