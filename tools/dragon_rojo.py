# Monta scenes/enemies/map1/red_dragon/red_dragon.glb a partir de "Red Dragon 3D" de soufiane oujihi
# (CC BY 4.0, /mnt/D2T/GodotRecursos/models3d/red_dragon). El original no se modifica.
#  - El modelo es estático (sin esqueleto): se unen sus 5 mallas, se fusionan los vértices (vienen
#    sueltos por triángulo), se reduce a TRIANGULOS y se dejan color y normales a TEX_MAX px.
#  - Se le crea un esqueleto (HUESOS, en puntos medidos del modelo: columna, cuello, cabeza, mandíbula,
#    cola, alas con dedos, patas y brazos). Pesos por distancia a los huesos: cada vértice va al ala o al
#    cuerpo según su hueso más cercano y la mandíbula inferior entera a "mandibula".
#  - Las animaciones son las del dragón rojo anterior (build_red_dragon.py de YoelGame, hechas a mano por
#    código) adaptadas a este esqueleto: cada pose es una lista de giros por hueso en el marco del dragón
#    (delante F, izquierda L, arriba U), en grados: "p" baja el morro (gira sobre L), "y" gira a la
#    izquierda (sobre U), "r" alabea a la derecha (sobre F). En los huesos del lado derecho "y" y "r" se
#    reflejan, así una pose vale para los dos lados. Las patas traseras llevan IK hacia el suelo (el cuerpo
#    se mueve y los pies no resbalan) y se hornea.
#  - Escala a LARGO m de la cabeza a la cola y mira a -Y (en Godot, +Z). El dragón mira a -Y, así que su
#    izquierda es +X.
#
# Uso:
#   blender -b --python tools/dragon_rojo.py [-- --render DIR [--only ANIM] [--frames N] [--zoom Z]]
#   (con --render, fotogramas de frente y de lado en vez de exportar; --zoom acerca a la cabeza)

import bpy, sys, os, math
import numpy
from mathutils import Vector, Matrix, Quaternion

ORIGEN = "/mnt/D2T/GodotRecursos/models3d/red_dragon/red_dragon_3d.glb"
PROYECTO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SALIDA = PROYECTO + "/scenes/enemies/map1/red_dragon/red_dragon.glb"
TEX_MAX = 1024
TRIANGULOS = 30000
LARGO = 15.0
FPS = 30
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(nombre, defecto=None):
	return ARGS[ARGS.index(nombre) + 1] if nombre in ARGS else defecto


