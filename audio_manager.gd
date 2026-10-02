extends Node
# Autoload as "Audio" (Project Settings → Autoload)

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var sfx := {
	"jump": preload("res://audio/jump.wav"),
	"land": preload("res://audio/land.wav"),
	"hurt": preload("res://audio/hurt.wav"),
	"goal": preload("res://audio/goal.wav"),
	"pickup": preload("res://audio/pickup.wav"),
}


func _ready() -> void:
	music_player.stream = preload("res://audio/music_loop.wav")
	music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.bus = "Music"
	music_player.play()
	print(music_player.volume_db)
	print(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	print("music playing: ", music_player.playing)


func play_sfx(sfx_name: String) -> void:
	if sfx.has(sfx_name):
		sfx_player.stream = sfx[sfx_name]
		sfx_player.bus = "SFX"
		sfx_player.play()
