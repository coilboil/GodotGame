class_name Player
extends CharacterBody3D

#movement vars
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var crouch_check: RayCast3D = $CrouchCheck
const JUMP_VELOCITY: float = 4.5
const walking_speed: float = 3
const spirnt_speed: float = 5
const crouch_speed: float = 1.8
enum PlayerState {idle_stand, idle_crouch, walking_crouch, walking, sprinting, air}
var input_dir: Vector2 = Vector2.ZERO
var direction: Vector3 = Vector3.ZERO
var SPEED: float = walking_speed
var sensivity: float = 0.002
var crouch_height: float = 0.5
var crouching: bool = false
var player_state: PlayerState = PlayerState.idle_stand
var moving: bool = false

#jump math
var jump_height: float = 1.1
var jump_time_to_peak: float = 0.33
var jump_time_to_descent: float = 0.29
var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak)
var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak))
var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent))

#UI
@onready var health: TextureProgressBar = $UI/CanvasLayer/Control/HealthBar
@onready var stamina: TextureProgressBar = $UI/CanvasLayer/Control/StaminaBar
@onready var open_hand_rect: TextureRect = $UI/CanvasLayer/Control/OpenHandRect
@onready var closed_hand_rect: TextureRect = $UI/CanvasLayer/Control/ClosedHandRect
@onready var test_cross_hair: TextureRect = $UI/CanvasLayer/Control/TestCrossHair
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var map: Control = $UI/CanvasLayer/Map

var can_regen: bool = false
var regen_delay: float = 1
var s_timer: float = 0
var can_start_stimer: bool = true
var regen_rate: float = 350

#camera 
@onready var camMarker = $CamMarker
@onready var camera_controller: CameraController = $CameraController
@onready var camera_3d: Camera3D = $CameraController/Camera3D

#weapon stuff
@onready var weapon_controller: Node = %WeaponController

#throw stuf
signal throw_sound(position: Vector3)

var vy

func player():
	pass

func get_gravy() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _ready() -> void:
	
	stamina.value = stamina.max_value
	health.value = health.max_value
	stamina.position.x = get_viewport().size.x/2 - stamina.get_size().x/2
	stamina.position.y = get_viewport().size.y * 0.98 - stamina.get_size().y
	health.position = stamina.position
	health.position.y = health.position.y  - health.get_size().y * 1.1
	open_hand_rect.position.x = get_viewport().size.x/2 - open_hand_rect.get_size().x/2
	open_hand_rect.position.y = get_viewport().size.y/2 - open_hand_rect.get_size().y/2
	closed_hand_rect.position = open_hand_rect.position
	test_cross_hair.position.x = get_viewport().size.x/2 - test_cross_hair.get_size().x/2
	test_cross_hair.position.y = get_viewport().size.y/2 - test_cross_hair.get_size().y/2
	rich_text_label.position.x = get_viewport().size.x/2 - rich_text_label.get_size().x/2
	rich_text_label.position.y = get_viewport().size.y/3 - rich_text_label.get_size().y/2

func _process(delta):

	
	if Input.is_action_just_pressed("debug_button"):
		rich_text_label.pop_up_text("TEST")
	#quit
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	#stamina stuff
	if stamina.value == 0:
		regen_delay = 3.0
	if can_regen == false && stamina.value != stamina.max_value:
		can_start_stimer = true
		if can_start_stimer:
			s_timer += delta
			if s_timer >= regen_delay:
				can_regen = true
				can_start_stimer = false
				s_timer = 0
				regen_delay = 1
	if stamina.value == stamina.max_value:
		can_regen = false
	if can_regen == true:
		stamina.value += delta * regen_rate
		can_start_stimer = false
		s_timer = 0

