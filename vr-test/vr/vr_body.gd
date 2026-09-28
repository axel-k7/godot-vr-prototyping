extends Node
class_name VRBody

@export var mass: float = 5.0
@export var linear_scale: float = 30.0
@export var angular_scale: float = 30.0
@export var collision_shape: Shape3D
@export var reference_node: Node3D

var reference_transform: Transform3D
var body_rid: RID


func _ready() -> void:
	if reference_transform == null:
		reference_transform = reference_node.global_transform
	
	body_rid = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_space(body_rid, reference_node.get_world_3d().space)
	PhysicsServer3D.body_set_mode(body_rid, PhysicsServer3D.BODY_MODE_RIGID)
	PhysicsServer3D.body_add_shape(body_rid, collision_shape.get_rid(), Transform3D.IDENTITY)
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, reference_transform)
	PhysicsServer3D.body_set_collision_layer(body_rid, 0b00000010)
	PhysicsServer3D.body_set_collision_mask(body_rid, 0b00000001)
	
	PhysicsServer3D.body_set_param(body_rid, PhysicsServer3D.BODY_PARAM_MASS, mass)
	PhysicsServer3D.body_set_param(body_rid, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE, 0.0)
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_CAN_SLEEP, 0.0)

func _physics_process(delta: float) -> void:
	var body_transform: Transform3D = PhysicsServer3D.body_get_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
	
	var pos_delta = reference_transform.origin - body_transform.origin
	var linear_velocity = pos_delta * linear_scale
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, linear_velocity)
	
	var rot_delta: Quaternion = reference_transform.basis.get_rotation_quaternion() * body_transform.basis.get_rotation_quaternion().inverse()
	var angle: float = rot_delta.get_angle()
	var axis: Vector3 = rot_delta.get_axis()
	
	if angle > PI:
		angle -= 2*PI

	var angular_velocity = axis * (angle * angular_scale)

	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, angular_velocity)


func _exit_tree() -> void:
	if body_rid.is_valid():
		PhysicsServer3D.free_rid(body_rid)
