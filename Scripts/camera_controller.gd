class_name CameraController
extends Node3D

#basic camera 
var player: Player
var input_rotation: Vector3
var mouse_input: Vector2
var mouse_sensitivity: float =  0.002
var crouch_depth: float = -.8
var base_fov: float = 75.0
var lerp_speed: float = 10.0
@onready var interaction_controller: Node = %InteractionController


#lean 
const lean_angle: float = 25.0
const lean_offset: float = 0.6
const lean_speed: float = 8.0
var targer_lean: float = 0.0 #-1 is left, 0 is mid, 1 is right
var current_lean: float = 0.0

#head bobbing
const bob_sprinting_speed: float = 22.0
const bob_walking_speed: float = 14.0
const bob_crouching_speed: float = 10.0
const bob_sprinting_inst: float = 0.2
const bob_walking_inst: float = 0.1
const bob_crouching_inst: float = 0.05
var bob_current_inst: float = 0.0
var bob_vector: Vector2 = Vector2.ZERO
var bob_index: float = 0.0
var step_dir: int = 0
var step_c: float = 0


#inventory vars
@onready var inventory_ui: Control = $"../InventoryUI"
@onready var interaction_ray: RayCast3D = %InteractionRay
@onready var item_grid: GridContainer = %ItemGrid
@onready var inventory: PanelContainer = %Inventory


#recoil stuff
var target_recoil: Vector2 = Vector2.ZERO
var current_recoil: Vector2 = Vector2.ZERO
var recoil_apply_speed: float = 10
var recoil_recovery_speed: float = 7.0
@onready var camera_3d: Camera3D = $Camera3D
@onready var arms: Marker3D = $SubViewportContainer/SubViewport/WeaponCam/Arms
var weapon_tilt: float = 2




func add_recoil(pitch: float, yaw: float,recovery: float, add_speed: float) -> void:
	target_recoil.x += pitch
	target_recoil.y += yaw
	recoil_recovery_speed = recovery
	recoil_apply_speed = add_speed
	

func update_recoil(delta) -> void:
	target_recoil = target_recoil.lerp(Vector2.ZERO, recoil_recovery_speed * delta)
	
	var prev_recoil = current_recoil
	current_recoil = current_recoil.lerp(target_recoil, recoil_apply_speed * delta)
	var recoil_difference = current_recoil - prev_recoil
	
	camera_3d.rotation.x += recoil_difference.y
	camera_3d.rotation.y += recoil_difference.x
	camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(0), deg_to_rad(90))
	
	#player.camMarker.rotation.x = clamp(player.camMarker.rotation.x, deg_to_rad(-80), deg_to_rad(90))
	


var is_inv_open: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player = get_parent()
	

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("lean_left") and player.player_state != player.PlayerState.sprinting and is_inv_open == false:
		targer_lean = -1.0
	elif Input.is_action_pressed("lean_right") and player.player_state != player.PlayerState.sprinting and is_inv_open == false:
		targer_lean = 1.0
	else:
		targer_lean = 0.0
	if is_inv_open:
		inventory_ui.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		inventory_ui.visible = false
		if not interaction_controller.current_obj:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if event is InputEventMouseMotion:
			if not interaction_controller.isCameraLocked():
				mouse_input.x += -event.screen_relative.x * mouse_sensitivity
				mouse_input.y += -event.screen_relative.y * mouse_sensitivity
				


