extends Node3D
class_name VRLimb

@export var limb_ik: IKBranch
@export var meshes: Array[Node3D]
@export var collisions: Array[VRBody]

@onready var limb_count = limb_ik.joints.size() - 1

var limb_node_references: Array[Node3D]

func _ready() -> void:
	if meshes.size() != limb_count:
		print("mesh count not equal to limbs in: ", name)
		return
	if collisions.size() != limb_count:
		print("collision count not equal to limbs in: ", name)
		return
	
	limb_ik.set_up_branch(self)
	
	limb_node_references.resize(limb_count)
	for i in limb_count:
		var limb_node = Node3D.new()
		add_child(limb_node)
		limb_node_references[i] = limb_node
		collisions[i].reference_node = limb_node_references[i]
		
		
func _process(delta: float) -> void:
	limb_ik.fabrik()
	for i in limb_count:
		var parent: IKJoint = limb_ik.joint_nodes[i]
		var child: IKJoint = limb_ik.joint_nodes[i+1]
		
		var limb_dir: Vector3 = (child.global_position - parent.global_position).normalized()
		limb_node_references[i].global_position = parent.global_position + (limb_dir * parent.length * 0.5)
		limb_node_references[i].global_basis = Basis.looking_at(limb_dir)


func _physics_process(delta: float) -> void:
	for i in limb_count:
		meshes[i].global_transform = PhysicsServer3D.body_get_state(collisions[i].body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
