extends Node

const rank: Array = ["0", "D", "C", "B", "A", "N", "Z", "X", "F", "R"]
const rank_score: Array = [0, 0, 750, 825, 900, 925, 950, 975, 990, 1000]
const rank_color: Array = [
	[Color(0xBBBBCCFF),Color(0xBBBBCCFF)],
	[Color(0xCCCCDDFF),Color(0xCCCCDDFF)],
	[Color(0xDDDDEEFF),Color(0xDDDDEEFF)],
	[Color(0xEEEEFFFF),Color(0xEEEEFFFF)],
	[Color(0xFFFFFFFF),Color(0xFFFFFFFF)],
	[Color(0x82EFCEFF),Color(0x82EFCEFF)],
	[Color(0xE384B8FF),Color(0xE384B8FF)],
	[Color(0x99CCEFFF),Color(0x99CCEFFF)],
	[Color(0xCCCCFFFF),Color(0xCCCCFFFF)],
	[Color(0xFF2666FF),Color(0x00FFE6FF)],
]

var _chapter_data: Dictionary = {}
var _save_data: Dictionary = {}
var _log_data: Array = []
var _dirty: bool = false

func beat_to_ms(chart: Array, beat: float) -> float:
	var _time: float = 0.0
	var _beat: float = 0.0
	var _bpm: float = chart[0][1]
	for bpm_event: Array in chart[5]:
		if bpm_event[0] >= beat:
			break
		_time = bpm_event[1]
		_beat = bpm_event[0]
		_bpm = bpm_event[2]
	_time += ( beat - _beat ) * ( 60000 / _bpm )
	return _time

func ms_to_beat(chart: Array, ms: float) -> float:
	var _beat: float = 0.0
	var _time: float = 0.0
	var _bpm: float = chart[0][1]
	for bpm_event: Array in chart[5]:
		if bpm_event[1] >= ms:
			break
		_beat = bpm_event[0]
		_time = bpm_event[1]
		_bpm = bpm_event[2]
	_beat += ( ms - _time ) / ( 60000.0 / _bpm )
	return _beat

func _ms_to_distance(events: Array, time: float) -> float:
	var _time: float = 0.0
	var _length: float = 0.0
	var _speed: float = 1.0
	var _acceleration: float = 0.0
	var _distance: float = 0.0
	for speed_event: Array in events:
		if speed_event[0] >= time:
			break
		_time = speed_event[0]
		_length = speed_event[1]
		_speed = speed_event[2]
		_acceleration = speed_event[3]
		_distance = speed_event[4]
	var delta_time: float = time - _time
	var cut_time: float = minf(delta_time, _length)
	_distance += cut_time * _speed
	_distance += cut_time ** 2.0 * _acceleration / 2.0
	_speed += cut_time * _acceleration
	cut_time = delta_time - cut_time
	_distance += cut_time * _speed
	return _distance

func _snappedpf(x: Variant) -> Variant:
	return null if x == null else snappedf(x, 0.0001)

func _sort(event_a: Dictionary, event_b: Dictionary):
	return abs(event_a.type) < abs(event_b.type) if event_a.time == event_b.time else event_a.time < event_b.time

func new_status(index: int) -> Array:
	return [
		index, 0, 0, 075.0, 120.0, 155.0, 175.0, 2.0, 100.0, {}, {},
		Vector3(), Vector3(), 0.0, 0.0, 0.0, Vector2(), Vector3(), Vector2(), Transform3D(),
	]

