extends Node

const SAVE_PATH := "user://keybinds.cfg"
const REBINDABLE := ["move_left", "move_right", "jump", "crouch"]


func _ready() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return  # no saved file yet, that's fine on first run

	for action in REBINDABLE:
		if cfg.has_section_key("keys", action):
			var keycode: int = cfg.get_value("keys", action)
			InputMap.action_erase_events(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)


func rebind(action: String, event: InputEventKey) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)

	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)  # ignore error, we're about to overwrite anyway
	cfg.set_value("keys", action, event.physical_keycode)
	cfg.save(SAVE_PATH)
