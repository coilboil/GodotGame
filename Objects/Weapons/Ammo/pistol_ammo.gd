extends RigidBody3D


@export var quant: int

func _set_quant(i : int) -> void:
	quant = i

func _get_quant() -> int:
	return quant
	
