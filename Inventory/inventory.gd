extends PanelContainer


@export var items: Array[ItemData] = []
@export var inventory_item_scene: PackedScene
@onready var item_grid: GridContainer = %ItemGrid
@onready var inventory: PanelContainer = %Inventory
@onready var camera_controller: CameraController = $"../../CameraController"

var interaction_controller
var item_grid_size: Vector2
var item_grid_pos: Vector2
var border: Vector2
var in_grid: bool = true

func _ready() -> void:
	item_grid_size = item_grid.size
	item_grid_pos = item_grid.global_position
	border.x = item_grid_pos.x + item_grid_size.x
	border.y = item_grid_pos.y + item_grid_size.y
	print(item_grid_pos)
	print(border)
	interaction_controller = %InteractionController
	for i in items:
		add_item(i)

func _input(event: InputEvent) -> void:
	if camera_controller.is_inv_open:
		var held_item = get_tree().get_first_node_in_group("held_item")
		if Input.is_action_just_pressed("left_click"):
			if held_item and not in_grid:
				print(held_item)
				item_grid.drop_item(held_item)
		if not in_grid:
			if get_global_mouse_position().x > item_grid_pos.x and get_global_mouse_position().x < border.x:
				if get_global_mouse_position().y > item_grid_pos.y and get_global_mouse_position().y < border.y:
					in_grid = true
		else:
			if (get_global_mouse_position().x < item_grid_pos.x or get_global_mouse_position().x > border.x) or get_global_mouse_position().y < item_grid_pos.y or get_global_mouse_position().y > border.y:
				in_grid = false

func add_item(item_data: ItemData) -> void:
	for i in item_grid.slot_data.size():
		if item_grid.slot_data[i]:
			if item_data.name == item_grid.slot_data[i].data.name:
				if (int(item_grid.slot_data[i].quantity.text) + item_data.quantity) <= item_grid.slot_data[i].data.max_quant and item_data.quant == false:
					item_grid.slot_data[i].quantity.text = str(int(item_grid.slot_data[i].quantity.text) + item_data.quantity)
					item_grid.slot_data[i].update_label()
					return
				if item_data.quant:
					if int(item_grid.slot_data[i].quantity.text) + interaction_controller.quant <= item_grid.slot_data[i].data.max_quant:
						item_grid.slot_data[i].quantity.text = str(int(item_grid.slot_data[i].quantity.text) + interaction_controller.quant)
						item_grid.slot_data[i].update_label()
						return
					elif int(item_grid.slot_data[i].quantity.text) + interaction_controller.quant > item_grid.slot_data[i].data.max_quant:
						print("RUN OFF")
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.data = item_data
	if item_data.quant:
		inventory_item.get_child(-1).text = str(interaction_controller.quant)
		print(inventory_item.get_child(-1))
	add_child(inventory_item)
	var success = item_grid.attempt_to_add_item_data(inventory_item)
