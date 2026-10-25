extends Node2D

const new_global_event_data: Array = [
]

const new_event_data: Array = [
	[ false, "Placeholder yet", null, null, null ],
	[ true, 0.5, 0.5, null, null ],
	[ true, 0.5, 0.5, null, null ],
	[ true, 0.0, 0.0, 1, null ],
	[ true, 0.0, 0.0, null, null ],
	[ true, 1.0, 1.0, null, null ],
	[ true, 1.0, 1.0, null, null ],
	[ true, 1.0, 1.0, 1, true ],
	[ true, 1.0, 1.0, null, null ],

	[ true, 0.0, 0.0, 1, null ],
	[ true, 0.0, 0.0, null, null ],
	[ true, 0.0, 0.0, null, null ],
	[ true, 0.0, 0.0, false, null ],
	[ true, 0.0, 0.0, null, null ],
	[ true, 1.0, 1.0, 1, null ],
	[ true, 0.0, 0.0, 1, null ],
	[ true, 0.0, 0.0, 2, null ],

	[ false, null, null, 1, null ],
	[ true, _DataManager.line_color, _DataManager.line_color, null, null ],
	[ true, _DataManager.note_color[0], _DataManager.note_color[0], null, null ],
	[ true, _DataManager.note_color[1], _DataManager.note_color[1], null, null ],
	[ true, _DataManager.note_color[2], _DataManager.note_color[2], null, null ],
	[ true, _DataManager.note_color[3], _DataManager.note_color[3], null, null ],
	[ true, _DataManager.note_color[4], _DataManager.note_color[4], null, null ],
	[ true, _DataManager.note_color[5], _DataManager.note_color[5], null, null ],

	[ true, 1.0, 1.0, null, null ],
	[ false, -1000.0, 1200.0, false, null ],
	[ false, 1200.0, 420.0, false, null ],
	[ false, 0.0, 1.0, null, null ],
	[ false, "", null, null, null ],
	[ true, 2.0, 2.0, null, null ],
	[ true, 100.0, 100.0, null, null ],
	[ false, 75.0, null, 0, null ],

	[ false, null, null, 0, null ],
	[ true, 0.0, 0.0, false, null ],
	[ true, 0.0, 0.0, 1, null ],
	[ true, 0.0, 0.0, 2, null ],
	[ true, 0.0, 1.0, 0, 0 ],
	[ false, null, null, 0, null ],
	[ true, 1.1, 1.1, false, null ],
	[ false, null, null, 1, null ],

	[ false, "", null, false, false ],
	[ false, "Not yet", null, null, null ],
	[ false, "Not yet", null, null, null ],
	[ false, "Not yet", null, null, null ],
	[ false, 0, null, null, null ],
]

const specified_event_value_types: Array = [
	
]

const new_note_data: Array = [
]

@onready var player: Node3D = SceneManager.get_scene("player")
@onready var viewport: SubViewport = $viewport_container/viewport

@onready var new_info: ColorRect = $new_chart
@onready var new_info_title: LineEdit = $new_chart/margin/container/title
@onready var new_info_artist: LineEdit = $new_chart/margin/container/artist
@onready var new_info_illust: LineEdit = $new_chart/margin/container/illust
@onready var new_info_chart: LineEdit = $new_chart/margin/container/chart
@onready var new_info_level: LineEdit = $new_chart/margin/container/level
@onready var new_info_bpm: LineEdit = $new_chart/margin/container/bpm

@onready var main_ui: ColorRect = $main_ui
@onready var page_scroller: PanelContainer = $main_ui/scroller
@onready var page_page: HBoxContainer = $main_ui/scroller/page
@onready var line_page: Control = $right_bar/lines/scroller
@onready var progress_drag: Button = $bottom_bar/progress/frame/drag

