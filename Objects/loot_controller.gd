extends Node

var ammo: Dictionary = {}
var consumable: Array
var heals: Dictionary = {}
var weapons: Array
var loot_table: Array
var max_ammo: Dictionary = {
	"pistol_ammo": 48,
	"revolver_ammo": 24,
	"buckshot": 16,
	"rifle_ammo": 10
}

var paths: Dictionary = {
	"pistol_ammo": "res://Objects/Weapons/Ammo/pistol_ammo.tscn",
	"revolver_ammo": "res://Objects/Weapons/Ammo/revolver_ammo.tscn",
	"buckshot": "res://Objects/Weapons/Ammo/buckshot.tscn",
	"rifle_ammo": "res://Objects/Weapons/Ammo/rifle_ammo.tscn",
	"bandage": "res://Objects/bandage.tscn",
}

var random: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var interaction_controller: Node = %InteractionController
@onready var item_grid: GridContainer = %ItemGrid
var last

func _ready() -> void:
	interaction_controller.connect("check_inv", Callable(self,"checking_inv"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func checking_inv(marker) -> void:
	
	for i in item_grid.slot_data.size():
		if item_grid.slot_data.get(i):
			if item_grid.slot_data.get(i).data.action_data.action_type == 0:
				if not ammo.has(item_grid.slot_data.get(i).data.name):
					ammo.set(item_grid.slot_data.get(i).data.name, int(item_grid.slot_data.get(i).quantity.text))
				else:
					ammo.set(item_grid.slot_data.get(i).data.name, ammo.get(item_grid.slot_data.get(i).data.name) + int(item_grid.slot_data.get(i).quantity.text))
			if item_grid.slot_data.get(i).data.action_data.action_type == 1:
				if not consumable.has(item_grid.slot_data.get(i)):
					consumable.append(item_grid.slot_data.get(i))
			if item_grid.slot_data.get(i).data.action_data.action_type == 2:
				if not weapons.has(item_grid.slot_data.get(i)):
					weapons.append(item_grid.slot_data.get(i))
	for i in consumable.size():
		if not heals.has(consumable.get(i).data.name):
			heals.set(consumable.get(i).data.name, int(consumable.get(i).quantity.text))
		else:
			heals.set(consumable.get(i).data.name, heals.get(consumable.get(i).data.name) + int(consumable.get(i).quantity.text))
	set_weight()
	pick_item(marker)
	

func set_weight() -> void:
	for i in weapons.size():
		if weapons.get(i):
			if not ammo.has(weapons.get(i).data.action_data.weapon_data.ammo_type):
				for n in range(5):
					loot_table.append(weapons.get(i).data.action_data.weapon_data.ammo_type)
			elif ammo.get(weapons.get(i).data.action_data.weapon_data.ammo_type) < max_ammo.get(weapons.get(i).data.action_data.weapon_data.ammo_type):
				for n in range(3):
					loot_table.append(weapons.get(i).data.action_data.weapon_data.ammo_type)
			elif ammo.get(weapons.get(i).data.action_data.weapon_data.ammo_type) >= max_ammo.get(weapons.get(i).data.action_data.weapon_data.ammo_type):
				loot_table.append(weapons.get(i).data.action_data.weapon_data.ammo_type)
	if not heals:
		for n in range(6):
			loot_table.append("bandage")
	elif heals.get("bandage") < 3:
		for n in range(3):
			loot_table.append("bandage")
	elif heals.get("bandage") >= 3:
		loot_table.append("bandage")
	if not weapons:
		loot_table.resize(15)
	elif weapons.size() == 1:
		loot_table.resize(20)
	elif weapons.size() == 2:
		loot_table.resize(25)
	elif weapons.size() == 2:
		loot_table.resize(30)
	var r = random.randi_range(0,3)
	var random_ammo
	match r:
		0:
			random_ammo = "pistol_ammo"
		1:
			random_ammo = "revolver_ammo"
		2:
			random_ammo = "buckshot"
		3:
			random_ammo = "rifle_ammo"
	loot_table.set(loot_table.size()-1, random_ammo)
	print(loot_table)

func pick_item(marker) -> void:
	var r = random.randi_range(0, loot_table.size() - 1)
	var pick = loot_table.get(r)
	print(paths.get(pick))
	if paths.get(pick) == null:
		return
	var inst = load(paths.get(pick)).instantiate() as Node3D
	get_tree().current_scene.add_child(inst)
	inst.global_transform.origin = marker.global_position
	loot_table.clear()
	
