extends VRInstance

@export var target: Targetable

@export var target_left_rect: TextureRect
var target_right_rect: TextureRect

@export var static_left: Control
var static_right: Control


func _ready() -> void:
	super()
	target_right_rect = add_ui(target_left_rect)
	static_right = add_ui(static_left)

func _process(delta: float) -> void:
	target_left_rect.position = _project_point_viewport(target.global_position, left_ui) - target_left_rect.size*0.5
	target_right_rect.position = _project_point_viewport(target.global_position, right_ui) - target_right_rect.size*0.5
