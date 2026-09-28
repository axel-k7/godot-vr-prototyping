extends Resource
class_name IKBranch

@export_node_path("IKJoint") var joints: Array[NodePath]
@export var tolerance: float = 0.001
@export var max_it: int = 10

#assuming one branch is from 'leaf' to first 'root' joint ex. hand -> shoulder
var joint_nodes: Array[IKJoint] = []

var total_length: float = 0.0

var target_position: Vector3 = Vector3.ZERO
var target_direction: Vector3 = Vector3.ZERO
var length_used: float = 0.0


func set_up_branch(_root_node: Node) -> void:
	for joint_path in joints:
		var joint: IKJoint = _root_node.get_node(joint_path)
		total_length += joint.length
		joint_nodes.append(joint)


func fabrik() -> void:
	var to_target: Vector3 = target_position - joint_nodes[0].global_position
	var target_distance: float = to_target.length()
	
	length_used = target_distance / total_length
	target_direction = to_target.normalized()
	
	#stretch joints and exit early if out of range
	if target_distance > total_length:
		for i in range(1, joint_nodes.size()):
			var current: IKJoint = joint_nodes[i]
			var parent: IKJoint = joint_nodes[i-1]
			current.global_position = parent.global_position + (target_direction * parent.length)
				
		return
	
	var leaf_joint: IKJoint = joint_nodes.back()
	var initial_root_position = joint_nodes[0].global_position
	
	var it = 0
	while leaf_joint.global_position.distance_squared_to(target_position) > tolerance**2:
		it += 1
		if it >= max_it:
			break
		
		#inverse pass
		leaf_joint.global_position = target_position
		
		for i in range(joint_nodes.size() - 2, -1, -1):
			var parent = joint_nodes[i]
			var child = joint_nodes[i+1]
			
			var to_parent = (child.global_position - parent.global_position).normalized()
			if child.reference_node != null and abs(to_parent.dot(target_direction)) > 0.99:
				var preferred_bend: Vector3 = -child.reference_node.global_transform.basis.z 
				to_parent = (to_parent + preferred_bend * 0.1).normalized()
			
			parent.global_position = child.global_position - (to_parent * parent.length)

		#forward pass
		joint_nodes[0].global_position = initial_root_position		
		for i in range(1, joint_nodes.size()):
			var child = joint_nodes[i]
			var parent = joint_nodes[i-1]
			var to_child = (child.global_position - parent.global_position).normalized()
			
			if i > 1 and child.max_angle != 0:
				var reference_dir: Vector3 = (parent.global_position - joint_nodes[i-2].global_position).normalized()
				to_child = _constrain_dir(reference_dir, to_child, child.max_angle)
				
			child.global_position = parent.global_position + (to_child * parent.length)


func _constrain_dir(ref_dir: Vector3, curr_dir: Vector3, max_angle: float) -> Vector3:
	var curr_angle = acos(ref_dir.dot(curr_dir))
	if curr_angle <= max_angle:
		return curr_dir
	
	var dir_axis = ref_dir.cross(curr_dir).normalized()
	var constrained_dir = curr_dir.rotated(dir_axis, deg_to_rad(max_angle))
	
	return constrained_dir.normalized()