func _process(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	var lerp_interval = player.direction / fps
	var lerp_position = player.camMarker.global_transform.origin + lerp_interval
	#$Arms.global_transform.origin = $Arms.global_transform.origin.lerp(lerp_position, 20 * delta)
	#arms.rotate_y(lerp(arms.rotation.y, mouse_input.x,delta *12))
	var lerp_rotation_x = player.camMarker.rotation.x + lerp_interval.x
	#$Arms.global_rotation.x = lerp($Arms.global_rotation.x, lerp_rotation_x, 12 * delta)
	arms.rotation.x = lerp(arms.rotation.x, (-mouse_input.y/2) + lerp_interval.x, delta * 10)
	arms.rotation.y = lerp(arms.rotation.y, (-mouse_input.x/2) + lerp_interval.y, delta * 10)
	#arms.rotation.y = lerp(arms.rotation.x, mouse_input.x * 100, delta)
	if Input.is_action_just_pressed("inventory"):
		if not is_inv_open:
			is_inv_open = true
		else:
			is_inv_open = false
			var held_item = get_tree().get_first_node_in_group("held_item")
			if held_item:
				var held_data = held_item.data
				print(held_data)
				held_item.queue_free()
				inventory.add_item(held_data)
				
	update_recoil(delta)	
	input_rotation.x = clampf(input_rotation.x + mouse_input.y, deg_to_rad(-80), deg_to_rad(90))
	input_rotation.y += mouse_input.x
	player.camMarker.transform.basis = Basis.from_euler(Vector3(input_rotation.x,0.0,0.0))
	player.global_transform.basis = Basis.from_euler(Vector3(0.0, input_rotation.y, 0.0))
	global_transform = player.camMarker.get_global_transform_interpolated()
	mouse_input = Vector2.ZERO

	player_state_cam_influence(delta)
	#lean
	current_lean = lerp(current_lean, targer_lean, delta * lean_speed)
	var target_tilt:float = deg_to_rad(-lean_angle) * current_lean
	var target_offset: float = lean_offset * current_lean
	player.camMarker.rotation.z = lerp(player.camMarker.rotation.z, target_tilt, delta * lean_speed)
	player.camMarker.position.x = lerp(player.camMarker.position.x, target_offset, delta * lean_speed)

#self explanitory
func player_state_cam_influence(delta: float) -> void:
	if player.player_state == player.PlayerState.air:
		player.camMarker.position.y = lerp(player.camMarker.position.y, 0.7, delta * lerp_speed)
		#player.camera_3d.fov = lerp(player.camera_3d.fov, base_fov * 1.01, delta * lerp_speed)
	if ((player.player_state == player.PlayerState.idle_crouch or player.player_state == player.PlayerState.walking_crouch) or Input.is_action_pressed("crouch")) or player.crouch_check.is_colliding():
		player.camMarker.position.y = lerp(player.camMarker.position.y, crouch_depth, delta * lerp_speed)
		#player.camera_3d.fov = lerp(player.camera_3d.fov, base_fov * 0.97, delta * lerp_speed)
		bob_current_inst = bob_crouching_inst
		bob_index += bob_crouching_speed * delta
		
	elif player.player_state == player.PlayerState.idle_stand:
		
		player.camMarker.position.y = lerp(player.camMarker.position.y, 0.6, delta * lerp_speed)
		#player.camera_3d.fov = lerp(player.camera_3d.fov, base_fov, delta * lerp_speed)
	elif player.player_state == player.PlayerState.walking:
		
		player.camMarker.position.y = lerp(player.camMarker.position.y, 0.6, delta * lerp_speed)
		#player.camera_3d.fov = lerp(player.camera_3d.fov, base_fov, delta * lerp_speed)
		bob_current_inst = bob_walking_inst
		bob_index += bob_walking_speed * delta
	elif player.player_state == player.PlayerState.sprinting:
		
		player.camMarker.position.y = lerp(player.camMarker.position.y, 0.6, delta * lerp_speed)
		#player.camera_3d.fov = lerp(player.camera_3d.fov, base_fov * 1.05, delta * lerp_speed)
		bob_current_inst = bob_sprinting_inst
		bob_index += bob_sprinting_speed * delta
	
	bob_vector.y = sin(bob_index)
	bob_vector.x = (sin(bob_index/2))
	var last_dir = step_dir
	if bob_vector.x > 0:
		step_dir = 1
		#print("RIGHT")
	else:
		step_dir = -1
		#print("LEFT")
	if last_dir != step_dir and player.player_state != player.PlayerState.idle_crouch  and player.player_state != player.PlayerState.air:
		$AudioStreamPlayer3D.play()
	
	
	if player.moving and not is_inv_open:
		player.camMarker.position.y = lerp(player.camMarker.position.y, 0.6 + bob_vector.y*(bob_current_inst/2.0), delta * lerp_speed)
		player.camMarker.position.x = lerp(player.camMarker.position.x, bob_vector.x*(bob_current_inst), delta * lerp_speed)
		arms.position.y = lerp(arms.position.y, bob_vector.y*(bob_current_inst/30.0), delta * lerp_speed)
		arms.position.x = lerp(arms.position.x, bob_vector.x*(bob_current_inst/15.0), delta * lerp_speed)
	else:
		player.camMarker.position.y = lerp(player.camMarker.position.y, 0.6, delta * lerp_speed)
		player.camMarker.position.x = lerp(player.camMarker.position.x, 0.0, delta * lerp_speed)
		arms.position.y = lerp(arms.position.y, 0.0, delta * lerp_speed)
		arms.position.x = lerp(arms.position.x, 0.0, delta * lerp_speed)