#huesos: nombre -> (padre, cabeza, cola) en coordenadas del modelo original (medidas con vistas de los
#vértices). Las alas y la cola son asimétricas porque el modelo viene posado así.
HUESOS = {
	"pelvis": (None, (0, 0.05, 0.062), (0, 0.02, 0.07)),
	"columna": ("pelvis", (0, 0.02, 0.07), (0, -0.01, 0.075)),
	"columna1": ("columna", (0, -0.01, 0.075), (0, -0.03, 0.08)),
	"cuello1": ("columna1", (0, -0.03, 0.08), (0.005, -0.05, 0.089)),
	"cuello2": ("cuello1", (0.005, -0.05, 0.089), (0.01, -0.066, 0.089)),
	"cuello3": ("cuello2", (0.01, -0.066, 0.089), (0.017, -0.082, 0.085)),
	"cabeza": ("cuello3", (0.017, -0.082, 0.085), (0.022, -0.12, 0.074)),
	"mandibula": ("cabeza", (0.019, -0.086, 0.074), (0.022, -0.11, 0.052)),
	"boca": ("cabeza", (0.022, -0.112, 0.065), (0.022, -0.125, 0.065)),
	"cola": ("pelvis", (0, 0.07, 0.056), (0, 0.11, 0.042)),
	"cola1": ("cola", (0, 0.11, 0.042), (-0.003, 0.15, 0.031)),
	"cola2": ("cola1", (-0.003, 0.15, 0.031), (0.003, 0.19, 0.023)),
	"cola3": ("cola2", (0.003, 0.19, 0.023), (0.025, 0.226, 0.02)),
	"cola4": ("cola3", (0.025, 0.226, 0.02), (0.056, 0.248, 0.03)),
	"cola5": ("cola4", (0.056, 0.248, 0.03), (0.077, 0.215, 0.07)),
	#alas: brazo (hombro -> muñeca con la garra), mano (borde de ataque) y punta; dos dedos de la membrana
	"ala.L1": ("columna1", (0.045, 0.0, 0.105), (0.1, -0.04, 0.195)),
	"ala.L2": ("ala.L1", (0.1, -0.04, 0.195), (0.2, -0.045, 0.19)),
	"ala.L3": ("ala.L2", (0.2, -0.045, 0.19), (0.33, 0.01, 0.155)),
	"dedo.L1": ("ala.L1", (0.1, -0.04, 0.195), (0.12, 0.1, 0.13)),
	"dedo.L2": ("ala.L1", (0.1, -0.04, 0.195), (0.27, 0.09, 0.15)),
	"ala.R1": ("columna1", (-0.04, 0.0, 0.105), (-0.09, -0.01, 0.21)),
	"ala.R2": ("ala.R1", (-0.09, -0.01, 0.21), (-0.19, 0.0, 0.15)),
	"ala.R3": ("ala.R2", (-0.19, 0.0, 0.15), (-0.225, 0.04, 0.04)),
	"dedo.R1": ("ala.R1", (-0.09, -0.01, 0.21), (-0.11, 0.12, 0.13)),
	"dedo.R2": ("ala.R1", (-0.09, -0.01, 0.21), (-0.21, 0.12, 0.09)),
	#patas traseras: muslo, pantorrilla, pie (hasta la punta de los dedos)
	"muslo.L": ("pelvis", (0.03, 0.045, 0.058), (0.04, 0.062, 0.03)),
	"pantorrilla.L": ("muslo.L", (0.04, 0.062, 0.03), (0.045, 0.056, 0.008)),
	"pie.L": ("pantorrilla.L", (0.045, 0.056, 0.008), (0.045, 0.032, 0.002)),
	"muslo.R": ("pelvis", (-0.025, 0.045, 0.058), (-0.03, 0.062, 0.03)),
	"pantorrilla.R": ("muslo.R", (-0.03, 0.062, 0.03), (-0.03, 0.056, 0.008)),
	"pie.R": ("pantorrilla.R", (-0.03, 0.056, 0.008), (-0.03, 0.032, 0.002)),
	#brazos delanteros (levantados, no pisan)
	"brazo.L": ("columna1", (0.02, -0.028, 0.066), (0.03, -0.045, 0.05)),
	"antebrazo.L": ("brazo.L", (0.03, -0.045, 0.05), (0.03, -0.06, 0.035)),
	"brazo.R": ("columna1", (-0.015, -0.028, 0.066), (-0.02, -0.06, 0.052)),
	"antebrazo.R": ("brazo.R", (-0.02, -0.06, 0.052), (-0.02, -0.078, 0.05)),
}
ALAS = [h for h in HUESOS if h.startswith(("ala", "dedo"))]
SIN_PESO = ("boca",)
NECK = ["cuello1", "cuello2", "cuello3"]
TAIL = ["cola", "cola1", "cola2", "cola3", "cola4", "cola5"]
PATAS = {"pie.L": 3, "pie.R": 3}
#mandíbula inferior: en la cabeza (y < MAND_Y) y por debajo de la recta que separa los labios (z, y)
MAND_Y = -0.085
MAND_RECTA = ((-0.12, 0.064), (-0.085, 0.074))


def log(*a):
	print("DRAGON", *a, flush=True)


#--- malla ---
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = FPS
bpy.ops.import_scene.gltf(filepath=ORIGEN)
mallas = [o for o in sc.objects if o.type == 'MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in mallas:
	o.select_set(True)
bpy.context.view_layer.objects.active = mallas[0]
bpy.ops.object.join()
malla = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in list(sc.objects):
	if o != malla:
		bpy.data.objects.remove(o)
malla.name = "dragon"

#escala: LARGO m de la punta del hocico al final de la cola; pies en z = 0
co = numpy.array([v.co[:] for v in malla.data.vertices])
factor = LARGO / (co[:, 1].max() - co[:, 1].min())
DESPLAZA = Vector((0, 0, -co[:, 2].min()))


def P(p):
	return (Vector(p) + DESPLAZA) * factor


malla.data.transform(Matrix.Translation(DESPLAZA))
malla.data.transform(Matrix.Scale(factor, 4))
log("escala", factor)

bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0001 * factor)
bpy.ops.object.mode_set(mode='OBJECT')
tris = sum(len(p.vertices) - 2 for p in malla.data.polygons)
if tris > TRIANGULOS:
	mod = malla.modifiers.new("reducir", 'DECIMATE')
	mod.ratio = TRIANGULOS / tris
	bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.shade_smooth()
