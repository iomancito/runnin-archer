class_name CreditsScreen extends Control

## Créditos y licencias de terceros (ver docs/licencias.md: mantener los dos iguales).
## Textos visibles en inglés.

signal back_pressed

#[título, líneas]
const CREDITOS : Array = [
	["GAME", ["Running Archer by Ioman"]],
	["3D MODELS", [
		"Based on \"Goblin scared\" by Anam Gul\n(sketchfab.com/humraz.khan)\nlicensed under CC-BY 4.0",
		"Based on \"Carter Cameron: Max Form\" by KillrWolf\n(sketchfab.com/KillrWolf)\nlicensed under CC-BY 4.0",
		"Based on \"Fire-Branded Ogre\" by ribtibs\n(sketchfab.com/ribtibs)\nlicensed under CC-BY 4.0",
		"Based on \"LOTR Cave Troll - (for animating/rigging)\"\nby Ole Gunnar Isager (sketchfab.com/FrenchBaguette)\nlicensed under CC-BY 4.0",
		"Based on \"Red Dragon 3D\" by soufiane oujihi\n(sketchfab.com/sararoujihi)\nlicensed under CC-BY 4.0",
		"Based on \"Skeleton Dragon\" by LivindorCreation\n(sketchfab.com/LivindorCreation)\nlicensed under CC-BY 4.0",
		"Based on \"Death Knight - Dungeons and Dragons\"\nby Brian Trepanier (sketchfab.com/CMBC)\nlicensed under CC-BY 4.0",
		"Based on \"Iron Reaper, Mechanical Gothic Scythe\"\nby Pigcraft (sketchfab.com/s8819296)\nlicensed under CC-BY 4.0",
		"Based on \"Black Dragon with Idle Animation\" by 3DHaupt\n(sketchfab.com/dennish2010)\nlicensed under CC-BY-NC 4.0",
		"Fire whelp model created with Meshy (meshy.ai)\nlicensed under CC-BY 4.0",
		"KayKit Skeletons by Kay Lousberg (kaylousberg.com)\nCC0 1.0",
		"3D Fantasy Bows Pack (polyy.ai)\nCC0 1.0",
		"Stylized Nature MegaKit by Quaternius (quaternius.com)\nCC0 1.0",
		"Characters and animations from Adobe Mixamo",
	]],
	["TEXTURES", ["Poly Haven (polyhaven.com)\nCC0 1.0"]],
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
	#el texto viene cortado a 80 columnas: se unen las líneas de cada párrafo
	var licencia = Engine.get_license_text().replace("\n\n", "\r").replace("\n", " ").replace("\r", "\n\n")
	t += "[font_size=20]%s[/font_size]" % licencia
	%Texto.text = t
