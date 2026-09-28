extends XRController3D

@export var collision: VRBody
@export var mesh: Node3D

func _physics_process(delta: float) -> void:
	if mesh == null or collision == null:
		return
	mesh.global_transform = PhysicsServer3D.body_get_state(collision.body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
