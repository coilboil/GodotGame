extends Node3D

@export var hinge: HingeJoint3D
@export var breakables: Array[Node3D]
@onready var door = $Door
@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var collision_shape_3d_2: CollisionShape3D = $StaticBody3D2/CollisionShape3D
@onready var interaction_component: Node = $Door/InteractionComponent
@export var has_run: bool = false
@export var hp: float = 40
@export var dmg_threshold: float = 35
@export var broken: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hp <= 0 and door:
		door.queue_free()
		broken = true
	if breakables:
		interaction_component.can_interact = false
		door.set_collision_layer_value(1, true)
		door.set_collision_layer_value(2, false)
		for i in breakables.size():
			if not is_instance_valid(breakables.get(i)):
				breakables.remove_at(i)
	elif not has_run:
		print("HAS")
		door.set_collision_layer_value(1, false)
		door.set_collision_layer_value(2, true)
		interaction_component.can_interact = true
		has_run = true
	
	if door: 
		if rad_to_deg(door.rotation.y) <= 0:
			collision_shape_3d.disabled = false
		elif not collision_shape_3d.disabled and not broken:
			collision_shape_3d.disabled = true
		
		if rad_to_deg(door.rotation.y) >= 110 and not broken:
			collision_shape_3d_2.disabled = false
		elif not collision_shape_3d_2.disabled:
			collision_shape_3d_2.disabled = true
