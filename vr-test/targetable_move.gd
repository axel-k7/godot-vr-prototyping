extends Targetable

@export var speed_scale: float = 1.0
var time: float = 0.0

func _process(delta: float) -> void:
	super(delta)
	time += delta*speed_scale
	position.x += sin(time)
