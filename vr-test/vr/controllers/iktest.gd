extends Node

@export var target: Node3D
@onready var shoulder: Node3D = $shoulder
@onready var elbow: Node3D = $elbow
@onready var hand: Node3D = $hand

@onready var upper_arm: MeshInstance3D = $UpperArmMesh
@onready var lower_arm: MeshInstance3D = $LowerArmMesh

#joints are top level for learning purposes

var elbow_max_angle: float = 90
var tolerance: float = 0.001

var s_e_length: float = 0.3
var e_h_length: float = 0.35

var max_it = 10

func _fabrik() -> void:
	var max_length: float = s_e_length + e_h_length
	var to_target: Vector3 = target.global_position - shoulder.global_position
	
	#stretch arm and exit early if out of range
	if (to_target.length_squared() > max_length**2):
		var dir: Vector3 = to_target.normalized()
		elbow.global_position = shoulder.global_position + dir * s_e_length
		hand.global_position = elbow.global_position + dir * e_h_length
		return
	
	var it = 0
	while hand.global_position.distance_squared_to(target.global_position) > tolerance**2:
		it += 1
		if it >= max_it:
			break
		
		hand.global_position = target.global_position
		
		var inv_lower_dir = (elbow.global_position - hand.global_position).normalized()
		elbow.global_position = hand.global_position + inv_lower_dir * e_h_length
		
		var upper_dir = (elbow.global_position - shoulder.global_position).normalized()
		elbow.global_position = shoulder.global_position + upper_dir * s_e_length
		
		var lower_dir = (hand.global_position - elbow.global_position).normalized()
		lower_dir = _constrain_dir(upper_dir, lower_dir, elbow_max_angle)
		hand.global_position = elbow.global_position + lower_dir * e_h_length


func _constrain_dir(ref_dir: Vector3, curr_dir: Vector3, max_angle: float) -> Vector3:
	var curr_angle = acos(ref_dir.dot(curr_dir))
	if curr_angle <= max_angle:
		return curr_dir
	
	var dir_axis = ref_dir.cross(curr_dir).normalized()
	var constrained_dir = curr_dir.rotated(dir_axis, deg_to_rad(max_angle))
	
	return constrained_dir.normalized()


func _process(delta: float) -> void:
	_fabrik()
	
	var s_to_elbow = (elbow.global_position - shoulder.global_position).normalized()
	upper_arm.global_position = shoulder.global_position + s_to_elbow * s_e_length * 0.5
	upper_arm.global_rotation =  Basis.looking_at(s_to_elbow, Vector3.UP).get_euler()
	
	var e_to_hand = (hand.global_position - elbow.global_position).normalized()
	lower_arm.global_position = elbow.global_position + e_to_hand * e_h_length * 0.5
	lower_arm.global_rotation = Basis.looking_at(e_to_hand, Vector3.UP).get_euler()
	
