extends Node
@onready var item_grid: GridContainer = %ItemGrid
@onready var ranged_weapon_ray: RayCast3D = %RangedWeaponRay
@onready var ranged_weapon_decal_ray: RayCast3D = %RangedWeaponDecalRay
@onready var melee_weapon_ray: RayCast3D = %MeleeWeaponRay
@onready var melee_weapon_ray_decal: RayCast3D = %MeleeWeaponRayDecal
@onready var interaction_controller: Node = %InteractionController
@onready var weapon_hand: Marker3D = %WeaponHand
@onready var camera_controller: CameraController = $"../CameraController"
@onready var shotgun_rays: Node3D = $"../CameraController/Camera3D/ShotgunRays"

var shotgun_spread: Vector2
@onready var player: Player = $".."
var animation_player: AnimationPlayer
@onready var arm_ani: AnimationPlayer = $"../CameraController/SubViewportContainer/SubViewport/WeaponCam/Arms/ArmPlacement/arms2/AnimationPlayer"

var right_click_pen: bool = false
var right_click_per: float
#ranged
var og_weapon_hand_position: Vector3
var equipped_data: WeaponData
var equipped_prefab: Node3D
var fire_rate: float
var fire_rate_locked: bool = false
var reload_time: float
var reload_lock: bool = false
var vertical_recoil: float
var revolver_delay: float = 1
var revolver_fired: bool = false
var cylinder_open: bool = false
var ads: bool = false
var missing_bulltes
var rev_bullets
var rev_hammer: Node
var double_shells
var shotgun_array: Array[Node]
var shotgun_array_d: Array[Node]
#melee
var swing_lock: bool = false
var swing_delay: float
var swing_recovery: float
var swing_recovery_lock: bool = false
@onready var melee_hit_box: Area3D = $"../CameraController/Camera3D/MeleeHitBox"
var block_rec: bool = false
var block_str: float = 0
var is_blocking: bool = false
var heavy_timer: float
var heavy_lock: bool = false
var heavy_ready: bool = false
var heavy_ready_pos: Vector3
var swing_dmg: float
var swing_crit_dmg: float
var swing_stagger_dmg: float
var load: int

var swing_stag: float
var breakable_dmg: float

func _ready() -> void:
	item_grid.connect("set_weapon_data", Callable(self, "_on_weapon_equipped"))
	item_grid.connect("remove_equip_data", Callable(self, "_on_unequip"))
	og_weapon_hand_position= weapon_hand.position
	heavy_ready_pos = weapon_hand.position + Vector3(0,0.5,0)