func convert_chart(chart_info: Dictionary, chart_data: Dictionary) -> Array:

	var info: Array = [
		chart_data.delay,
		chart_info.bpm,
		0,
	]

	if chart_data.event is Dictionary:
		chart_data.event = []
	var line: Array = []
	var global_event: Array = chart_data.event.duplicate_deep()
	var global_event_final: Array = []
	global_event_final.resize(100)
	global_event_final.fill([])
	global_event_final = global_event_final.duplicate_deep()
	var global_event_cull: Array = []
	global_event_cull.resize(100)
	global_event_cull.fill(0)
	var effect: Array = []
	var bpm_events: Array = []

	var converted_chart: Array[Array] = [
		info, line,
		global_event_final, global_event_cull,
		effect, bpm_events
	]

	global_event.sort_custom(_sort)
	for event: Dictionary in global_event:
		if event.type == -1:
			var _beat: float = event.time
			var _time: float = beat_to_ms(converted_chart, _beat)
			bpm_events.append([ _beat, _time, event.value.v1 ])

	for event: Dictionary in global_event:

		var time_raw: float = event.time
		var event_time: float = _snappedpf(beat_to_ms(converted_chart, time_raw))

		var event_length: Variant = null
		if event.has("length"):
			var time_finish: float = time_raw + event.length
			event_length = _snappedpf(beat_to_ms(converted_chart, time_finish) - event_time)

		var event_type: int = - int(event.type)
		var event_easing: int = int(event.easing) - 1 if event.has("easing") else 0
		var value: Dictionary = event.value
		if value.has("v1") and value.has("v2"):
			value.delta = _snappedpf(value.v2 - value.v1)
		var array: Array = global_event_final[event_type]
		var new_event: Array = [
			array.size(),
			event_type,
			time_raw,
			event_time,
			event_length,
			event_easing,
			value.get("v1"),
			value.get("v2"),
			value.get("v3"),
			value.get("v4"),
			value.get("delta"),
		]
		array.append(new_event)

	for _line: Dictionary in chart_data.line:

		if _line.event is Dictionary:
			_line.event = []
		var line_event: Array = _line.event.duplicate_deep()
		var line_event_final: Array = []
		line_event_final.resize(100)
		line_event_final.fill([])
		line_event_final = line_event_final.duplicate_deep()
		var line_event_cull: Array = []
		line_event_cull.resize(100)
		line_event_cull.fill(0)
		if not _line.has("event_layer") or _line.event_layer is Dictionary:
			_line.event_layer = []
		var line_event_layer: Array = _line.event_layer.duplicate_deep()
		var line_event_layer_final: Array = []
		var line_event_layer_cull: Array = []
		var speed_events: Array = []
		if _line.note is Dictionary:
			_line.note = []
		var line_note: Array = _line.note.duplicate_deep()
		var line_note_final: Array = []
		var line_note_cull: Array = []

		var new_line: Array = [
			line_event_final, line_event_cull,
			line_event_layer_final, line_event_layer_cull,
			speed_events,
			line_note_final, line_note_cull,
			[], "Compiled Line"
		]
		line.append(new_line)

		line_event.sort_custom(_sort)
		for event: Dictionary in line_event:

			var time_raw: float = event.time
			var event_time: float = _snappedpf(beat_to_ms(converted_chart, time_raw))

			var event_length: Variant = null
			if event.has("length"):
				var time_finish: float = time_raw + event.length
				event_length = _snappedpf(beat_to_ms(converted_chart, time_finish) - event_time)

			var event_type: int = int(event.type)
			event_length = _snappedpf(event_length)
			var event_easing: int = int(event.easing) - 1 if event.has("easing") else 0
			var value: Dictionary = event.value
			if event_type >= 19 and event_type <= 24:
				for key: String in ["v3", "v4"]:
					var color: int = value[key]
					if color == 0x2FA7DA:
						value[key] = 0x6488E5
					elif color == 0xDAC400:
						value[key] = 0x009834
					elif color == 0xDA79A5:
						value[key] = 0xD3863A
					elif color == 0xBB0000:
						value[key] = 0xAE4242
			if value.has("v1") and value.has("v2"):
				value.delta = _snappedpf(value.v2 - value.v1)
			var array: Array = line_event_final[event_type]
			var new_event: Array = [
				array.size(),
				event_type,
				time_raw,
				event_time,
				event_length,
				event_easing,
				value.get("v1"),
				value.get("v2"),
				value.get("v3"),
				value.get("v4"),
				value.get("delta"),
			]
			array.append(new_event)
			if event_type == 5:
				var _time: float = event_time
				var _length: float = event_length
				var _speed: float = new_event[6]
				var _acceleration: float = ( new_event[7] - _speed ) / _length
				var _distance: float = _ms_to_distance(speed_events, _time)
				speed_events.append([
					_time, _length, _speed, _acceleration, _distance
				])

		line_event_layer.sort_custom(_sort)
		for event: Dictionary in line_event_layer:
			var time_raw: float = event.time
			var event_time: float = _snappedpf(beat_to_ms(converted_chart, time_raw))

			var event_length: Variant = null
			if event.has("length"):
				var time_finish: float = time_raw + event.length
				event_length = _snappedpf(beat_to_ms(converted_chart, time_finish) - event_time)

			var event_type: int = int(event.type)
			event_length = _snappedpf(event_length)
			var event_easing: int = int(event.easing) - 1 if event.has("easing") else 0
			var value: Dictionary = event.value
			if value.has("v1") and value.has("v2"):
				value.delta = _snappedpf(value.v2 - value.v1)
			var array: Array = line_event_layer_final
			var index: int = array.size()
			var new_event: Array = [
				index,
				event_type,
				time_raw,
				event_time,
				event_length,
				event_easing,
				value.get("v1"),
				value.get("v2"),
				value.get("v3"),
				value.get("v4"),
				value.get("delta"),
			]
			array.append(new_event)
			line_event_layer_cull.append(index)
		line_event_layer_cull.append(line_event_layer_final.size())

		line_note.sort_custom(_sort)
		for note: Dictionary in line_note:

			var time_raw: float = note.time
			var note_time: float = _snappedpf(beat_to_ms(converted_chart, time_raw))
			var note_distance: float = _snappedpf(_ms_to_distance(speed_events, note_time) / 1000.0)

			var note_length: Variant = null
			var note_distance_length: Variant = null
			if note.has("length"):
				var time_finish: float = time_raw + note.length
				note_length = _snappedpf(beat_to_ms(converted_chart, time_finish) - note_time)
				time_finish = note_time + note_length
				note_distance_length = _snappedpf(_ms_to_distance(speed_events, time_finish) / 1000.0 - note_distance)

			var note_type: int = int(note.type) - 1
			var note_pos: float = _snappedpf(note.pos)
			var note_width: float = _snappedpf(note.width)
			var note_endpos: Variant = _snappedpf(note.get("endpos"))
			var note_speed: float = _snappedpf(note.speed) if note.has("speed") else 1.0
			var note_texture_vec: float = _snappedpf(randf_range(0.0, TAU))
			var array: Array = line_note_final
			var index: int = array.size()
			var new_note: Array = [
				index,
				note_type,
				time_raw,
				note_time,
				note_length,
				note_distance,
				note_distance_length,
				note_pos,
				note_width,
				note_endpos,
				note_speed,
				note_texture_vec,
				note.gold,
				note.fake,
				note.auto,
				false,
				note_pos,
			]
			array.append(new_note)
			line_note_cull.append(index)
			if not note.fake:
				converted_chart[0][2] += 1
		line_note_cull.append(line_note_final.size())

	return converted_chart

