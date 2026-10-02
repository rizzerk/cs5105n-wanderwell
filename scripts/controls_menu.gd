extends Control

@onready var buttons := {
	"move_left": $MarginContainer/VBoxContainer/RowMoveLeft/KeyButton,
	"move_right": $MarginContainer/VBoxContainer/RowMoveRight/KeyButton,
	"jump": $MarginContainer/VBoxContainer/RowJump/KeyButton,
	"crouch": $MarginContainer/VBoxContainer/RowCrouch/KeyButton,
}
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

var listening_for: String = ""


func _ready() -> void:
	for action in buttons:
		_refresh_button(action)
		# connect each button's click to a listening function, remembering which action it's for
		buttons[action].pressed.connect(_on_key_button_pressed.bind(action))
	back_button.pressed.connect(_on_back_pressed)


func _refresh_button(action: String) -> void:
	var events := InputMap.action_get_events(action)
	if events.size() > 0:
		buttons[action].text = events[0].as_text()
	else:
		buttons[action].text = "Unbound"


func _on_key_button_pressed(action: String) -> void:
	listening_for = action
	buttons[action].text = "Press a key..."


func _input(event: InputEvent) -> void:
	if listening_for == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		Settings.rebind(listening_for, event)
		_refresh_button(listening_for)
		listening_for = ""
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