func _physics_process(delta: float) -> void:
	$Marker3D.rotation.x = $CamMarker.rotation.x
	$Marker3D.rotation.y = rotation.y
	#Handle jump and gravity
	if not is_on_floor():
		velocity.y += get_gravy() * delta  
	else:
		if Input.is_action_just_pressed("jump") and is_on_floor() and stamina.value > 0 and not camera_controller.is_inv_open:
			velocity.y = jump_velocity
			stamina.value -= 100
			can_regen = false
			s_timer = 0
			
	if weapon_controller.right_click_pen and Input.is_action_pressed("right_click"):
		SPEED = SPEED * weapon_controller.right_click_per
	
	#Movement
	input_dir = Input.get_vector("left", "right", "up", "down")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta *10)
	if direction and not camera_controller.is_inv_open:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if camera_controller.is_inv_open == true:
		Input.action_release("crouch")
	
	if Input.is_action_just_pressed("map"):
		map.texture_rect.visible = not map.texture_rect.visible
	
	noise()
	updatePlayerState()
	crouch()
	sprint(delta)
	move_and_slide()
	if vy < -11.5 and player_state == PlayerState.air and is_on_floor():
		health.value -= pow(2.9,abs(vy/5))
		print("FALLD")

func sprint(delta):
	if Input.is_action_pressed("crouch"):
		pass
	elif player_state == PlayerState.sprinting and Input.is_action_pressed("shift"):
		$CameraController/AudioStreamPlayer3D.volume_db = -29
		SPEED = spirnt_speed
		if (Input.is_action_pressed("right") or Input.is_action_pressed("left") or Input.is_action_pressed("down") )and not Input.is_action_pressed("up"):
			stamina.value -= delta * 240
		else:
			stamina.value -= delta * 70
		can_regen = false
		s_timer = 0
	else:
		SPEED = walking_speed
		$CameraController/AudioStreamPlayer3D.volume_db = -33


func crouch():
	if (player_state == PlayerState.idle_crouch or player_state == PlayerState.walking_crouch) and camera_controller.is_inv_open == false:
		$CameraController/AudioStreamPlayer3D.volume_db = -43
		SPEED = crouch_speed
		standing_collision.disabled = true
		crouching_collision.disabled = false
	elif player_state == PlayerState.air and Input.is_action_pressed("crouch"):
		SPEED = crouch_speed
		standing_collision.disabled = true
		crouching_collision.disabled = false
	elif not crouch_check.is_colliding():
		SPEED = walking_speed
		standing_collision.disabled = false
		crouching_collision.disabled = true

func noise():
	var noise_level = 0
	if player_state == PlayerState.walking:
		noise_level = 1
	elif player_state == PlayerState.sprinting:
		noise_level = 2
	elif Input.is_action_just_pressed("jump") and stamina.value > 0:
		noise_level = 2
	if weapon_controller.equipped_data:
		if weapon_controller.equipped_data.is_ranged:
			if weapon_controller.revolver_fired:
				noise_level = 3
			if Input.is_action_just_pressed("left_click") and weapon_controller.ads and weapon_controller.equipped_data.cur_ammo > 0:
				noise_level = 3
	if player_state == PlayerState.air and is_on_floor() and vy < -3:
		noise_level = 2
		$CameraController/AudioStreamPlayer3D2.play()
		print("ASDASDASD")
		print(vy)
	vy = velocity.y
	return noise_level

func updatePlayerState():
	moving = (input_dir != Vector2.ZERO)
	if not is_on_floor():
		player_state = PlayerState.air
	else:
		if Input.is_action_pressed("crouch"):
			if not moving:
				player_state = PlayerState.idle_crouch
			else:
				player_state = PlayerState.walking_crouch
		elif not crouch_check.is_colliding():
			if not moving:
				player_state = PlayerState.idle_stand
			elif Input.is_action_pressed("shift") and stamina.value > 0 and not (Input.is_action_pressed("right_click") and weapon_controller.equipped_data):  
				player_state = PlayerState.sprinting
			else:
				player_state = PlayerState.walking

func _on_inventory_mouse_entered() -> void:
	pass # Replace with function body.

func throw_land(position: Vector3) -> void:
	print("LAND")
	emit_signal("throw_sound", position)

func damaged(i: float) -> void:
	if weapon_controller.is_blocking and stamina.value > 0:
		stamina.value -= i * 5
		can_regen = false
		s_timer = 0
		if weapon_controller.block_str:
			pass
			var dmg = i - weapon_controller.block_str
			if dmg >= 0:
				health.value -= dmg
				return
			else:
				return
	health.value -= i