func generate_data() -> void:
	var chapter_list: Dictionary = {}
	var root_path: String = "res://chapter/"
	var chapters: DirAccess = DirAccess.open(root_path)
	chapters.list_dir_begin()
	var chapter: String = chapters.get_next()
	while chapter:
		if chapters.current_is_dir():
			var song_list: Array = []
			var chapter_dir: String = root_path.path_join(chapter)
			chapter_list[chapter] = song_list
			var songs: DirAccess = DirAccess.open(chapter_dir)
			songs.list_dir_begin()
			var song: String = songs.get_next()
			while song:
				if songs.current_is_dir():
					var chart_list: Array = []
					var song_dir: String = chapter_dir.path_join(song)
					var song_info: Dictionary = Json.load_file(song_dir.path_join("info.json"))
					song_list.append({
						song = song,
						chart = [ song_info, chart_list ]
					})
					var charts: DirAccess = DirAccess.open(song_dir)
					charts.list_dir_begin()
					var chart: String = charts.get_next()
					while chart:
						if charts.current_is_dir():
							var chart_path: String = song_dir.path_join(chart)
							var chart_info: Dictionary = Json.load_file(chart_path.path_join("info.json"))
							chart_info.id = chart
							chart_list.append(chart_info)
							var chart_data: Dictionary = Json.load_file(chart_path.path_join("data.json"))
							var converted_chart: Array = convert_chart(chart_info, chart_data)
							Json.write_file_crypt(song_dir.path_join(chart + ".cslc"), converted_chart)
						chart = charts.get_next()
					chart_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
						var diff_a: Dictionary = a.difficulty
						var diff_b: Dictionary = b.difficulty
						var value_a: float = diff_a.value + ( 0.5 if diff_a.plus else 0.0 )
						var value_b: float = diff_b.value + ( 0.5 if diff_b.plus else 0.0 )
						var index_a: int = diff_a.index
						var index_b: int = diff_b.index
						return not ( value_a < value_b if index_a == index_b else index_a < index_b )
					)
				song = songs.get_next()
			song_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var index_a: int = a.song.split("_")[0].to_int()
				var index_b: int = b.song.split("_")[0].to_int()
				return index_a < index_b
			)
		chapter = chapters.get_next()
	Json.write_file_crypt(root_path.path_join("chapter.cslu"), chapter_list)
	var unlock: Dictionary = Json.load_file(root_path.path_join("unlock.json"))
	Json.write_file_crypt(root_path.path_join("unlock.cslu"), unlock)