log("triangulos", tris, "->", sum(len(p.vertices) - 2 for p in malla.data.polygons))

#materiales: solo color y normales, texturas reducidas. Los 5 UV del original son iguales: se deja
#el primero (Godot solo lee dos y el mapa de normales usaba el tercero)
uv0 = malla.data.uv_layers[0].name
for uv in list(malla.data.uv_layers)[1:]:
	malla.data.uv_layers.remove(uv)
for m in malla.data.materials:
	nt = m.node_tree
	bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
	if bsdf is None:
		continue
	for entrada in list(bsdf.inputs):
		if entrada.name in ("Base Color", "Normal"):
			continue
		for l in list(entrada.links):
			nt.links.remove(l)
	bsdf.inputs["Roughness"].default_value = 0.6
	bsdf.inputs["Metallic"].default_value = 0.0
	#fuera la oclusión (grupo "glTF Material Output"), los nodos UV y las texturas que no llegan al BSDF
	usados = set()

	def sube(n):
		usados.add(n)
		for e in n.inputs:
			for l in e.links:
				sube(l.from_node)
	sube(bsdf)
	for n in list(nt.nodes):
		if n.type == 'NORMAL_MAP':
			n.uv_map = uv0
		if n.type in ('UVMAP', 'GROUP') or (n.type == 'TEX_IMAGE' and n not in usados):
			nt.nodes.remove(n)
for img in bpy.data.images:
	if img.size[0] > TEX_MAX:
		img.scale(TEX_MAX, TEX_MAX)
		img.pack()

#--- esqueleto ---
arm = bpy.data.armatures.new("rig")
rig = bpy.data.objects.new("rig", arm)
sc.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for nombre, (padre, cab, cola) in HUESOS.items():
	b = arm.edit_bones.new(nombre)
	b.head = P(cab)
	b.tail = P(cola)
	if padre:
		b.parent = arm.edit_bones[padre]
		b.use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')