func _process(delta: float) -> void:
	if fire_rate_locked == true:
		fire_rate -= delta
		if fire_rate <= 0:
			fire_rate_locked = false
	if reload_lock == true:
		reload_time -= delta
		if reload_time <= 0:
			equipped_data.cur_ammo = load
			reload_lock = false
			print("RELOADED")
	
	if interaction_controller.closed_hand_rect.visible:
		return
	if equipped_data:
		if equipped_data.is_revolver:
			rev_hammer.rotation.x = lerp(rev_hammer.rotation.x, 0.0, delta * 10)
		if equipped_data.is_ranged:
			if equipped_data.manual_cycle:
					if Input.is_action_just_pressed("reload") and equipped_data.cur_ammo > 0 and not Input.is_action_pressed("right_click") and not Input.is_action_pressed("check_ammo") and not animation_player.current_animation:
						animation_player.play("cycle")
						equipped_data.manual_cycle_loaded = true
						equipped_data.cur_ammo-=1
					if Input.is_action_just_pressed("reload") and Input.is_action_pressed("check_ammo") and equipped_data.cur_ammo < equipped_data.max_ammo and not equipped_data.manual_load:
						load = 0
						print(equipped_data.ammo_type)
						for i in item_grid.slot_data.size():
							if item_grid.slot_data.get(i) and item_grid.slot_data.get(i).data:
								if item_grid.slot_data.get(i).data.name == equipped_data.ammo_type:
									print(item_grid.slot_data.get(i).data.name)
									if int(item_grid.slot_data.get(i).quantity.text) >= equipped_data.max_ammo:
										item_grid.slot_data.get(i).quantity.text = str( int(item_grid.slot_data.get(i).quantity.text) - (equipped_data.max_ammo - load))
										load = equipped_data.max_ammo
										print("RELOAD IF")
										if int(item_grid.slot_data.get(i).quantity.text) <= 0:
											item_grid.slot_data.get(i).queue_free()
										break
									else:
										print("RELOAD ELSE")
										load += int(item_grid.slot_data.get(i).quantity.text)
										item_grid.slot_data.get(i).queue_free()
										
									print(item_grid.slot_data.get(i).quantity.text)
									
						if equipped_data.cur_ammo < equipped_data.max_ammo and load > 0:
							print(load)
							animation_player.play("reload")
							print("RELOADING")
							reload_time = equipped_data.reload_time
							reload_lock = true
			
			if Input.is_action_just_pressed("reload") and equipped_data.manual_load == false and camera_controller.is_inv_open == false and equipped_data.manual_cycle == false:
				load = 0
				print(equipped_data.ammo_type)
				for i in item_grid.slot_data.size():
					if item_grid.slot_data.get(i) and item_grid.slot_data.get(i).data:
						if item_grid.slot_data.get(i).data.name == equipped_data.ammo_type:
							print(item_grid.slot_data.get(i).data.name)
							if int(item_grid.slot_data.get(i).quantity.text) >= equipped_data.max_ammo:
								item_grid.slot_data.get(i).quantity.text = str( int(item_grid.slot_data.get(i).quantity.text) - (equipped_data.max_ammo - load))
								load = equipped_data.max_ammo
								print("RELOAD IF")
								if int(item_grid.slot_data.get(i).quantity.text) <= 0:
									item_grid.slot_data.get(i).queue_free()
								break
							else:
								print("RELOAD ELSE")
								load += int(item_grid.slot_data.get(i).quantity.text)
								item_grid.slot_data.get(i).queue_free()
								
							print(item_grid.slot_data.get(i).quantity.text)
							
				if equipped_data.cur_ammo < equipped_data.max_ammo and load > 0:
					print(load)
					animation_player.play("reload")
					print("RELOADING")
					reload_time = equipped_data.reload_time
					reload_lock = true
			if Input.is_action_pressed("right_click") and camera_controller.is_inv_open == false and reload_lock == false:
				ads = true
				if (equipped_data.is_revolver or equipped_data.weapon_name == "double_barrel") and cylinder_open == true:
					return
				weapon_hand.position = lerp(weapon_hand.position, equipped_data.ads_position, delta * equipped_data.ads_speed)
				weapon_hand.rotation = lerp(weapon_hand.rotation, Vector3.ZERO, delta * equipped_data.ads_speed)
				if equipped_data.is_revolver:
					if Input.is_action_pressed("left_click") and equipped_data.cur_ammo != 0 and revolver_fired == false:
						revolver_delay -= delta * 6
						var hammer_rotation = ((1 - revolver_delay) * 100) * 0.75
						rev_hammer.rotation.x = lerp(rev_hammer.rotation.x, hammer_rotation, delta)
						rev_hammer.rotation.x = clamp(rev_hammer.rotation.x, deg_to_rad(0), deg_to_rad(75))
						if revolver_delay <= 0:
							animation_player.play("fire")
							rev_hammer.rotation.x = 0
							rev_bullets.get(equipped_data.cur_ammo - 1).visible = false
							vertical_recoil = randf_range(-equipped_data.recoil.x, equipped_data.recoil.x)
							camera_controller.add_recoil(vertical_recoil,equipped_data.recoil.y,equipped_data.recoil_recovery,equipped_data.recoil_add_speed)
							equipped_data.cur_ammo -= 1
							if ranged_weapon_decal_ray.is_colliding() and not ranged_weapon_decal_ray.get_collider().is_in_group("enemy"):
								print(ranged_weapon_decal_ray.get_collision_point())
							if ranged_weapon_ray.is_colliding():
								if ranged_weapon_ray.get_collider().is_in_group("breakable"):
									print(ranged_weapon_ray.get_collider().hp)
									ranged_weapon_ray.get_collider().hp -= equipped_data.damage
								var enemy = _get_enemy_root(ranged_weapon_ray.get_collider())
								if enemy and enemy.is_in_group("enemy"):
									if ranged_weapon_ray.get_collider().has_node("Head"):
										print("CRIT")
										enemy.hit(0,ranged_weapon_ray.get_collider())
										enemy.cur_health -= equipped_data.crit_damage
										enemy.cur_stagger += equipped_data.stagger_dmg
									elif ranged_weapon_ray.get_collider().has_node("Armor"):
										print("BLOCKED")
										enemy.hit(3,ranged_weapon_ray.get_collider())
									elif ranged_weapon_ray.get_collider().has_node("Break"):
										print("BREAK")
									else:
										print("HIT")
										enemy.hit(3,ranged_weapon_ray.get_collider())
										enemy.cur_health -= equipped_data.damage
							revolver_fired = true
					if Input.is_action_just_released("left_click"):
						revolver_delay = 1
						revolver_fired = false
				
				if equipped_data.is_shotgun:
					if Input.is_action_just_pressed("left_click") and equipped_data.cur_ammo > 0:
						equipped_data.cur_ammo-=1
						vertical_recoil = randf_range(-equipped_data.recoil.x, equipped_data.recoil.x)
						camera_controller.add_recoil(vertical_recoil,equipped_data.recoil.y,equipped_data.recoil_recovery,equipped_data.recoil_add_speed)
						if double_shells.get(1).visible:
							double_shells.get(1).visible = false
						elif double_shells.get(0).visible:
							double_shells.get(0).visible = false
						for i in shotgun_array.size():
							if i == 0:
								if shotgun_array.get(i).is_colliding():
									print(i)
							else:
								shotgun_spread.x = randf_range(-0.016,0.016)
								shotgun_spread.y = randf_range(-0.016,0.016)
								shotgun_array.get(i).rotation.x = shotgun_spread.x
								shotgun_array.get(i).rotation.y = shotgun_spread.y
								shotgun_array_d.get(i).rotation = shotgun_array.get(i).rotation
							if shotgun_array_d.get(i).is_colliding() and not shotgun_array_d.get(i).get_collider().is_in_group("enemy"):
								print(shotgun_array_d.get(i).get_collision_point())
							if shotgun_array.get(i).is_colliding():
								print(i)
								if shotgun_array.get(i).get_collider().is_in_group("breakable"):
									shotgun_array.get(i).get_collider().hp -= equipped_data.damage
								var enemy = _get_enemy_root(shotgun_array.get(i).get_collider())
								if enemy and enemy.is_in_group("enemy"):
									if shotgun_array.get(i).get_collider().has_node("Head"):
										print("CRIT") 
										enemy.hit(0,shotgun_array.get(i).get_collider())
										enemy.cur_health -= equipped_data.crit_damage
										enemy.cur_stagger += equipped_data.stagger_dmg
									elif shotgun_array.get(i).get_collider().has_node("Armor"):
										print("BLOCKED")
									else:
										print("HIT")
										enemy.hit(0,shotgun_array.get(i).get_collider())
										enemy.cur_health -= equipped_data.damage
				
				if equipped_data.semi_auto:
					if Input.is_action_just_pressed("left_click") and fire_rate_locked == false and ((equipped_data.cur_ammo > 0 and equipped_data.manual_cycle == false) or equipped_data.manual_cycle_loaded):
						vertical_recoil = randf_range(-equipped_data.recoil.x, equipped_data.recoil.x)
						camera_controller.add_recoil(vertical_recoil,equipped_data.recoil.y,equipped_data.recoil_recovery,equipped_data.recoil_add_speed)
						animation_player.play("fire")
						if not equipped_data.manual_cycle:
							equipped_data.cur_ammo -= 1
						equipped_data.manual_cycle_loaded = false
						if ranged_weapon_decal_ray.is_colliding() and not ranged_weapon_decal_ray.get_collider().is_in_group("enemy"):
							print(ranged_weapon_decal_ray.get_collision_point())
						if ranged_weapon_ray.is_colliding():
							if ranged_weapon_ray.get_collider().is_in_group("breakable"):
								print(ranged_weapon_ray.get_collider().hp)
								ranged_weapon_ray.get_collider().hp -= equipped_data.damage
							var enemy = _get_enemy_root(ranged_weapon_ray.get_collider())
							if enemy and enemy.is_in_group("enemy"):
								print(enemy.cur_health)
								if ranged_weapon_ray.get_collider().has_node("Head"):
									print("CRIT") 
									enemy.hit(0,ranged_weapon_ray.get_collider())
									enemy.cur_health -= equipped_data.crit_damage
									enemy.cur_stagger += equipped_data.stagger_dmg
								elif ranged_weapon_ray.get_collider().has_node("Armor"):
									print("BLOCKED")
									enemy.hit(3,ranged_weapon_ray.get_collider())
								else:
									print("HIT")
									enemy.hit(3,ranged_weapon_ray.get_collider())
									enemy.cur_health -= equipped_data.damage
							fire_rate_locked = true
							fire_rate = equipped_data.fire_rate
			
			else:
				ads = false
				weapon_hand.position = lerp(weapon_hand.position, og_weapon_hand_position, delta * equipped_data.ads_speed)
				weapon_hand.rotation = lerp(weapon_hand.rotation, Vector3(deg_to_rad(-20),0,0), delta * equipped_data.ads_speed)
			
			if Input.is_action_just_pressed("check_ammo") and not Input.is_action_pressed("right_click") and camera_controller.is_inv_open == false:
				if equipped_data.is_revolver and cylinder_open == true:
					animation_player.play_backwards("check_ammo")
					cylinder_open = false
				elif equipped_data.is_revolver and cylinder_open == false:
					animation_player.play("check_ammo")
					cylinder_open = true
				if equipped_data.weapon_name == "double_barrel" and cylinder_open == false:
					print(equipped_data.cur_ammo)
					animation_player.play("open_chamber")
					cylinder_open = true
				elif equipped_data.weapon_name == "double_barrel" and cylinder_open == true:
					animation_player.play_backwards("open_chamber")
					cylinder_open = false
				if not equipped_data.manual_load:
					player.rich_text_label.pop_up_text(str(equipped_data.cur_ammo), 1.2)
				
			if cylinder_open and equipped_data.is_revolver and camera_controller.is_inv_open == false:
				for i in range(equipped_data.cur_ammo):
						rev_bullets.get(i).visible = true
				if Input.is_action_just_pressed("left_click") and equipped_data.cur_ammo < equipped_data.max_ammo:
					
					for i in item_grid.slot_data.size():
						if item_grid.slot_data.get(i) and item_grid.slot_data.get(i).data:
							if item_grid.slot_data.get(i).data.name == equipped_data.ammo_type:
								item_grid.slot_data.get(i).quantity.text = str( int(item_grid.slot_data.get(i).quantity.text) - 1)
								if int(item_grid.slot_data.get(i).quantity.text) <= 0:
									item_grid.slot_data.get(i).queue_free()
								equipped_data.cur_ammo += 1
								print(item_grid.slot_data.get(i).data.name)
			
			if cylinder_open and equipped_data.weapon_name == "double_barrel" and camera_controller.is_inv_open == false:
				if Input.is_action_just_pressed("left_click") and equipped_data.cur_ammo < equipped_data.max_ammo:
					for i in item_grid.slot_data.size():
						if item_grid.slot_data.get(i) and item_grid.slot_data.get(i).data:
							if item_grid.slot_data.get(i).data.name == equipped_data.ammo_type:
								item_grid.slot_data.get(i).quantity.text = str( int(item_grid.slot_data.get(i).quantity.text) - 1)
								if int(item_grid.slot_data.get(i).quantity.text) <= 0:
									item_grid.slot_data.get(i).queue_free()
								equipped_data.cur_ammo += 1
								if not double_shells.get(1).visible:
									double_shells.get(1).visible = true
								elif not double_shells.get(0).visible:
									double_shells.get(0).visible = true
								print(item_grid.slot_data.get(i).data.name)
		
		if equipped_data.is_melee:
			handel_melee()
	else:
		arm_ani.play("Idle")

