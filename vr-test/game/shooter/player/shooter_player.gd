extends VRInstance

const TARGETING_MIN_RANGE: float = 0.0005
const TARGETING_MAX_RANGE: float = 5000.0
const NARROWING_FACTOR: float = 5.0

#target -> ui-pair
var targets : Dictionary[Targetable, Array]

@export var targeting_ui: Control

func _ready() -> void:
	super()
	
	#this is obviously terrible, here just for testing purposes
	targets.get_or_add( get_tree().root.get_children().all( func(node): return node is Targetable) )

func _physics_process(delta: float) -> void:
	super(delta)
	
	
	
func _target_in_view() -> void:
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
		var target_local_pos = camera.global_transform.affine_inverse() * target.global_position
		var inside_projection = true
		
		for i in planes.size():
			var dist = planes[i].distance_to(target_local_pos)
			if dist > 0:
				inside_projection = false
				break
				
		if inside_projection and not target.being_targeted:
			var left_duplucate
			targets[target].append()
	
	
	
		if not target.being_targeted:
			left_hud.try_target(target)
			right_hud.try_target(target)
			target.being_targeted = true
	else:
		if target.being_targeted:
			left_hud.stop_target()
			right_hud.stop_target()
			target.being_targeted = false