var drag_menu: Array = [
	[
		"编辑器",
		[
			[
				"保存",
				save,
			],
			[
				"退出",
				(func() -> void:
					if _dirty == 0:
						exit()
					else:
						var dialog: Node = await SceneManager.insert("dialog")
						dialog.data = {
							type = 1,
							title = "警告",
							content = "有%s个未保存的更改" % [_dirty],
							options = [
								{
									enabled = true,
									main = "保存并退出",
									tip = "Save & Exit",
									function = (func() -> void:
										save()
										exit()
										),
								},
								{ enabled = false },
								{
									enabled = true,
									main = "不保存",
									tip = "Exit",
									function = (func() -> void:
										var node: Node2D = await SceneManager.change_scene("song_select")
										node.load_illust()
										),
								},
							]
						}
					)
			],
		]
	],
	[
		"判定线",
		[
			[
				"新建",
				(func() -> void:
					_data_new_line()
					_load_lines()
					),
			],
		]
	],
]

var _music_player: FmodOggPlayer
var _seek_playing: bool = false

var _line_items: Array = []
var _page_items: Array = []

var _dirty: int = 0

var edit_pages: Array = []
var beat: float = 0.0

var chart_info: Dictionary
var chart_data: Array = []

func _tween_enter() -> void:
	player.editor = true

func _tween_leave() -> void:
	player.editor = false
	player.stop()
	chart_data = []
	_load_lines()
	edit_pages = []
	_load_pages()

func _sort_event(event_a: Array, event_b: Array):
	return event_a[3] < event_b[3]

func _sort_event_build_index(event_group: Array) -> void:
	event_group.sort_custom(_sort_event)
	for i: int in event_group.size():
		event_group[i][0] = i

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _load_player() -> void:
	edit_pages = []
	beat = 0.0
	new_info.visible = false
	new_info.process_mode = Node.PROCESS_MODE_DISABLED
	player.load_chart(chart_info)
	player.start()
	player.pause()
	_music_player = player._player
	chart_data = player.chart_data

func _load_pages() -> void:
	for item: Control in _page_items:
		page_page.remove_child(item)
	_page_items = []
	if valid():
		for page: int in edit_pages:
			var new_item: Control = preload("res://scenes/editor_page_item.tscn").instantiate()
			new_item.root = self
			new_item.scroller = page_scroller
			new_item.main_ui = main_ui
			new_item.page = page
			_page_items.append(new_item)
			page_page.add_child(new_item)
		page_scroller.scroll_max = maxf(edit_pages.size() * 768.0 - 1536.0, 0.0)

func _load_lines() -> void:
	for item: Control in _line_items:
		line_page.remove_child(item)
	_line_items = []
	if valid():
		var y: float = 0.0
		var size: int = chart_data[1].size()
		for index: int in size:
			var new_item: Control = preload("res://scenes/editor_line_item.tscn").instantiate()
			new_item.root = self
			new_item.position.y = y
			new_item.index = index
			new_item.visible = true
			_line_items.append(new_item)
			line_page.add_child(new_item)
			y += 108.0
		line_page.scroll_max = maxf(size * 107.0 - 781.0, 0.0)

func save() -> void:
	var save_chart: Array = chart_data.duplicate_deep()
	for line: Array in save_chart[1]:
		line[7] = []
	var chart_path: String = chart_info.path.path_join(chart_info.id)
	Json.write_file_crypt(chart_path + ".cslc", save_chart)
	_dirty = 0

func exit() -> void:
	var node: Node2D = await SceneManager.change_scene("song_select")
	node.load_illust()

func _ready() -> void:
	viewport.add_child(player)

func _data_new_line() -> void:
	var line_event_final: Array = []
	line_event_final.resize(100)
	for i: int in 100:
		line_event_final[i] = []
	var line_event_cull: Array = []
	line_event_cull.resize(100)
	line_event_cull.fill(0)
	var lines: Array = chart_data[1]
	var status: Array = DataManager.new_status(lines.size())
	lines.append( [ line_event_final, line_event_cull, [], [0], [], [], [0], status, "New Line" ] )
	_dirty += 1

