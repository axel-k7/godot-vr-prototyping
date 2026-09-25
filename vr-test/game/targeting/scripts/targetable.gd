extends Node3D
class_name Targetable

@export var mesh_instance : MeshInstance3D
@export var lock_on_time := 2.0

var target_material: StandardMaterial3D = null
var base_albedo: Color

var being_targeted := false
var locked := false
var progress := 0.0

signal locked_on

func _ready() -> void:
	var material := mesh_instance.get_active_material(0) as StandardMaterial3D 
	base_albedo = material.albedo_color
	target_material = material.duplicate()
	mesh_instance.set_surface_override_material(0, target_material)

func _process(delta: float) -> void:
	if being_targeted || (not being_targeted and progress > 0):
		progress += delta * (int(being_targeted) * 2 - 1)
		target_material.albedo_color = lerp(base_albedo, Color.RED, progress)
		
		if progress > lock_on_time and not locked:
			locked = true
			locked_on.emit()
		elif progress < lock_on_time and locked:
			locked = false
