extends CharacterBody3D

#enemy senses
enum States {idle, search, chase, attack, die}
@onready var deAggroTimer = $DeAggroTimer
var state: States = States.idle
const gravity: float = 9.8
var target: Object = null
var last_position: Vector3 = Vector3.ZERO

#enemy movement
@export var navAgent : NavigationAgent3D
var direction: Vector3 = Vector3.ZERO
var look: Vector3 = Vector3.ZERO
var speed: float = 2
var accel: float = 10

#collision vision
func _on_vision_timer_timeout() -> void:
	var overlaps = $VisionCone.get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.has_method("player"):
				var playerPosition = overlap.global_transform.origin
				$VisionRay.look_at(playerPosition, Vector3.UP)
				$VisionRay.force_raycast_update()
				if $VisionRay.is_colliding():
					var collider = $VisionRay.get_collider()
					if collider.has_method("player"):
						state = States.chase
						target = collider
						deAggroTimer.start()
					else:
						pass

#hearing
func _on_hearing_timer_timeout() -> void:
	var overlaps1 = $Hearing1.get_overlapping_bodies()
	if overlaps1.size() > 0:
		for overlap in overlaps1:
			if overlap.has_method("player"):
				if overlap.noise() >= 1:
					print(overlap.noise())
					state = States.chase
					target = overlap
					deAggroTimer.start()
	var overlaps2 = $Hearing2.get_overlapping_bodies()
	if overlaps2.size() > 0:
		for overlap in overlaps2:
			if overlap.has_method("player"):
				if overlap.noise() >= 2:
					state = States.chase
					target = overlap
					deAggroTimer.start()

#movement
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity
	if state == States.idle:
		deAggroTimer.stop()
		velocity = Vector3.ZERO
		target = null
		look = lerp(look, last_position, delta * 10)
		look_at(Vector3(look.x, global_position.y, look.z) , Vector3.UP, true)
	elif state == States.search:
		navAgent.target_position = last_position
		direction = navAgent.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		target = null
		look = lerp(look, global_position + velocity, delta * 10)
		look_at(Vector3(look.x, global_position.y, look.z) , Vector3.UP, true)
	elif state == States.chase:
		navAgent.target_position = target.global_position
		last_position = navAgent.target_position
		direction = navAgent.get_next_path_position() - global_position
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		look = lerp(look, global_position + velocity, delta * 10)
		look_at(Vector3(look.x, global_position.y, look.z) , Vector3.UP, true)
	
	
	if state == States.attack:
		print("attack")
	elif state == States.die:
		pass
		
	move_and_slide()

#deaggro
func _on_de_aggro_timer_timeout() -> void:
	if state == States.search:
		state = States.idle
		print(last_position)
		print("FAAAAAH")
	if state == States.chase:
		state = States.search
		print("FAH")
		deAggroTimer.start()
	
