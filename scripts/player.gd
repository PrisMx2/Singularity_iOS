extends Node3D

const basic_width: float = 19.2
const basic_height: float = 10.8
const basic_diagonal: float = sqrt(pow(basic_width, 2.0) + pow(basic_height, 2.0))
const basic_center: Vector3 = Vector3(basic_width / 2.0, basic_height / 2.0, 0.0)
const line_width_base: float = basic_height * 0.005
const frame_width: float = basic_height * 0.005
const double_frame_width: float = frame_width * 2.0

const contour: CompressedTexture2D = preload("res://textures/generic/contour_texture.png")

@onready var line_labels: Node3D = $line_labels
@onready var line_label: Label3D = $line_labels/item
@onready var judgement: Node3D = $judgement
@onready var _player_ui: Node2D = null

var _note_color: Array = [
	Color(0x6488E5FF).srgb_to_linear(),	# Tap
	Color(0x6488E5FF).srgb_to_linear(),	# Hold
	Color(0x009834FF).srgb_to_linear(),	# Drag
	Color(0x009834FF).srgb_to_linear(),	# Drag-Hold
	Color(0xD3863AFF).srgb_to_linear(),	# Flick
	Color(0xAE4242FF).srgb_to_linear(),	# Error
]

var _line_multimesh: MultiMesh
var _line_material: ShaderMaterial
var _line_data_array: PackedVector4Array
var _line_labels: Array = []

var _note_multimesh_0: MultiMesh
var _note_multimesh_1: MultiMesh
var _note_material_0: ShaderMaterial
var _note_material_1: ShaderMaterial
var _note_data_array: PackedVector4Array

var _effect_multimesh: MultiMesh
var _effect_material: ShaderMaterial
var _effect_data_array: PackedVector4Array
var _effect_size: float = 1.0

var _judgement_multimesh: MultiMesh
var _judgement_material: ShaderMaterial
var _judgement_enabled: bool = true

var _player: FmodOggPlayer
var _music_path: String = ""
var _music_start: float = 0.0
var _music_length: float = 0.0
var _music_offset: int = 0

var music_progress: float = 0.0
var judgement_offset: float = 0.0
var judgement_method: int = 0
var autoplay: bool = false
var editor: bool = false

var chart_info: Dictionary = {}
var chart_data: Array = []

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func get_player_time() -> float:
	if _music_start < 0.0:
		return _music_length
	elif _player.is_paused():
		_music_start = _get_time() - _player.get_position_ms()
	return maxf( _get_time() - _music_start - _music_offset - chart_data[0][0], 0.0 )

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

func _parse_color(hex: int) -> Color:
	return Color.hex(hex << 8 | 0xFF).srgb_to_linear()

func _ready() -> void:
	$camera.fov = rad_to_deg(atan2(5.4, 19.2)) * 2.0

	_init_render()
	_line_data_array = PackedVector4Array()
	_line_data_array.resize(640)
	_note_data_array = PackedVector4Array()
	_note_data_array.resize(2688)
	_effect_data_array = PackedVector4Array()
	_effect_data_array.resize(768)

