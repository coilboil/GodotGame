extends RichTextLabel
var text_lock: bool = false
var text_timer: float = 0

func _process(delta: float) -> void:
	if text_timer > 0:
		visible = true
		text_timer -= delta
	else:
		visible = false

func pop_up_text(set_text: String, time: float) -> void:
	text = set_text
	text_timer = time
