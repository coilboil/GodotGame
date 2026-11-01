extends GridContainer

@onready var context_menu: PopupMenu = PopupMenu.new()
@onready var player: Player = $"../../.."
@onready var weapon_hand: Marker3D = %WeaponHand
@onready var inventory: PanelContainer = %Inventory


const SLOT_SIZE: int = 32
@export var inventory_slot_scene: PackedScene
@export var dimentions: Vector2i
var slot_data: Array[Node] = []
var held_item_intersects: bool = false
var equipped_item: Node = null
var wep_instance: Node3D
var key_chain: Array[String] = []
var hot_bar: Array[int] = [-1,-1,-1,-1]

signal set_weapon_data(weapon_data, weapon_prefab)
signal remove_equip_data()

func _ready() -> void:
	create_slots()
	init_slot_data()
	add_child(context_menu)
	context_menu.connect("id_pressed", Callable(self, "_on_context_menu_selected"))

func create_slots() -> void:
	self.columns = dimentions.x
	for y in dimentions.y:
		for x in dimentions.x:
			var inventory_slot = inventory_slot_scene.instantiate()
			add_child(inventory_slot)

func _input(event: InputEvent) -> void:
	if not slot_data[hot_bar.get(0)]:
		hot_bar.set(0,-1)
	if not slot_data[hot_bar.get(1)]:
		hot_bar.set(1,-1)
	if not slot_data[hot_bar.get(2)]:
		hot_bar.set(2,-1)
	if not slot_data[hot_bar.get(3)]:
		hot_bar.set(3,-1)
	
	if Input.is_action_just_pressed("hotbar1"):
		print(hot_bar.get(0))
		if slot_data[hot_bar.get(0)]:
			equip_item(slot_data[hot_bar.get(0)])
	if Input.is_action_just_pressed("hotbar2"):
		print(hot_bar.get(1))
		if slot_data[hot_bar.get(1)]:
			equip_item(slot_data[hot_bar.get(1)])
	if Input.is_action_just_pressed("hotbar3"):
		print(hot_bar.get(2))
		if slot_data[hot_bar.get(2)]:
			use_item(slot_data[hot_bar.get(2)])
	if Input.is_action_just_pressed("hotbar4"):
		print(hot_bar.get(3))
		if slot_data[hot_bar.get(3)]:
			use_item(slot_data[hot_bar.get(3)])

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var held_item = get_tree().get_first_node_in_group("held_item")
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			if !held_item:
				var slot_index = get_slot_index_from_coords(get_global_mouse_position())
				var item = slot_data[slot_index]
				if !item:
					return
				item.get_picked_up()
				remove_item_from_slot_data(item)
			else:
				if !held_item_intersects: return
				var offset = Vector2(SLOT_SIZE, SLOT_SIZE) /2
				var index = get_slot_index_from_coords(held_item.anchor_point + offset)
				check_for_border(index,held_item)
				var items = items_in_area(index, held_item.data.dimentions)
				if items.size():
					if held_item.data.name == items[0].data.name:
							if (int(held_item.quantity.text) + int(items[0].quantity.text)) <= items[0].data.max_quant:
								items[0].updata_quantity(int(held_item.quantity.text))
								held_item.queue_free()
								return
					if items.size() == 1:
						held_item.get_placed(get_coords_from_slot_index(index))
						remove_item_from_slot_data(items[0])
						add_item_to_slot_data(index, held_item)
						items[0].get_picked_up()
					return
				held_item.get_placed(get_coords_from_slot_index(index))
				add_item_to_slot_data(index, held_item)
		if event.button_index == MOUSE_BUTTON_MIDDLE && event.is_pressed() and !held_item:
			var slot_index = get_slot_index_from_coords(get_global_mouse_position())
			var item = slot_data[slot_index]
			if !item:
				return
			drop_item(item)
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed() and !held_item:
			var slot_index = get_slot_index_from_coords(get_global_mouse_position())
			var item = slot_data[slot_index]
			if !item:
				return
			_on_item_right_clicked(slot_index)
	if event is InputEventMouseMotion: 
		var held_item = get_tree().get_first_node_in_group("held_item")
		if held_item:
			detect_held_item_intersection(held_item)