func _init_render() -> void:

	var aabb: AABB = AABB(Vector3(), Vector3.ONE)

	var quad_mesh_bendable: QuadMesh = QuadMesh.new()
	quad_mesh_bendable.size = Vector2(1.0, 1.0)
	quad_mesh_bendable.subdivide_width = 0
	quad_mesh_bendable.subdivide_depth = 128

	var cylinder_mesh: CylinderMesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 1.0
	cylinder_mesh.bottom_radius = 1.0
	cylinder_mesh.height = 1.0
	cylinder_mesh.radial_segments = 96
	cylinder_mesh.rings = 6
	cylinder_mesh.cap_top = false
	cylinder_mesh.cap_bottom = false

	var torus_mesh: TorusMesh = TorusMesh.new()
	torus_mesh.inner_radius = 1.0
	torus_mesh.outer_radius = 0.25
	torus_mesh.rings = 48
	torus_mesh.ring_segments = 4

	var quad_mesh_simple: QuadMesh = QuadMesh.new()
	quad_mesh_simple.size = Vector2(1.0, 1.0)
	quad_mesh_simple.subdivide_width = 0
	quad_mesh_simple.subdivide_depth = 0

	_line_material = ShaderMaterial.new()
	_line_material.shader = preload("res://shaders/player/line.gdshader")
	_line_material.render_priority = 0
	$line_multimesh.material_override = _line_material

	_line_multimesh = MultiMesh.new()
	_line_multimesh.custom_aabb = aabb
	_line_multimesh.use_custom_data = true
	_line_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_line_multimesh.mesh = quad_mesh_bendable
	_line_multimesh.instance_count = 128
	_line_multimesh.visible_instance_count = 0
	$line_multimesh.multimesh = _line_multimesh

	_note_material_0 = ShaderMaterial.new()
	_note_material_0.shader = preload("res://shaders/player/note_0.gdshader")
	_note_material_0.set_shader_parameter("contour", contour)
	_note_material_0.render_priority = 1
	$note_multimesh_0.material_override = _note_material_0

	_note_multimesh_0 = MultiMesh.new()
	_note_multimesh_0.custom_aabb = aabb
	_note_multimesh_0.use_custom_data = true
	_note_multimesh_0.transform_format = MultiMesh.TRANSFORM_3D
	_note_multimesh_0.mesh = quad_mesh_bendable
	_note_multimesh_0.instance_count = 512
	_note_multimesh_0.visible_instance_count = 0
	$note_multimesh_0.multimesh = _note_multimesh_0

	_note_material_1 = ShaderMaterial.new()
	_note_material_1.shader = preload("res://shaders/player/note_1.gdshader")
	_note_material_1.set_shader_parameter("contour", contour)
	_note_material_1.render_priority = 1
	$note_multimesh_1.material_override = _note_material_1

	_note_multimesh_1 = MultiMesh.new()
	_note_multimesh_1.custom_aabb = aabb
	_note_multimesh_1.use_custom_data = true
	_note_multimesh_1.transform_format = MultiMesh.TRANSFORM_3D
	_note_multimesh_1.mesh = cylinder_mesh
	_note_multimesh_1.instance_count = 256
	_note_multimesh_1.visible_instance_count = 0
	$note_multimesh_1.multimesh = _note_multimesh_1

	_effect_material = ShaderMaterial.new()
	_effect_material.shader = preload("res://shaders/player/effect.gdshader")
	_effect_material.render_priority = 2
	$effect_multimesh.material_override = _effect_material

	_effect_multimesh = MultiMesh.new()
	_effect_multimesh.custom_aabb = aabb
	_effect_multimesh.use_custom_data = true
	_effect_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_effect_multimesh.mesh = torus_mesh
	_effect_multimesh.instance_count = 256
	_effect_multimesh.visible_instance_count = 0
	$effect_multimesh.multimesh = _effect_multimesh

	_judgement_material = ShaderMaterial.new()
	_judgement_material.shader = preload("res://shaders/player/judgement.gdshader")
	_judgement_material.render_priority = 3
	$judgement_multimesh.material_override = _judgement_material

	_judgement_multimesh = MultiMesh.new()
	_judgement_multimesh.custom_aabb = aabb
	_judgement_multimesh.use_custom_data = true
	_judgement_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_judgement_multimesh.mesh = quad_mesh_simple
	_judgement_multimesh.instance_count = 128
	_judgement_multimesh.visible_instance_count = 0
	$judgement_multimesh.multimesh = _judgement_multimesh

func load_ui() -> void:
	_player_ui = SceneManager.get_scene("player_ui")
	add_child(_player_ui)
	_player_ui.player = self
	_player_ui.judgement = judgement
	_player_ui.load_info(chart_info)

func unload_ui() -> void:
	if _player_ui:
		remove_child(_player_ui)
		_player_ui = null

func load_chart(info: Dictionary) -> void:
	stop()
	chart_info = info

	var song_path: String = chart_info.path
	var chart_path: String = song_path.path_join(chart_info.id)
	chart_data = Json.load_file_crypt(chart_path + ".cslc")
	_music_path = chart_path + ".ogg"
	if not FileAccess.file_exists(_music_path):
		_music_path = song_path.path_join("music.ogg")
	_player = FmodServer.create_player_by_ogg(_music_path)
	_player.set_volume(DataManager.get_save("settings.music_volume"))
	_music_offset = DataManager.get_save("settings.music_offset")

	ChartClient.append_data(Json.serialize(chart_data).to_utf8_buffer())

	_effect_size = DataManager.get_save("settings.effect_size") * 0.1 + 0.6
	_judgement_enabled = DataManager.get_save("settings.display_el")

	judgement_offset = DataManager.get_save("settings.judgement_offset") * 5.0
	judgement_method = DataManager.get_save("settings.judgement_method")
	autoplay = DataManager.get_save("settings.autoplay")

	for label: Label3D in _line_labels:
		line_labels.remove_child(label)
	_line_labels = []
	for index: int in chart_data[1].size():
		var label: Label3D = line_label.duplicate()
		_line_labels.append(label)
		line_labels.add_child(label)

		chart_data[1][index][7] = DataManager.new_status(index)

	judgement.load_chart()

func start() -> void:
	_music_length = _player.get_length_ms()
	_music_start = _get_time()
	_player.play()

func pause() -> void:
	_player.pause()

func resume() -> void:
	_player.resume()

func stop() -> void:
	if _player:
		_player.stop()
	_music_start = -1.0
	_music_length = 0.0
	chart_data = []

