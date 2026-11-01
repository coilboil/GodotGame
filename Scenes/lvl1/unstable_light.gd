extends StaticBody3D

@export var wane: bool = false
@export var flicker: bool = false
@export var con: float = 0.0
@export var switch: bool = false
@export var flicker_f: float = 0.0


func _process(delta: float) -> void:
	if wane:
		con += delta
		$SpotLight3D.light_energy += sin(con/4)/2000
		print($SpotLight3D.light_energy)
		if $SpotLight3D.light_energy > 1.175:
			switch = true
		else:
			switch = false
			$SpotLight3D.visible = true
		if flicker:
			if switch == true:
				flicker_f+= delta
				if flicker_f > 0.05:
					$SpotLight3D.visible = not $SpotLight3D.visible
					flicker_f = 0.0
