class_name WeaponData
extends Resource

@export var weapon_name: String
@export var right_click_pen: float #percentage so 0.8 is 80% of normal speed when holding right click

@export var is_ranged: bool
@export var damage: float
@export var crit_damage: float
@export var stagger_dmg: float
@export var fire_rate: float
@export var max_ammo: int
@export var ads_position: Vector3
@export var ads_speed: float = 10
@export var ammo_type: String
@export var cur_ammo: int
@export var reload_time: float
@export var semi_auto: bool = false
@export var is_revolver: bool = false
@export var manual_load: bool = false
@export var manual_cycle: bool = false
@export var manual_cycle_loaded: bool = false
@export var is_shotgun: bool = false 
@export var recoil: Vector2 
@export var recoil_recovery: float
@export var recoil_add_speed: float


@export var is_melee: bool
@export var hitbox_d: Vector2
@export var hitbox_t: Vector3
@export var light_damage: float
@export var light_stag: float
@export var light_crit_damage: float
@export var light_stagger_dmg: float
@export var light_delay: float
@export var light_recovery: float
@export var range: float
@export var light_stamina_cost: float
@export var has_block: bool
@export var block_str: float
@export var block_stam_mtp: float 
@export var has_heavy: bool
@export var heavy_damage: float
@export var heavy_stag: float
@export var heavy_crit_damage: float
@export var heavy_charge_up: float
@export var heavy_delay: float
@export var heavy_recovery: float
@export var heavy_stam: float
@export var breakable_dmg: float