func restart() -> void:
	load_chart(chart_info)

func exit() -> void:
	var node: Node2D = await SceneManager.change_scene("song_select")
	node.load_illust()
	unload_ui()

func clear() -> void:
	stop()
	if autoplay:
		var node: Node2D = await SceneManager.change_scene("song_select")
		node.load_chapter()
		unload_ui()
	else:
		var node: Node2D = await SceneManager.change_scene("clear")
		node.playing_stat = judgement.playing_stat
		node.load_info(chart_info)

func _process(__delta: float) -> void:

	if chart_data.is_empty():
		return

	music_progress = get_player_time() / _music_length
	music_progress = 0.0 if is_nan(music_progress) or is_inf(music_progress) else maxf(music_progress, 0.0)
	if music_progress > 1.0:
		clear()
		return

	var time: float = get_player_time()
	var time_raw: float = _get_time()

	var global_pos: Vector3 = Vector3()
	var global_rot: Vector3 = Vector3()

	var event_cull: Array = chart_data[3]
	var event_groups: Array = chart_data[2]
	for type: int in range(27, 30):
		var event_list: Array = event_groups[type]
		for i: int in range(event_cull[type], event_list.size()):
			var event: Array = event_list[i]
			if event[3] > time:
				break
			var progress: float = 0.0
			if event[4] != null:
				progress = clampf( ( time - event[3] ) / event[4], 0.0, 1.0 )
				progress = Easings.Function[event[5]].call(progress)
			if type == 27: # GLOBAL_X
				global_pos.x = basic_width * ( event[6] + event[10] * progress )
			elif type == 28: # GLOBAL_Y
				global_pos.y = basic_height * ( event[6] + event[10] * progress )
			elif type == 29: # GLOBAL_R
				global_rot.z = deg_to_rad( event[6] + event[10] * progress )
			event_cull[type] = event[0]

	chart_data[1].sort_custom(func(a: Array, b: Array):
		a = a[7]; b = b[7]
		return a[0] < b[0] if a[2] == b[2] else a[2] < b[2]
	)

	for label: Label3D in _line_labels:
		label.text = ""
		label.visible = false

	var line_index: int = 0
	var note_index: int = 0
	var note_index_0: int = 0
	var note_index_1: int = 0

	for line: Array in chart_data[1]:

		var status: Array = line[7]
		var camera_pos: Vector3 = Vector3(0.0, 0.0, basic_width)

		var line_pos: Vector3 = basic_center;
		var line_rot: Vector3 = Vector3(0.0, 0.0, 0.0);
		var line_offset: float = 0.0
		var line_offset_angle: float = 0.0
		var line_offset_angle_z: float = 0.0

		var line_length: float = basic_width
		var line_length_multiplier: float = 2.0
		var line_width: float = line_width_base
		var line_start_color: Color = Color(0xFFFFFF00)
		var line_end_color: Color = Color(0xFFFFFF00)
		var line_start_alpha: float = 0.0
		var line_end_alpha: float = 0.0

		var line_text: String = ""
		var line_terminal: int = 0
		var line_style: int = 0
		var line_circle_angle: float = TAU
		var line_curve_control: Vector2 = Vector2(0.0, 0.0)

		var note_speed: float = 1.0
		var note_speed_mode: int = 1
		var note_upright: bool = false
		var note_start_time: float = -1000.0
		var note_end_time: float = 1200.0
		var note_start_color: Array = _note_color.duplicate()
		var note_end_color: Array = _note_color.duplicate()
		var note_start_alpha: float = 1.0
		var note_end_alpha: float = 1.0

		var note_gradient_start_time: float = 1200
		var note_gradient_end_time: float = 400
		var note_gradient_start_alpha: float = 1.0
		var note_gradient_end_alpha: float = 1.0

		var note_style: int = 0

		var effect_size: float = 1.2
		var effect_3d: bool = false

		var line_distance: float = DataManager._ms_to_distance(line[4], time) / 1000.0

		var line_event_cull: Array = line[1]
		var line_event_groups: Array = line[0]
		for type: int in range(1, 47):
			var line_event: Array = line_event_groups[type]
			for i: int in range(line_event_cull[type], line_event.size()):
				var event: Array = line_event[i]
				if event[3] > time:
					break
				var progress: float = 0.0
				if event[4] != null:
					progress = clampf( ( time - event[3] ) / event[4], 0.0, 1.0 )
					progress = Easings.Function[event[5]].call(progress)
				if type == 1: # X
					line_pos.x = basic_width * ( event[6] + event[10] * progress )
				elif type == 2: # Y
					line_pos.y = basic_height * ( event[6] + event[10] * progress )
				elif type == 3: # Z
					var v3: float = event[8]
					if v3 == 1:
						line_pos.z = -basic_width
					elif v3 == 2:
						line_pos.z = -basic_height
					elif v3 == 3:
						line_pos.z = -basic_diagonal
					line_pos.z *= event[6] + event[10] * progress
				elif type == 4: # R
					line_rot.z = deg_to_rad(event[6] + event[10] * progress)
				elif type == 5: # SPEED
					note_speed = event[6] + event[10] * progress
				elif type == 6: # ALPHA
					if event[4] == 0.0:
						line_start_alpha = event[6]
						line_end_alpha = event[7]
					else:
						var alpha: float = event[6] + event[10] * progress
						line_start_alpha = alpha
						line_end_alpha = alpha
				elif type == 7: # LENGTH
					var v3: float = event[8]
					if v3 == 1:
						line_length = basic_width
					elif v3 == 2:
						line_length = basic_height
					elif v3 == 3:
						line_length = basic_diagonal
					line_length *= event[6] + event[10] * progress
					line_length_multiplier = 2.0 if event[9] else 1.0
				elif type == 8: # WIDTH
					line_width = line_width_base * (event[6] + event[10] * progress)
				elif type == 9: #OFFSET
					var v3: float = event[8]
					if v3 == 1:
						line_offset = basic_width
					elif v3 == 2:
						line_offset = basic_height
					elif v3 == 3:
						line_offset = basic_diagonal
					line_offset *= event[6] + event[10] * progress
				elif type == 10: # OFFSET_R
					line_offset_angle = deg_to_rad(event[6] + event[10] * progress)
				elif type == 11: # OFFSET_ZR
					line_offset_angle_z = deg_to_rad(event[6] + event[10] * progress)
				elif type == 12: # FLIP
					line_rot.x = deg_to_rad(event[6] + event[10] * progress)
					note_upright = event[8]
				elif type == 13: # ROLL
					line_rot.y = deg_to_rad(event[6] + event[10] * progress)
				elif type == 14: # CAMERA_Z
					var v3: float = event[8]
					if v3 == 1:
						camera_pos.z = basic_width
					elif v3 == 2:
						camera_pos.z = basic_height
					elif v3 == 3:
						camera_pos.z = basic_diagonal
					camera_pos.z *= event[6] + event[10] * progress
				elif type == 15: # CAMERA_X
					var v3: float = event[8]
					if v3 == 1:
						camera_pos.x = basic_width
					elif v3 == 2:
						camera_pos.x = basic_height
					elif v3 == 3:
						camera_pos.x = basic_diagonal
					camera_pos.x *= event[6] + event[10] * progress
				elif type == 16: # CAMERA_Y
					var v3: float = event[8]
					if v3 == 1:
						camera_pos.y = basic_width
					elif v3 == 2:
						camera_pos.y = basic_height
					elif v3 == 3:
						camera_pos.y = basic_diagonal
					camera_pos.y *= event[6] + event[10] * progress
				elif type == 17: # SPEED_MODE
					note_speed_mode = int(event[8])
				elif type == 18: # COLOR
					if event[4] == 0.0:
						line_start_color = _parse_color(event[8])
						line_end_color = _parse_color(event[9])
					else:
						var color: Color = _parse_color(event[8])
						color += ( _parse_color(event[9]) - color ) * progress
						line_start_color = color
						line_end_color = color
				elif type >= 19 and type <= 24: #_note_color
					var note_type: int = type - 19
					if event[4] == 0.0:
						note_start_color[note_type] = _parse_color(event[8])
						note_end_color[note_type] = _parse_color(event[9])
					else:
						var color: Color = _parse_color(event[8])
						color += ( _parse_color(event[9]) - color ) * progress
						note_start_color[note_type] = color
						note_end_color[note_type] = color
				elif type == 25: # NOTE_ALPHA
					if event[4] == 0.0:
						note_start_alpha = event[6]
						note_end_alpha = event[7]
					else:
						var alpha: float = event[6] + event[10] * progress
						note_start_alpha = alpha
						note_end_alpha = alpha
				elif type == 26: # NOTE_TIME
					var d_time: float = ( event[3] - time ) if event[8] else 0.0
					note_start_time = event[6] + d_time
					note_end_time = event[7] + d_time
				elif type == 27: # NOTE_GRADIENT_TIME
					note_gradient_start_time = event[6]
					note_gradient_end_time = event[7]
				elif type == 28: # NOTE_GRADIENT_ALPHA
					note_gradient_start_alpha = event[6]
					note_gradient_end_alpha = event[7]
				elif type == 29: # TEXT
					line_text = event[6]
				elif type == 30: # JUDGEMENT_WIDTH
					status[7] = event[6] + event[10] * progress
				elif type == 31: # JUDGEMENT_HEIGHT
					status[8] = event[6] + event[10] * progress
				elif type == 32: # JUDGEMENT_TIME
					var v3: int = int(event[8])
					status[v3 + 3] = event[6]
				elif type == 33: # STYLE
					line_style = int(event[8])
				elif type == 34: # CIRCLE_ANGLE
					line_circle_angle = deg_to_rad(event[6] + event[10] * progress)
				elif type == 35: # CURVE_COLTROL_X
					var v3: float = event[8]
					if v3 == 1:
						line_curve_control.x = basic_width
					elif v3 == 2:
						line_curve_control.x = basic_height
					elif v3 == 3:
						line_curve_control.x = basic_diagonal
					line_curve_control.x *= event[6] + event[10] * progress
				elif type == 36: # CURVE_COLTROL_Y
					var v3: float = event[8]
					if v3 == 1:
						line_curve_control.y = basic_width
					elif v3 == 2:
						line_curve_control.y = basic_height
					elif v3 == 3:
						line_curve_control.y = basic_diagonal
					line_curve_control.y *= event[6] + event[10] * progress
				elif type == 37: # SENSOR
					pass
				elif type == 38: # NOTE_STYLE
					note_style = int(event[8])
				elif type == 39: # EFFECT_CONFIG
					effect_size = event[6] + event[10] * progress
					effect_3d = event[8]
				elif type == 40: # TERMINAL
					line_terminal = int(event[8]) - 1
				elif type == 41: # TEXTURE
					pass
				elif type == 42: # NOTE_TEXTURE
					pass
				elif type == 43: # EFFECT_TEXTURE
					pass
				elif type == 44: # HIT_SOUND
					pass
				elif type == 45: # LAYER
					status[2] = int(event[6])
				line_event_cull[type] = event[0]

		var line_event_layer: Array = line[2]
		var layer_dsu_index: int = _search_index(line[3], 0)
		for i: int in range(layer_dsu_index, line_event_layer.size()):
			var event: Array = line_event_layer[i]
			if event[0] < 0:
				continue
			if event[3] > time:
				break
			var type: int = event[1]
			var progress: float = 0.0
			if event[4] != null:
				progress = maxf( ( time - event[3] ) / event[4], 0.0 )
				if progress > 1.0:
					_mark_index(line[3], event[0])
					event[0] = -1
					continue
				progress = Easings.Function[event[5]].call(progress)
			if type == 1: # X
				line_pos.x += basic_width * ( event[6] + event[10] * progress )
			elif type == 2: # Y
				line_pos.y += basic_height * ( event[6] + event[10] * progress )
			elif type == 3: # Z
				var v3: float = event[8]
				if v3 == 1:
					v3 = -basic_width
				elif v3 == 2:
					v3 = -basic_height
				elif v3 == 3:
					v3 = -basic_diagonal
				line_pos.z += v3 * (event[6] + event[10] * progress)
			elif type == 4: # R
				line_rot.z += deg_to_rad(event[6] + event[10] * progress)
			elif type == 7: # LENGTH
				var v3: float = event[8]
				if v3 == 1:
					v3 = basic_width
				elif v3 == 2:
					v3 = basic_height
				elif v3 == 3:
					v3 = basic_diagonal
				line_length += v3 * (event[6] + event[10] * progress)
			elif type == 8: # WIDTH
				line_width += line_width_base * (event[6] + event[10] * progress)
			elif type == 9: # OFFSET
				var v3: float = event[8]
				if v3 == 1:
					v3 = basic_width
				elif v3 == 2:
					v3 = basic_height
				elif v3 == 3:
					v3 = basic_diagonal
				line_offset += v3 * (event[6] + event[10] * progress)
			elif type == 10: # OFFSET_R
				line_offset_angle += deg_to_rad(event[6] + event[10] * progress)
			elif type == 11: # OFFSET_ZR
				line_offset_angle_z += deg_to_rad(event[6] + event[10] * progress)
			elif type == 12: # FLIP
				line_rot.x += deg_to_rad(event[6] + event[10] * progress)
			elif type == 13: # ROLL
				line_rot.y += deg_to_rad(event[6] + event[10] * progress)
			elif type == 14: # CAMERA_Z
				var v3: float = event[8]
				if v3 == 1:
					v3 = basic_width
				elif v3 == 2:
					v3 = basic_height
				elif v3 == 3:
					v3 = basic_diagonal
				camera_pos.z += v3 * (event[6] + event[10] * progress)
			elif type == 15: # CAMERA_X
				var v3: float = event[8]
				if v3 == 1:
					v3 = basic_width
				elif v3 == 2:
					v3 = basic_height
				elif v3 == 3:
					v3 = basic_diagonal
				camera_pos.x += v3 * (event[6] + event[10] * progress)
			elif type == 16: # CAMERA_Y
				var v3: float = event[8]
				if v3 == 1:
					v3 = basic_width
				elif v3 == 2:
					v3 = basic_height
				elif v3 == 3:
					v3 = basic_diagonal
				camera_pos.y += v3 * (event[6] + event[10] * progress)

		var sin_flip: float = sin(line_rot.x)
		var cos_flip: float = cos(line_rot.x)
		line_rot.x *= 0.0 if line_style == 1 else -1.0
		line_rot.z += global_rot.z
		line_offset_angle *= 1.0
		line_pos += Vector3(line_offset, 0.0, 0.0).rotated(Vector3.UP, line_offset_angle_z).rotated(Vector3.FORWARD, -line_offset_angle)
		line_pos = ( line_pos - basic_center ).rotated(Vector3.FORWARD, -global_rot.z) + basic_center
		line_pos += global_pos
		var half_line_length: float = line_length / 2.0
		var proj_pos: Vector2 = Vector2(line_pos.x / basic_width, line_pos.y / basic_height)
		camera_pos = camera_pos.rotated(Vector3.FORWARD, -line_rot.z)

		var terminal_style: float = ( -1.0 if line_terminal == 1 else 1.0 ) * ( line_style + 0.1 )
		var camera_data_0: Vector4 = Vector4(
			camera_pos.x, camera_pos.y, camera_pos.z, terminal_style
		)
		var camera_data_1: Vector4 = Vector4(
			proj_pos.x, proj_pos.y, line_curve_control.x, line_curve_control.y
		)
		var line_color_a: Vector4 = Vector4(
			line_start_color.r, line_start_color.g, line_start_color.b, line_start_alpha
		)
		var line_color_b: Vector4 = Vector4(
			line_end_color.r, line_end_color.g, line_end_color.b, line_end_alpha
		)
		var line_basis: Basis = Basis.from_euler(line_rot, EulerOrder.EULER_ORDER_ZYX)
		var line_origin: Vector3 = Vector3(0.0, 0.0, line_pos.z)
		var line_transform: Transform3D = Transform3D(line_basis, line_origin)
		if line_text.length() > 0:
			var label: Label3D = _line_labels[status[0]]
			label.text = line_text
			label.visible = true
			label.modulate = Color(line_start_color, line_start_alpha)
			label.scale = Vector3(1.0, 1.0, 1.0) * line_width * 5.0 / basic_height
			label.rotation = line_rot
			label.position = line_pos - basic_center
		elif ( line_index < 128 and line_length > 0.0 and ( line_start_alpha > 0.0 or line_end_alpha > 0.0 )
		and ( line_style != 1 or line_circle_angle != 0 ) ):
			var line_array_index: int = line_index * 5
			_line_data_array.set(line_array_index, camera_data_0)
			_line_data_array.set(line_array_index + 1, camera_data_1)
			_line_data_array.set(line_array_index + 2, Vector4(
				line_length, line_length_multiplier, line_width, line_circle_angle
			))
			_line_data_array.set(line_array_index + 3, line_color_a)
			_line_data_array.set(line_array_index + 4, line_color_b)
			_line_multimesh.set_instance_custom_data(line_index, Color(line_index + 0.1, 0.0, 0.0, 0.0))
			_line_multimesh.set_instance_transform(line_index, line_transform)
			line_index += 1

		status[1] = line_style
		status[11] = line_pos - basic_center
		status[12] = line_rot
		status[13] = line_length
		status[14] = line_length_multiplier
		status[15] = line_circle_angle
		status[16] = line_curve_control
		status[17] = camera_pos
		status[18] = proj_pos
		status[19] = line_transform

		for i: int in 6:
			var color_a: Color = note_start_color[i]
			note_start_color[i] = Vector4(
				color_a.r, color_a.g, color_a.b, color_a.a
			)
			var color_b: Color = note_end_color[i]
			note_end_color[i] = Vector4(
				color_b.r, color_b.g, color_b.b, color_b.a
			)

		var alpha_duration: float = status[6] / 3.0

		var line_note: Array = line[5]
		var note_dsu_index: int = _search_index(line[6], 0)
		for i: int in range(note_dsu_index, line_note.size()):
			if note_index >= 384:
				break
			var note: Array = line_note[i]
			if note[0] == -1:
				continue
			var delta_time: float = note[3] - time
			if delta_time > note_end_time:
				break
			var delta_time_length: float = delta_time + note[4] if note[4] != null else delta_time
			if ( not note[15] and delta_time_length < note_start_time
			or editor and delta_time_length < 0.0 ):
				continue

			var type: int = note[1]
			var distance: float = 0.0
			var distance_length: float = 0.0
			if note_speed_mode == 2:
				distance = delta_time * note_speed * 0.0108
				if note[4] != null:
					distance_length = note[4] * note_speed * 0.0108
			else:
				distance = ( note[5] - line_distance ) * 10.8
				if note[4] != null:
					distance_length = note[6] * 10.8

			var alpha_multiplier: float = 1.0
			if delta_time < 0.0:
				if type % 2 == 1:
					distance_length = 0.0 if delta_time_length < 0.0 else distance_length + distance
					distance = 0.0
				if not note[14]:
					if note[4] != null and note[13]:
						alpha_multiplier = 0.3
					elif note[15] or editor:
						alpha_multiplier = 1.0
					else:
						alpha_multiplier = ( - delta_time - alpha_duration ) / ( alpha_duration * 2.0 ) * 0.7
						alpha_multiplier = clampf(1.0 - alpha_multiplier, 0.3, 1.0)
			distance *= note[10]
			distance_length *= note[10]
			var alpha: float = ( note_gradient_end_time - delta_time ) / ( note_gradient_end_time - note_gradient_start_time )
			alpha = note_gradient_start_alpha + ( 1.0 - clampf(alpha, 0.0, 1.0) ) * ( note_gradient_end_alpha - note_gradient_start_alpha )
			alpha *= alpha_multiplier

			var _sign: float = 1.0 if signf(distance_length) >= 0 else -1.0
			var pos: float = note[7]
			var dpos: float = 0.0
			if note[9] != null:
				pos += ( note[9] - pos ) * clampf(-delta_time / note[4], 0.0, 1.0)
				dpos = note[9] - pos
			note[16] = pos

			var note_array_index: int = note_index * 7
			var note_complex: int = type * 10 + note_style
			camera_data_0.w = ( 1.0 if note[12] else -1.0 ) * ( note_complex + 0.1 )
			_note_data_array.set(note_array_index, camera_data_0)
			var texture_vec: float = note[11]
			camera_data_1.z = sin(texture_vec)
			camera_data_1.w = cos(texture_vec)
			_note_data_array.set(note_array_index + 1, camera_data_1)

			if line_style == 1:
				var max_distance: float = half_line_length * 0.92 / cos_flip
				var comparor: Callable = maxf if max_distance < 0 else minf
				distance = comparor.call(distance, max_distance)
				var length: float = comparor.call(distance + distance_length, max_distance) - distance
				dpos *= 1.0 if distance_length == 0.0 else clampf(length / distance_length, 0.0, 1.0)
				var body_width_rad: float = note[8] / 10.0 * line_circle_angle
				var body_width: float = body_width_rad * line_length
				var frame_width_rad: float = double_frame_width / line_length
				var width_rad: float = body_width_rad + frame_width_rad
				var half_note_height: float = 0.0
				if note_style == 3:
					half_note_height = body_width / sqrt(3.0)
				elif note_style == 1 or note_style == 2 or note_style == 4:
					half_note_height = body_width / 2.0
				else:
					if note[9] == null:
						if type == 2 or type == 3:
							half_note_height = line_width * 1.1
						else:
							half_note_height = line_width * 2.2
				var half_border: float = ( half_note_height + frame_width ) * _sign
				var s_distance: float = distance - half_border
				var s_radius: float = half_line_length - s_distance * cos_flip
				var height: float = length + half_border * 2.0
				var e_radius: float = half_line_length - ( s_distance + height ) * cos_flip
				var z_height: float = height * sin_flip
				var rotate_fix: float = PI - line_circle_angle / 2.0
				var note_basis: Basis = Basis(Vector3(s_radius, 0.0, 0.0), Vector3(0.0, s_radius, 0.0), Vector3(0.0, 0.0, z_height))
				note_basis = note_basis.rotated(Vector3.BACK, pos * line_circle_angle / 2.0 - rotate_fix)
				var note_origin: Vector3 = Vector3(0.0, 0.0, -s_distance * sin_flip)

				var progress_border: float = 0.0
				if note_style == 3:
					progress_border = ( half_note_height / 2.0 + frame_width ) / height
				else:
					progress_border = ( half_note_height + frame_width ) / height
				_note_data_array.set(note_array_index + 2, Vector4(
					progress_border,
					-dpos * line_circle_angle / 2.0,
					-( e_radius - s_radius ) / s_radius,
					TAU / width_rad,
				))

				_note_multimesh_1.set_instance_custom_data(note_index_1, Color(
					note_index + 0.1,
					frame_width_rad / width_rad,
					frame_width / height * _sign,
					0.0,
				))
				_note_multimesh_1.set_instance_transform(note_index_1, line_transform * Transform3D(note_basis, note_origin))

				note_index_1 += 1

			else:
				var body_width: float = note[8] / 10.0 * line_length
				var width: float = body_width + double_frame_width
				var half_note_height: float = 0.0
				if note_style == 3:
					half_note_height = body_width / sqrt(3.0)
				elif note_style == 1 or note_style == 2 or note_style == 4:
					half_note_height = body_width / 2.0
				else:
					if note[9] == null:
						if type == 2 or type == 3:
							half_note_height = line_width * 1.1
						else:
							half_note_height = line_width * 2.2
				var height: float = absf(distance_length) + half_note_height * 2.0 + double_frame_width
				var note_basis: Basis = Basis(Vector3(width, 0.0, 0.0), Vector3(0.0, height * _sign, 0.0), Vector3(0.0, 0.0, 1.0))
				var note_origin: Vector3 = Vector3(pos * half_line_length, distance, 0.0)
				if note_upright:
					note_basis = note_basis.rotated(Vector3.FORWARD, -line_rot.z)
					note_origin = line_origin + line_basis * note_origin + Vector3(0.0, distance_length / 2.0, 0.0)
				else:
					note_origin += Vector3(0.0, distance_length / 2.0, 0.0)

				var progress_border: float = 0.0
				if note_style == 3:
					progress_border = ( half_note_height / 2.0 + frame_width ) / height
				else:
					progress_border = ( half_note_height + frame_width ) / height
				_note_data_array.set(note_array_index + 2, Vector4(
					progress_border,
					dpos * half_line_length / width,
					0.0,
					0.0,
				))

				_note_multimesh_0.set_instance_custom_data(note_index_0, Color(
					note_index + 0.1,
					frame_width / width,
					frame_width / height,
					0.0,
				))
				if note_upright:
					_note_multimesh_0.set_instance_transform(note_index_0, Transform3D(note_basis, note_origin))
				else:
					_note_multimesh_0.set_instance_transform(note_index_0, line_transform * Transform3D(note_basis, note_origin))

				note_index_0 += 1

			line_color_a.w = note_start_alpha * alpha
			_note_data_array.set(note_array_index + 3, line_color_a)
			line_color_b.w = note_end_alpha * alpha
			_note_data_array.set(note_array_index + 4, line_color_b)
			var color_a: Vector4 = note_start_color[type]
			color_a.w = note_start_alpha * alpha
			_note_data_array.set(note_array_index + 5, color_a)
			var color_b: Vector4 = note_end_color[type]
			color_b.w = note_end_alpha * alpha
			_note_data_array.set(note_array_index + 6, color_b)

			note_index += 1

	var effect_index: int = 0
	var effects: Array = chart_data[4]
	for i: int in range(effects.size()-1, -1, -1):
		if effect_index >= 256:
			break
		var effect: Dictionary = effects[i]
		var progress: float = maxf(time_raw - effect.time, 0.0) / 400.0
		if progress > 1.0:
			effects.remove_at(i)
			continue
		var cam_and_progress: Vector4 = effect.camera_pos
		cam_and_progress.w = progress
		var effect_array_index: int = effect_index * 3
		_effect_data_array.set(effect_array_index, cam_and_progress)
		_effect_data_array.set(effect_array_index + 1, effect.proj_pos)
		_effect_data_array.set(effect_array_index + 2, effect.color)

		var effect_basis: Basis = Basis().scaled(Vector3(_effect_size, _effect_size, 0.0))
		_effect_multimesh.set_instance_custom_data(effect_index, Color(effect_index + 0.1, 0.0, 0.0, 0.0))
		_effect_multimesh.set_instance_transform(effect_index, Transform3D(effect_basis, effect.pos))
		effect_index += 1

	var judgement_effect_index: int = 0
	if _judgement_enabled:
		effects = judgement.judgement_effects
		for i: int in range(effects.size()-1, -1, -1):
			if judgement_effect_index >= 128:
				break
			var effect: Dictionary = effects[i]
			var progress: float = maxf(time_raw - effect.time, 0.0) / 200.0
			if progress > 1.0:
				effects.remove_at(i)
				continue
			var ratio: float = effect.ratio
			var _position: Vector3 = Vector3(ratio * 9.6, 5.25, 0.0)
			_judgement_multimesh.set_instance_custom_data(judgement_effect_index, Color(ratio, progress, 0.0, 0.0))
			_judgement_multimesh.set_instance_transform(judgement_effect_index, Transform3D(Basis(), _position))
			judgement_effect_index += 1

	_line_material.set_shader_parameter("line_data", _line_data_array)
	_note_material_0.set_shader_parameter("note_data", _note_data_array)
	_note_material_1.set_shader_parameter("note_data", _note_data_array)
	_effect_material.set_shader_parameter("effect_data", _effect_data_array)

	_line_multimesh.visible_instance_count = line_index
	_note_multimesh_1.visible_instance_count = note_index_1
	_note_multimesh_0.visible_instance_count = note_index_0
	_effect_multimesh.visible_instance_count = effect_index
	_judgement_multimesh.visible_instance_count = judgement_effect_index
