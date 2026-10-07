extends Node2D

const new_global_event_data: Array = [
]

const new_event_data: Array = [
	[ 0.5, 0.5, null, null ]
]

const new_note_data: Array = [
]

@onready var player: Node3D = SceneManager.get_scene("player")
@onready var viewport: SubViewport = $main_ui/viewport_container/viewport

@onready var new_info: ColorRect = $new_chart
@onready var new_info_title: LineEdit = $new_chart/margin/container/title
@onready var new_info_artist: LineEdit = $new_chart/margin/container/artist
@onready var new_info_illust: LineEdit = $new_chart/margin/container/illust
@onready var new_info_chart: LineEdit = $new_chart/margin/container/chart
@onready var new_info_level: LineEdit = $new_chart/margin/container/level
@onready var new_info_bpm: LineEdit = $new_chart/margin/container/bpm

@onready var line_page: Control = $right_bar/mask/scroller
@onready var line_item: ColorRect = $right_bar/mask/scroller/item

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
					_dirty += 1
					_load_lines()
					),
			],
		]
	],
]

var _line_items: Array = []

var edit_pages: Array = []
var beat: float = 0.0

var chart_info: Dictionary
var chart_data: Array = []

var _dirty: int = 0

func _tween_after() -> void:
	player.editor = true

func _tween_leave() -> void:
	player.editor = false

func _sort(event_a: Dictionary, event_b: Dictionary):
	return event_a[3] < event_b[3]

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _load_player() -> void:
	new_info.visible = false
	new_info.process_mode = Node.PROCESS_MODE_DISABLED
	player.load_chart(chart_info)
	player.start()
	player.pause()
	chart_data = player.chart_data

func _load_lines() -> void:
	if valid():
		for item: Control in _line_items:
			line_page.remove_child(item)
		var y: float = 0.0
		for index: int in chart_data[1].size():
			var new_item: Control = line_item.duplicate()
			new_item.position.y = y
			new_item.index = index
			new_item.visible = true
			_line_items.append(new_item)
			line_page.add_child(new_item)
			y += 108.0

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

func _data_new_event(events: Array, time: float, type: int) -> void:
	var event: Array = []
	var data: Array = new_global_event_data if type < 0 else new_event_data
	event[2] = time
	event[3] = DataManager.beat_to_ms(chart_data, time)
	for i in 4:
		event[i + 6] = data[i]
	events.append(event)
	events.sort_custom(_sort)

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
			Json.write_file_crypt(song_path.path_join("info.json"), new_song_info)

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
			Json.write_file_crypt(chart_path.path_join("info.json"), chart_info)

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






func drag_time(progress: float) -> void:
	var ms: float = progress * player._music_length
	beat = DataManager.ms_to_beat(chart_data, ms)









func _process(_delta: float) -> void:
	if valid():
		pass
	pass
