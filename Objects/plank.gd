extends StaticBody3D

@export var hp: float = 30
@export var dmg_threshold: float = 16

func _process(delta: float) -> void:
	if hp <= 0:
		self.queue_free()
