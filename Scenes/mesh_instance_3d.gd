extends MeshInstance3D

@onready var sub_viewport_2: SubViewport = $"../Node3D/SubViewport2"
@onready var sprite_2d: Sprite2D = $"../SubViewport/Sprite2D"
#@onready var sprite_2d: Sprite2D = $"../Sprite2D"


var tex: Array[Texture]
func _process(delta: float) -> void:
	pass
	#var img: Image = sub_viewport_2.get_viewport().get_texture().get_image()
	#img.save_png("res://test_tex.png")
	#var texture: Texture = ImageTexture.create_from_image(img)
	#texture.get_image().save_png("res://test_tex.png")
	#get_surface_override_material(0).albedo_texture = texture
	#var shader = sprite_2d.material
	#shader.set_shader_parameter("my_tex", texture)
	
	

func _ready() -> void:
	pass