func _on_weapon_equipped(weapon_data: WeaponData, prefab: Node3D):
	print("this one " , weapon_data.fire_rate)
	equipped_data = weapon_data
	equipped_prefab = prefab
	right_click_pen = true
	right_click_per = equipped_data.right_click_pen
	if weapon_data.is_melee:
		melee_weapon_ray.target_position.z = -weapon_data.range
		breakable_dmg = weapon_data.breakable_dmg
		swing_dmg = weapon_data.light_damage
		swing_crit_dmg = weapon_data.light_crit_damage
		$"../CameraController/Camera3D/MeleeHitBox/MeleeHitBox".shape.radius = weapon_data.hitbox_d.x
		$"../CameraController/Camera3D/MeleeHitBox/MeleeHitBox".shape.height = weapon_data.hitbox_d.y
		$"../CameraController/Camera3D/MeleeHitBox/MeleeHitBox".position = weapon_data.hitbox_t
		
	if weapon_data.has_block:
		block_str = weapon_data.block_str
	if weapon_data.weapon_name == "revolver":
		rev_bullets = equipped_prefab.get_child(0).get_child(0).get_child(0).get_child(0).get_child(0).get_children()
		rev_hammer = equipped_prefab.get_child(0).get_child(0).get_child(3)
		cylinder_open = false
	if weapon_data.weapon_name == "double_barrel":
		pass
		shotgun_array = shotgun_rays.get_children()
		double_shells = equipped_prefab.get_child(0).get_child(0).get_children()
		double_shells.remove_at(-1)
		print("ASdasdasdasdasd",double_shells)
		#cylinder_open = false
	if weapon_data.is_shotgun:
		for i in shotgun_array.size():
			i += 1
			if i < shotgun_array.size():
				shotgun_array_d.append(shotgun_array.get(i))
				shotgun_array.remove_at(i)
	set_animations(prefab)