func _data_new_event(events: Array, _beat: float, type: int) -> void:
	var default: Array = new_event_data[type]
	var event_time: float = DataManager.beat_to_ms(chart_data, _beat)
	var length_raw: Variant = null
	var event_length: Variant = null
	var delta: Variant = null
	if default[0]:
		length_raw = 1.0
		event_length = DataManager.beat_to_ms(chart_data, _beat + 1.0) - event_time
		delta = default[2] - default[1]
	var v1: Variant = default[1]
	if v1 is Color:
		v1 = v1.to_rgba32()
	var v2: Variant = default[2]
	if v2 is Color:
		v2 = v2.to_rgba32()
	var event: Array = [
		0,
		type,
		_beat,
		event_time,
		length_raw,
		event_length,
		0,
		v1,
		v2,
		default[3],
		default[4],
		delta,
	]
	events.append(event)
	_sort_event_build_index(events)
	_dirty += 1

func new_chart() -> void:

	if not chart_info.path:

		var file_dialog: FileDialog = FileDialog.new()
		add_child(file_dialog)
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.filters = ["*.ogg"]
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.use_native_dialog = true
		file_dialog.file_selected.connect(func(file_path: String):
			remove_child(file_dialog)

			var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(file_path)
			var length: float = stream.get_length() * 1000.0
			var new_song_info: Dictionary = {
				title = new_info_title.text,
				artist = new_info_artist.text,
				illust = new_info_illust.text,
				preview = { begin = 0, end = length },
				tag = "Editor",
				length = length,
			}
			var chapter_path: String = "user://editor"
			var song_id: String = str(randi_range(0, 999999))
			while DirAccess.dir_exists_absolute(chapter_path.path_join(song_id)):
				song_id = str(randi_range(0, 999999))
			var song_path: String = chapter_path.path_join(song_id)
			DirAccess.make_dir_absolute(song_path)
			Json.write_file(song_path.path_join("info.json"), new_song_info)

			chart_info = {
				external = true,
				level = new_info_level.text,
				chart = new_info_chart.text,
				difficulty = { index = 6, value = -1, plus = false },
				save = false,
			}
			var chart_id: String = str(randi_range(0, 999999))
			while DirAccess.dir_exists_absolute(song_path.path_join(chart_id)):
				chart_id = str(randi_range(0, 999999))
			chart_info.id = chart_id
			chart_info.path = song_path
			var chart_path: String = song_path.path_join(chart_id)
			DirAccess.make_dir_absolute(chart_path)
			Json.write_file(chart_path.path_join("info.json"), chart_info)

			var global_event_final: Array = []
			global_event_final.resize(100)
			for i: int in 100:
				global_event_final[i] = []
			var global_event_cull: Array = []
			global_event_cull.resize(100)
			global_event_cull.fill(0)
			chart_data = [ [ 0, 180, 0 ], [], global_event_final, global_event_cull, [], [] ]
			Json.write_file_crypt(chart_path + ".cslc", chart_data)

			DirAccess.copy_absolute(file_path, song_path.path_join("music.ogg"))

			load_chart(chart_info)
		)
		file_dialog.popup_file_dialog()

	else:
		pass

func load_chart(info: Dictionary) -> void:
	chart_info = info
	if chart_info.id:
		_load_player()
		_load_lines()

	else:
		new_info.visible = true
		new_info.process_mode = Node.PROCESS_MODE_PAUSABLE

func valid() -> bool:
	return not chart_data.is_empty()

func pause() -> void:
	player.pause()

func play() -> void:
	player.resume()

func playing() -> bool:
	return not _music_player.is_paused()

func seek_begin() -> void:
	_seek_playing = playing()
	_music_player.pause()

func seek_progress(progress: float) -> void:
	var ms: float = progress * player._music_length
	beat = DataManager.ms_to_beat(chart_data, ms)
	seek_time(ms)

func seek_beat(_beat: float) -> void:
	beat = _beat
	var ms: float = DataManager.beat_to_ms(chart_data, _beat)
	var progress: float = ms / player._music_length
	progress_drag.set_value(progress)
	seek_time(ms)

func seek_time(ms: float) -> void:
	_music_player.seek(ms)

func seek_end() -> void:
	if _seek_playing:
		_music_player.resume()

func _process(_delta: float) -> void:
	if valid():
		pass
	pass
