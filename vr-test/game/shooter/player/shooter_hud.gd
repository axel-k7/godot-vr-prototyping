extends Control

@onready var cooldown_label: Label = $HFlowContainer/CooldownLabel

func set_cooldown(_value: float):
	cooldown_label.text = str(snapped(_value, 0.01))