func detect_held_item_intersection(held_item: Node) -> void:
	var h_rect = Rect2(held_item.anchor_point,held_item.size)
	var g_rect = Rect2(global_position, size)
	var inter = h_rect.intersection(g_rect).size
	held_item_intersects = (inter.x * inter.y) / (held_item.size.x * held_item.size.y) > 0.8

func remove_item_from_slot_data(item: Node) -> void:
	for i in slot_data.size():
		if slot_data[i] == item:
			slot_data[i] = null

func check_for_border(index: int,item: Node) -> void:
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			print(index + x + y * columns)

func add_item_to_slot_data(index: int,item: Node) -> void:
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slot_data[index + x + y * columns] = item

func items_in_area(index: int, item_dimentions: Vector2i) -> Array:
	var items: Dictionary = {}
	var fault: int = slot_data.size()
	for y in item_dimentions.y:
		for x in item_dimentions.x:
			var slot_index = index + x + y * columns
			var item = slot_data[slot_index]
			if !item:
				continue
			if !items.has(item):
				items[item] = true

	return items.keys() if items.size() else []

func init_slot_data() -> void:
	slot_data.resize(dimentions.x * dimentions.y)
	slot_data.fill(null)

func is_not_full(item: ItemData) -> bool:
	var slot_index: int = 0
	while slot_index < slot_data.size():
		if item_fits(slot_index, item.dimentions):
			break
		slot_index += 1
	if slot_index >= slot_data.size():
		return false
	return true

func attempt_to_add_item_data(item: Node) -> bool:
	var slot_index: int = 0
	while slot_index < slot_data.size():
		if item_fits(slot_index, item.data.dimentions):
			break
		slot_index += 1
	if slot_index >= slot_data.size():
		return false
	
	for y in item.data.dimentions.y:
		for x in item.data.dimentions.x:
			slot_data[slot_index + x + y * columns] = item
	
	item.set_init_position(get_coords_from_slot_index(slot_index))
	return true

func item_fits(index: int, dimentions: Vector2i) -> bool:
	for y in dimentions.y:
		for x in dimentions.x:
			var curr_index = index + x + y * columns
			if curr_index >= slot_data.size():
				return false
			if slot_data[curr_index] != null:
				return false
			var split: bool = index / columns != (index + x) / columns
			if split:
				return false
	return true

func get_slot_index_from_coords(coords: Vector2i) -> int:
	coords -= Vector2i(self.global_position)
	coords = coords / SLOT_SIZE
	var index = coords.x + coords.y * columns
	if index > dimentions.x * dimentions.y || index < 0:
		return - 1
	if index >= slot_data.size():
		return -1
	return index

func get_coords_from_slot_index(index: int) -> Vector2i:
	var row = index / columns
	var column = index % columns
	return Vector2i(global_position) + Vector2i(column * SLOT_SIZE, row * SLOT_SIZE)

func _on_item_right_clicked(slot_index: int) -> void:
	var slot = slot_data[slot_index]
	if slot == null:
		return
	context_menu.clear()
	match slot.data.action_data.action_type:
		1:#consumable
			context_menu.add_item("Use", 1)
			context_menu.add_item("Drop", 0)
			context_menu.add_item("Bind to 3", 6)
			context_menu.add_item("Bind to 4", 7)
		2:#equippable
			context_menu.add_item("Equip", 2)
			context_menu.add_item("Drop", 0)
			context_menu.add_item("Bind to 1", 4)
			context_menu.add_item("Bind to 2", 5)
		3:#inspectable
			context_menu.add_item("View", 3)
			context_menu.add_item("Drop", 0)
		0: #default
			context_menu.add_item("Drop", 0)
	context_menu.set_meta("slot_index", slot_index)
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var rect: Rect2i = Rect2i(mouse_pos.floor(), Vector2i(1,1))
	context_menu.popup(rect)

