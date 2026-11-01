extends CharacterBody3D

@export var world_collider: CollisionShape3D 
@export var max_health: float = 25
@export var chase_time: float = 3
@export var path_rest_time: float = 10
@export var wonder_time: float = 5
@export var wonder_timer: float
@export var wonder_fail_check: RayCast3D
@export var cur_health: float
@export var max_stagger: float
@export var cur_stagger: float = 0
@export var stag_time: float 
@export var staggered: bool = false
@export var cur_stag_time: float
@export var is_dead: bool = false
@export var animation_player: AnimationPlayer
@export var navAgent: NavigationAgent3D
@export var vision_ray: RayCast3D
@export var vision_cone: Area3D
@export var hearing_far: Area3D
@export var hearing_close: Area3D
@export var hearing: Area3D
var player: Player
enum enemy_type {dummy,gob,lank, spit,frog,crawler}
@export var enemy: enemy_type
enum s {idle,dead,chase,wonder, attack, post_attack, search, pathing, flee, stunmned, distacted}
@export var chase_timer: float
@export var last_known_position: Vector3
var random: RandomNumberGenerator = RandomNumberGenerator.new()
@export var state: s
@export var timer: float
@export var time_out: bool = false
@export var deaggro_timer: float
@export var deaggro_time_out: bool = false
@export var random_position: Vector3
@export var random_f: float 
@export var random_i: int
@export var target: Node
@export var speed: float = 2.0
@export var accel: float = 10.0
@export var direction: Vector3 = Vector3.ZERO
const gravity: float = 9.8
var look: Vector3
@export var hit_box: Area3D
@export var hit_range: Area3D
@export var dmg: float = 15.0
@export var hit_landed: bool = false
@export var hit0: int = 0
@export var breaks: Dictionary
@export var activation_region: Area3D
@export var activated: bool = false
@export var path: PathFollow3D
@export var eyes: Node3D
@export var attack_cooldown: float = 3
@export var projectile: Node3D
@export var breakable_range: Area3D
@export var breakable: Node3D
@export var marker: Marker3D
@export var has: bool = false
@export var throw_view: Area3D
const spit_projectile = preload("res://Objects/Enemies/projectile.tscn")
var ran_direction
@export var nav_update: float = 0
@export var nav_lock: bool = false
@export var throw_pos: Vector3
@export var animation_tree: AnimationTree
@export var animations: Dictionary
@export var blend_speed: float = 15
enum dum {IDLE, WALK_F, WALK_B, WALK_L, WALK_R, ATTACK1, ATTACK2, ATTACK3, HIT, STUNNED}
var cur_ani : dum
var cur_ani_pos: float = 0
var audio_timer: float
var audio_bool: bool

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	player.connect("throw_sound", Callable(self,"throwable_sound"))
	if enemy == enemy_type.dummy:
		cur_health = max_health
		wonder_timer = wonder_time
		animation_player.set_default_blend_time(0.5)
		animation_player.set_blend_time("Walk", "Walk", 0)
		animation_player.set_blend_time("Punch", "Walk", 1)
	if enemy == enemy_type.lank:
		cur_health = max_health
	if enemy == enemy_type.spit:
		timer = attack_cooldown
		cur_health = max_health
	if enemy == enemy_type.frog:
		cur_health = max_health
		wonder_timer = wonder_time
	if enemy == enemy_type.crawler:
		cur_health = max_health
		state = s.search
		breaks = {
			"Tongue": 0
		}
	if enemy == enemy_type.gob:
		animation_tree["parameters/Idle_S/seek_request"] = random.randf_range(0, animation_player.get_animation("Idle").length)
		wonder_timer = wonder_time
		cur_ani = dum.IDLE
		cur_health = max_health
		animations ={
			"Idle": 0,
			"Walk_F": 0,
			"Walk_B": 0,
			"Walk_L": 0,
			"Walk_R": 0,
			"Attack1": 0,
			"Attack2": 0,
			"Attack3": 0,
			"Hit": 0,
			"Stunned": 0
		}

func _physics_process(delta: float) -> void:
	if global_position.distance_to(player.global_position) > 110:
		return
	match enemy:
		enemy_type.dummy:
			dummy(delta)
		enemy_type.gob:
			gob(delta)
		enemy_type.lank:
			lank(delta)
		enemy_type.spit:
			spit(delta)
		enemy_type.frog:
			frog(delta)
		enemy_type.crawler:
			crawler(delta)

