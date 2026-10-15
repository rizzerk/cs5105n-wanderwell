extends Node
# Autoload as "Settings". Key rebinds, saved to user://keybinds.cfg.
# Each action can have up to two keys (e.g. A and Left Arrow), stored as physical keycodes.

const SAVE_PATH := "user://keybinds.cfg"
const REBINDABLE := ["move_left", "move_right", "jump", "crouch"]
const SLOTS := 2


func _ready() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return  # no saved file yet, that's fine on first run

	for action in REBINDABLE:
		if cfg.has_section_key("keys", action):
			var saved: Variant = cfg.get_value("keys", action)
			# Week 5 saves held a single keycode, newer ones hold a list
			_set_keys(action, saved if saved is Array else [saved])


# Keycodes bound to an action, in slot order
func get_keys(action: String) -> Array:
	var keys := []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return keys


# Puts a key in one slot of an action. A key only ever does one thing: if another action
# (or this action's other slot) already had it, it's taken off there.
func rebind(action: String, slot: int, keycode: int) -> void:
	for other in REBINDABLE:
		var other_keys := get_keys(other)
		if other != action and keycode in other_keys:
			other_keys.erase(keycode)
			_set_keys(other, other_keys)

	var keys := get_keys(action)
	keys.erase(keycode)
	if slot < keys.size():
		keys[slot] = keycode
	else:
		keys.append(keycode)
	_set_keys(action, keys)
	_save()


func reset_to_defaults() -> void:
	InputMap.load_from_project_settings()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


# Key name for the menu, e.g. "A", "Space", "Left". Desktop shows it as printed on this
# keyboard layout (AZERTY etc.); Web can't look up layouts, so it uses the QWERTY name.
func key_name(keycode: int) -> String:
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		keycode = DisplayServer.keyboard_get_keycode_from_physical(keycode)
	return OS.get_keycode_string(keycode)


func _set_keys(action: String, keycodes: Array) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for keycode in keycodes.slice(0, SLOTS):
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func _save() -> void:
	var cfg := ConfigFile.new()
	for action in REBINDABLE:
		cfg.set_value("keys", action, get_keys(action))
	cfg.save(SAVE_PATH)
