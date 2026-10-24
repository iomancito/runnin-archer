class_name PanelSkills extends Node3D

enum skills {arrow_speed, arrow_distance, attack_speed, move_speed, side_speed, arrow_damage,arrow_add}
#mismo orden que el enum skills, con el valor que da cada mejora
var skills_name : Array[String] = ["Arrow speed\n+30", "Range\n+4 m", "Fire rate\n+0.2/s", "Run speed\n+20", "Dodge speed\n+5", "Damage\n+2", "Arrows\n+1"]
var left_rnd : int
var right_rnd : int
@onready var left_txt = $left_mesh/left_label
@onready var right_txt = $right_mesh/right_label

func _ready() -> void:
	left_rnd = randi_range(0, skills.size()-1)
	right_rnd = randi_range(0, skills.size()-1)
	while left_rnd == right_rnd:
		right_rnd = randi_range(0, skills.size()-1)	
	left_txt.text = skills_name[left_rnd]
	right_txt.text = skills_name[right_rnd]

func _on_left_area_body_entered(body: Node3D) -> void:
	if body is Player:
		upgrade_skill_player(body, left_rnd)
		
func _on_right_area_body_entered(body: Node3D) -> void:
	if body is Player:
		upgrade_skill_player(body, right_rnd)

func upgrade_skill_player(body : Node3D, valor : int) -> void:
	match valor:
		skills.arrow_speed:
			body.increase_arrow_speed(30)
		skills.arrow_distance:
			body.increase_arrow_distance(4)
		skills.attack_speed:
			body.increase_attack_speed(0.2)
		skills.move_speed:
			body.increase_move_speed(20)
		skills.side_speed:
			body.increas_side_speed(5)
		skills.arrow_damage:
			body.increase_arrow_damage(2)
		skills.arrow_add:
			body.increase_arrow_number(1)
	queue_free()