func gob(delta: float) -> void:
	if activation_region and activated == false:
		if hearing.get_overlapping_bodies() and player.noise() > 2:
			activated = true
		if activation_region.get_overlapping_bodies().size() > 0:
			activated = true
			if path:
				state = s.pathing
		if not activated:
			return
	
	if not is_on_floor():
		velocity.y -= gravity
	
	if is_dead:
		timer -= delta
		if timer <= 0:
			queue_free()
		return
	
	if cur_health <= 0:
		$sounds/Idle.stop()
		is_dead = true
		timer = 40
		animation_tree.active = false
		world_collider.disabled = true
		$goboA/Armature/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
		var nodes = get_all_children(self)
		if not has:
			for i in nodes.size():
				if nodes.get(i) is PhysicalBone3D:
					nodes.get(i).set_collision_mask_value(1,true)
			has = true
	
	if vision_cone.get_overlapping_bodies().size() > 0:
		if vision_ray.is_colliding():
			if vision_ray.get_collider().has_method("player") and state != s.attack and state != s.post_attack:
				target = player
				deaggro_timer = 8
	
	if hearing_close.get_overlapping_bodies() and state != s.attack and not target and state != s.post_attack:
		if player.noise() > 0:
			target = player
			deaggro_timer = 10
			state = s.chase
		
	if hearing_far.get_overlapping_bodies() and not target:
		if player.noise() > 1:
			last_known_position = player.global_position
			navAgent.target_position = last_known_position
			state = s.search
		
	if hearing.get_overlapping_bodies() and not target:
		if player.noise() > 2:
			if state == s.pathing:
				state = s.idle
				deaggro_timer = 10
			eyes.look_at(Vector3(hearing.get_overlapping_bodies().get(0).global_position.x,global_position.y,hearing.get_overlapping_bodies().get(0).global_position.z))
			rotate_y(deg_to_rad(eyes.rotation.y * 5))
		
	if get_tree().get_first_node_in_group("throwable") and throw_view.get_overlapping_bodies():
		#vision_ray.look_at(Vector3(get_tree().get_first_node_in_group("throwable").global_position.x,global_position.y,get_tree().get_first_node_in_group("throwable").global_position.z))
		if vision_ray.get_collider():
			if vision_ray.get_collider().is_in_group("throwable"):
				target = player
	
	if not target:
		pass
		if throw_pos != Vector3.ZERO:
			navAgent.target_position = throw_pos
			state = s.search
			throw_pos = Vector3.ZERO
	
	if target:
		if state != s.attack and state != s.post_attack:
			animation_tree["parameters/Attack1_S/seek_request"] = 0
			animation_tree["parameters/Attack2_S/seek_request"] = 0
			animation_tree["parameters/Attack3_S/seek_request"] = 0
			state = s.chase
		if state == s.chase:
			if hit_range.get_overlapping_bodies():
				state = s.attack
				random_i = random.randi_range(0,2)
		deaggro_timer -= delta
		if deaggro_timer <= 0:
			last_known_position = target.global_position
			target = null
			state = s.search
	
	
	if nav_update <=0:
		nav_lock = false
	else:
		nav_update -= delta
	
	if cur_stagger > 30:
		state = s.stunmned
	match state:
		s.idle:
			velocity.x = 0
			velocity.z = 0
			cur_ani = dum.IDLE
			if path and not target:
				deaggro_timer -= delta
				if deaggro_timer <= 0:
					state = s.pathing
			else:
				wonder_timer -= delta
				if wonder_timer <= 0:
					print("WONDER")
					random_position = Vector3.ZERO
					random_position.x = random.randf_range(-3,3)
					random_position.z = random.randf_range(-3,3)
					random_position = global_position - random_position
					navAgent.target_position = random_position
					state = s.wonder
					wonder_timer = 2
			if state == s.wonder:
				if not navAgent.is_target_reachable():
					print("NAHHH")
					wonder_fail_check.position = Vector3(0,2,0)
					wonder_fail_check.target_position = Vector3(0,-5,0)
					wonder_fail_check.global_position.x = random_position.x
					wonder_fail_check.global_position.z = random_position.z
					if wonder_fail_check.is_colliding():
						navAgent.target_position = wonder_fail_check.get_collision_point()
						if navAgent.is_target_reachable():
							if navAgent.get_path_length() <= 5:
								pass
							else:
								print("NOPE")
								state = s.idle 
								wonder_timer = wonder_time
						else:
							print("NUH UH")
							state = s.idle 
							wonder_timer = wonder_time
					else:
						print("OOOOF")
						state = s.idle 
						wonder_timer = wonder_time
		s.chase:
			cur_ani = dum.WALK_F
			if not nav_lock:
				nav_lock = true
				nav_update = 0.2
				navAgent.target_position = target.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			direction.y = 0
			velocity = velocity.lerp(direction * (speed), accel * delta)
			animation_tree["parameters/Stunned_S/seek_request"] = 0
			eyes.look_at(Vector3(navAgent.get_next_path_position().x, global_position.y, navAgent.get_next_path_position().z))
			rotate_y(deg_to_rad(eyes.rotation.y * 5))
		
		s.attack:
			
			cur_ani_pos += delta
			velocity.x = 0
			velocity.z = 0
			match random_i:
				0:
					cur_ani = dum.ATTACK1
					if cur_ani_pos <= 0.45:
						eyes.look_at(player.global_position)
						rotate_y(deg_to_rad(eyes.rotation.y * 5))
					if cur_ani_pos >= 0.5 and cur_ani_pos <= 0.75 and not hit_landed:
						$sounds/Attack.play()
						print("HIT")
						if $"goboA/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Bone_032/HitBox".get_overlapping_bodies():
							print("HIT")
							player.damaged(25)
							hit_landed = true
				1:
					cur_ani = dum.ATTACK2
					if cur_ani_pos <= 0.48:
						eyes.look_at(player.global_position)
						rotate_y(deg_to_rad(eyes.rotation.y * 5))
					if cur_ani_pos >= 0.63 and cur_ani_pos <= 0.75 and not hit_landed:
						$sounds/Attack.play()
						print("HIT")
						if $"goboA/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Bone_017/HitBox".get_overlapping_bodies():
							print("HIT")
							player.damaged(25)
							hit_landed = true
				2:
					cur_ani = dum.ATTACK3
					if cur_ani_pos <= 0.35:
						eyes.look_at(player.global_position)
						rotate_y(deg_to_rad(eyes.rotation.y * 5))
					if cur_ani_pos >= 0.4 and cur_ani_pos <= 0.6 and not hit_landed:
						$sounds/Attack.play()
						print("HIT")
						if $"goboA/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Bone_032/HitBox".get_overlapping_bodies():
							print("HIT")
							player.damaged(25)
							hit_landed = true
			
			if cur_ani_pos >= 1.49:
				hit_landed = false
				cur_ani_pos = 0
				timer = 2
				random_i = random.randi_range(0,6)
				if random_i <= 2:
					random_i = random.randi_range(0,2)
					state = s.post_attack
					wonder_fail_check.position = Vector3(0,0.5,0)
					wonder_fail_check.target_position = Vector3(0,-2.5,0)
				else:
					state = s.chase
		
		s.post_attack:
			if wonder_fail_check.position == Vector3(0,0.5,0):
				match random_i:
					0:
						wonder_fail_check.position = Vector3(0,0.5,1)
						cur_ani = dum.WALK_B
					1:
						wonder_fail_check.position = Vector3(-1,0.5,0)
						cur_ani = dum.WALK_L
					2:
						wonder_fail_check.position = Vector3(1,0.5,0)
						cur_ani = dum.WALK_R
			if not navAgent.is_target_reachable():
				state = s.chase
			if not nav_lock:
				nav_lock = true
				nav_update = 0.2
				if wonder_fail_check.is_colliding():
					navAgent.target_position = wonder_fail_check.get_collision_point()
				else:
					state = s.chase
				if navAgent.get_path_length() >= 2:
					state = s.chase
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			direction.y = 0
			velocity = velocity.lerp(direction * (speed * 0.5), accel * delta)
				
				
			time_out = true
			if time_out:
				timer -= delta
			if timer <= 0:
				time_out = false
				timer = 0
				nav_update = 0
				state = s.chase
			eyes.look_at(target.global_transform.origin, Vector3.UP, false)
			rotate_y(deg_to_rad(eyes.rotation.y * 5))
		
		s.search:
			cur_ani = dum.WALK_F
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			direction.y = 0
			velocity = velocity.lerp(direction * (speed), accel * delta)
			animation_tree["parameters/Stunned_S/seek_request"] = 0
			eyes.look_at(Vector3(navAgent.get_next_path_position().x, global_position.y, navAgent.get_next_path_position().z))
			rotate_y(deg_to_rad(eyes.rotation.y * 5))
			if navAgent.is_target_reached():
				state = s.idle
			if not navAgent.is_target_reachable():
				look_at(Vector3(player.global_position.x, global_position.y,player.global_position.z), Vector3.UP)
				state = s.idle
			if path and deaggro_timer != 2:
				deaggro_timer = 10
		
		s.wonder:
			wonder_timer -= delta
			if wonder_timer <= 0 and state == s.wonder:
				state = s.idle
				wonder_timer = wonder_time
				print("STUCK")
			cur_ani = dum.WALK_F
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			direction.y = 0
			velocity = velocity.lerp(direction * (speed), accel * delta)
			nav_lock = true
			animation_tree["parameters/Stunned_S/seek_request"] = 0
			eyes.look_at(Vector3(navAgent.get_next_path_position().x, global_position.y, navAgent.get_next_path_position().z))
			rotate_y(deg_to_rad(eyes.rotation.y * 5))
			if navAgent.is_target_reached():
				state = s.idle
				wonder_timer = wonder_time + (random.randi_range(-(wonder_time - 2), wonder_time + 3))
		
		s.stunmned:
			cur_ani_pos += delta
			velocity.x = 0
			velocity.z = 0
			cur_ani = dum.STUNNED
			if cur_ani_pos >= 3.5:
				state = s.idle
				cur_stagger = 0
				cur_ani_pos = 0
				nav_update = 0
		
		s.pathing:
			if not nav_lock:
				nav_lock = true
				nav_update = 0.2
				navAgent.target_position = path.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			direction.y = 0
			velocity = velocity.lerp(direction * (speed), accel * delta)
			animation_tree["parameters/Stunned_S/seek_request"] = 0
			eyes.look_at(Vector3(navAgent.get_next_path_position().x, global_position.y, navAgent.get_next_path_position().z))
			rotate_y(deg_to_rad(eyes.rotation.y * 5))
			if navAgent.is_target_reached():
				cur_ani = dum.IDLE
			else:
				cur_ani = dum.WALK_F
			if navAgent.is_target_reached():
				velocity.x = 0
				velocity.z = 0
	
	
	handle_animations(delta)
	handle_audio(delta)
	update_tree()
	move_and_slide()

