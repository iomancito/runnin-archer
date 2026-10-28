# Copia modelos animados de otro proyecto (YoelGame) a este, recortados para el móvil:
#  - solo las animaciones que usa el juego (el resto engorda el APK);
#  - texturas como mucho de TEX_MAX px de lado;
#  - escala para que el modelo mida "alto" m en reposo (con los pies en el suelo).
# El origen no se modifica: se lee y se exporta un glb nuevo dentro de este proyecto.
#
# Uso:
#   blender -b --python tools/importar_modelos.py -- [modelo ...]     (sin nombres: todos)

import bpy, sys, os
from mathutils import Vector

ORIGEN = "/home/ioman/Proyectos/Godot/YoelGame/assets/enemies"
PROYECTO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEX_MAX = 1024

#nombre: (glb de origen, carpeta de destino, alto en m, animaciones que se conservan)
#El dragón rojo ya no sale de aquí: lo monta tools/dragon_rojo.py con otro modelo.
MODELOS = {
	"fire_whelp": ("fire_whelp/fire_whelp.glb", "scenes/enemies/map1/fire_whelp", 1.3,
		["idle", "walk", "spit"]),
	"zombie_bloater": ("zombie/zombie_bloater.glb", "scenes/enemies/map2/bloater", 2.6,
		["walk", "scream"]),
	"skeleton_dragon": ("skeleton_dragon/skeleton_dragon.glb", "scenes/enemies/map3/skeleton_dragon", 6.5,
		["idle", "breath", "rear_breath", "roar", "death"]),
	"skeleton_rogue": ("skeleton/skeleton_rogue.glb", "scenes/enemies/map3/skeleton_rogue", 1.8,
		["run"]),
	"skeleton_mage": ("skeleton/skeleton_mage.glb", "scenes/enemies/map3/skeleton_mage", 1.9,
		["idle", "bolt"]),
	"iron_scythe": ("iron_scythe/iron_scythe.glb", "scenes/enemies/map3/iron_scythe", 2.2,
		["walk"]),
	"death_knight": ("death_knight/death_knight.glb", "scenes/enemies/map3/death_knight", 2.4,
		["idle", "roar"]),
}


def log(*a):
	print("IMPORTAR", *a, flush=True)


def procesa(nombre):
	src, carpeta, alto, anims = MODELOS[nombre]
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=os.path.join(ORIGEN, src))
	for a in list(bpy.data.actions):
		if a.name not in anims:
			bpy.data.actions.remove(a)
	faltan = [n for n in anims if n not in bpy.data.actions]
	if faltan:
		raise RuntimeError("%s: faltan animaciones %s" % (nombre, faltan))
	for o in bpy.data.objects:
		if o.animation_data:
			o.animation_data.action = None
	#alto en reposo: escala la raíz (los nodos sin padre)
	bpy.context.view_layer.update()
	mallas = [o for o in bpy.data.objects if o.type == 'MESH']
	zs = [(o.matrix_world @ Vector(c)).z for o in mallas for c in o.bound_box]
	factor = alto / (max(zs) - min(zs))
	for o in bpy.data.objects:
		if o.parent is None:
			o.scale *= factor
			o.location *= factor
	for img in bpy.data.images:
		w, h = img.size
		if max(w, h) > TEX_MAX:
			k = TEX_MAX / max(w, h)
			img.scale(max(1, int(w * k)), max(1, int(h * k)))
			img.pack()
	destino = os.path.join(PROYECTO, carpeta)
	os.makedirs(destino, exist_ok=True)
	salida = os.path.join(destino, nombre + ".glb")
	bpy.ops.export_scene.gltf(filepath=salida, export_format='GLB', export_animation_mode='ACTIONS',
		export_force_sampling=True, export_frame_step=2, export_optimize_animation_size=True,
		export_image_format='AUTO', export_apply=False)
	log(nombre, "escala %.3f" % factor, "anims", anims, "%.1f MB" % (os.path.getsize(salida) / 1e6))


argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
for n in (argv or list(MODELOS)):
	procesa(n)
