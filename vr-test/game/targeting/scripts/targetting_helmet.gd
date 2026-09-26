extends VRInstance

@export var target: Targetable

@onready var left_hud : TargetingHUD = $LeftUIViewport/TargetingHud
@onready var left_hud_quad : OpenXRCompositionLayerQuad = $Camera/LeftCompositionLayer

@onready var right_hud : TargetingHUD = $RightUIViewport/TargetingHud
@onready var right_hud_quad : OpenXRCompositionLayerQuad = $Camera/RightCompositionLayer

const TARGETING_MIN_RANGE := 0.05
const TARGETING_MAX_RANGE := 5000.0
const NARROWING_FACTOR := 3.0

var aspect_ratio: float

var inside_projection: bool = true


	
func _physics_process(delta: float) -> void:
	super(delta)
	
	var left_eye_transform = xr_interface.get_transform_for_view(0, global_transform)
	var left_local_pos: Vector3 = left_eye_transform.affine_inverse() * target.global_position
	
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
	
	
	inside_projection = true
	for i in planes.size():
		var dist = planes[i].distance_to(left_local_pos)
		if dist > 0:
			inside_projection = false
			break
	
	if inside_projection:
		if not target.being_targeted:
			left_hud.try_target(target)
			right_hud.try_target(target)
			target.being_targeted = true
	else:
		if target.being_targeted:
			left_hud.stop_target()
			right_hud.stop_target()
			target.being_targeted = false


func _process(delta: float) -> void:
	if not inside_projection:
		return

	#ui only updated when necessary
		

	#-----	not using this anymore but might be nice to have	
	#var near: float = -planes[0].d 
	#var far: float = planes[1].d

	#var near_left_top: Vector3 = planes[0].intersect_3(planes[2], planes[4])
	#var near_right_bottom: Vector3 = planes[0].intersect_3(planes[3], planes[5])

	#var left: float = near_left_top.x
	#var top: float = near_left_top.y
	#var right: float = near_right_bottom.x
	#var bottom: float = near_right_bottom.y
	#hud.projection_matrix = Projection.create_frustum(left, right, bottom, top, near, far)
	#-----------------------