func lank(delta: float) -> void:
	if activation_region and activated == false:
		if hearing.get_overlapping_bodies() and player.noise() > 2:
			activated = true
		if activation_region.get_overlapping_bodies().size() > 0:
			activated = true
			if path:
				state = s.pathing
		if not activated:
			return
	var guard: bool
	if hit0 >= 2:
		guard = true
	else:
		guard = false
	
	if not is_on_floor():
		velocity.y -= gravity
	
	if is_dead:
		world_collider.disabled = true
		await get_tree().create_timer(delta * 1000).timeout
		queue_free()
		return
	if cur_health <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		state = s.dead
	else:
		vision_ray.look_at(player.global_position)
		if vision_cone.get_overlapping_bodies().size() > 0 and not guard:
			if vision_ray.is_colliding():
				if vision_ray.get_collider().has_method("player") and state != s.attack:
					target = vision_cone.get_overlapping_bodies().get(0)
					deaggro_timer = 5
					state = s.chase
		
		if hearing_close.get_overlapping_bodies() and state != s.attack and not target:
			if player.noise() > 0:
				if not guard:
					state = s.chase
					target = hearing_close.get_overlapping_bodies().get(0)
					print("WASDASDASDWFGGHBJN")
				else:
					last_known_position = player.global_position
					state = s.search
		
		if hearing_far.get_overlapping_bodies() and not target and state != s.attack:
			if player.noise() > 1 :
				last_known_position = player.global_position
				state = s.search
		
		if hearing.get_overlapping_bodies() and state != s.search and state != s.chase:
			if player.noise() > 2:
				if state == s.pathing:
					state = s.idle
					deaggro_timer = 10
				look_at(hearing.get_overlapping_bodies().get(0).global_position)
	
	if guard:
		if hit_range.get_overlapping_bodies():
				if hit_range.get_overlapping_bodies().get(0).has_method("player"):
					state = s.attack
	
	if target and not is_dead:
		if state == s.chase:
			if hit_range.get_overlapping_bodies():
				if hit_range.get_overlapping_bodies().get(0).has_method("player"):
					state = s.attack
		deaggro_timer -= delta
		if deaggro_timer <= 0:
			last_known_position = target.global_position
			target = null
			state = s.search
	if breakable_range.get_overlapping_bodies().size():
		breakable = breakable_range.get_overlapping_bodies().get(0).get_parent()
		state = s.post_attack
	
	match state:
		s.idle:
			target = null
			if guard:
				animation_player.play("Idle_Guard")
			else:
				animation_player.play("Idle")
			velocity.x = 0
			velocity.z = 0
			if path and not target and not guard:
				deaggro_timer -= delta
				if deaggro_timer <= 0:
					state = s.pathing
			else:
				wonder_timer -= delta
				if wonder_timer <= 0:
					random_position = Vector3.ZERO
					random_position.x = random.randf_range(-3,3)
					random_position.z = random.randf_range(-3,3)
					random_position = global_position - random_position
					navAgent.target_position = random_position
					state = s.wonder
					wonder_timer = 2
			if state == s.wonder:
				if not navAgent.is_target_reachable():
					wonder_fail_check.global_position.x = random_position.x
					wonder_fail_check.global_position.z = random_position.z
					if wonder_fail_check.is_colliding():
						navAgent.target_position = wonder_fail_check.get_collision_point()
						if navAgent.is_target_reachable():
							if navAgent.get_path_length() <= 5:
								pass
							else:
								state = s.idle 
								wonder_timer = wonder_time
						else:
							state = s.idle 
							wonder_timer = wonder_time
					else:
						state = s.idle 
						wonder_timer = wonder_time
		
		s.search:
			if guard:
				animation_player.play("Walk_Guard")
			else:
				animation_player.play("Walk")
			navAgent.target_position = last_known_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			if not guard:
				velocity = velocity.lerp(direction * (speed * 0.3), accel * delta)
			else:
				velocity = velocity.lerp(direction * (speed * 1.5), accel * delta)
			
			if navAgent.is_target_reached():
				state = s.idle
			look = lerp(look, global_position + (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			if not navAgent.is_target_reachable():
				look_at(player.global_position)
				state = s.idle
			if path:
				deaggro_timer = 15
		
		s.wonder:
			wonder_timer -= delta
			if wonder_timer <= 0 and state == s.wonder:
				state = s.idle
				wonder_timer = wonder_time
				print("STUCK")
			if guard:
				animation_player.play("Walk_Guard")
			else:
				animation_player.play("Walk")
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.4), accel * delta)
			look = lerp(look, global_position + (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			if navAgent.is_target_reached():
				state = s.idle
				wonder_timer = wonder_time + (random.randi_range(-(wonder_time - 2), wonder_time + 3))
		
		s.chase:
			if guard:
				last_known_position = player.global_position
				state = s.search
			animation_player.play("Walk")
			navAgent.target_position = target.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			if not guard:
				velocity = velocity.lerp(direction * (speed * 0.8), accel * delta)
			else:
				velocity = velocity.lerp(direction * (speed * 1.5), accel * delta)
			look = lerp(look, global_position + (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
		
		s.attack:
			velocity = Vector3.ZERO
			if guard:
				animation_player.play("Attack_Guard", -1, 2.5)
			else:
				animation_player.play("Attack", -1, 2.5)
			if animation_player.get_current_animation_position() >= 1.04 and animation_player.get_current_animation_position() < 1.13:
				if hit_box.get_overlapping_bodies() and hit_landed == false:
					print("HIT")
					if player.weapon_controller.is_blocking and player.weapon_controller.equipped_data.block_str >= 15 and player.stamina.value >= (15 * player.weapon_controller.equipped_data.block_stam_mtp):
						player.stamina.value -= (15 * player.weapon_controller.equipped_data.block_stam_mtp)
						player.can_regen = false
						player.s_timer = 0
						print("BLOCKED")
					else:
						player.health.value -= dmg
					hit_landed = true
			if animation_player.get_current_animation_position() > 2.6:
				hit_landed = false
				if not guard:
					if target:
						state = s.chase
				else:
					state = s.idle
		
		s.post_attack:
			velocity = Vector3.ZERO
			if guard:
				animation_player.play("Attack_Guard", -1, 2.5)
			else:
				animation_player.play("Attack", -1, 2.5)
			if animation_player.get_current_animation_position() >= 1.04 and animation_player.get_current_animation_position() < 1.13:
				if breakable:
					breakable.hp -= dmg
			if animation_player.get_current_animation_position() > 2.6:
				if path:
					state = s.pathing
				else:
					state = s.idle
		s.pathing:
			if navAgent.is_target_reached():
				if guard:
					animation_player.play("Idle_Guard")
				else:
					animation_player.play("Idle")
			else:
				if guard:
					animation_player.play("Walk_Guard")
				else:
					animation_player.play("Walk")
			navAgent.target_position = path.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.7), accel * delta)
			look = lerp(look, global_position + (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			if navAgent.is_target_reached():
				velocity = Vector3.ZERO
		
		s.dead:
			$Lank_animated3/Armature/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
			var nodes = get_all_children(self)
			for i in nodes.size():
				if nodes.get(i) is PhysicalBone3D:
					nodes.get(i).set_collision_mask_value(1,true)
	
	
	move_and_slide()

func spit(delta: float) -> void:
	
	if activation_region and activated == false:
		if hearing.get_overlapping_bodies() and player.noise() > 2:
			activated = true
		if activation_region.get_overlapping_bodies().size() > 0:
			activated = true
			if path:
				state = s.pathing
		if not activated:
			return
	
	if not is_on_floor():
		velocity.y -= gravity
	
	if is_dead:
		world_collider.disabled = true
		await get_tree().create_timer(delta * 1000).timeout
		queue_free()
		return
	if cur_health <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		state = s.dead
	
	vision_ray.look_at(player.camera_controller.global_position)
	if animation_player.current_animation == "Walk":
		vision_cone.rotation = Vector3(0.436332, 0.20944, -0.10472)
	else:
		vision_cone.rotation = Vector3.ZERO
		vision_cone.rotation.x = deg_to_rad(10)
	if vision_cone.get_overlapping_bodies().size() > 0:
		if vision_ray.is_colliding():
			if vision_ray.get_collider().has_method("player"):
				target = vision_cone.get_overlapping_bodies().get(0)
				deaggro_timer = 8
				if state == s.pathing:
					look_at(target.global_position)
	
	if hearing_close.get_overlapping_bodies() and state != s.flee:
		if player.noise() > 0:
			if state == s.pathing:
				state = s.idle
			look_at(hearing_close.get_overlapping_bodies().get(0).global_position)
	
	if hearing_far.get_overlapping_bodies() and state != s.flee:
		if player.noise() > 1:
			if state == s.pathing:
				state = s.idle
			look_at(hearing_far.get_overlapping_bodies().get(0).global_position)
	
	if hearing.get_overlapping_bodies() and state != s.flee:
		if player.noise() > 2:
			if state == s.pathing:
				state = s.idle
			look_at(hearing.get_overlapping_bodies().get(0).global_position)
	
	if target and not is_dead:
		if global_position.distance_to(target.global_position) > 12 and state != s.attack and state != s.post_attack:
			state = s.chase
		if global_position.distance_to(target.global_position) < 9 and state != s.attack and state != s.post_attack:
			state = s.idle
		
		if global_position.distance_to(target.global_position) < 6 and state != s.attack and state != s.post_attack:
			state = s.flee
		if state == s.flee:
			if global_position.distance_to(target.global_position) > 7:
				state = s.idle
			if global_position.distance_to(target.global_position) < 2:
				velocity = Vector3.ZERO
				look_at(target.global_position)
				state = s.idle
		
		if state == s.idle:
			if global_position.distance_to(target.global_position) < 2:
				if hit_range.get_overlapping_bodies():
					state = s.post_attack
		
		deaggro_timer -= delta
		if deaggro_timer <= 0:
			last_known_position = target.global_position
			target = null
			print(target)
			state = s.search
	
	
	match state:
		
		s.idle:
			animation_player.play("Idle")
			velocity.x = 0
			velocity.z = 0
			if target:
				timer -= delta
				if global_position.distance_to(target.global_position) > 6 and timer <= 0:
					state = s.attack
			if path and not target:
				deaggro_timer -= delta
				if deaggro_timer <= 0:
					state = s.pathing
		
		s.chase:
			animation_player.play("Walk")
			navAgent.target_position = target.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.7), accel * delta)
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
		
		s.flee:
			pass
			if global_position.distance_to(target.global_position) > 3.5:
				animation_player.play("Walk")
				direction = navAgent.get_next_path_position() - global_position
				direction = direction.normalized()
				navAgent.target_position = global_position + eyes.global_basis.z
				velocity = velocity.lerp(direction * (speed * 0.4), accel * delta)
				eyes.look_at(target.global_transform.origin, Vector3.UP, false)
				rotate_y(deg_to_rad(eyes.rotation.y * 10))
			else:
				animation_player.play("Walk")
				direction = navAgent.get_next_path_position() - global_position
				direction = direction.normalized()
				eyes.look_at(target.global_transform.origin, Vector3.UP, false)
				navAgent.target_position = global_position + eyes.global_basis.z
				velocity = velocity.lerp(direction * (speed), accel * delta)
				look_at(global_position + eyes.global_basis.z)
		
		s.attack:
			look_at(target.global_position)
			velocity = Vector3.ZERO
			animation_player.play("Punch", -1, 0.8)
			timer = attack_cooldown
			if animation_player.current_animation_position >= animation_player.current_animation_length - 0.1:
				projectile = spit_projectile.instantiate()
				add_child(projectile)
				eyes.look_at(target.global_position)
				projectile.global_transform = vision_ray.global_transform
				state = s.idle
				print(vision_ray.get_collider())
		
		s.post_attack:
			velocity = Vector3.ZERO
			animation_player.play("Punch", -1, 0.55)
			if animation_player.get_current_animation_position() >= 0.35 and animation_player.get_current_animation_position() < 0.37:
				if hit_box.get_overlapping_bodies() and hit_landed == false:
					print("HIT")
					if player.weapon_controller.is_blocking and player.weapon_controller.equipped_data.block_str >= 15 and player.stamina.value >= (15 * player.weapon_controller.equipped_data.block_stam_mtp):
						player.stamina.value -= (15 * player.weapon_controller.equipped_data.block_stam_mtp)
						player.can_regen = false
						player.s_timer = 0
						print("BLOCKED")
					else:
						player.health.value -= 15
					hit_landed = true
			if animation_player.get_current_animation_position() > 1.2:
				hit_landed = false
				state = s.idle
		
		s.search:
			animation_player.play("Walk")
			navAgent.target_position = last_known_position
			if not navAgent.is_target_reachable():
				look_at(player.global_position)
				state = s.idle
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.3), accel * delta)
			if navAgent.is_target_reached():
				state = s.idle
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			if path:
				deaggro_timer = 10
		
		s.pathing:
			if navAgent.is_target_reached():
				animation_player.play("Idle")
			else:
				animation_player.play("Walk")
			navAgent.target_position = path.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.7), accel * delta)
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			if navAgent.is_target_reached():
				velocity = Vector3.ZERO
		
		s.dead:
			animation_player.play("Die", 0.5, 1, false)
	
	move_and_slide()

