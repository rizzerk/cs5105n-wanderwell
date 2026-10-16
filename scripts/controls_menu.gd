extends Control
# Controls screen: two key slots per action. Select a slot, then press the new key.
# Esc cancels while waiting for a key, otherwise goes back to the main menu.

const ACTIONS := [
	["move_left", "Move Left"],
	["move_right", "Move Right"],
	["jump", "Jump"],
	["crouch", "Crouch"],
]

@onready var grid: GridContainer = $UI/Root/Center/Panel/VBox/Grid
@onready var hint: Label = $UI/Root/Center/Panel/VBox/Hint
@onready var reset_button: Button = $UI/Root/Center/Panel/VBox/Buttons/ResetButton
@onready var back_button: Button = $UI/Root/Center/Panel/VBox/Buttons/BackButton
@onready var ui_root: Control = $UI/Root

var slot_buttons := {}  # action -> [Button, Button]
var listening_for: String = ""
var listening_slot: int = -1
var _hint_text: String
var _pulse: Tween


func _ready() -> void:
	_hint_text = hint.text
	for pair in ACTIONS:
		_add_row(pair[0], pair[1])
	_refresh_all()
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	slot_buttons[ACTIONS[0][0]][0].grab_focus()  # keyboard / controller can start right away
	ui_root.modulate.a = 0.0
	create_tween().tween_property(ui_root, "modulate:a", 1.0, 0.4)


func _add_row(action: String, label_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.theme_type_variation = &"StatValueLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(label)

	slot_buttons[action] = []
	for slot in Settings.SLOTS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 0)
		button.pressed.connect(_on_slot_pressed.bind(action, slot))
		grid.add_child(button)
		slot_buttons[action].append(button)


func _refresh_all() -> void:
	for action in slot_buttons:
		var keys := Settings.get_keys(action)
		for slot in Settings.SLOTS:
			slot_buttons[action][slot].text = Settings.key_name(keys[slot]) if slot < keys.size() else "-"


func _on_slot_pressed(action: String, slot: int) -> void:
	_stop_listening()
	listening_for = action
	listening_slot = slot
	var button: Button = slot_buttons[action][slot]
	button.text = "Press a key"
	hint.text = "Press a key for %s  -  Esc to cancel" % _action_label(action)
	_pulse = create_tween().set_loops()
	_pulse.tween_property(button, "modulate:a", 0.45, 0.45)
	_pulse.tween_property(button, "modulate:a", 1.0, 0.45)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if listening_for == "":
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_on_back_pressed()
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		_stop_listening()
		return
	var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	Settings.rebind(listening_for, listening_slot, keycode)
	_stop_listening()


func _stop_listening() -> void:
	if _pulse:
		_pulse.kill()
	if listening_for != "":
		slot_buttons[listening_for][listening_slot].modulate.a = 1.0
	listening_for = ""
	listening_slot = -1
	hint.text = _hint_text
	_refresh_all()


func _action_label(action: String) -> String:
	for pair in ACTIONS:
		if pair[0] == action:
			return pair[1]
	return action


func _on_reset_pressed() -> void:
	_stop_listening()
	Settings.reset_to_defaults()
	_refresh_all()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
