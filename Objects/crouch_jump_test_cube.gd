extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var label_3d: Label3D = $Label3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_3d.text = str(collision_shape_3d.scale.y)
	mesh_instance_3d.scale = collision_shape_3d.scale
