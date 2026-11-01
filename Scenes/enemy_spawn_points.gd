extends Node3D

var keys: Array[Node]
var points: Dictionary
@onready var player: Player = $"../Player"
var enemy_count: int = 0
var enemies: Dictionary = {
	"frog": preload("res://Objects/Enemies/frog.tscn"),
	"crawler": preload("res://Objects/Enemies/crawler.tscn")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	keys = self.get_children()
	for i in keys.size():
		points.set(keys.get(i), false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	print(enemy_count)
	for i in keys.size():
		if keys.get(i).global_position.distance_to(player.global_position) > 110 and points.get(keys.get(i)) == false:
			print(keys.get(i))
			points.set(keys.get(i), true)
		if  keys.get(i).global_position.distance_to(player.global_position) <= 110:
			points.set(keys.get(i), false)
	
	if enemy_count < 4:
		for i in keys.size():
			if points.get(keys.get(i)) == true and not keys.get(i).get_children():
				if enemy_count < 4:
					var enemy_keys = enemies.keys()
					var pick = enemy_keys.get(randi_range(0, enemy_keys.size()-1))
					var spawn = enemies.get(pick).instantiate()
					keys.get(i).add_child(spawn)
					spawn.global_position = keys.get(i).global_position
				else:
					break
	
	enemy_count = get_tree().get_nodes_in_group("enemy").size()
	