func frog(delta: float) -> void:
	if not is_on_floor():
		if not target:
			velocity.y -= gravity
		if target:
			velocity.y -= gravity/10
			animation_player.play("Attack")
		if hit_box.get_overlapping_bodies() and not hit_landed and target:
			player.health.value -= dmg
			print("HIT")
			hit_landed = true
			deaggro_timer = 7
			if not target:
				target = hit_box.get_overlapping_bodies().get(0)
	
	if is_dead:
		world_collider.disabled = true
		await get_tree().create_timer(delta * 80).timeout
		$frog2/Armature/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_stop_simulation()
		await get_tree().create_timer(delta * 1000).timeout
		queue_free()
		return
	
	if cur_health <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		state = s.dead
	
	if state == s.dead:
		$frog2/Armature/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
		var nodes = get_all_children(self)
		for i in nodes.size():
			if nodes.get(i) is PhysicalBone3D:
				nodes.get(i).set_collision_mask_value(1,true)
	
	
	if target:
		if global_position.distance_to(target.global_position) > 10 and state != s.attack and state != s.post_attack and state != s.idle:
			state = s.chase
		elif state == s.chase and state != s.attack and state != s.post_attack and state != s.idle:
			state = s.flee
		if player.noise() <= 0:
			deaggro_timer -= delta
		if deaggro_timer <= 0:
			target = null
			state = s.idle
	
	else:
		wonder_timer -= delta
		if wonder_timer <= 0 and state == s.idle:
			print("WONDER")
			random_position = Vector3.ZERO
			random_position.x = random.randf_range(-6,6)
			random_position.z = random.randf_range(-6,6)
			random_position = global_position - random_position
			navAgent.target_position = random_position
			state = s.wonder
			if state == s.wonder:
				if not navAgent.is_target_reachable():
					print("NAHHH")
					wonder_fail_check.global_position.x = random_position.x
					wonder_fail_check.global_position.z = random_position.z
					if wonder_fail_check.is_colliding():
						navAgent.target_position = wonder_fail_check.get_collision_point()
						if navAgent.is_target_reachable():
							if navAgent.get_path_length() <= 10:
								pass
							else:
								print("NOPE")
								state = s.idle 
								wonder_timer = wonder_time
						else:
							print("NUH UH")
							state = s.idle 
							wonder_timer = wonder_time
					else:
						print("OOOOF")
						state = s.idle 
						wonder_timer = wonder_time
	
	if hearing_close.get_overlapping_bodies():
		if player.noise() > 0:
			target = hearing_close.get_overlapping_bodies().get(0)
			if target:
				deaggro_timer = 7
	
	if hearing_far.get_overlapping_bodies():
		if player.noise() > 1:
			target = hearing_far.get_overlapping_bodies().get(0)
			if target:
				deaggro_timer = 7
	
	if hearing.get_overlapping_bodies() and state != s.flee:
		if player.noise() > 2:
			if state == s.pathing:
				state = s.idle
			look_at(hearing.get_overlapping_bodies().get(0).global_position)
	
	match state:
		
		s.idle:
			has = false
			pass
			if target:
				if is_on_floor():
					velocity = lerp(velocity,Vector3.ZERO, delta * 10)
					timer -= delta 
					hit_landed = false
					hit_box.get_child(0).disabled = true
					animation_player.play("Post Attack", 0.1)
				if timer <= 0:
					timer = attack_cooldown
					random_i = random.randi_range(0,1)
					state = s.flee
			else:
				velocity.x = 0
				velocity.z = 0
				animation_player.play("Idle", 0.1, 1)
		
		s.chase:
			animation_player.play("Run", 0.1)
			timer -= delta
			navAgent.target_position = target.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.7), accel * delta)
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
		
		s.flee:
			animation_player.play("Run", 0.1)
			eyes.look_at(target.position)
			if global_position.distance_to(target.global_position) > 5:
				if random_i == 0:
					marker.global_position = global_position + (eyes.global_basis.x *3)
				if random_i == 1:
					marker.global_position = global_position - (eyes.global_basis.x *3)
			if global_position.distance_to(target.global_position) < 7:
				if random_i == 0:
					marker.global_position = (global_position - (target.global_position - global_position)) + (eyes.global_basis.x *3)
				if random_i == 1:
					marker.global_position = (global_position - (target.global_position - global_position)) - (eyes.global_basis.x *3)
			wonder_fail_check.global_position = marker.global_position
			navAgent.target_position = wonder_fail_check.get_collision_point()
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.85), accel * delta)
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			timer -= delta
			if timer <= 0:
				velocity = lerp(velocity,Vector3.ZERO, delta * 10)
				timer = 0.4
				state = s.post_attack
		
		s.post_attack:
			timer -= delta
			if timer > 0:
				if random_i == 0:
					animation_player.play("Turn_Left", -1, 2)
				if random_i == 1:
					animation_player.play("Turn_Right", -1, 2)
				if not has:
					random_f = random.randi_range(1,4)
					has = true
					if random_f == 4:
						pass
						print("CHARGE")
				velocity = lerp(velocity,Vector3.ZERO, delta * 10)
				eyes.look_at(target.position)
				rotate_y(deg_to_rad(eyes.rotation.y * 6))
				last_known_position = target.global_position
				navAgent.target_position = last_known_position
			if timer <= -0.1:
				state = s.attack
		
		s.attack:
			if not random_f == 4:
				hit_box.get_child(0).disabled = false
				direction = navAgent.get_next_path_position() - global_position
				direction = direction.normalized()
				print(global_position.distance_to(target.global_position))
				velocity =  Vector3(direction.x * 28, 12, direction.z * 28)
				timer = animation_player.get_animation("Post Attack").length
				state = s.idle
			else:
				if has:
					animation_player.play("Run", 0.1)
					navAgent.target_position = target.global_position
					direction = navAgent.get_next_path_position() - global_position
					direction = direction.normalized()
					velocity = velocity.lerp(direction * (speed * 0.7), accel * delta)
					look = lerp(look, global_position - (velocity * 2), delta*10)
					look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
				if animation_player.current_animation == "Charge_Attack":
					velocity.x = 0
					velocity.z = 0
				if animation_player.get_current_animation_position() <= 1.29 and animation_player.current_animation == "Charge_Attack":
					eyes.look_at(target.position)
					rotate_y(deg_to_rad(eyes.rotation.y * 6))
				if animation_player.get_current_animation_position() >= 1.65 and animation_player.get_current_animation_position() <= 1.75 and animation_player.current_animation == "Charge_Attack":
					print( hit_box.get_overlapping_bodies())
					if hit_box.get_overlapping_bodies() and not hit_landed:
						player.health.value -= 40
						print("HIT")
						hit_landed = true
						deaggro_timer = 7
						if not target:
							target = hit_box.get_overlapping_bodies().get(0)
				if hit_range.get_overlapping_bodies():
					has = false
					animation_player.play("Charge_Attack", -1, 1.85)
					hit_box.position.z = -0.8
					hit_box.get_child(0).disabled = false
				if animation_player.get_current_animation_position() >= 3.22 and animation_player.current_animation == "Charge_Attack":
					state = s.idle
					hit_box.position.z = 0
					hit_box.get_child(0).disabled = true
		s.wonder:
			animation_player.play("Walk", 0.1, 1)
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.05), accel * delta)
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
			if navAgent.is_target_reached():
				velocity.x = 0
				velocity.z = 0
				wonder_timer = wonder_time + (random.randi_range(-(wonder_time - 2), wonder_time + 3))
				if target:
					state = s.flee
				else:
					state = s.idle
	
	move_and_slide()

