extends Node

var _players: Dictionary = {}
var _event_type: Dictionary = {

	tap = 0,
	drag = 0,
	flick = 0,
	#effect = 0,

	button_pressed = 1,
	input = 1,
	input_fail = 1,
	play = 1,
	#ui = 1,

	#music = 2,

	#bgm = 3,
}

func load_resources() -> void:
	for key: String in _event_type:
		var path: String = "res://sounds".path_join(key + ".ogg")
		DataManager.append_log("Sounds: Original File", path, ":", FileAccess.file_exists(path))
		var player: FmodOggPlayer = FmodServer.create_player_by_ogg(path)
		player.set_one_shot(true)
		_players[key] = player
		DataManager.append_log("Sounds: Successfully created one-shot player", key)

func set_volume(type: int, volume: float) -> void:
	for key: String in _event_type:
		if _event_type[key] == type:
			_players[key].set_volume(volume)

func play(key: String) -> FmodOggPlayer:
	var player: FmodOggPlayer = _players[key]
	player.play()
	DataManager.append_log("Sounds: Played sound", key)
	return player

func reboot() -> void:
	FmodServer.shutdown()
	var dsp_buffer: int = 2 ** DataManager.get_save("settings.dsp_buffer", 9)
	FmodServer.init_system(256, dsp_buffer, 2, 44100)
	DataManager.append_log("Sounds: Successfully (re)booted fmod system")
	DataManager.append_log("Sounds: Using", 256, dsp_buffer, 2, 22000)
	load_resources()

func _ready() -> void:
	reboot()

func _physics_process(_delta: float) -> void:
	FmodServer.update()
