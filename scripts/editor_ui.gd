extends Control

const width: float = 1536.0
const height: float = 864.0

const event_max: int = 45

const base_y: float = height * 0.25

@export var root: Node2D

var zoom: float = 1.0

var beat_zoom: float = 4.0

var event_page: int = 0
var event_division: int = 8

func beat_to_y(beat: float) -> float:
	return 1.0

func _draw() -> void:
	if root.valid():

		draw_line(Vector2(0.0, 0.0), Vector2(width, height), Color.GREEN, 4.0, true)

		#var chunk: float
		#var beat: float = root.beat
		#var snapped_beat: float
		#for i: int in range(-1, 1):
			#
			#var y: float = beat_to_y(snappedf())
			#draw_line(Vector2(0.0, y), Vector2(width, y), Color.WHITE, 4.0, true)

		var pages: Array = root.edit_pages
		for page: int in pages:
			var line_index: int = page / 2
			var page_type: int = page % 2
			var line: Array = root.chart_data[1][line_index]
			var event_groups: Array = line[0]

			var s_type: int = event_page * event_division
			#if s_type > event_max:
				#event_page -= 1
			for event_type: int in range(s_type, s_type + event_division):
				var events: Array = event_groups[event_type]
				for event: Array in events:
					print(event)

			for event_layer_group: Array in line[2]:
				pass

func _unhandled_input(event: InputEvent) -> void:
	pass

func _process(_delta: float) -> void:
	queue_redraw()
