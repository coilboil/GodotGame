extends SpotLight3D


func execute(percentage: float) -> void:
	visible = true
	percentage *=10
	light_energy = percentage 
	
	
	
