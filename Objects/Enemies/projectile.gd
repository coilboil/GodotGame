extends RayCast3D

@export var speed: float = 60

func _physics_process(delta: float) -> void:
	position += global_basis * Vector3.FORWARD * speed * delta
	target_position = Vector3.FORWARD * speed * delta
	force_raycast_update()
	var collider = get_collider()
	if is_colliding():
		queue_free()
		if collider.is_in_group("player"):
			collider.health.value -= 30
			print("HIT")
		else:
			print(get_collider())
		
