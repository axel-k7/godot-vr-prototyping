extends IKTest

@export var target: Node3D

func _process(delta: float) -> void:
	target_position = target.global_position
	super(delta)
