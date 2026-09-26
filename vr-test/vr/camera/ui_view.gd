extends RefCounted
class_name  UIView

func _init(
	_quad: OpenXRCompositionLayerQuad,
	_camera: XRCamera3D,
	_near_clip: float,
	_far_clip: float,
	_fov: float,
	_distance: float,
	_xr_interface: OpenXRInterface, 
	_index: int
) -> void:
	#could save more of these arguments
	quad = _quad
	index = _index
	
	var render_target_size = _xr_interface.get_render_target_size()
	var aspect_ratio: float = render_target_size.x / render_target_size.y
	
	var projection = _xr_interface.get_projection_for_view(index, aspect_ratio, _near_clip, _far_clip)
	var forward: Vector3 = Vector3(projection.z.x, projection.z.y, projection.z.z)
	quad.position += forward * _distance
	
	var quad_height = 2.0 * _distance * tan(deg_to_rad(_fov) * 0.5)
	var quad_width = quad_height * aspect_ratio
	var quad_size = Vector2(quad_width, quad_height) * 1.2
	
	quad.quad_size = quad_size
	quad.layer_viewport.size = quad_size * 1000
	
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	quad.layer_viewport.add_child(ui_root)
	
	
var quad: OpenXRCompositionLayerQuad
var ui_root: Control
var aspect: float
var near_clip: float
var far_clip: float
var index: int
