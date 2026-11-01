extends Resource
class_name ItemData

@export var name: String
@export var texture: Texture2D
@export var dimentions: Vector2i
@export var action_data: ActionData
@export var quantity: int = 1
@export var max_quant: int = 1
@export var cur_ammo: int = 0
@export var item_model_prefab: PackedScene
@export var quant: bool = false

var is_rotated: bool = false
