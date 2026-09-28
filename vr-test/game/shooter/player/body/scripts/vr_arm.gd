extends VRLimb

@export var controller: XRController3D

@export var ik_hand: IKJoint

func _ready() -> void:
	ik_hand.reference_node = controller
	super()

func _process(delta: float) -> void: 	
	arm_ik.target_position = controller.global_position
	super(delta)
