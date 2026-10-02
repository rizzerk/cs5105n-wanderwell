extends CanvasLayer
# Autoload as "Hud"

@onready var label: Label = $MarginContainer/Label
var elapsed: float = 0.0


func _process(delta: float) -> void:
	elapsed += delta
	var m := int(elapsed) / 60
	var s := int(elapsed) % 60
	label.text = "%02d:%02d" % [m, s]
