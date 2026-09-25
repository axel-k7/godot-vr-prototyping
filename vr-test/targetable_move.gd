extends Targetable

var time: float = 0.0

func _process(delta: float) -> void:
	super(delta)
	time += delta
	position.x += sin(time)
