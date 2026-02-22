class_name Goblin extends Enemy

@onready var animation_player = $AnimationPlayer

func update_hp() -> void:
	$Label3D.text = str(vida)
