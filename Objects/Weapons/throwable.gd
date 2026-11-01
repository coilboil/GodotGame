extends RigidBody3D

@onready var interaction_component: Node = $InteractionComponent
@export var thrown: bool = false
@export var breaks: bool = false
@export var hp_dmg: float = 10
@export var stun_dmg: float = 40
var group_lock: bool = false
var group_counter: float = 0
var has: bool = false
var player: Player
var last_v: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	interaction_component.connect("thrown", Callable(self, "_thrown"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#print(get_linear_velocity().length())
	if interaction_component.is_interacting:
		add_to_group("throwable")
		group_counter = 0.2
		has = true
	else:
		group_counter -= delta
		if group_counter <= 0 and has:
			remove_from_group("throwable")
			has = false
			print("done")
	if last_v > 9.0:
		thrown = true
	else:
		thrown = false
	if thrown:
		if get_colliding_bodies():
			print(get_colliding_bodies().get(0))
			var enemy = _get_enemy_root(get_colliding_bodies().get(0))
			if enemy:
				if enemy.is_in_group("enemy"):
					enemy.cur_stagger += stun_dmg
					enemy.cur_health -= hp_dmg
				print("enemy")
			thrown = false
			player.throw_land(global_position)
			if breaks:
				queue_free()
	
	last_v = get_linear_velocity().length()

func _get_enemy_root(node) -> Node:
	if node.get_parent() and not node is CharacterBody3D:
		node = node.get_parent()
	else:
		return node
	return _get_enemy_root(node)