func _on_context_menu_selected(id_pressed: int) -> void:
	var slot_index = context_menu.get_meta("slot_index")
	var item = slot_data[slot_index]
	match id_pressed:
		0:
			print("Drop")
			drop_item(item)
		1:
			print("Use")
			use_item(item)
		2:
			print("Equip")
			equip_item(item)
		3:
			print("View")
		4:
			hot_bar.set(0,slot_index)
			print(slot_index)
		5:
			hot_bar.set(1,slot_index)
			print(slot_index)
		6:
			hot_bar.set(2,slot_index)
			print(slot_index)
		7:
			hot_bar.set(3,slot_index)
			print(slot_index)

func drop_item(item: Node) -> void:
	if item == equipped_item:
		print("YAUPPERS")
		emit_signal("remove_equip_data")
	var instance
	if item.data.quant:
		instance = item.data.item_model_prefab.instantiate() as Node3D
		instance.quant = int(item.get_child(-1).text)
	else:
		if item.data.max_quant > 1:
			if int(item.quantity.text) > 1:
				print("STACKABLE")
				var path: String = str("res://Objects/", item.data.name, "[",     item.quantity.text     ,"].tscn")
				print(path)
				load(path)
				print("res://Objects/", item.data.name, "[",     item.quantity.text     ,"].tscn")
				instance = load(path).instantiate() as Node3D
			else:
				instance = item.data.item_model_prefab.instantiate() as Node3D
		else:
			instance = item.data.item_model_prefab.instantiate() as Node3D
	#fowrad check
	var drop_distance: float = 1.8
	var forward_dir: Vector3 = -player.camera_controller.global_transform.basis.z.normalized()
	var target_pos: Vector3 = player.camera_controller.global_transform.origin + forward_dir * drop_distance
	var space_state = player.camera_controller.interaction_controller.hand.get_world_3d().direct_space_state
	#collision check 
	var obstacle_params = PhysicsRayQueryParameters3D.new()
	obstacle_params.from = player.camera_controller.global_transform.origin
	obstacle_params.to = target_pos
	obstacle_params.exclude = [player.camera_controller]
	var obstecle_hit: Dictionary = space_state.intersect_ray(obstacle_params)
	if obstecle_hit:
		print("Nuh Uh")
		return
	#ground check
	var ground_params = PhysicsRayQueryParameters3D.new()
	ground_params.from = target_pos + Vector3.UP * 2.0
	ground_params.to = target_pos - Vector3.UP * 5.0 
	ground_params.exclude = [player.camera_controller]
	var ground_hit: Dictionary = space_state.intersect_ray(ground_params)
	if not ground_hit:
		print("Nuh Uh Uh")
		return
	
	var ground_pos: Vector3 = ground_hit.position
	var buffer_height: float = 0.2
	get_tree().current_scene.add_child(instance)
	item.queue_free()
	instance.global_transform.origin = target_pos + Vector3.UP * buffer_height
	if equipped_item == item:
		equipped_item = null
		weapon_hand.remove_child(weapon_hand.get_child(-1))

func use_item(item: Node) -> void:
	var item_mod = item.data.action_data.modifier_name
	var item_mod_val = item.data.action_data.modifier_value
	match item_mod:
		"health":
			player.health.value += item_mod_val
			print(item_mod_val)
			if int(item.quantity.text) > 1:
				item.quantity.text = str(int(item.quantity.text) - 1)
				if int(item.quantity.text) == 1:
					item.update_label()
			else:
				item.queue_free()

func equip_item(item: Node) -> void:
	weapon_hand.get_child(0)
	if equipped_item == item:
		print("already equipped")
		return
	equipped_item = item
	wep_instance = item.data.item_model_prefab.instantiate() as Node3D
	var col = wep_instance.find_child("CollisionShape3D", true, false)
	if col:
		col.get_parent().remove_child(col)
		col.queue_free()
	var lock: bool = true
	var counter = 0
	var children = get_all_children(wep_instance)
	for i in children.size():
		if children.get(i) is MeshInstance3D:
			print(children.get(i))
			children.get(i).set_layer_mask_value(1, false)
			children.get(i).set_layer_mask_value(2, true)
	
		
	emit_signal("set_weapon_data", wep_instance.get_child(-1).item_data.action_data.weapon_data, wep_instance)

func get_all_children(node) -> Array:
	var nodes : Array = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

func add_key(key_name: String) -> void:
	key_chain.append(key_name)
