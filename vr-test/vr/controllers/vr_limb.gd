extends Node3D
class_name VRLimb

@export var arm_ik: IKBranch
@export var meshes: Array[Node3D]
@export var collisions: Array[VRBody]

@onready var limb_count = arm_ik.joints.size() - 1

var limb_transforms: Array[Transform3D]

func _ready() -> void:
	if meshes.size() != limb_count:
		print("mesh count not equal to limbs in: ", name)
		return
	if collisions.size() != limb_count:
		print("collision count not equal to limbs in: ", name)
		return
	
	arm_ik.set_up_branch(self)
	
	limb_transforms.resize(limb_count)
	limb_transforms.fill(Transform3D())
	for i in limb_count:
		collisions[i].reference_transform = limb_transforms[i]
		
		
func _process(delta: float) -> void:
	arm_ik.fabrik()
	for i in limb_count:
		var parent: IKJoint = arm_ik.joint_nodes[i]
		var child: IKJoint = arm_ik.joint_nodes[i+1]
		
		var limb_dir: Vector3 = (child.global_position - parent.global_position).normalized()
		limb_transforms[i].origin = parent.global_position + (limb_dir * parent.length * 0.5)
		limb_transforms[i].basis = Basis.looking_at(limb_dir)


func _physics_process(delta: float) -> void:
	for i in limb_count:
		meshes[i].global_transform = PhysicsServer3D.body_get_state(collisions[i].body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
