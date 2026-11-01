extends Sprite2D

@onready var quantity: Label = $Quantity
@export var quant : int
var data: ItemData = null
var is_picked: bool = false
var divider: float = 2
var size: Vector2:
	get():
		return Vector2(data.dimentions.x, data.dimentions.y) * 32
	
var anchor_point: Vector2:
	get():
		return global_position - size / divider

func _ready() -> void:
	if not data.quant:
		quantity.text = str(data.quantity)
		update_label()
	else:
		update_label()
	if data:
		texture = data.texture

func _process(delta: float) -> void:	
	if is_picked:
		global_position = get_global_mouse_position()

func set_init_position(pos: Vector2) -> void:
	global_position = pos + size / divider
	anchor_point = global_position - size / divider

func get_picked_up() -> void:
	add_to_group("held_item")
	is_picked = true
	z_index = 10
	anchor_point = global_position - size / divider

func get_placed(pos: Vector2i) -> void:
	is_picked = false
	global_position = pos + Vector2i(size / divider)
	z_index = 0
	anchor_point = global_position - size / divider
	remove_from_group("held_item")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			if is_picked:
				do_rotation()

func do_rotation() -> void:
	data.is_rotated = !data.is_rotated
	data.dimentions = Vector2i(data.dimentions.y, data.dimentions.x)
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", 90 if data.is_rotated else 0, 0.0)
	await tween.finished
	tween.kill()
	anchor_point = global_position - size / divider

func update_label() -> void:
	if int(quantity.text) > 1:
		quantity.show()
	else:
		quantity.hide()

func updata_quantity(added_q: int) -> void:
	if not data.quant:
		quantity.text = str(int(quantity.text) + added_q)
		update_label()
	else:
		update_label()
