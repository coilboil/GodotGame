extends Control

@onready var texture_rect: TextureRect = $TextureRect
var map_markers: Array[Node]
@export var open_work_markers: Array[Node]
var paired_marks: Dictionary
@onready var area_checker: Area3D = $"../../../AreaChecker"
var is_in_marked_area: bool = false
var last_key


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_rect.position.x = (get_viewport().size.x/2 -texture_rect. get_size().x/2 * 0.5)
	texture_rect.position.y = get_viewport().size.y/2 - texture_rect.get_size().y/2 * 0.4
	map_markers = texture_rect.get_children()
	if get_parent().get_parent().get_parent().get_parent().name == "OpenWorld":
		open_work_markers = get_parent().get_parent().get_parent().get_parent().get_child(0).get_children()
		print(get_parent().get_parent().get_parent().get_parent().get_child(0))
		for i in map_markers.size():
			paired_marks.set(open_work_markers.get(i), map_markers.get(i))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if get_tree().get_current_scene().name == "open_word":
		if area_checker.get_overlapping_areas() and not is_in_marked_area:
			print(paired_marks.get(area_checker.get_overlapping_areas().get(0)))
			is_in_marked_area = true
		
		if is_in_marked_area:
			if area_checker.get_overlapping_areas():
				paired_marks.get(area_checker.get_overlapping_areas().get(0)).visible = true
				last_key = area_checker.get_overlapping_areas().get(0)
			else:
				paired_marks.get(last_key).visible = false
				is_in_marked_area = false
