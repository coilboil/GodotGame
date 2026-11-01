extends Node

#This is defined on individual objects in the game

enum interactionType {
	default,
	door,
	switch,
	item,
	lock,
	key,
	container,
	throwable
}

@export var object_ref: Node3D
@export var interaction_type: interactionType = interactionType.default
@export var maximum_rotation: float = 110
@export var pivot_point: Node3D
@export var nodes_to_affect: Array[Node]
@export var item_data: ItemData
@export var lock_name: String
@export var key_name: String
@export var animation: AnimationPlayer
@export var marker: Marker3D
@export var stam_cost: float

var opened: bool = false
var can_interact: bool = true
var is_interacting: bool = false
var lock_camera: bool = false
var starting_rotation: float
var is_front: bool
var player_hand: Marker3D
var player: Player

#signals
signal item_collected(item: Node)
signal thrown()


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	match interaction_type:
		interactionType.door:
			starting_rotation = pivot_point.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation) + maximum_rotation)
		interactionType.switch:
			starting_rotation = object_ref.rotation.z
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation) + maximum_rotation)
		interactionType.lock:
			lock_name = object_ref.get_lock_name()
		interactionType.key:
			key_name = object_ref.get_key_name()

#runs once when player FIRST clicks on object, setup
func preInteract(hand: Marker3D):
	is_interacting = true
	match interaction_type:
		interactionType.default:
			player_hand = hand
		interactionType.door:
			lock_camera = true
		interactionType.switch:
			lock_camera = true
		interactionType.lock:
			pass
		interactionType.key:
			object_ref.queue_free()
		interactionType.container:
			if not opened:
				animation.play("open")
				opened = true

#runs every frame and performs logic
func interact():
	if not can_interact:
		return
	is_interacting = true
	match interaction_type:
		interactionType.default:
			_default_interact()
		interactionType.item:
			_collect_item()


func auxInteract() -> void:
	if not can_interact:
		return
	is_interacting = true
	match interaction_type:
		interactionType.default:
			_default_throw()

#runs once when the player last interacts with object
func postInteract():
	is_interacting = false
	lock_camera = false

func _input(event: InputEvent) -> void:
	if is_interacting:
		match interaction_type:
			interactionType.door:
				if event is InputEventMouseMotion:
					if is_front:
						pivot_point.rotate_y(-event.relative.y * 0.001)
					else:
						pivot_point.rotate_y(event.relative.y * 0.001)
					pivot_point.rotation.y = clamp(pivot_point.rotation.y, starting_rotation, maximum_rotation)
			interactionType.switch:
				if event is InputEventMouseMotion:
					var percentage: float
					object_ref.rotate_z(event.relative.y * 0.001)
					object_ref.rotation.z = clamp(object_ref.rotation.z, starting_rotation, maximum_rotation)
					percentage = (object_ref.rotation.z - starting_rotation)/(maximum_rotation - starting_rotation)
					notify_nodes(percentage)

func _default_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		rigid_body_3d.set_linear_velocity((object_distance)*(5/rigid_body_3d.mass))
		

func _default_throw() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if stam_cost:
		player.stamina.value -= stam_cost
		player.can_regen = false
		player.s_timer = 0
	if rigid_body_3d:
		var throw_direction: Vector3 = -player_hand.global_transform.basis.z.normalized()
		var throw_stregnth: float = (10.0/rigid_body_3d.mass)
		rigid_body_3d.set_linear_velocity(throw_direction * throw_stregnth)
		
		can_interact = false
		await  get_tree().create_timer(1.0).timeout
		can_interact = true 
	
func set_direction(_normal: Vector3) -> void:
	if _normal.z > 0:
		is_front = true
	else:
		is_front = false

func notify_nodes(percentage: float):
	for node in nodes_to_affect:
		if node.has_method("execute"):
			node.call("execute", percentage)

func _collect_item() -> void:
	emit_signal("item_collected", get_parent())
	item_data.item_model_prefab = load(get_parent().scene_file_path)
	print(item_data.item_model_prefab)
	get_parent().queue_free()

func _open_lock(key_name: String, key_chain: Array[String]) -> bool:
	for i in key_chain.size():
		if key_chain.get(i) == lock_name:
			player.rich_text_label.pop_up_text("Unlocked", 1.2)
			return true
	player.rich_text_label.pop_up_text("Locked", 1.2)
	return false

func _add_key(key_name: String, key_chain: Array[String]) -> void:
	key_chain.append(key_name)
	
