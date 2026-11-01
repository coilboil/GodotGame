extends PathFollow3D

@export var time: float
@export var speed: float
@export var back: bool = false
@export var timer: float
@export var time_out: bool = false
@export var enemy: CharacterBody3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = time

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if enemy:
		if enemy.state != enemy.s.pathing:
			return
	else:
		self.queue_free()
	if time_out:
		timer -= delta
		if timer <= 0:
			timer = time
			back = not back
			time_out = false
	if not back:
		progress += delta * speed
		if progress_ratio == 1:
			time_out = true
	if back:
		progress -= delta * speed
		if progress_ratio == 0.0:
			time_out = true
	