func read_chapter() -> void:
	_chapter_data = Json.load_file_crypt("res://chapter/chapter.cslu")
	for chapter: String in _chapter_data:
		var song_list: Array = _chapter_data[chapter]
		for song: Dictionary in song_list:
			var song_name: String = song.song
			var song_data: Array = song.chart
			var song_info: Dictionary = song_data[0]
			for chart_info: Dictionary in song_data[1]:
				chart_info.merge(song_info, false)
				chart_info.save = ".".join([chapter, song_name, chart_info.id])
				chart_info.path = "res://chapter".path_join("/".join([chapter, song_name]))
			song.chart = song_data[1]

func get_chapter(id: String) -> Array:
	if id == "editor":
		var song_list: Array = [
			{
				song = "new",
				chart = [{
					title = "New Chart",
					artist = "Singularity",
					illust = "Unknown",
					tag = "Unknown",
					id = false,
					level = "Unknown",
					chart = "Unknown",
					difficulty = { index = 6, value = -1, plus = false },
					save = false,
					path = false,
				}]
			}
		]
		var chapter_dir: String = "user://editor"
		var songs: DirAccess = DirAccess.open(chapter_dir)
		if songs == null:
			DirAccess.make_dir_recursive_absolute(chapter_dir)
			songs = DirAccess.open(chapter_dir)
		songs.list_dir_begin()
		var song: String = songs.get_next()
		while song:
			if songs.current_is_dir():
				var chart_list: Array = []
				var song_dir: String = chapter_dir.path_join(song)
				var song_info: Dictionary = Json.load_file_crypt(song_dir.path_join("info.json"))
				song_list.append({
					song = song,
					chart = chart_list
				})
				var charts: DirAccess = DirAccess.open(song_dir)
				charts.list_dir_begin()
				var chart: String = charts.get_next()
				while chart:
					if charts.current_is_dir():
						var chart_path: String = song_dir.path_join(chart)
						var chart_info: Dictionary = Json.load_file_crypt(chart_path.path_join("info.json"))
						chart_info.merge({
							id = chart,
							save = false,
							path = "user://editor".path_join(song),
						}, true)
						chart_info.merge(song_info, false)
						chart_list.append(chart_info)
						chart = charts.get_next()
					chart = charts.get_next()
			song = songs.get_next()
		return song_list
	else:
		var chapter: Array = _chapter_data[id]
		return chapter

func read_save() -> void:
	if FileAccess.file_exists("user://save"):
		_save_data = Json.load_file_crypt("user://save")
	for chapter: String in _chapter_data:
		var song_list: Array = _chapter_data[chapter]
		for song_data: Dictionary in song_list:
			for chart: Dictionary in song_data.chart:
				if not _save_data.has(chart.save):
					_save_data[chart.save] = {
						accuracy = 0.0,
						score = 0.0,
						rank = 0,
						unlock = false,
					}
	save_save()

func get_save(id: String, default: Variant = null) -> Variant:
	if id == "none":
		return default
	elif _save_data.has(id):
		return _save_data[id]
	else:
		return set_save(id, default)

func match_save(id: String) -> Array:
	var result: Array = []
	for key: String in _save_data:
		if key.match(id):
			result.append(_save_data[key])
	return result

func set_save(id: String, data: Variant) -> Variant:
	_save_data[id] = data
	_dirty = true
	return data

func save_save() -> void:
	Json.write_file_crypt("user://save", _save_data)

func append_log(...list: Array) -> void:
	var string_list: Array = []
	for item: Variant in list:
		string_list.append(str(item))
	var text: String = Time.get_time_string_from_system() + ": " + " ".join(string_list)
	print(text)
	_log_data.append(text)

func get_log() -> String:
	return "\n".join(_log_data)

func _ready() -> void:
	if OS.has_feature("editor"):
		generate_data()
	read_chapter()
	read_save()

	var timer: Timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(func() -> void:
		if _dirty:
			save_save()
			_dirty = false
	)
	add_child(timer)
	timer.start()