func _on_unequip():
	$"../CameraController/SubViewportContainer/SubViewport/WeaponCam/Arms/ArmPlacement".remove_child($"../CameraController/SubViewportContainer/SubViewport/WeaponCam/Arms/ArmPlacement".get_child(-1))
	equipped_data = null
	right_click_pen = false
	melee_weapon_ray.target_position.z = 0
	$"../CameraController/Camera3D/MeleeHitBox/MeleeHitBox".shape.radius = 0.001
	$"../CameraController/Camera3D/MeleeHitBox/MeleeHitBox".shape.height = 0.001
	$"../CameraController/Camera3D/MeleeHitBox/MeleeHitBox".position = Vector3.ZERO

func _get_enemy_root(node) -> Node:
	if node.get_parent() and not node is CharacterBody3D:
		node = node.get_parent()
	else:
		return node
	return _get_enemy_root(node)

func set_animations(prefab: Node3D) -> void:
	match equipped_data.weapon_name: 
		"pipe":
			arm_ani.play("Pipe_I")
			animation_player = prefab.get_child(0).get_child(1)
			prefab.get_child(0).position = Vector3.ZERO
			prefab.get_child(0).position = Vector3.ZERO
			prefab.get_child(0).scale = Vector3(1,1,1)
			prefab.get_child(0).get_child(0).position = Vector3(-3.42,-2.837,-2.862)
			prefab.get_child(0).get_child(0).rotation = Vector3(deg_to_rad(60.4),deg_to_rad(22.2),deg_to_rad(29.8))
			prefab.get_child(0).get_child(0).scale = Vector3(1,1,1)
			prefab.get_child(0).get_child(0).get_child(0).position = Vector3.ZERO
			prefab.get_child(0).get_child(0).get_child(0).rotation = Vector3.ZERO
			prefab.get_child(0).get_child(0).get_child(0).scale = Vector3(1,1,1)
			prefab.get_child(0).get_child(0).get_child(0).get_child(0).set_layer_mask_value(2, true)
			prefab.get_child(0).get_child(0).get_child(0).get_child(0).set_layer_mask_value(1, false)
			prefab.get_child(0).get_child(0).get_child(0).show_rest_only = false
			prefab.get_child(0).get_child(1).active = true
			prefab.get_child(0).get_child(1).play("Pipe_I_001")
			print(prefab.position)
			$"../CameraController/SubViewportContainer/SubViewport/WeaponCam/Arms/ArmPlacement".add_child(prefab)

