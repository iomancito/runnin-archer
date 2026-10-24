class_name BowCard extends PanelContainer

signal buy_pressed

@onready var imagen : TextureRect = %Imagen
@onready var nombre : Label = %Nombre
@onready var equipado : Label = %Equipado
@onready var estado : Label = %Estado
@onready var descripcion : Label = %Descripcion
@onready var pips : HBoxContainer = %Pips
@onready var boton : Button = %Boton
@onready var accion : Label = %Accion
@onready var moneda : Control = %Moneda
@onready var coste : Label = %Coste

func _ready() -> void:
	boton.pressed.connect(func(): buy_pressed.emit())
	for i in Balance.ARCO_NIVEL_MAX:
		var pip = Panel.new()
		pip.custom_minimum_size = Vector2(0, 12)
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)

func refresh(id : String, nivel : int, es_equipado : bool, texto_estado : String, texto_accion : String, precio : int, habilitado : bool, nivel_desc : int) -> void:
	imagen.texture = load("res://assets/images/bows/%s.png" % id)
	nombre.text = Balance.ARCOS[id].nombre
	equipado.visible = es_equipado
	estado.text = texto_estado
	descripcion.text = Balance.arco_descripcion(id, nivel_desc)
	for i in pips.get_child_count():
		pips.get_child(i).theme_type_variation = &"PipOn" if i < nivel else &"PipOff"
	accion.text = texto_accion
	moneda.visible = precio > 0
	coste.visible = precio > 0
	coste.text = str(precio)
	boton.disabled = not habilitado
	#un arco bloqueado se ve apagado
	imagen.modulate = Color(0.6, 0.6, 0.6) if texto_accion.begins_with("CLEAR") else Color.WHITE

func pulse() -> void:
	pivot_offset = size * 0.5
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.07)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
