extends RigidBody3D

@export var hp: float = 40
@export var dmg_threshold: float = 35

func _process(delta: float) -> void:
	if hp <= 0:
		self.queue_free()