func crawler(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity
	
	if is_dead:
		world_collider.disabled = true
		await get_tree().create_timer(delta * 80).timeout
		$crawleranimation6/Armature_001/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_stop_simulation()
		await get_tree().create_timer(delta * 1000).timeout
		queue_free()
		return
	
	if cur_health <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		state = s.dead
	
	if state == s.dead:
		$crawleranimation6/Armature_001/Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()
		$crawleranimation6/Armature_002.queue_free()
		var nodes = get_all_children(self)
		for i in nodes.size():
			if nodes.get(i) is PhysicalBone3D:
				nodes.get(i).set_collision_mask_value(1,true)
	
	if not is_dead:
		if not breaks.get("Tongue") < 2 and not breaks.get("Tongue") >= 3:
			$crawleranimation6/Armature_002.visible = false
			var tongue = load("res://Objects/Enemies/tongue.tscn").instantiate()
			self.owner.add_child(tongue)
			tongue.global_position = $Marker3D.global_position
			state = s.flee
			print(tongue.global_position)
			breaks.set("Tongue", breaks.get("Tongue") + 1)
		
		if hearing_close.get_overlapping_bodies():
			if player.noise() > 0:
				target = hearing_close.get_overlapping_bodies().get(0)
				if target:
					deaggro_timer = 7
				if not has:
					state = s.wonder
					has = true
		
		if target:
			deaggro_timer -= delta
		if target and deaggro_timer <= 0:
			state = s.idle
			target = null
		
		if state == s.search:
			$crawleranimation6/Armature_001/Skeleton3D/Cube.set_surface_override_material(0,load("res://Objects/Enemies/hidden_mat.tres"))
			$crawleranimation6/Armature_002/Skeleton3D/Cube_002.set_surface_override_material(0,load("res://Objects/Enemies/hidden_mat.tres"))
		else:
			$crawleranimation6/Armature_001/Skeleton3D/Cube.set_surface_override_material(0,load("res://Objects/Enemies/reg_mat.tres"))
			$crawleranimation6/Armature_002/Skeleton3D/Cube_002.set_surface_override_material(0,load("res://Objects/Enemies/reg_mat.tres"))
		
		if target and state != s.flee and state != s.wonder:
			eyes.look_at(target.position)
			
			attack_cooldown -= delta
			if state != s.attack and state != s.post_attack:
				state = s.chase
			
			if $HitRange2.get_overlapping_bodies() and attack_cooldown <= 0 and state != s.post_attack and state != s.attack and not breaks.get("Tongue") >= 3:
				state = s.post_attack
			
			if state == s.chase and state != s.post_attack:
				if hit_range.get_overlapping_bodies():
					state = s.attack
	
	
	match state:
		s.idle:
			animation_player.play("Idle")
			animation_player.get_child(0).play("Idle3")
			velocity.x = 0
			velocity.z = 0
		
		s.chase:
			animation_player.play("Walk")
			animation_player.get_child(0).play("Walk3")
			navAgent.target_position = target.global_position
			direction = navAgent.get_next_path_position() - global_position
			direction = direction.normalized()
			velocity = velocity.lerp(direction * (speed * 0.7), accel * delta)
			look = lerp(look, global_position - (velocity * 2), delta*10)
			look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP, true)
		
		s.flee:
			velocity.x = 0
			velocity.z = 0
			animation_player.play("Break",0.5)
			if animation_player.current_animation_position >= 2.4 and animation_player.current_animation == "Break":
				state = s.idle
		
		s.attack:
			velocity.x = 0
			velocity.z = 0
			animation_player.play("Melee")
			animation_player.get_child(0).play("Melee3")
			if animation_player.current_animation_position < 0.4:
				rotate_y(deg_to_rad(eyes.rotation.y * 6))
			if animation_player.current_animation_position > 0.56 and animation_player.current_animation_position < 0.67 and not hit_landed:
				if hit_box.get_overlapping_bodies():
					print("HIT")
					player.health.value -= 30
					hit_landed = true
			if animation_player.current_animation_position > 1.2:
				state = s.chase
				hit_landed = false
		
		s.post_attack:
			attack_cooldown = 3
			velocity.x = 0
			velocity.z = 0
			animation_player.play("Lick")
			animation_player.get_child(0).play("Lick3")
			if animation_player.current_animation_position < 0.9:
				rotate_y(deg_to_rad(eyes.rotation.y * 6))
			if animation_player.current_animation_position > 1.05 and animation_player.current_animation_position < 1.3 and not hit_landed:
				if $crawleranimation6/Armature_002/Skeleton3D/PhysicalBoneSimulator3D/Tongue/HitBox.get_overlapping_bodies():
					print("HIT")
					player.health.value -= 25
					hit_landed = true
			if animation_player.current_animation_position > 2.23:
				state = s.chase
				hit_landed = false
		
		s.search:
			animation_player.play("Hidden")
			animation_player.get_child(0).play("Hidden3")
	
		s.wonder:
			animation_player.play("Awaken")
			animation_player.get_child(0).play("Awaken3")
			if target:
				if animation_player.current_animation_position > 1.95:
					state = s.chase
			
	move_and_slide()

