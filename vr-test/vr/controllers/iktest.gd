extends Node3D
class_name  IKTest

@onready var shoulder: Node3D = $shoulder
@onready var elbow: Node3D = $elbow
@onready var hand: Node3D = $hand


#joints are top level for learning purposes

@onready var upper_arm: Node3D = $UpperArm
@onready var lower_arm: Node3D = $LowerArm

@onready var upper_mesh: MeshInstance3D = $UpperArmMesh
@onready var lower_mesh: MeshInstance3D = $LowerArmMesh

@export var upper_collision: VRBody
@export var lower_collision: VRBody

@export var upper_arm_length: float = 0.25
@export var lower_arm_length: float = 0.3

@export var elbow_max_angle: float = 90
@export var tolerance: float = 0.001

@onready var total_arm_length: float = upper_arm_length + lower_arm_length


var target_position: Vector3 = Vector3.ZERO
var target_dir: Vector3 = Vector3.ZERO
var arm_length_used: float = 0.0

var max_it = 10

func _fabrik() -> void:
	var to_target: Vector3 = target_position - shoulder.global_position
	var target_dist: float = to_target.length()
	
	arm_length_used = target_dist / total_arm_length
	target_dir = to_target.normalized()
	
	#stretch arm and exit early if out of range
	if target_dist > total_arm_length:
		elbow.global_position = shoulder.global_position + target_dir * upper_arm_length
		hand.global_position = elbow.global_position + target_dir * lower_arm_length
		return
	
	var elbow_preferred_bend: Vector3 = Vector3.ZERO #make this based on current joints reference node
	
	var it = 0
	while hand.global_position.distance_squared_to(target_position) > tolerance**2:
		it += 1
		if it >= max_it:
			break
		
		hand.global_position = target_position
		
		var inv_lower_dir = (elbow.global_position - hand.global_position).normalized()
		elbow.global_position = hand.global_position + inv_lower_dir * lower_arm_length
		
		var upper_dir = (elbow.global_position - shoulder.global_position).normalized()
		if abs(upper_dir.dot(target_dir)) > 0.99:
			upper_dir = (upper_dir + elbow_preferred_bend * 0.1).normalized()
		elbow.global_position = shoulder.global_position + upper_dir * upper_arm_length
		
		var lower_dir = (hand.global_position - elbow.global_position).normalized()
		lower_dir = _constrain_dir(upper_dir, lower_dir, elbow_max_angle)
		hand.global_position = elbow.global_position + lower_dir * lower_arm_length


func _constrain_dir(ref_dir: Vector3, curr_dir: Vector3, max_angle: float) -> Vector3:
	var curr_angle = acos(ref_dir.dot(curr_dir))
	if curr_angle <= max_angle:
		return curr_dir
	
	var dir_axis = ref_dir.cross(curr_dir).normalized()
	var constrained_dir = curr_dir.rotated(dir_axis, deg_to_rad(max_angle))
	
	return constrained_dir.normalized()


func _process(delta: float) -> void:
	_fabrik()
	
	var upper_arm_dir = (elbow.global_position - shoulder.global_position).normalized()
	upper_arm.global_position = shoulder.global_position + upper_arm_dir * upper_arm_length * 0.5
	upper_arm.global_rotation =  Basis.looking_at(upper_arm_dir, Vector3.UP).get_euler()
	
	var lower_arm_dir = (hand.global_position - elbow.global_position).normalized()
	lower_arm.global_position = elbow.global_position + lower_arm_dir * lower_arm_length * 0.5
	lower_arm.global_rotation = Basis.looking_at(lower_arm_dir, Vector3.UP).get_euler()

func _physics_process(delta: float) -> void:
	upper_mesh.global_transform = PhysicsServer3D.body_get_state(upper_collision.body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
	lower_mesh.global_transform = PhysicsServer3D.body_get_state(lower_collision.body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
