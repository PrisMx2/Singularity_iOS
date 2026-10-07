extends Node3D

const effect_color: Array = [
	Color(0x8970F0FF),
	Color(0x99CCEFFF),
	Color(0xB93C3FFF)
]

@export var camera: Camera3D
@export var player: Node3D

@onready var basic_width: float = player.basic_width
@onready var basic_height: float = player.basic_height
@onready var basic_center: Vector3 = player.basic_center

var _effect_color: Array = []
var _timer: float = 0.0
var _touch_data: Dictionary = {}

var judgement_offset: float = 0.0
var judgement_method: int = 0
var autoplay: bool = false

var playing_stat: Array = []
var judgement_effects: Array = []

var chart_info: Dictionary = {}
var chart_data: Array = []

func _tween_before() -> void:
	playing_stat = [ 0, 0, 0, 0, [], 0, 0, 0, 0, [] ]

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _search_index(data: Array, index: int) -> int:
	var root: int = index
	while data[root] != root:
		root = data[root]
	while data[index] != index:
		var next: int = data[index]
		data[index] = root
		index = next
	return root

func _mark_index(data: Array, index: int) -> void:
	if index > -1 and index < data.size() - 1:
		data[index] = _search_index(data, index + 1)

func _ready() -> void:
	for i: int in 3:
		var color: Color = effect_color[i].srgb_to_linear()
		_effect_color.append(Vector4(color.r, color.g, color.b, 0.0))

func load_chart() -> void:
	chart_info = player.chart_info
	chart_data = player.chart_data

	judgement_offset = player.judgement_offset
	judgement_method = player.judgement_method
	autoplay = player.autoplay

func _judge(line: Array, note: Array, time: float) -> bool:
	var status: Array = line[7]
	for level: int in 3 if note[4] == null else 2:
		if time < status[level + 3]:
			if note[4] != null:
				note[15] = level + 1
			else:
				_mark_index(line[6], note[0])
				note[0] = -1
				if not note[13]:
					playing_stat[level] += 1
					if level == 2:
						playing_stat[4].append(playing_stat[5])
						playing_stat[5] = 0
					else:
						playing_stat[5] += 1
			var type: int = note[1]
			if not note[13] and type != 5:
				_generate_effect(status, note, level)
				if type == 0 or type == 1:
					SoundManager.play("tap")
				elif type == 2 or type == 3:
					SoundManager.play("drag")
				elif type == 4:
					SoundManager.play("flick")
			return true
	return false

func _judgement(note_list: Array) -> void:
	if note_list.size() > 0:
		if judgement_method == 0:
			note_list.sort_custom(func(a: Dictionary, b: Dictionary):
				var t_a: float = absf(a.delta_time)
				var t_b: float = absf(b.delta_time)
				return a.dpos < b.dpos if t_a == t_b else t_a < t_b
			)
		elif judgement_method == 1:
			note_list.sort_custom(func(a: Dictionary, b: Dictionary):
				var t_a: float = a.delta_time
				var t_b: float = b.delta_time
				return a.dpos < b.dpos if t_a == t_b else t_a < t_b
			)
		elif judgement_method == 2:
			note_list.sort_custom(func(a: Dictionary, b: Dictionary):
				var p_a: float = a.dpos
				var p_b: float = b.dpos
				return a.delta_time < b.delta_time if p_a == p_b else p_a < p_b
			)
		for data: Dictionary in note_list:
			var line: Array = data.line
			var delta_time: float = data.delta_time
			if _judge(line, data.note, absf(delta_time)):
				playing_stat[9].append(delta_time)
				_generate_judgement_effect( -delta_time / line[7][5] )
				break

func _generate_effect(status: Array, note: Array, level: int) -> void:
	var pos: Vector3
	if status[1] == 1:
		var _transform: Transform3D = status[19]
		_transform = _transform.rotated(Vector3.BACK, ( note[16] + 1.0 ) * status[15] / 2.0)
		pos = _transform * Vector3(0.0, status[13] / 2.0, 0.0)
	else:
		pos = status[19] * Vector3(note[16] * status[13] / 2.0, 0.0, 0.0)
	var cam: Vector3 = status[17]
	var proj: Vector2 = status[18]
	chart_data[4].append({
		time = _get_time(),
		color = _effect_color[level],
		camera_pos = Vector4(cam.x, cam.y, cam.z, 0.0),
		proj_pos = Vector4(proj.x, proj.y, 0.0, 0.0),
		pos = pos,
	})

func _generate_judgement_effect(ratio: float) -> void:
	judgement_effects.append({
		time = _get_time(),
		ratio = ratio,
	})

