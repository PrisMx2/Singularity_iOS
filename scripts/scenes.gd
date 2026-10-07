extends Node

var _scenes: Dictionary = {
	main = [ true ],
	login = [ true ],
	chapter_selection = [ true ],
	chapter_confirm = [ true ],
	unlock = [ true ],
	unlock_sp = [ true ],
	song_select = [ false ],
	main_chapters = [ true ],
	player_ui = [ true ],
	pause_ui = [ true ],
	player = [ false ],
	clear = [ false ],
	dialog = [ true ],
	settings = [ true ],
	offset_test = [ false ],
	credits = [ false ],
	licence = [ false ],
	editor = [ false ],
}
var _loaded: Dictionary = {}

var _cover_a: ColorRect = ColorRect.new()
var _cover_b: ColorRect = ColorRect.new()

var _bgm: AudioStreamPlayer
var _bgm_tween: Tween
var _bgm_status: int = -1

var _focus_record: bool = false

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _ready() -> void:
	Input.use_accumulated_input = false

	for key: String in _scenes:
		_loaded[key] = load("res://scenes/".path_join(key + ".tscn")).instantiate()

	_cover_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover_a.color = Color(0x000000FF)
	_cover_a.size = Vector2(1920.0, 1080.0)
	_cover_a.z_index = 127

	_cover_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover_b.color = Color(0x000000FF)
	_cover_b.size = Vector2(1920.0, 1080.0)
	_cover_b.z_index = 127

	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	_bgm.bus = "bgm"
	_bgm.stream = preload("res://sounds/stellar_genome_firsttake.ogg")
	_bgm.finished.connect(func() -> void:
		var stream: AudioStreamOggVorbis = preload("res://sounds/stellar_genome_repeat.ogg")
		stream.loop = true
		_bgm.stream = stream
		_bgm.play()
	)
	_bgm.volume_linear = 0.0

	_bgm_tween = create_tween()
	_bgm_tween.kill()

func get_scene(scene: String) -> Node:
	return _loaded[scene]

func change_scene(scene: String, _leave: bool = true) -> Node:
	var node_a: Node = get_tree().current_scene

	get_viewport().gui_disable_input = true
	if _leave:
		await TweenTrigger.execute_leave(node_a)
	_cover_a.self_modulate.a = 0.0
	node_a.add_child(_cover_a)
	var tween_a: Tween = create_tween()
	tween_a.set_ease(Tween.EASE_IN)
	tween_a.set_trans(Tween.TRANS_QUAD)
	tween_a.tween_property(_cover_a, "self_modulate:a", 1.0, 0.2).from(0.0)
	tween_a.tween_interval(0.1)
	await tween_a.finished

	var config: Array = _scenes[scene]
	if config[0]:
		resume_bgm()
	else:
		pause_bgm()

	var node_b: Node = get_scene(scene)
	if node_a == node_b:
		await TweenTrigger.execute_before(node_b)
		change_scene_self(node_b)

	else:
		_cover_b.self_modulate.a = 1.0
		node_b.add_child(_cover_b)
		get_tree().root.add_child(node_b)
		await TweenTrigger.execute_break(node_a)
		await TweenTrigger.execute_before(node_b)
		get_tree().current_scene = node_b

		node_a.remove_child(_cover_a)
		get_tree().root.remove_child(node_a)

		change_scene_enter(node_b)
	return node_b

func change_scene_and_leave(scene: String, node_b: Node) -> Node:
	var node_a: Node = get_tree().current_scene
	var node_c: Node = await change_scene(scene, false)

	node_a.remove_child(node_b)

	return node_c

func change_scene_self(node_b: Node) -> Node:
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	await RenderingServer.frame_post_draw

	var tween_a: Tween = create_tween()
	tween_a.set_ease(Tween.EASE_OUT)
	tween_a.set_trans(Tween.TRANS_QUAD)
	tween_a.tween_interval(0.1)
	tween_a.tween_property(_cover_a, "self_modulate:a", 0.0, 0.2).from(1.0)
	await tween_a.finished

	node_b.remove_child(_cover_a)
	await TweenTrigger.execute_enter(node_b)
	get_viewport().gui_disable_input = false
	return node_b

func change_scene_enter(node_b: Node) -> Node:
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	await RenderingServer.frame_post_draw

	var tween_b: Tween = create_tween()
	tween_b.set_ease(Tween.EASE_OUT)
	tween_b.set_trans(Tween.TRANS_QUAD)
	tween_b.tween_interval(0.1)
	tween_b.tween_property(_cover_b, "self_modulate:a", 0.0, 0.2).from(1.0)
	await tween_b.finished

	node_b.remove_child(_cover_b)
	await TweenTrigger.execute_enter(node_b)
	get_viewport().gui_disable_input = false

	return node_b

func insert(scene: String) -> Node:
	var node_a: Node = get_tree().current_scene
	var node_b: Node = get_scene(scene)

	get_viewport().gui_disable_input = true
	node_a.add_child(node_b)
	await TweenTrigger.execute_break(node_a)
	await TweenTrigger.execute_before(node_b)

	insert_enter(node_b)
	return node_b

func insert_enter(node_b: Node) -> Node:
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	await RenderingServer.frame_post_draw

	await TweenTrigger.execute_enter(node_b)
	get_viewport().gui_disable_input = false
	return node_b

func leave(node_b: Node) -> Node:
	var node_a: Node = get_tree().current_scene

	get_viewport().gui_disable_input = true
	await TweenTrigger.execute_break(node_b)
	await TweenTrigger.execute_leave(node_b)
	node_a.remove_child(node_b)
	get_viewport().gui_disable_input = false

	return node_a

func unknown_function() -> void:
	var dialog: Node = await SceneManager.insert("dialog")
	dialog.data = {
		title = "generic.notice",
		content = "generic.unknown",
		options = [
			{ enabled = false },
			{ enabled = true },
			{ enabled = false },
		]
	}

func start_bgm() -> void:
	_bgm.play()
	_bgm_tween = create_tween()
	_bgm_tween.set_ease(Tween.EASE_IN)
	_bgm_tween.set_trans(Tween.TRANS_SINE)
	_bgm_tween.tween_property(_bgm, "volume_linear", 1.0, 5.0)

func pause_bgm() -> bool:
	if _bgm_status == 1:
		return false
	_bgm_status = 1
	if _bgm_tween.is_running():
		await _bgm_tween.finished
	_bgm_tween = create_tween()
	_bgm_tween.set_ease(Tween.EASE_IN)
	_bgm_tween.set_trans(Tween.TRANS_SINE)
	_bgm_tween.tween_property(_bgm, "volume_linear", 0.0, 1.0)
	await _bgm_tween.finished
	_bgm.stream_paused = true
	return true

func resume_bgm() -> bool:
	if _bgm_status == 0:
		return true
	_bgm_status = 0
	if _bgm_tween.is_running():
		await _bgm_tween.finished
	if not _bgm.has_stream_playback():
		_bgm.play()
	_bgm.stream_paused = false
	_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.set_ease(Tween.EASE_IN)
	_bgm_tween.set_trans(Tween.TRANS_SINE)
	_bgm_tween.tween_property(_bgm, "volume_linear", 1.0, 1.0)
	return true

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focus_record = _bgm.playing
		_bgm.stream_paused = true
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		if _focus_record:
			await get_tree().process_frame
			_bgm.stream_paused = false

func _process(_delta: float) -> void:
	RenderingServer.global_shader_parameter_set("time", _get_time())