func handel_melee() -> void:
		match equipped_data.weapon_name:
			"pipe":
				if not camera_controller.is_inv_open:
					if not arm_ani.current_animation:
						animation_player.play("Pipe_I_001")
						arm_ani.play("Pipe_I")
						block_rec = false
					if Input.is_action_just_pressed("left_click") and not block_rec and player.stamina.value > 0:
						swing_lock = false
						if arm_ani.current_animation == "Pipe_A1" and arm_ani.current_animation_position > 0.42 and arm_ani.current_animation_position < 0.6:
							animation_player.play("Pipe_A2_001-Armature")
							arm_ani.play("Pipe_A2")
							player.stamina.value -= equipped_data.light_stamina_cost
							player.can_regen = false
							player.s_timer = 0
						elif not arm_ani.current_animation == "Pipe_A2" and not arm_ani.current_animation == "Pipe_A1":
							animation_player.play("Pipe_A1_001-Armature")
							arm_ani.play("Pipe_A1")
							player.stamina.value -= equipped_data.light_stamina_cost
							player.can_regen = false
							player.s_timer = 0
					if Input.is_action_pressed("right_click") and arm_ani.current_animation != "Pipe_A1" and arm_ani.current_animation != "Pipe_A2":
						if arm_ani.current_animation == "Pipe_B" and arm_ani.current_animation_position > 0.29:
							is_blocking = true
						if arm_ani.current_animation == "Pipe_B" and arm_ani.current_animation_position > 0.38:
							animation_player.pause()
							arm_ani.pause()
						if not arm_ani.current_animation == "Pipe_B":
							block_rec = true
							animation_player.play("Pipe_B_001-Armature", -1, 2)
							arm_ani.play("Pipe_B", -1, 2)
					if Input.is_action_just_released("right_click") and arm_ani.current_animation == "Pipe_B":
						is_blocking = false
						animation_player.play_backwards()
						arm_ani.play_backwards()
					if is_blocking:
						player.can_regen = false
						player.s_timer = 0
				if arm_ani.current_animation == "Pipe_A1" and arm_ani.current_animation_position > 0.25 and arm_ani.current_animation_position < 0.27:
					melee_swing_hit()
				if arm_ani.current_animation == "Pipe_A2" and arm_ani.current_animation_position > 0.265 and arm_ani.current_animation_position < 0.28:
					melee_swing_hit()