func _calcuate_all() -> void:

	var time: float = _get_time()
	for line: Array in chart_data[1]:
		var status: Array = line[7]
		var style: int = status[1]
		if style > -1:
			var touchs: Dictionary = status[10]
			var pos: Vector3 = status[11]
			var rot: Vector3 = status[12]
			if style == 1:
				rot.x = 0.0
			var _basis: Basis = Basis.from_euler(rot, EulerOrder.EULER_ORDER_ZYX)
			var plane: Plane = Plane(-_basis.z, pos)
			for _key: int in _touch_data:
				var t_data: Array = _touch_data[_key]
				var event: InputEvent = t_data[0]
				var index: int = event.index
				var _position: Vector2 = event.position
				var ray_origin: Vector3 = camera.project_ray_origin(_position)
				var ray_normal: Vector3 = camera.project_ray_normal(_position)
				var intersection = plane.intersects_ray(ray_origin, ray_normal)
				if intersection == null:
					touchs.erase(index)
					continue
				var local: Vector3 = ( intersection - pos ) / status[13] * 2.0 * _basis
				var flick: bool = event.relative.length() / ( time - t_data[1] ) > 72.0 if event is InputEventScreenDrag else false
				var data: Array = [ flick ]
				if style == 1:
					data.append( sqrt(pow(local[0], 2.0) + pow(local[1], 2.0)) )
					var angle: float = wrapf(atan2(-local[0], local[1]), 0, TAU)
					for i: int in 3:
						data.append( ( angle + TAU * ( i - 1 ) ) / status[15] * 2.0 - 1.0 )
				else:
					data.append_array([local.y, local.x])
				touchs[index] = data

func _calcuate(_position: Vector2, status: Array) -> Array:
	var style: int = status[1]
	var pos: Vector3 = status[11]
	var rot: Vector3 = status[12]
	if style == 1:
		rot.x = 0.0
	var _basis: Basis = Basis.from_euler(rot, EulerOrder.EULER_ORDER_ZYX)
	var plane: Plane = Plane(-_basis.z, pos)
	var ray_origin: Vector3 = camera.project_ray_origin(_position)
	var ray_normal: Vector3 = camera.project_ray_normal(_position)
	var intersection = plane.intersects_ray(ray_origin, ray_normal)
	if intersection == null:
		return [ false, INF ]
	var local: Vector3 = ( intersection - pos ) / status[13] * 2.0 * _basis
	var data: Array = [ false ]
	if style == 1:
		data.append( sqrt(pow(local[0], 2.0) + pow(local[1], 2.0)) )
		var angle: float = wrapf(atan2(-local[0], local[1]), 0, TAU)
		for i: int in 3:
			data.append( ( angle + TAU * ( i - 1 ) ) / status[15] * 2.0 - 1.0 )
		return data
	else:
		data.append_array([absf(local.y), local.x])
		return data

func _unhandled_input(event: InputEvent) -> void:

	var time: float = player.get_player_time()
	var time_raw: float = _get_time()

	if chart_data.is_empty() or autoplay:
		return

	if event is InputEventScreenTouch:
		if event.pressed:

			_touch_data[event.index] = [ event, time_raw ]
			var note_list: Array = []
			for line: Array in chart_data[1]:
				var status: Array = line[7]
				var style: int = status[1]
				if style > -1:
					var j_bad: float = status[5]
					var j_width: float = status[7]
					var j_height: float = status[8]
					var touch: Array = _calcuate(event.position, status)
					if touch[1] < j_height:
						status[10][event.index] = touch

						var line_note: Array = line[5]
						for _index: int in range(_search_index(line[6], 0), line_note.size()):
							var note: Array = line_note[_index]
							if note[0] < 0 or note[13] or note[14] or note[15]:
								continue
							var delta_time: float = note[3] - time - judgement_offset
							if delta_time > j_bad:
								break
							var type: int = note[1]
							if type == 0 or type == 1:
								var pos: float = note[7]
								if style == 1:
									for i: int in 3:
										var dpos: float = absf(pos - touch[i + 2])
										if dpos < note[8] * j_width / 10.0:
											note_list.append({
												delta_time = delta_time,
												dpos = dpos,
												line = line,
												note = note
											})
											break
								else:
									var dpos: float = absf(pos - touch[2])
									if dpos < note[8] * j_width / 10.0:
										note_list.append({
											delta_time = delta_time,
											dpos = dpos,
											line = line,
											note = note
										})
			_judgement(note_list)

		else:
			var index: int = event.index
			for line: Array in chart_data[1]:
				var status: Array = line[7]
				status[10].erase(index)
			_touch_data.erase(index)

	elif event is InputEventScreenDrag:
		_touch_data[event.index] = [ event, time_raw ]