#--- pesos ---
def dist_segmento(V, a, b):
	ab = b - a
	t = numpy.clip(((V - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
	return numpy.linalg.norm(V - (a + t[:, None] * ab), axis=1)


V = numpy.array([v.co[:] for v in malla.data.vertices])
nombres = [n for n in HUESOS if n not in SIN_PESO]
D = numpy.stack([dist_segmento(V, numpy.array(P(HUESOS[n][1])), numpy.array(P(HUESOS[n][2]))) for n in nombres], axis=1)
de_ala = numpy.array([n in ALAS for n in nombres])
#cada vértice va al ala o al cuerpo según su hueso más cercano; el pecho (columna1) puede pesar en los dos
es_ala = de_ala[D.argmin(axis=1)]
puente = nombres.index("columna1")
valido = numpy.where(es_ala[:, None], de_ala[None, :], ~de_ala[None, :])
valido[:, puente] = True
#mandíbula inferior entera a su hueso
(y0, z0), (y1, z1) = MAND_RECTA
yo = V[:, 1] / factor
zo = V[:, 2] / factor - DESPLAZA.z
corte = z0 + (yo - y0) * (z1 - z0) / (y1 - y0)
es_mand = (yo < MAND_Y) & (zo < corte) & ~es_ala
D = numpy.where(valido, D, numpy.inf)
W = 1.0 / (D ** 4 + 1e-12)
W[~numpy.isfinite(D)] = 0
mand = nombres.index("mandibula")
W[es_mand] = 0
W[es_mand, mand] = 1
W[~es_mand & (V[:, 1] / factor < MAND_Y), mand] = 0
orden = numpy.argsort(-W, axis=1)[:, :4]
grupos = {n: malla.vertex_groups.new(name=n) for n in nombres}
for i in range(len(V)):
	idx = orden[i]
	w = W[i, idx]
	w = w / w.sum()
	for j, wj in zip(idx, w):
		if wj > 0.01:
			grupos[nombres[j]].add([i], float(wj), 'REPLACE')
malla.parent = rig
mod = malla.modifiers.new("rig", 'ARMATURE')
mod.object = rig
log("pesos", len(V), "vertices,", int(es_ala.sum()), "de alas,", int(es_mand.sum()), "de mandibula")

#--- marco del dragón: mira a -Y, arriba Z ---
F = Vector((0, -1, 0))
U = Vector((0, 0, 1))
L = U.cross(F).normalized()
AXIS = {"p": L, "y": U, "r": F}
#1 m del dragón anterior (las poses están en esas unidades) en metros de este: espalda a 0,9 m en
#aquel, a ESPALDA m en este
ESPALDA = 0.105 * factor
UNIT = ESPALDA / 0.9
#cuánto baja el cuerpo al morir (m del dragón anterior): la tripa queda en el suelo
DESPLOME = 0.22


def is_right(nombre):
	return nombre.endswith(".R") or ".R" in nombre


def quat(nombre, rots):
	q = Quaternion()
	for eje, g in rots:
		if is_right(nombre) and eje in "yr":
			g = -g
		q = Quaternion(AXIS[eje], math.radians(g)) @ q
	return q


def ease(x):
	x = min(1.0, max(0.0, x))
	return x * x * (3 - 2 * x)


def ramp(t, a, b):
	"""0 antes de a, 1 después de b, suave en medio."""
	return ease((t - a) / (b - a)) if b > a else float(t >= a)


def bump(t, a, b, c, d):
	"""Sube entre a y b, se mantiene, baja entre c y d."""
	return ramp(t, a, b) * (1.0 - ramp(t, c, d))


class Pose:
	def __init__(self):
		self.rot = {}
		self.root = Vector()  # desplazamiento del cuerpo (F, L, U) en m del dragón anterior
		self.root_rot = []
		self.targets = {}  # pie -> desplazamiento (F, L, U)

	def add(self, hueso, eje, g):
		if abs(g) > 1e-4:
			self.rot.setdefault(hueso, []).append((eje, g))

	def both(self, hueso, eje, g):
		self.add(hueso.replace("#", "L"), eje, g)
		self.add(hueso.replace("#", "R"), eje, g)

	def spread(self, huesos, eje, g):
		for h in huesos:
			self.add(h, eje, g / len(huesos))


def wings(p, alzar=0.0, flap=0.0, plegar=0.0):
	"""Alas abiertas como en el reposo del modelo. alzar sube las alas enteras desde el hombro, flap sube (+)
	o baja (-) las puntas (aleteo) y plegar (0-1) recoge los dedos y la mano hacia atrás."""
	p.both("ala.#1", "r", alzar + flap * 0.4)
	p.both("ala.#2", "r", flap * 0.6)
	p.both("ala.#3", "r", flap * 0.5)
	p.both("dedo.#1", "r", flap * 0.3)
	p.both("dedo.#2", "r", flap * 0.4)
	p.both("ala.#1", "y", 25 * plegar)
	p.both("ala.#2", "y", 40 * plegar)
	p.both("dedo.#2", "y", 30 * plegar)


def tail_wave(p, t, amp=7.0, cycles=1.0, lift=0.0):
	for i, s in enumerate(TAIL):
		k = (i + 1) / len(TAIL)
		p.add(s, "y", amp * k * math.sin(2 * math.pi * (cycles * t) - i * 0.6))
		p.add(s, "p", lift * k)  # + sube la cola (apunta hacia atrás)


def breathing(p, t, cycles=1.0, depth=1.0):
	s = math.sin(2 * math.pi * cycles * t)
	p.add("columna", "p", -1.5 * s * depth)
	p.add("columna1", "p", -1.5 * s * depth)
	p.root += Vector((0, 0, 0.012 * s * depth))


#la boca del modelo viene muy abierta: en reposo se cierra MAND_CERRADA grados y los ataques la abren
MAND_CERRADA = -12


def jaw(p, abre):
	"""abre en grados sobre la boca casi cerrada del reposo (p baja la mandíbula)."""
	p.add("mandibula", "p", MAND_CERRADA + abre)


def arms(p, t, amp=1.0):
	"""Los brazos delanteros acompañan un poco el movimiento."""
	s = math.sin(2 * math.pi * t + 0.5)
	p.both("brazo.#", "p", 4 * s * amp)
	p.both("antebrazo.#", "p", 6 * s * amp)


#--- animaciones: nombre -> (fotogramas, bucle, pose(t) con t en [0, 1]) ---
def idle(t):
	p = Pose()
	breathing(p, t)
	wings(p, flap=4.0 * math.sin(2 * math.pi * t))
	tail_wave(p, t)
	arms(p, t)
	sway = math.sin(2 * math.pi * t)
	p.spread(NECK, "y", 8 * sway)
	p.spread(NECK, "p", 3 * math.sin(2 * math.pi * t + 1.0))
	p.add("cabeza", "y", 4 * sway)
	jaw(p, 3 + 3 * math.sin(2 * math.pi * t))
	return p


def bite(t):
	p = Pose()
	wind = bump(t, 0.0, 0.32, 0.34, 0.46)   # se echa atrás
	strike = bump(t, 0.34, 0.46, 0.6, 0.95)  # muerde
	boca = bump(t, 0.1, 0.32, 0.4, 0.47)     # abre del todo y cierra de golpe al morder
	breathing(p, t, depth=0.5)
	wings(p, alzar=12 * wind, flap=8 * wind - 6 * strike)
	tail_wave(p, t, amp=5 + 6 * strike, lift=6 * wind)
	arms(p, t, 1 + 2 * strike)
	p.spread(NECK, "p", -30 * wind + 40 * strike)
	p.add("cabeza", "p", -12 * wind + 10 * strike)
	jaw(p, 26 * boca + 8 * strike)
	p.add("columna1", "p", -6 * wind + 6 * strike)
	p.root += Vector((-0.07 * wind + 0.22 * strike, 0, 0.04 * wind - 0.06 * strike))
	p.root_rot.append(("p", -5 * wind + 6 * strike))
	return p


def breath(t):
	p = Pose()
	inhale = bump(t, 0.0, 0.28, 0.3, 0.4)
	blow = bump(t, 0.3, 0.4, 0.82, 0.97)
	boca = bump(t, 0.32, 0.4, 0.82, 0.92)
	sweep = math.sin(math.pi * (ramp(t, 0.4, 0.82) - 0.5))  # -1 -> 1
	breathing(p, t, cycles=1.0, depth=0.4)
	wings(p, alzar=14 * inhale + 6 * blow, flap=12 * inhale)
	tail_wave(p, t, amp=4 + 4 * blow, lift=10 * inhale)
	arms(p, t, 1 + inhale)
	p.spread(NECK, "p", -40 * inhale + 22 * blow)
	p.add("columna", "p", 3 * inhale)  # pecho hinchado
	p.add("columna1", "p", -6 * inhale)
	p.add("cabeza", "p", -10 * inhale + 8 * blow)
	p.spread(NECK, "y", 34 * sweep * blow)
	p.add("columna1", "y", 8 * sweep * blow)
	p.add("cabeza", "y", 6 * sweep * blow)
	jaw(p, 26 * boca)
	p.root += Vector((-0.08 * inhale + 0.05 * blow, 0, 0.06 * inhale - 0.03 * blow))
	p.root_rot.append(("p", -10 * inhale + 4 * blow))
	return p


def roar(t):
	"""Se alza, abre más las alas y ruge sacudiendo la cabeza."""
	p = Pose()
	up = bump(t, 0.0, 0.3, 0.8, 1.0)
	shout = bump(t, 0.28, 0.38, 0.72, 0.85)
	breathing(p, t, depth=0.5)
	wings(p, alzar=18 * up, flap=10 * up * math.sin(2 * math.pi * 2 * t))
	tail_wave(p, t, amp=8, lift=12 * up)
	arms(p, 2 * t, 1 + 2 * up)
	p.root += Vector((-0.08 * up, 0, 0.16 * up))
	p.root_rot.append(("p", -16 * up))
	p.spread(NECK, "p", -20 * up + 10 * shout)
	p.add("cabeza", "p", -14 * up + 12 * shout)
	p.add("cabeza", "y", 7 * shout * math.sin(2 * math.pi * 6 * t))
	jaw(p, 28 * shout)
	return p


def death(t):
	"""Se alza herido, se tambalea y se desploma hacia delante: ceden las patas, cae el pecho, el cuello
	golpea el suelo después y las alas caen y se recogen con retraso. Cada parte va a destiempo."""
	p = Pose()
	rear = bump(t, 0.0, 0.18, 0.22, 0.4)
	stagger = bump(t, 0.18, 0.25, 0.38, 0.48) * math.sin(2 * math.pi * 3 * t)
	buckle = ease(ramp(t, 0.32, 0.66))      # ceden las patas
	thud = bump(t, 0.64, 0.68, 0.7, 0.8)     # el pecho golpea el suelo y rebota
	neck_fall = ease(ramp(t, 0.42, 0.78))    # el cuello cae después
	head_thud = bump(t, 0.76, 0.79, 0.81, 0.9)
	wing_fall = ease(ramp(t, 0.36, 0.88))
	breathing(p, t, depth=1 - buckle)
	wings(p, alzar=20 * rear - 8 * wing_fall, flap=-10 * stagger - 10 * wing_fall + 10 * thud, plegar=0.8 * wing_fall)
	p.root += Vector((0.08 * buckle, 0, 0.12 * rear - DESPLOME * buckle + 0.04 * thud))
	p.root_rot.append(("p", -14 * rear + 3 * buckle))
	p.root_rot.append(("r", 10 * buckle + 5 * stagger))
	p.root_rot.append(("y", 6 * stagger))
	p.both("brazo.#", "p", -20 * rear + 35 * buckle)
	p.both("antebrazo.#", "p", 25 * buckle)
	tail_wave(p, t, amp=6 * (1 - buckle))
	for i, s in enumerate(TAIL):
		k = (i + 1) / len(TAIL)
		p.add(s, "y", 14 * k * thud)
		p.add(s, "p", 6 * k * rear)
	p.spread(NECK, "p", -24 * rear + 30 * neck_fall - 8 * head_thud)
	p.spread(NECK, "y", 4 * stagger - 15 * neck_fall)
	p.add("cabeza", "p", -10 * rear + 8 * neck_fall)
	jaw(p, 24 * bump(t, 0.05, 0.15, 0.25, 0.4) + 14 * neck_fall)
	return p


#mismos tiempos de disparo que antes: bite 0,55 s, breath 1,05 s, roar 0,8 s (ver DragonRojo.gd)
ANIMS = {
	"idle": (90, True, idle),
	"bite": (36, False, bite),
	"breath": (84, False, breath),
	"roar": (75, False, roar),
	"death": (90, False, death),
}

#--- IK de las patas traseras ---
ik_targets = {}
for pie, cadena in PATAS.items():
	pb = rig.pose.bones[pie]
	vacio = bpy.data.objects.new("IK_" + pie, None)
	sc.collection.objects.link(vacio)
	vacio.parent = rig
	vacio.location = pb.bone.tail_local
	c = pb.constraints.new('IK')
	c.target = vacio
	c.chain_count = cadena
	c.use_tail = True
	c.use_stretch = False
	ik_targets[pie] = (vacio, pb.bone.tail_local.copy())

for pb in rig.pose.bones:
	pb.rotation_mode = 'QUATERNION'
RAIZ = "pelvis"


def apply_pose(p):
	for pb in rig.pose.bones:
		q = quat(pb.name, p.rot.get(pb.name, []))
		rest = pb.bone.matrix_local.to_quaternion()
		local = rest.inverted() @ q @ rest
		m = local.to_matrix().to_4x4()
		if pb.name == RAIZ:
			off = (F * p.root.x + L * p.root.y + U * p.root.z) * UNIT
			m = (rest.inverted() @ quat(pb.name, p.root_rot) @ q @ rest).to_matrix().to_4x4()
			m.translation = rest.inverted() @ off
		pb.matrix_basis = m
	for pie, (vacio, base) in ik_targets.items():
		off = p.targets.get(pie, Vector())
		vacio.location = base + (F * off.x + L * off.y + U * off.z) * UNIT


def bake(nombre, frames, loop, fn):
	"""Muestrea la pose con IK y la guarda como fotogramas clave sin restricciones."""
	muestras = []
	n = frames if loop else frames + 1
	for f in range(n):
		apply_pose(fn(f / frames))
		bpy.context.view_layer.update()
		muestras.append({pb.name: pb.matrix.copy() for pb in rig.pose.bones})
	return muestras


SOLO = arg("--only")
horneadas = {n: bake(n, *spec) for n, spec in ANIMS.items() if not SOLO or n == SOLO}
for pb in rig.pose.bones:
	for c in list(pb.constraints):
		pb.constraints.remove(c)
for vacio, _ in ik_targets.values():
	bpy.data.objects.remove(vacio)

rig.animation_data_create()


def basis(pb, mats):
	b = pb.bone
	if b.parent is None:
		return b.matrix_local.inverted() @ mats[pb.name]
	return (b.parent.matrix_local.inverted() @ b.matrix_local).inverted() @ mats[b.parent.name].inverted() @ mats[pb.name]


for nombre, muestras in horneadas.items():
	act = bpy.data.actions.new(nombre)
	act.use_fake_user = True
	rig.animation_data.action = act
	frames, loop, _ = ANIMS[nombre]
	claves = muestras + ([muestras[0]] if loop else [])  # en bucle, el último fotograma repite el primero
	for f, mats in enumerate(claves):
		for pb in rig.pose.bones:
			pb.matrix_basis = basis(pb, mats)
			pb.keyframe_insert("rotation_quaternion", frame=f)
			if pb.bone.parent is None:
				pb.keyframe_insert("location", frame=f)
	log("anim", nombre, "%.2f s" % (frames / FPS), "bucle" if loop else "")

if "--render" in ARGS:
	carpeta = arg("--render")
	os.makedirs(carpeta, exist_ok=True)
	sc.render.engine = 'BLENDER_WORKBENCH'
	sc.display.shading.color_type = 'TEXTURE'
	sc.display.shading.light = 'STUDIO'
	sc.display.shading.background_type = 'VIEWPORT'
	sc.display.shading.background_color = (0.55, 0.65, 0.75)
	sc.render.resolution_x = 480; sc.render.resolution_y = 360; sc.render.resolution_percentage = 100
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
	cam.data.clip_end = 500
	cam.data.type = 'ORTHO'
	#--zoom Z acerca la cámara a la cabeza
	zoom = float(arg("--zoom", "1"))
	cam.data.ortho_scale = LARGO * 1.5 / zoom
	#vistas: de frente (como la cámara del juego, desde el player) y de lado
	vistas = {"frente": Vector((0.35, -1, 0.25)), "lado": Vector((1, 0, 0.05))}
	centro = Vector((0, 0, LARGO * 0.25)) if zoom == 1 else P(HUESOS["cabeza"][1])
	n_fot = int(arg("--frames", "6"))
	for v, dirc in vistas.items():
		cam.location = centro + dirc.normalized() * LARGO * 4
		cam.rotation_euler = (centro - cam.location).to_track_quat('-Z', 'Y').to_euler()
		for i, nombre in enumerate(ANIMS):
			if nombre not in horneadas:
				continue
			rig.animation_data.action = bpy.data.actions[nombre]
			frames = ANIMS[nombre][0]
			for k in range(n_fot):
				sc.frame_set(int(frames * k / (n_fot - 1)))
				sc.render.filepath = "%s/rd_%s_%02d_%d.png" % (carpeta, v, i, k)
				bpy.ops.render.render(write_still=True)
else:
	rig.animation_data.action = bpy.data.actions["idle"]
	os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
	bpy.ops.object.select_all(action='DESELECT')
	rig.select_set(True); malla.select_set(True)
	bpy.ops.export_scene.gltf(filepath=SALIDA, export_format='GLB', use_selection=True,
		export_animation_mode='ACTIONS', export_force_sampling=True, export_frame_step=2,
		export_optimize_animation_size=True, export_image_format='JPEG')
	log("exportado", SALIDA, "%.1f MB" % (os.path.getsize(SALIDA) / 1e6))
