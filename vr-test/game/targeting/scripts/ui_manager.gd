extends Node
class_name UIManager

@export var camera: XRCamera3D
@export var replicated_ui : Control
@export var ui_distance: float = 1.0

var left_view: VRViewInfo
var right_view: VRViewInfo

var aspect_ratio: float
var xr_interface : XRInterface


func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if !xr_interface or !xr_interface.is_initialized():
		print('uh oh')
		return
	
	


func _process(delta: float) -> void:
	pass
	#var left_eye_transform = xr_interface.get_transform_for_view(0, camera.global_transform)
	#var right_eye_transform = xr_interface.get_transform_for_view(1, camera.global_transform)


func _set_up_ui() -> void:
	var quad_height = 2.0 * ui_distance * tan(deg_to_rad(camera.fov) * 0.5)
	var quad_width = quad_height * aspect_ratio
	
	left_view = VRViewInfo.new()
	right_view = VRViewInfo.new()
	
	left_view.index = 0
	left_view.replicated_ui = replicated_ui.duplicate()
	left_view.ui_quad = OpenXRCompositionLayerQuad.new()
	camera.add_child(left_view.ui_quad)
	left_view.viewport = SubViewport.new()
	add_child(left_view.viewport)
	
	left_view.ui_quad.layer_viewport = left_view.viewport
	left_view.ui_quad.alpha_blend = true
	
	var render_target_size = xr_interface.get_render_target_size()
	aspect_ratio = render_target_size.x / render_target_size.y
	
	var left_projection = xr_interface.get_projection_for_view(0, aspect_ratio, 0.001, 10000.0)
	var right_projection = xr_interface.get_projection_for_view(1, aspect_ratio, 0.001, 10000.0)
	
	var left_forward: Vector3 = Vector3(left_projection.z.x, left_projection.z.y, left_projection.z.z)
	var right_forward: Vector3 = Vector3(right_projection.z.x, right_projection.z.y, right_projection.z.z)
	
	left_ui_quad.position += left_forward * ui_distance
	right_ui_quad.position += right_forward * ui_distance
	
	
	
	left_ui_quad.quad_size = Vector2(quad_width, quad_height) * 1.2
	left_ui_quad.layer_viewport.size = left_ui_quad.quad_size * 1000
	
	right_ui_quad.quad_size = left_ui_quad.quad_size
	right_ui_quad.layer_viewport.size = left_ui_quad.layer_viewport.size
	


func project_point_viewport(point: Vector3, quad: OpenXRCompositionLayerQuad) -> Vector2:
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