func _physics_process(_delta: float) -> void:

	if chart_data.is_empty():
		return

	var time: float = player.get_player_time()
	var time_raw: float = _get_time()
	var tick: bool = false
	if time_raw - _timer > 200.0:
		_timer = time_raw
		tick = true

	if autoplay:
		for line: Array in chart_data[1]:
			var status: Array = line[7]
			var line_note: Array = line[5]
			var line_note_cull: Array = line[6]
			for _index: int in range(_search_index(line_note_cull, 0), line_note.size()):
				var note: Array = line_note[_index]
				if note[0] < 0:
					continue
				var delta_time: float = note[3] - time
				if delta_time > 0.0:
					break
				if note[15]:
					if delta_time < -note[4]:
						_mark_index(line_note_cull, note[0])
						note[0] = -1
						if not note[13]:
							playing_stat[note[15] - 1] += 1
							playing_stat[5] += 1
							if note[1] != 5:
								_generate_effect(status, note, note[15] - 1)
						continue
					if not note[13]:
						if tick and note[1] != 5:
							_generate_effect(status, note, note[15] - 1)
				else:
					_judge(line, note, 0.0)
					continue

	else:
		_calcuate_all()

		for line: Array in chart_data[1]:
			var status: Array = line[7]
			var style: int = status[1]
			var j_perfect: float = status[3]
			var j_good: float = status[4]
			var j_miss: float = status[6]
			var j_width: float = status[7]
			var j_height: float = status[8]
			var miss: Dictionary = status[9]
			var touch: Dictionary = status[10]

			var line_note: Array = line[5]
			var line_note_cull: Array = line[6]
			for _index: int in range(_search_index(line_note_cull, 0), line_note.size()):
				var note: Array = line_note[_index]
				if note[0] < 0:
					continue
				var delta_time: float = note[3] - time - judgement_offset
				var delta_time_offseted: float = delta_time
				if delta_time_offseted > j_good:
					break
				var type: int = note[1]
				if delta_time < 0.0:
					if note[15]:
						if delta_time < -note[4]:
							miss.erase(_index)
							_mark_index(line_note_cull, note[0])
							note[0] = -1
							if not note[13]:
								playing_stat[note[15] - 1] += 1
								playing_stat[5] += 1
								_generate_effect(status, note, note[15] - 1)
							continue
					elif delta_time_offseted < -j_miss:
						if not note[13]:
							playing_stat[3] += 1
							playing_stat[4].append(playing_stat[5])
							playing_stat[5] = 0
						if note[4] == null:
							_mark_index(line_note_cull, note[0])
							note[0] = -1
						else:
							note[13] = true
							note[15] = true
						continue
					elif type == 5 or note[14]:
						_judge(line, note, 0.0)
						continue
				if note[13] or note[14]:
					continue
				var cpos: float = note[16]
				if type == 4:
					var keep: bool = false
					for _key: int in touch:
						var data: Array = touch[_key]
						if data[0] and data[1] < j_height:
							if style == 1:
								for i: int in 3:
									var dpos: float = abs(cpos - data[i + 2])
									if dpos < note[8] * j_width / 10.0:
										keep = true
										break
							else:
								var dpos: float = abs(cpos - data[2])
								if dpos < note[8] * j_width / 10.0:
									keep = true
									break
					if keep:
						note[14] = true
				else:
					var keep: bool = false
					for _key: int in touch:
						var data: Array = touch[_key]
						if data[1] < j_height:
							if style == 1:
								for i: int in 3:
									var dpos: float = abs(cpos - data[i + 2])
									if dpos < note[8] * j_width / 10.0:
										keep = true
										break
							else:
								var dpos: float = abs(cpos - data[2])
								if dpos < note[8] * j_width / 10.0:
									keep = true
									break
					if note[15] and type != 5:
						if keep:
							miss.erase(_index)
							if tick:
								_generate_effect(status, note, note[15] - 1)
						elif delta_time + note[4] > j_perfect:
							if miss.has(_index):
								if time - miss[_index] > j_perfect:
									note[13] = true
									playing_stat[3] += 1
									playing_stat[4].append(playing_stat[5])
									playing_stat[5] = 0
							else:
								miss[_index] = time
					elif keep:
						if type == 2:
							note[14] = true
						elif delta_time < 0.0:
							if type == 3:
								_judge(line, note, 0.0)
							elif type == 5:
								playing_stat[2] += 1
								playing_stat[4].append(playing_stat[5])
								playing_stat[5] = 0
								_generate_effect(status, note, 2)
								note[13] = true
								note[15] = 1

			for _key: int in touch:
				touch[_key][0] = false

	var note_count: float = max(chart_data[0][2], 1)

	var accuracy_back: float = 1.0 - ( playing_stat[1] * 0.75 + playing_stat[2] + playing_stat[3] ) / note_count
	playing_stat[7] = accuracy_back

	var accuracy: float = ( playing_stat[0] + playing_stat[1] * 0.75 ) / note_count
	playing_stat[6] = accuracy
	var score: float = accuracy * 9500000
	for combo: int in playing_stat[4]:
		score += pow(combo / note_count, 1.2) * 500000
	score += pow(playing_stat[5] / note_count, 1.2) * 500000
	playing_stat[8] = score
