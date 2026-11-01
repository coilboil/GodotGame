extends ActionData
class_name EquippableAction

@export var one_time_use: bool = false
@export var success_text: String = "Door Unlocked"
@export var weapon_data: WeaponData

func _init() -> void:
	action_type = ActionType.equippable
