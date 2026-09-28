extends IKTest
class_name ExoIKTest

@export var ik_reference: IKTest

func _process(delta: float) -> void:
	target_position = shoulder.global_position + ik_reference.target_dir * (total_arm_length * ik_reference.arm_length_used)

	super(delta)
