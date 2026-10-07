extends Control

@export var scroll_min: float = 0.0
@export var scroll_max: float = 1920.0
@export var resistance: float = 1.0

var _touch_index: int = -1

var _scroll_time: float = 0.0
var _scroll_record: float = 0.0
var _scroll_base: float = 0.0
var _scroll_pixel: float = 0.0
var _scroll_target: float = 0.0
var _scroll_speed: float = 0.0

var stable: bool = false

func _tween_break() -> void:
	_touch_index = -1

func _get_time() -> float:
	return Time.get_ticks_usec() / 1000.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if _touch_index == -1:
				var rect: Rect2 = get_global_rect()
				rect.position -= position
				if rect.has_point(event.position): 
					var y: float = event.position.y * 2.0 - position.y
					_touch_index = event.index
					_scroll_time = _get_time()
					_scroll_record = position.y
					_scroll_base = y
					_scroll_pixel = y
					_scroll_target = y
					_scroll_speed = 0.0
					accept_event()
		else:
			if _touch_index == event.index:
				_touch_index = -1
	elif event is InputEventScreenDrag:
		if _touch_index == event.index:
			_scroll_target = event.position.y * 2.0 - position.y
			accept_event()

func reset() -> void:
	_touch_index = -1
	_scroll_time = 0.0
	_scroll_record = 0.0
	_scroll_base = 0.0
	_scroll_pixel = 0.0
	_scroll_target = 0.0
	_scroll_speed = 0.0

func _process(_delta: float) -> void:
	var delta_time: float = _get_time() - _scroll_time

	if _touch_index == -1:
		_scroll_speed *= ( 1.0 - minf(absf(_scroll_speed) * delta_time * resistance / 50.0, 0.1) )
		if abs(_scroll_speed) < 0.2:
			_scroll_speed = 0.0
	else:
		_scroll_speed = _scroll_target - _scroll_pixel

	stable = _scroll_speed == 0.0
	_scroll_pixel += _scroll_speed * minf(delta_time / resistance / 20.0, 1.0)
	position.y = clampf((_scroll_record + _scroll_pixel - _scroll_base), -scroll_max, scroll_min)
	_scroll_time = _get_time()