func hit(i: int, b: Node) -> void:
	print(b)
	match enemy:
		enemy_type.gob:
			last_known_position = player.global_position
			navAgent.target_position = last_known_position
			state = s.search
		enemy_type.lank:
			if state != s.attack:
				if hit0 < 2:
					target = player
					state = s.chase
				else:
					last_known_position = player.global_position
					state = s.search
			if i == 0:
				hit0 += 1
		enemy_type.crawler:
			if state == s.idle:
				target = player
				state = s.chase
			if state == s.search:
				state = s.wonder
			if b.name == "Tongue" and breaks.get("Tongue") < 2:
				breaks.set("Tongue", breaks.get("Tongue") + 1)

func get_all_children(node) -> Array:
	var nodes : Array = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

func throwable_sound(position: Vector3) -> void:
	if hearing_close:
		if not target:
			match enemy:
				enemy_type.gob:
					if position.distance_to(global_position) <= 5:
						print(position)
						throw_pos = position
					elif position.distance_to(global_position) < 8:
						look_at(Vector3(position.x,global_position.y,position.z))
						animation_tree["parameters/Idle_S/seek_request"] = 0
						wonder_timer = 10

func dummy(delta) -> void:
	pass

func handle_animations(delta) -> void:
	match cur_ani:
		dum.IDLE:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.WALK_F:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),1,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.WALK_B:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),1,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.WALK_L:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),1,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.WALK_R:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),1,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.ATTACK1:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),1,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.ATTACK2:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),1,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.ATTACK3:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),1,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.HIT:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),1,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),0,blend_speed*delta))
		dum.STUNNED:
			animations.set("Walk_F", lerpf(animations.get("Walk_F"),0,blend_speed*delta))
			animations.set("Walk_B", lerpf(animations.get("Walk_B"),0,blend_speed*delta))
			animations.set("Walk_L", lerpf(animations.get("Walk_L"),0,blend_speed*delta))
			animations.set("Walk_R", lerpf(animations.get("Walk_R"),0,blend_speed*delta))
			animations.set("Attack1", lerpf(animations.get("Attack1"),0,blend_speed*delta))
			animations.set("Attack2", lerpf(animations.get("Attack2"),0,blend_speed*delta))
			animations.set("Attack3", lerpf(animations.get("Attack3"),0,blend_speed*delta))
			animations.set("Hit", lerpf(animations.get("Hit"),0,blend_speed*delta))
			animations.set("Stunned", lerpf(animations.get("Stunned"),1,blend_speed*delta))

func update_tree() -> void:
	match enemy:
		enemy_type.gob:
			animation_tree["parameters/Walk_F/blend_amount"] = animations.get("Walk_F")
			animation_tree["parameters/Walk_B/blend_amount"] = animations.get("Walk_B")
			animation_tree["parameters/Walk_L/blend_amount"] = animations.get("Walk_L")
			animation_tree["parameters/Walk_R/blend_amount"] = animations.get("Walk_R")
			animation_tree["parameters/Attack1/blend_amount"] = animations.get("Attack1")
			animation_tree["parameters/Attack2/blend_amount"] = animations.get("Attack2")
			animation_tree["parameters/Attack3/blend_amount"] = animations.get("Attack3")
			animation_tree["parameters/Hit/blend_amount"] = animations.get("Hit")
			animation_tree["parameters/Stunned/blend_amount"] = animations.get("Stunned")

func handle_audio(delta) -> void:
	match enemy:
		enemy_type.gob:
			if cur_ani == dum.WALK_F or cur_ani == dum.WALK_B or cur_ani == dum.WALK_L or cur_ani == dum.WALK_R:
				if audio_timer <= 0:
					$sounds/Step.play()
					audio_timer = 0.5
				else:
					audio_timer -= delta
