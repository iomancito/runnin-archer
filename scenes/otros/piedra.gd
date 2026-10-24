extends CharacterBody3D

@export var daño : int = 3

func _on_area_daño_body_entered(body: Node3D) -> void:
	if body is Player:
		body.recibe_daño(daño)
		queue_free()
		
func _physics_process(delta: float) -> void:
	move_and_slide()
