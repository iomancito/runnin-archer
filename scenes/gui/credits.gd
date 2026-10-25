class_name CreditsScreen extends Control

## Créditos y licencias de terceros (ver docs/licencias.md: mantener los dos iguales).
## Textos visibles en inglés.

signal back_pressed

#[título, líneas]
const CREDITOS : Array = [
	["GAME", ["Running Archer by Ioman"]],
	["3D MODELS", [
		"\"Arrows\" by Akshat (sketchfab.com/shooter24994)\nlicensed under CC-BY 4.0",
		"Based on \"Death Knight - Dungeons and Dragons\"\nby Brian Trepanier (sketchfab.com/CMBC)\nlicensed under CC-BY 4.0",
		"Based on \"Iron Reaper, Mechanical Gothic Scythe\"\nby Pigcraft (sketchfab.com/s8819296)\nlicensed under CC-BY 4.0",
		"Black Dragon by 3DHaupt (3dhaupt.com)",
		"Stylized Nature MegaKit by Quaternius (quaternius.com)\nCC0 1.0",
	]],
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
