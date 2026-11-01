extends Sprite2D


@onready var player: Player = $"../../Player"



func _ready() -> void:
	position = Vector2(player.global_position.x*51.2,player.global_position.z*51.2) + (Vector2(256,256) - Vector2(64,64))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player.is_on_floor():
		visible = true
	else:
		visible = false
	print(player.global_position, "    ", position)
	position = Vector2(player.global_position.x*51.2,player.global_position.z*51.2) + (Vector2(256,256) - Vector2(64,64))
