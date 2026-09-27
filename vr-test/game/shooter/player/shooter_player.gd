extends VRInstance

const TARGETING_MIN_RANGE: float = 0.0005
const TARGETING_MAX_RANGE: float = 5000.0
const NARROWING_FACTOR: float = 3.0

#target -> ui-pair
var targets : Dictionary[Targetable, Array]
@onready var homing_projectile_res = preload("res://game/shooter/player/homing_projectile.tscn")
@onready var hud_res = preload("res://game/shooter/player/shooter_hud.tscn")
@export var firing_cooldown: float = 1.0
var _cooldown: float = 0.0
var cooldown: float:
	get: return _cooldown
	set(value):
		_cooldown = value
		_cooldown = clamp(value, 0.0, firing_cooldown)
		cooldown_changed.emit(cooldown)
signal cooldown_changed

@export var texture_locking: Texture
@export var texture_locked: Texture

func _ready() -> void:
	super()
	#this is obviously terrible, here just for testing purposes
	var found_targets = get_tree().root.find_children('*', 'Targetable', true, false)
	for target in found_targets:
		targets.get_or_add(target, [])
		
	var left_hud = hud_res.instantiate()
	var right_hud = add_ui(left_hud)
	cooldown_changed.connect(left_hud.set_cooldown)
	cooldown_changed.connect(right_hud.set_cooldown)


func _process(delta: float) -> void:
	_target_in_view()
	
	if cooldown > 0.0:
		cooldown -= delta
		cooldown_changed.emit(cooldown)
	
	for target in targets:
		if target.being_targeted:
			var ui = targets[target]
			ui[0].position = _project_point_viewport(target.global_position, left_ui) - ui[0].size*0.5
			ui[1].position = _project_point_viewport(target.global_position, right_ui) - ui[1].size*0.5

func _bind_inputs() -> void:
	super()
	right_hand.button_pressed.connect(_shoot_targets)

func _shoot_targets(_action_name: String) -> void:
	if _action_name != "trigger_click" or cooldown > 0.0:
		return
	
	cooldown = firing_cooldown
	
	for target : Targetable in targets.keys():
		if target.locked:
			var homing_projectile = homing_projectile_res.instantiate()
			homing_projectile.target = target
			get_tree().root.add_child(homing_projectile)
			homing_projectile.global_transform = right_hand.global_transform
			homing_projectile.global_position += -right_hand.global_basis.z * 1.5 
			

func _target_in_view() -> void:
	var inv_left_transform = xr_interface.get_transform_for_view(0, global_transform).affine_inverse()
	var left_projection = xr_interface.get_projection_for_view(0, aspect_ratio, TARGETING_MIN_RANGE, TARGETING_MAX_RANGE)
	var right_projection = xr_interface.get_projection_for_view(1, aspect_ratio, TARGETING_MIN_RANGE, TARGETING_MAX_RANGE)
	
	left_projection.x.x *= NARROWING_FACTOR
	left_projection.y.y *= NARROWING_FACTOR
	
	right_projection.x.x *= NARROWING_FACTOR
	right_projection.y.y *= NARROWING_FACTOR
		
	var planes: Array[Plane] = [
		left_projection.get_projection_plane(Projection.PLANE_NEAR),
		left_projection.get_projection_plane(Projection.PLANE_FAR),
		left_projection.get_projection_plane(Projection.PLANE_LEFT),
		right_projection.get_projection_plane(Projection.PLANE_RIGHT),
		left_projection.get_projection_plane(Projection.PLANE_TOP),
		left_projection.get_projection_plane(Projection.PLANE_BOTTOM)
	]
	
	for target in targets:
		var target_local_pos = inv_left_transform * target.global_position
		var inside_projection = true
		
		for i in planes.size():
			var dist = planes[i].distance_to(target_local_pos)
			if dist > 0:
				inside_projection = false
				break
				
		if inside_projection and not target.being_targeted:
			var left_ui = TextureRect.new()
			left_ui.texture = texture_locking
			var right_ui = add_ui(left_ui)
			targets[target].append_array([left_ui, right_ui])
			target.being_targeted = true
			target.locked_on.connect(_target_locked_on)
	
		elif not inside_projection and target.being_targeted:
			var ui : Array = targets.get_or_add(target)
			if ui == null:
				return
			ui[0].queue_free()
			ui[1].queue_free()
			ui.clear()
			target.being_targeted = false
			target.locked_on.disconnect(_target_locked_on)
			

func _target_locked_on(_target: Targetable):
	var ui : Array = targets.get_or_add(_target)
	if ui == null:
		return
	ui[0].texture = texture_locked
	ui[1].texture = texture_locked


func _target_lock_on_failed(_target: Targetable):
	pass
