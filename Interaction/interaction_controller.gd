extends Node

@onready var interaction_controller: Node = $InteractionController
@onready var interaction_ray: RayCast3D = %InteractionRay
@onready var player_cam: Camera3D = $CameraController/Camera3D
@onready var hand: Marker3D = %Hand
@onready var open_hand_rect: TextureRect = $"../UI/CanvasLayer/Control/OpenHandRect"
@onready var closed_hand_rect: TextureRect = $"../UI/CanvasLayer/Control/ClosedHandRect"
@onready var inventory: PanelContainer = %Inventory
@onready var camera_controller: CameraController = $"../CameraController"
@onready var item_grid: GridContainer = %ItemGrid
@onready var interaction_limit: Area3D = %InteractionLimit
@onready var rich_text_label: RichTextLabel = %RichTextLabel

var current_obj: Object
var last_obj: Object
var interaction_comp: Node
var item_size: ItemData
var overlaps: Array
var quant: int
var player: Player

signal check_inv(marker)

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

#if on previous frame we were interacting with an object lets keep interacting with it 
func _process(delta: float) -> void:
	if open_hand_rect:
		open_hand_rect.visible = false
	
	overlaps = interaction_limit.get_overlapping_bodies()
	if camera_controller.is_inv_open:
		open_hand_rect.visible = false
		Input.action_release("interact_key")
	
	if current_obj:
		if interaction_comp:
				if ((Input.is_action_just_pressed("interact_key") and interaction_comp.interaction_type == interaction_comp.interactionType.default) and not camera_controller.is_inv_open) or player.stamina.value <= 0:
					interaction_comp.postInteract()
					current_obj = null
					closed_hand_rect.visible = false
				elif interaction_comp.interaction_type == interaction_comp.interactionType.default:
					interaction_comp.interact()
					player.stamina.value -= delta * current_obj.mass * 20
					player.can_regen = false
					player.s_timer = 0
					closed_hand_rect.visible = true
					open_hand_rect.visible = false
				if Input.is_action_pressed("interact_key") and interaction_comp.interaction_type != interaction_comp.interactionType.default:
					if not camera_controller.is_inv_open:
						open_hand_rect.visible = false
					if interaction_comp.interaction_type == interaction_comp.interactionType.item:
						closed_hand_rect.visible = false
						if item_grid.is_not_full(item_size):
							interaction_comp.interact()
					else:
						closed_hand_rect.visible = true
					if interaction_comp.interaction_type != interaction_comp.interactionType.item and interaction_comp.interaction_type != interaction_comp.interactionType.lock and interaction_comp.interaction_type != interaction_comp.interactionType.key and interaction_comp.interaction_type != interaction_comp.interactionType.container:
						interaction_comp.interact()
						
				if not Input.is_action_pressed("interact_key") and interaction_comp.interaction_type != interaction_comp.interactionType.default :
					interaction_comp.postInteract()
					closed_hand_rect.visible = false
					current_obj = null
				if Input.is_action_just_pressed("left_click") and interaction_comp.interaction_type == interaction_comp.interactionType.default:
					interaction_comp.auxInteract()
					closed_hand_rect.visible = false
					current_obj = null
				if overlaps.has(current_obj):
					pass
				elif interaction_comp.interaction_type != interaction_comp.interactionType.default:
					interaction_comp.postInteract()
					current_obj = null
					Input.action_release("interact_key")
				elif interaction_comp.interaction_type == interaction_comp.interactionType.default:
					interaction_comp.postInteract()
					current_obj = null
	
	else: # runs if not currently interacting with an object already
		var potential_object: Object = interaction_ray.get_collider()
		if potential_object and potential_object is Node:
			interaction_comp = potential_object.get_node_or_null("InteractionComponent")
			if interaction_comp:
				if interaction_comp.interaction_type == interaction_comp.interactionType.item:
					rich_text_label.pop_up_text(interaction_comp.item_data.name,0.1)
				if interaction_comp.interaction_type == interaction_comp.interactionType.item and interaction_comp.item_data.quant:
					if quant != potential_object.quant:
						quant = potential_object.quant
				if interaction_comp.interaction_type == interaction_comp.interactionType.container and interaction_comp.opened:
					return
				if not camera_controller.is_inv_open:
					open_hand_rect.visible = true
				if interaction_comp.can_interact == false:
					return
				last_obj = current_obj
				if Input.is_action_just_pressed("interact_key") and interaction_comp.interaction_type == interaction_comp.interactionType.item:
					current_obj = potential_object
					item_size = current_obj.get_child(-1).item_data
					if item_grid.is_not_full(item_size):
						interaction_comp.connect("item_collected", Callable(self, "_on_item_collected"))
				if Input.is_action_just_pressed("interact_key") and interaction_comp.interaction_type == interaction_comp.interactionType.default and not camera_controller.is_inv_open:
					current_obj = potential_object
					interaction_comp.preInteract(hand)
				if Input.is_action_pressed("interact_key") and interaction_comp.interaction_type != interaction_comp.interactionType.default and interaction_comp.interaction_type != interaction_comp.interactionType.item and interaction_comp.interaction_type != interaction_comp.interactionType.lock and interaction_comp.interaction_type != interaction_comp.interactionType.key:
					current_obj = potential_object
					interaction_comp.preInteract(hand)
					interaction_comp.set_direction(current_obj.to_local(interaction_ray.get_collision_point()))
				if Input.is_action_just_pressed("interact_key") and interaction_comp.interaction_type == interaction_comp.interactionType.lock and not camera_controller.is_inv_open:
					interaction_comp.preInteract(hand)
					if interaction_comp._open_lock(interaction_comp.lock_name, item_grid.key_chain):
						interaction_comp.object_ref.queue_free()
				if Input.is_action_just_pressed("interact_key") and interaction_comp.interaction_type == interaction_comp.interactionType.key and not camera_controller.is_inv_open:
					interaction_comp.preInteract(hand)
					interaction_comp._add_key(interaction_comp.key_name, item_grid.key_chain)
				if Input.is_action_just_pressed("interact_key") and interaction_comp.interaction_type == interaction_comp.interactionType.container and not camera_controller.is_inv_open:
					emit_signal("check_inv", interaction_comp.marker)
					interaction_comp.preInteract(hand)
					
		else:
			open_hand_rect.visible = false
			closed_hand_rect.visible = false

func isCameraLocked() -> bool:
	if interaction_comp:
		if interaction_comp.lock_camera and interaction_comp.is_interacting:
			return true
	return false

func _on_item_collected(item: Node) -> void:
	var data = item.get_node("InteractionComponent").item_data
	if data != null:
		inventory.add_item(data)
	else:
		print("No data stinky")
