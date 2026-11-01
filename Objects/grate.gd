extends StaticBody3D

@export var hp: float = 10
@export var dmg_threshold: float = 1

func _process(delta: float) -> void:
	if hp <= 0:
		self.queue_free()
