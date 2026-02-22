extends Panel

enum pasivas {arrow_distance, arrow_speed, side_walk_speed, walk_speed, attack_speed, damage, arrows, vida}
@onready var menu_mejoras = $"."
@onready var menu_principal = $"../ColorRect/MenuPrincipal"

var pasivas_array : Array[Pasiva] =[]
var reembolso : int = 0


func _ready() -> void:
	pasivas_array.append(Pasiva.new("arrow_distance",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("arrow_speed",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("side_walk_speed",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("walk_speed",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("attack_speed",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("damage",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("arrow_number",[1,2,3,4,5],0,5))
	pasivas_array.append(Pasiva.new("vida",[1,2,3,4,5],0,5))
	actualiza_txt()

func _on_volver_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			$"../..".show_principal()

func _on_reset_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			print("Reset")

func _on_arrow_distance_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.arrow_distance]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["f_max_distancia"] += 4
				actualiza_txt()
		
func _on_arrow_speed_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.arrow_speed]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["f_velocidad"] += 30
				actualiza_txt()


func _on_side_walk_speed_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.side_walk_speed]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["p_side_speed"] += 5
				actualiza_txt()

func _on_walk_speed_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.walk_speed]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["p_speed"] += 20
				actualiza_txt()

func _on_attack_speed_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.attack_speed]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["p_attack_speed"] += 0.2
				actualiza_txt()

func _on_damage_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.damage]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["f_daño"] += 2
				actualiza_txt()

func _on_arrow_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.arrows]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["f_cantidad"] += 1
				actualiza_txt()

func _on_vida_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var ref = pasivas_array[pasivas.vida]
			if subir_lvl_pasiva(ref):
				Progreso.progreso_permanente["p_vida"] += 10
				actualiza_txt()

func _on_arco_1_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.


func _on_arco_2_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.


func _on_arco_3_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.


func _on_arco_4_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.

func actualiza_txt() -> void:
	$"../gold".text = str(Progreso.p_gold)
	$VBoxContainer/HBoxContainer/ArrowDistance/Label.text = pasivas_array[pasivas.arrow_distance].to_String()
	$VBoxContainer/HBoxContainer/ArrowSpeed/Label.text = pasivas_array[pasivas.arrow_speed].to_String()
	$VBoxContainer/HBoxContainer/SideWalkSpeed/Label.text = pasivas_array[pasivas.side_walk_speed].to_String()
	$VBoxContainer/HBoxContainer/WalkSpeed/Label2.text = pasivas_array[pasivas.walk_speed].to_String()
	$VBoxContainer/HBoxContainer2/AttackSpeed/Label.text = pasivas_array[pasivas.attack_speed].to_String()
	$"VBoxContainer/HBoxContainer2/Damage+2"/Label.text = pasivas_array[pasivas.damage].to_String()
	$VBoxContainer/HBoxContainer2/Arrow/Label.text = pasivas_array[pasivas.arrows].to_String()
	$VBoxContainer/HBoxContainer2/Vida/Label2.text = pasivas_array[pasivas.vida].to_String()

func subir_lvl_pasiva(ref) -> bool:
	var ret = false
	if ref.puede_subir() and Progreso.p_gold >= ref.get_coste_next():
		ret = ref.subir_lvl()
		Progreso.p_gold -= ref.get_coste()
	return ret
	
class Pasiva:
	
	var nombre :String
	var costes: Array
	var nivel : int
	var nivel_max :int
	
	func _init(nom : String = "", cost : Array[int] = [],niv : int = 0, nivmax : int = 0) -> void:
		nombre = nom
		costes = cost.duplicate()
		nivel = niv
		nivel_max = nivmax
		
	func subir_lvl() -> bool:
		if nivel < nivel_max:
			nivel +=1
			return true
		return false
			
	func get_coste_next() -> int:
		if nivel < nivel_max:
			return costes[nivel]
		return 0
		
	func get_coste() -> int:
		return costes[nivel-1]
		
	func puede_subir() -> bool:
		return nivel < nivel_max
		
	func get_money() -> int:
		if nivel == 0:
			return 0
		var total = 0
		for i in range(0,nivel):
			total += costes[i]
		return total
		
	func to_String() -> String:
		return str(nivel) + "->"+ str(get_coste_next())
	
	func to_dict() -> Dictionary:
		return{
			"nombre": nombre,
			"costes": costes,
			"nivel": nivel,
			"nivel_max": nivel_max
		}
	func from_dict(data : Dictionary) -> void:
		nombre = data.get("nombre","")
		costes = data.get("costes", [])
		nivel = data.get("nivel", 0)
		nivel_max = data.get("nivel_max", 0)
