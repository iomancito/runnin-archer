class_name CreditsScreen extends Control

## Créditos y licencias de terceros (ver docs/licencias.md: mantener los dos iguales).
## Textos visibles en inglés.

signal back_pressed

#[título, líneas]
const CREDITOS : Array = [
	["GAME", ["Running Archer by Ioman"]],
	["3D MODELS", [
		"Based on \"Goblin scared\" by Anam Gul\n[font_size=20]sketchfab.com/3d-models/goblin-scared-cf6fa5eafce741a0a749daf14758717e[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Carter Cameron: Max Form\" by KillrWolf\n[font_size=20]sketchfab.com/3d-models/carter-cameron-max-form-69bf6e4cf1de4069aaa12e9c6940a735[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Fire-Branded Ogre\" by ribtibs\n[font_size=20]sketchfab.com/3d-models/fire-branded-ogre-39cbab6fbaf14ccc87444e06695a1a35[/font_size]\nlicensed under CC-BY 4.0",
		"Based on a cave troll model by Ole Gunnar Isager\n[font_size=20]sketchfab.com/3d-models/lotr-cave-troll-for-animatingrigging-20a50af723314c1dac04aad8c929aa1e[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Red Dragon 3D\" by soufiane oujihi\n[font_size=20]sketchfab.com/3d-models/red-dragon-3d-f13c1b48e8934d299ccd02d0e4d48b35[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Skeleton Dragon\" by LivindorCreation\n[font_size=20]sketchfab.com/3d-models/skeleton-dragon-0ae92a30d2c242069acd61ed432f6c32[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Death Knight - Dungeons and Dragons\"\nby Brian Trepanier\n[font_size=20]sketchfab.com/3d-models/death-knight-dungeons-and-dragons-37fd804499614441a7996427a98ccc11[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Iron Reaper, Mechanical Gothic Scythe\"\nby Pigcraft\n[font_size=20]sketchfab.com/3d-models/iron-reaper-mechanical-gothic-scythe-3c13ff9c9334406fbad16f2333d9f435[/font_size]\nlicensed under CC-BY 4.0",
		"Based on \"Black Dragon with Idle Animation\" by 3DHaupt\n[font_size=20]sketchfab.com/3d-models/black-dragon-with-idle-animation-fb0053a2e59b43868e934c239bf4eb36[/font_size]\nlicensed under CC-BY-NC 4.0",
		"Fire whelp model created with Meshy (meshy.ai)\nlicensed under CC-BY 4.0",
		"KayKit Skeletons by Kay Lousberg (kaylousberg.com)\nCC0 1.0",
		"3D Fantasy Bows Pack (polyy.ai)\nCC0 1.0",
		"Stylized Nature MegaKit by Quaternius (quaternius.com)\nCC0 1.0",
		"Characters and animations from Adobe Mixamo",
	]],
	["MUSIC", ["Created with Suno (suno.com)"]],
	["TEXTURES", ["Poly Haven (polyhaven.com)\nCC0 1.0", "ambientCG (ambientcg.com)\nCC0 1.0"]],
	["VISUAL EFFECTS", ["BinbunVFX Vol.2 by Binbun3D (bun3d.com)\nCC0 1.0"]],
	["FONT", ["Nunito by Vernon Adams, Cyreal, Jacques Le Bailly\nSIL Open Font License 1.1"]],
	["ENGINE", ["Made with Godot Engine (godotengine.org)\nMIT License"]],
]

func _ready() -> void:
	%BackButton.pressed.connect(func(): back_pressed.emit())
	var t := ""
	for seccion in CREDITOS:
		t += "[font_size=34][color=#ffd34d]%s[/color][/font_size]\n" % seccion[0]
		for linea in seccion[1]:
			t += "%s\n\n" % linea
		t += "\n"
	#aviso obligatorio de la licencia MIT de Godot
	t += "[font_size=34][color=#ffd34d]GODOT ENGINE LICENSE[/color][/font_size]\n"
	var licencia := _unir_lineas(Engine.get_license_text())
	t += "[font_size=20]%s[/font_size]\n" % licencia
	%Texto.text = t
	#son ~90 000 caracteres: maquetarlos de golpe congelaba el móvil ~3 s al abrir los créditos.
	#Van en otra etiqueta con threaded, que los maqueta en segundo plano
	%Bibliotecas.text = _bibliotecas_godot()

## Avisos de las bibliotecas de terceros que incluye el motor (FreeType, mbedTLS, ENet...):
## sus licencias piden mostrar el copyright y el texto de la licencia.
func _bibliotecas_godot() -> String:
	var t := "[font_size=34][color=#ffd34d]THIRD-PARTY LIBRARIES IN GODOT[/color][/font_size]\n[font_size=20]"
	var usadas := {}
	for componente in Engine.get_copyright_info():
		t += "[b]%s[/b]\n" % _escapar(componente["name"])
		for parte in componente["parts"]:
			for copyright in parte["copyright"]:
				t += "© %s\n" % _escapar(copyright)
			t += "License: %s\n" % parte["license"]
			#"Expat and Zlib", "Unlicense or MIT-0"...
			for nombre in parte["license"].replace(" and ", " ").replace(" or ", " ").split(" "):
				usadas[nombre] = true
		t += "\n"
	var textos := Engine.get_license_info()
	for nombre in usadas:
		if textos.has(nombre):
			t += "\n[b]%s[/b]\n%s\n" % [nombre, _escapar(_unir_lineas(textos[nombre]))]
	return t + "[/font_size]"

## Los textos de las licencias vienen cortados a 80 columnas: se unen las líneas de cada párrafo.
func _unir_lineas(s: String) -> String:
	return s.replace("\n\n", "\r").replace("\n", " ").replace("\r", "\n\n")

## Los textos de las licencias llevan corchetes que el BBCode tomaría por etiquetas.
func _escapar(s: String) -> String:
	return s.replace("[", "[lb]")
