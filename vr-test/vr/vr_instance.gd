extends XROrigin3D
class_name VRInstance

enum MovementPreference {
	LEFT_CONTROLLER,
	RIGHT_CONTROLLER
}

##VR-------------------------
@export var camera: XRCamera3D
@export var left_hand: XRController3D
@export var right_hand: XRController3D

var xr_interface : XRInterface
var aspect_ratio: float
##VR-------------------------


##MOVEMENT-------------------
@export var movement_pref := MovementPreference.LEFT_CONTROLLER
@export var body_shape: Shape3D

const MOVE_SPEED := 5.0
const ROT_SENS := 0.05

var body_rid : RID
var parameters := PhysicsTestMotionParameters3D.new()
var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var grounded: bool = false
const MAX_SLIDE := 4
const GRAVITY := -9.82 

var move_axis := Vector2.ZERO
var rot_axis := Vector2.ZERO
##MOVEMENT--------------------


##UI--------------------------
@export var left_quad: OpenXRCompositionLayerQuad
@export var right_quad: OpenXRCompositionLayerQuad
@export var ui_distance: float = 1.0
@export var near_clip: float = 0.005
@export var far_clip: float = 5000.0

var left_ui: UIView
var right_ui: UIView

##UI--------------------------

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if !xr_interface or !xr_interface.is_initialized():
		print('uh oh')
		return
		
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().use_xr = true
	
	var render_target_size = xr_interface.get_render_target_size()
	var aspect_ratio: float = render_target_size.x / render_target_size.y
	
	_set_up_ui()
	_set_up_movement()
	_bind_inputs()


func _set_up_ui() -> void:
	left_ui = UIView.new(left_quad, camera, near_clip, far_clip, camera.fov, ui_distance, xr_interface, 0)
	right_ui = UIView.new(right_quad, camera, near_clip, far_clip, camera.fov, ui_distance, xr_interface, 1)

#"node" becomes left-view, "copy" is right-view
func add_ui(node: Control) -> Control:
	var copy = node.duplicate()
	if node.get_parent():
		node.get_parent().remove_child(node)
		
	left_ui.ui_root.add_child(node)
	right_ui.ui_root.add_child(copy)
	
	var forward: Vector3 = camera.global_transform * (Vector3.FORWARD * ui_distance)
	
	var left_center: Vector2 = _project_point_viewport(forward, left_ui)
	var right_center: Vector2 = _project_point_viewport(forward, right_ui)
	
	#assuming the elements want to be centered
	node.position = left_center - (node.size * 0.5)
	copy.position = right_center - (copy.size * 0.5)
	
	return copy

func _project_point_viewport(point: Vector3, view: UIView) -> Vector2:
	var view_transform_inverse: Transform3D = xr_interface.get_transform_for_view(view.index, global_transform).affine_inverse()
	
	var quad_local: Vector3 = view_transform_inverse * view.quad.global_position
	var target_local: Vector3 = view_transform_inverse * point
	
	var target_depth: float = -target_local.z
	if target_depth <= 0:
		return Vector2(9999,9999)
		
	var quad_dist: float = -quad_local.z
	var dist_scalar: float = quad_dist / target_depth
	
	var quad_intersection: Vector2 = Vector2(
		(target_local.x * dist_scalar) - quad_local.x,
		(target_local.y * dist_scalar) - quad_local.y
	)
	
	#normalize to quad uv position
	quad_intersection /= view.quad.quad_size
	
	var viewport_pos: Vector2 = Vector2(
		quad_intersection.x + 0.5,
		-quad_intersection.y + 0.5,
	) * Vector2(view.quad.layer_viewport.size)
	
	return viewport_pos


func _set_up_movement() -> void:
	body_rid = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_space(body_rid, get_world_3d().space)
	PhysicsServer3D.body_set_mode(body_rid, PhysicsServer3D.BODY_MODE_KINEMATIC)
	PhysicsServer3D.body_add_shape(body_rid, body_shape.get_rid(), Transform3D.IDENTITY)
	PhysicsServer3D.body_set_collision_layer(body_rid, 0b00000010)
	PhysicsServer3D.body_set_collision_mask(body_rid, 0b00000001)
	
	parameters.margin = 0.04
	parameters.recovery_as_collision = true

func _physics_process(delta: float) -> void:
	if !body_rid.is_valid():
		return
	
	_update_shape_height()
	
	if !rot_axis.is_zero_approx():
		rotate_y(-rot_axis.x * ROT_SENS)
	
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, _get_projected_transform())
	
	var target_velocity := Vector3.ZERO
	if !move_axis.is_zero_approx():
		var input_dir := Vector3(move_axis.x, 0.0, -move_axis.y)
		var world_dir = camera.global_basis * input_dir
		world_dir.y = 0

		target_velocity = world_dir.normalized() * MOVE_SPEED
	
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	acceleration.y += GRAVITY
	
	_move_and_slide(delta)


func _move_and_slide(delta: float):
	velocity += acceleration * delta
	acceleration = Vector3.ZERO
	var result := PhysicsTestMotionResult3D.new()
		
	var motion := velocity * delta
	
	grounded = false
	var latest_grounded_normal = Vector3.ZERO
	
	var current_transform = _get_projected_transform()
	var start_position: Vector3 = current_transform.origin
	
	for i in MAX_SLIDE:
		if motion.is_zero_approx():
			break
		
		parameters.from = current_transform
		parameters.motion = motion
		
		var collided: bool = PhysicsServer3D.body_test_motion(body_rid, parameters, result)
		
		if !collided:
			current_transform.origin += motion
			break
			
		current_transform.origin += result.get_travel()
		var normal := result.get_collision_normal()
	
		if normal.y > 0.7: #~45deg
			grounded = true
			latest_grounded_normal = normal
		
		var remainder = result.get_remainder()
		motion = remainder - normal * remainder.dot(normal)
	
	var motion_delta: Vector3 = current_transform.origin - start_position
	global_transform.origin += motion_delta
	
	if grounded and velocity.y < 0.0:
		velocity = velocity - latest_grounded_normal * velocity.dot(latest_grounded_normal)
	
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, _get_projected_transform())


func _update_shape_height():
	if body_shape is CapsuleShape3D:
		body_shape.height = camera.position.y
	
	var shape_transform := Transform3D.IDENTITY
	shape_transform.origin.y = camera.position.y * 0.5
	
	PhysicsServer3D.body_set_shape_transform(body_rid, 0, shape_transform)


func _get_projected_transform() -> Transform3D:
	var body_transform := global_transform
	var camera_offset := camera.position
	camera_offset.y = 0
	body_transform.origin += global_basis * camera_offset
	
	return body_transform

func _bind_inputs() -> void:
	match movement_pref:
		MovementPreference.LEFT_CONTROLLER:
			left_hand.input_vector2_changed.connect(_move_input_changed)
			right_hand.input_vector2_changed.connect(_rotation_input_changed)
		MovementPreference.RIGHT_CONTROLLER:
			right_hand.input_vector2_changed.connect(_move_input_changed)
			left_hand.input_vector2_changed.connect(_rotation_input_changed)


func _move_input_changed(action_name: String, value: Vector2) -> void:
	move_axis = value

func _rotation_input_changed(action_name: String, value: Vector2) -> void:
	rot_axis = value

func _exit_tree() -> void:
	if body_rid.is_valid():
		PhysicsServer3D.free_rid(body_rid)
