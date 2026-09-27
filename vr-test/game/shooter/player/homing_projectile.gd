extends Node3D
class_name HomingProjectile

@export var projectile_speed: float = 50.0
@export var homing_speed: float = 5.0
@export var lifetime: float = 8.0

var target: Targetable
	
func _process(delta: float) -> void:
	if target == null:
		return
		
	var target_transform = global_transform.looking_at(target.global_position, global_basis.y)
	global_basis = global_basis.slerp(target_transform.basis, delta*homing_speed)
	
	global_position += -global_basis.z * projectile_speed * delta
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
