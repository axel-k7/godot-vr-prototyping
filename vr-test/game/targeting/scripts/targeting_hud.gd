extends Control
class_name TargetingHUD

@onready var texture_rect : TextureRect = $TextureRect

@export var texture_start: Texture
@export var texture_done: Texture

var rendering_camera: XRCamera3D
var target: Targetable = null
var idle := true

var projection_matrix: Projection
var quad_size: Vector2
var quad_local_pos: Vector3
var target_local_pos: Vector3

signal lock_on_confirmed

func _process(delta: float) -> void:
	if idle:
		return
	
	texture_rect.position = project_point_viewport(target_local_pos) - texture_rect.size * 0.5


func project_point_viewport(point: Vector3) -> Vector2:
	var target_depth: float = -point.z
	var quad_dist: float = -quad_local_pos.z
	#divide by 0 safety check
	if target_depth == 0:
		return Vector2(9999,9999)
	var dist_scalar: float = quad_dist / target_depth
	
	texture_rect.size = texture_rect.texture.get_size() * (2+dist_scalar) #scaling is temp
	
	var quad_intersection: Vector2 = Vector2(
		(point.x * dist_scalar) - quad_local_pos.x,
		(point.y * dist_scalar) - quad_local_pos.y
	)
	
	#normalize
	quad_intersection /= quad_size
	
	var screen_pos: Vector2 = Vector2(
		(quad_intersection.x + 0.5) * size.x,
		(-quad_intersection.y + 0.5) * size.y,
	)
	
	return screen_pos

func try_target(_new_target: Targetable):
	target = _new_target
	target.connect("locked_on", _on_locked_on)
	
	texture_rect.texture = texture_start
	texture_rect.show()
	
	idle = false

func stop_target():
	texture_rect.hide()
	texture_rect.texture = texture_start
	
	target.disconnect("locked_on", _on_locked_on)
	target = null
	
	idle = true


func _on_locked_on(_locked_target: Targetable):
	texture_rect.texture = texture_done
	lock_on_confirmed.emit(_locked_target)
