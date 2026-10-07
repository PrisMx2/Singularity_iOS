extends Button

@export var follow_modulate: Array[Node] = []
@export var pixel_button: bool = false
@export var scroller: Control

@onready var image: Image = icon.get_image() if pixel_button else null

var _touch_position: Vector2 = Vector2(0.0, 0.0)
var _touch_index: int = -1

var _modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
var _modulate_vlist: Dictionary = {}
var _callable: Callable

func _tween_break() -> void:
	_touch_index = -1
	button_up.emit()

func _pressed() -> void:
	pass

func _ready() -> void:
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_color_override("font_disabled_color", Color.WHITE)
	add_theme_color_override("icon_disabled_color", Color.WHITE)
	connect("pressed", func():
		SoundManager.play("button_pressed")
		_pressed()
	)
	connect("button_down", func():
		_modulate = self_modulate
		self_modulate.v *= 0.8
		for node: Node in follow_modulate:
			_modulate_vlist[node] = node.self_modulate
			node.self_modulate.v *= 0.8
	)
	connect("button_up", func():
		self_modulate = _modulate
		for node: Node in _modulate_vlist:
			node.self_modulate = _modulate_vlist[node]
	)

func connect_override(callable: Callable) -> void:
	if _callable:
		disconnect("pressed", _callable)
	_callable = callable
	connect("pressed", callable)

func _input(event: InputEvent) -> void:
	if can_process() and is_visible_in_tree():
		if event is InputEventScreenTouch:
			if event.pressed and not event.canceled:
				if _touch_index == -1:
					var local_event: InputEvent = make_input_local(event)
					if not get_global_rect().has_point(event.position)\
					or pixel_button and image.get_pixelv(local_event.position).a8 < 25:
						return
					_touch_position = event.position
					_touch_index = event.index
					button_down.emit()
					accept_event()
			elif event.index == _touch_index:
				_touch_index = -1
				button_up.emit()
				pressed.emit()
				accept_event()
		elif event is InputEventScreenDrag:
			if event.index == _touch_index:
				var local_event: InputEvent = make_input_local(event)
				if ( not get_global_rect().has_point(event.position)
				or (event.position - _touch_position).length() > 25.0
				or pixel_button and image.get_pixelv(local_event.position).a8 < 25 ):
					_touch_index = -1
					button_up.emit()
					if scroller != null:
						var new_event: InputEventScreenTouch = InputEventScreenTouch.new()
						new_event.index = event.index
						new_event.pressed = true
						new_event.position = event.position
						scroller._input(new_event)
				accept_event()