func melee_swing_hit() -> void:
	if melee_weapon_ray.is_colliding() and not swing_lock:
		if melee_weapon_ray.get_collider().is_in_group("breakable"):
			if breakable_dmg >= melee_weapon_ray.get_collider().dmg_threshold:
					print(melee_weapon_ray.get_collider().hp)
					swing_lock = true
					melee_weapon_ray.get_collider().hp -= swing_dmg
		var enemy = _get_enemy_root(melee_weapon_ray.get_collider())
		if enemy and enemy.is_in_group("enemy"):
				if melee_weapon_ray.get_collider().has_node("Head"):
					print("CRIT")
					swing_lock = true
					enemy.hit(0,melee_weapon_ray.get_collider())
					enemy.cur_health -= swing_crit_dmg
					enemy.cur_stagger += swing_stag
				elif melee_weapon_ray.get_collider().has_node("Armor"):
					print("BLOCKED")
					swing_lock = true
					enemy.hit(3,melee_weapon_ray.get_collider())
					enemy.cur_stagger += swing_stag
				else:
					print("HIT")
					swing_lock = true
					enemy.hit(3,melee_weapon_ray.get_collider())
					enemy.cur_health -= swing_dmg
					enemy.cur_stagger += swing_stag
					print(enemy.cur_health)
	elif melee_hit_box.get_overlapping_bodies() and not swing_lock:
		print("ASDASDASD")
		if melee_hit_box.get_overlapping_bodies().get(0).is_in_group("breakable"):
			if breakable_dmg >= melee_hit_box.get_overlapping_bodies().get(0).dmg_threshold:
				print(melee_hit_box.get_overlapping_bodies().get(0).hp)
				swing_lock = true
				melee_hit_box.get_overlapping_bodies().get(0).hp -= swing_dmg
		var enemy = _get_enemy_root(melee_hit_box.get_overlapping_bodies().get(0))
		if enemy and enemy.is_in_group("enemy"):
			if melee_hit_box.get_overlapping_bodies().get(0).has_node("Armor"):
				print("BLOCKED")
				swing_lock = true
				enemy.hit(3,melee_hit_box.get_overlapping_bodies().get(0))
				enemy.cur_stagger += swing_stag
			else:
				print("HIT")
				swing_lock = true
				enemy.hit(3,melee_hit_box.get_overlapping_bodies().get(0))
				enemy.cur_health -= swing_dmg
				enemy.cur_stagger += swing_stag
			print(enemy.cur_health)
